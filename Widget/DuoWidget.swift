import AppIntents
import DuoCore
import SwiftUI
import WidgetKit

// MARK: - 組み合わせの設定（文字盤の編集画面で選ぶ）

/// AppEnum は別のパッケージの型に付けられない（メタデータの書き出しで弾かれる）ので、ここで写しを持つ。
/// **`rawValue` は `Slot` と同じにしておく**
enum SlotChoice: String, AppEnum {
    case battery, steps, nextEvent

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "表示するもの"
    static let caseDisplayRepresentations: [SlotChoice: DisplayRepresentation] = [
        .battery: "電池", .steps: "歩数", .nextEvent: "次の予定",
    ]

    var slot: Slot { Slot(rawValue: rawValue) ?? .steps }
    init(_ slot: Slot) { self = SlotChoice(rawValue: slot.rawValue) ?? .steps }
}

struct PairIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "左右に出すもの"
    static let description = IntentDescription("大きい四角の左と右に出すものを選びます。")

    @Parameter(title: "左", default: .steps) var left: SlotChoice
    @Parameter(title: "右", default: .battery) var right: SlotChoice

    init() {}
    init(_ pair: SlotPair) {
        left = SlotChoice(pair.left)
        right = SlotChoice(pair.right)
    }

    var pair: SlotPair { SlotPair(left: left.slot, right: right.slot) }
}

// MARK: - タイムライン

struct Entry: TimelineEntry {
    let date: Date
    let pair: SlotPair
    let snapshot: Snapshot
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: .now, pair: .default, snapshot: .sample)
    }

    func snapshot(for configuration: PairIntent, in context: Context) async -> Entry {
        if context.isPreview { return Entry(date: .now, pair: configuration.pair, snapshot: .sample) }
        return Entry(date: .now, pair: configuration.pair, snapshot: await read())
    }

    func timeline(for configuration: PairIntent, in context: Context) async -> Timeline<Entry> {
        let now = Date.now
        let snap = await read(now: now)
        let refresh = now.addingTimeInterval(15 * 60)
        // 予定は先に分かっているので、始まり・終わりの時刻にあらかじめ区切っておく
        let dates = [now] + NextEvent.changeDates(snap.events ?? [], now: now, until: refresh)
        let entries = dates.map { Entry(date: $0, pair: configuration.pair, snapshot: snap) }
        return Timeline(entries: entries, policy: .after(refresh))
    }

    /// watchOS では、設定つきのウィジェットは「おすすめ」に並べたものだけが文字盤の編集画面に出る
    func recommendations() -> [AppIntentRecommendation<PairIntent>] {
        SlotPair.all.map { AppIntentRecommendation(intent: PairIntent($0), description: $0.name) }
    }

    private func read(now: Date = .now) async -> Snapshot {
        Snapshot(battery: BatteryReader.read(), steps: await StepsReader.read(now: now),
                 events: EventsReader.readOrStored(now: now))
    }
}

// MARK: - 枠

struct DuoWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "duo.rect", intent: PairIntent.self, provider: Provider()) { e in
            PairView(pair: e.pair, snapshot: e.snapshot, now: e.date)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Duo Slot")
        .description("大きい四角の左右に、別々のものを出します。")
        .supportedFamilies([.accessoryRectangular])
    }
}

@main
struct DuoWidgets: WidgetBundle {
    var body: some Widget { DuoWidget() }
}
