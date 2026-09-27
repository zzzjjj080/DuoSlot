import Foundation

/// カレンダーの予定（EventKit から写した最小限）
public struct CalEvent: Codable, Equatable, Sendable {
    public var title: String
    public var start: Date
    public var end: Date
    public var isAllDay: Bool

    public init(title: String, start: Date, end: Date, isAllDay: Bool = false) {
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
    }
}

/// 文字盤に出す「次の予定」1件
public struct NextEventDisplay: Equatable, Sendable {
    /// 上の小さい行（例：「14:30」「〜15:00」「明日 9:00」）
    public var when: String
    /// 下の行（予定の名前）。無いときは「予定なし」
    public var title: String
    public var inProgress: Bool
}

public enum NextEvent {
    /// 見る範囲。今から36時間先まで（夜に見ても明日の朝の予定が出る）
    public static let horizon: TimeInterval = 36 * 3600

    /// 出す1件を選ぶ。終日の予定は出さない（時刻の付いた予定だけ）。
    /// 進行中のものがあればそれ、無ければ次に始まるもの
    public static func pick(_ events: [CalEvent], now: Date) -> CalEvent? {
        events
            .filter { !$0.isAllDay && $0.end > now && $0.start < now.addingTimeInterval(horizon) }
            .sorted { ($0.start, $0.end) < ($1.start, $1.end) }
            .first
    }

    public static func display(_ events: [CalEvent], now: Date, calendar: Calendar = .current) -> NextEventDisplay {
        guard let e = pick(events, now: now) else {
            return NextEventDisplay(when: "", title: "予定なし", inProgress: false)
        }
        let title = e.title.isEmpty ? "（無題）" : e.title
        if e.start <= now {
            return NextEventDisplay(when: "〜" + hm(e.end, calendar), title: title, inProgress: true)
        }
        let prefix: String
        if calendar.isDate(e.start, inSameDayAs: now) {
            prefix = ""
        } else if let t = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(e.start, inSameDayAs: t) {
            prefix = "明日 "
        } else {
            prefix = "\(calendar.component(.month, from: e.start))/\(calendar.component(.day, from: e.start)) "
        }
        return NextEventDisplay(when: prefix + hm(e.start, calendar), title: title, inProgress: false)
    }

    /// 表示が変わる時刻（予定の始まり・終わり・日付の変わり目）。タイムラインの区切りに使う。
    /// 予定は先に分かっているので、描き直しを頼まなくても時刻どおりに切り替わる（4-113）
    public static func changeDates(_ events: [CalEvent], now: Date, until: Date, calendar: Calendar = .current) -> [Date] {
        var dates = Set<Date>()
        for e in events where !e.isAllDay {
            for d in [e.start, e.end] where d > now && d <= until { dates.insert(d) }
        }
        var day = calendar.startOfDay(for: now)
        while let next = calendar.date(byAdding: .day, value: 1, to: day), next <= until {
            dates.insert(next)
            day = next
        }
        return dates.sorted()
    }

    static func hm(_ d: Date, _ calendar: Calendar) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: d)
        return String(format: "%d:%02d", c.hour ?? 0, c.minute ?? 0)
    }
}
