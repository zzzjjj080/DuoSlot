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
            guard let events = snapshot.events else { return "予定" }
            let d = NextEvent.display(events, now: now)
            return d.when.isEmpty ? "予定" : d.when
        }
    }

    private var value: String {
        switch slot {
        case .battery: return snapshot.battery.percentText
        case .steps: return StepsText.format(snapshot.steps)
        case .nextEvent:
            guard let events = snapshot.events else { return "許可なし" }
            return NextEvent.display(events, now: now).title
        }
    }

    private var valueSize: CGFloat { slot == .nextEvent ? 15 : 24 }
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
    }

    @ViewBuilder private func half(_ slot: Slot) -> some View {
        if linked {
            Link(destination: slot.url) { SlotHalf(slot: slot, snapshot: snapshot, now: now) }
        } else {
            SlotHalf(slot: slot, snapshot: snapshot, now: now)
        }
    }
}
