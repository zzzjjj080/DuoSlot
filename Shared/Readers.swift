import CoreMotion
import DuoCore
import EventKit
import Foundation
import HealthKit
import WatchKit
import WidgetKit

/// アプリと文字盤の拡張で共有する保存場所（App Group）。
/// 拡張は自分でも読みに行くが、読めなかったときはアプリが最後に書いた値を出す
enum Shared {
    static let group = "group.com.zzzjjj080.DuoSlot"
    static var defaults: UserDefaults { UserDefaults(suiteName: group) ?? .standard }

    static func save<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }

    static func load<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

struct StoredSteps: Codable {
    var steps: Int
    var day: Date
}

// MARK: - 電池

enum BatteryReader {
    static func read() -> BatteryReading {
        let dev = WKInterfaceDevice.current()
        dev.isBatteryMonitoringEnabled = true
        let r = BatteryReading(raw: dev.batteryLevel, charging: dev.batteryState == .charging || dev.batteryState == .full)
        if r.level != nil {
            Shared.save(r, "battery")
            return r
        }
        return Shared.load(BatteryReading.self, "battery") ?? r
    }
}

// MARK: - 歩数（引き継ぎ書 4-168：ヘルスケアの合計＋その後の歩数計）

enum StepsReader {
    static let health = HKHealthStore()
    static let stepType = HKQuantityType(.stepCount)

    /// 許可を求める（アプリ本体だけ。拡張からは呼ばない）
    static func requestAuthorization() async {
        if HKHealthStore.isHealthDataAvailable() {
            try? await health.requestAuthorization(toShare: [], read: [stepType])
        }
        // 歩数計（モーション）の許可は、1回読むと出る
        _ = try? await pedometer(from: Calendar.current.startOfDay(for: .now), to: .now)
    }

    static func read(now: Date = .now) async -> Int? {
        let start = Calendar.current.startOfDay(for: now)
        let watchToday = try? await pedometer(from: start, to: now)
        var healthTotal: Int?
        var since: Int?
        if HKHealthStore.isHealthDataAvailable(), let until = await lastWatchSampleEnd(from: start, to: now) {
            let p = HKQuery.predicateForSamples(withStart: start, end: until, options: [])
            let d = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: stepType, predicate: p), options: .cumulativeSum)
            if let sum = try? await d.result(for: health)?.sumQuantity() {
                healthTotal = Int(sum.doubleValue(for: .count()))
                since = try? await pedometer(from: until, to: now)
            }
        }
        let fresh = StepCombiner.steps(healthTotal: healthTotal, watchSince: since, watchToday: watchToday)
        // 同じ日なら大きいほうを残す（アプリと拡張が別々に読むので、小さい数で戻さない。4-168）
        let stored = Shared.load(StoredSteps.self, "steps").flatMap { Calendar.current.isDate($0.day, inSameDayAs: now) ? $0.steps : nil }
        let best = [fresh, stored].compactMap { $0 }.max()
        if let best { Shared.save(StoredSteps(steps: best, day: now), "steps") }
        return best
    }

    static func lastWatchSampleEnd(from start: Date, to now: Date) async -> Date? {
        let p = HKQuery.predicateForSamples(withStart: start, end: now, options: [])
        let d = HKSampleQueryDescriptor(predicates: [.quantitySample(type: stepType, predicate: p)],
                                        sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)], limit: 100)
        guard let samples = try? await d.result(for: health) else { return nil }
        return samples.first {
            ($0.sourceRevision.productType?.hasPrefix("Watch") ?? false) || $0.device?.model == "Watch"
        }?.endDate
    }

    static func pedometer(from: Date, to: Date) async throws -> Int {
        guard from < to else { return 0 }
        guard CMPedometer.isStepCountingAvailable() else { throw CocoaError(.featureUnsupported) }
        nonisolated(unsafe) let p = CMPedometer()
        return try await withCheckedThrowingContinuation { cont in
            p.queryPedometerData(from: from, to: to) { data, error in
                _ = p   // 返事が来るまで手放さない
                if let data { cont.resume(returning: data.numberOfSteps.intValue) }
                else { cont.resume(throwing: error ?? CocoaError(.featureUnsupported)) }
            }
        }
    }
}

// MARK: - 次の予定

enum EventsReader {
    static let store = EKEventStore()

    static var authorized: Bool { EKEventStore.authorizationStatus(for: .event) == .fullAccess }

    static func requestAuthorization() async -> Bool {
        (try? await store.requestFullAccessToEvents()) ?? false
    }

    static func read(now: Date = .now) -> [CalEvent]? {
        guard authorized else { return nil }
        let p = store.predicateForEvents(withStart: now.addingTimeInterval(-12 * 3600),
                                         end: now.addingTimeInterval(NextEvent.horizon), calendars: nil)
        let events = store.events(matching: p).map {
            CalEvent(title: $0.title ?? "", start: $0.startDate, end: $0.endDate, isAllDay: $0.isAllDay)
        }
        Shared.save(events, "events")
        return events
    }

    static func readOrStored(now: Date = .now) -> [CalEvent]? {
        read(now: now) ?? Shared.load([CalEvent].self, "events")
    }
}
