import DuoCore
import SwiftUI

/// 1回ぶんの読み取り結果。文字盤とアプリの両方がこれを描く
struct Snapshot {
    var battery: BatteryReading
    var steps: Int?
    /// nil はカレンダーの許可が無い
    var events: [CalEvent]?

    static let sample = Snapshot(
        battery: BatteryReading(level: 0.82, charging: false), steps: 8432,
        events: [CalEvent(title: "打ち合わせ", start: .now.addingTimeInterval(3600), end: .now.addingTimeInterval(7200))])
}

/// 大きい四角の半分。上に小さい見出し、下に大きい値
struct SlotHalf: View {
    let slot: Slot
    let snapshot: Snapshot
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 2) {
                Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
                Text(caption).font(.system(size: 12, weight: .semibold)).lineLimit(1)
            }
            .foregroundStyle(tint)
            .widgetAccentable()
            Text(value)
                .font(.system(size: valueSize, weight: .semibold, design: .rounded))
                .lineLimit(slot == .nextEvent ? 2 : 1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
    }

    private var symbol: String {
        slot == .battery ? snapshot.battery.symbol : slot.symbol
    }

    private var tint: Color {
        switch slot {
        case .battery: snapshot.battery.isLow ? .red : .green
        case .steps: .orange
        case .nextEvent: .cyan
        }
    }

    private var caption: String {
        switch slot {
        case .battery, .steps: return slot.title
        case .nextEvent:
            guard let events = snapshot.events else { return String(localized: "予定") }
            return NextEvent.display(events, now: now).whenText ?? String(localized: "予定")
        }
    }

    private var value: String {
        switch slot {
        case .battery: return snapshot.battery.percentText
        case .steps: return StepsText.format(snapshot.steps)
        case .nextEvent:
            guard let events = snapshot.events else { return String(localized: "許可なし") }
            return NextEvent.display(events, now: now).titleText
        }
    }

    private var valueSize: CGFloat { slot == .nextEvent ? 15 : 24 }
}

/// 文言は Core に持たせず、ここで訳す（引き継ぎ書 4-178）
extension Slot {
    var title: String {
        switch self {
        case .battery: String(localized: "電池")
        case .steps: String(localized: "歩数")
        case .nextEvent: String(localized: "次の予定")
        }
    }
}

extension SlotPair {
    var name: String { "\(left.title) | \(right.title)" }
}

extension NextEventDisplay {
    /// 上の小さい行。予定が無いときは nil
    var whenText: String? {
        switch self {
        case .none: return nil
        case .now(_, let until): return String(localized: "〜\(Self.time(until))")
        case .upcoming(_, let start, let day):
            switch day {
            case .today: return Self.time(start)
            case .tomorrow: return String(localized: "明日 \(Self.time(start))")
            case .later: return start.formatted(.dateTime.month(.defaultDigits).day().hour().minute())
            }
        }
    }

    var titleText: String {
        if case .none = self { return String(localized: "予定なし") }
        return title ?? String(localized: "（無題）")
    }

    static func time(_ d: Date) -> String { d.formatted(date: .omitted, time: .shortened) }
}

/// 大きい四角の中身。左右それぞれを Link で包むと、文字盤の上で押し分けられる（引き継ぎ書 4-193）
struct PairView: View {
    let pair: SlotPair
    let snapshot: Snapshot
    let now: Date
    var linked = true

    var body: some View {
        HStack(spacing: 6) {
            half(pair.left)
            Rectangle().fill(.secondary.opacity(0.35)).frame(width: 1)
            half(pair.right)
        }
        // 「左」「右」は画面の左右のこと。右から左の言語でも入れ替えない（引き継ぎ書 4-187）
        .environment(\.layoutDirection, .leftToRight)
    }

    @ViewBuilder private func half(_ slot: Slot) -> some View {
        if linked {
            Link(destination: slot.url) { SlotHalf(slot: slot, snapshot: snapshot, now: now) }
        } else {
            SlotHalf(slot: slot, snapshot: snapshot, now: now)
        }
    }
}
