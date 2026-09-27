import AppIntents
import SwiftUI
import WidgetKit

// 大きい四角（accessoryRectangular）で、左右を押し分けられるかを確かめる試作。
// 押し方ごとに別の枠にしてあるので、文字盤に1つずつ置いて比べる。
//   ① Link×2       … 左右に別の URL
//   ② ボタン×2     … Button(intent:)。効けばアプリを開かず数字が増える
//   ③ トグル×2     … Toggle(isOn:intent:)
//   ④ 全体で1つ    … widgetURL だけ（比べる基準）

struct Entry: TimelineEntry {
    let date: Date
    let left: Int
    let right: Int
    let leftOn: Bool
    let rightOn: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { make() }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(make()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [make()], policy: .never))
    }
    private func make() -> Entry {
        Entry(date: Date(), left: TapLog.count("left"), right: TapLog.count("right"),
              leftOn: TapLog.isOn("left"), rightOn: TapLog.isOn("right"))
    }
}

/// 左右の見た目（中身は仮。左に歩数、右に電池のつもり）
struct Half: View {
    let symbol: String
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Label(title, systemImage: symbol).font(.caption2).lineLimit(1)
            Text(value).font(.title3.weight(.semibold)).minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct Divided<L: View, R: View>: View {
    let tag: String
    @ViewBuilder let left: L
    @ViewBuilder let right: R
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(tag).font(.system(size: 11)).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                left
                Rectangle().frame(width: 1).opacity(0.3)
                right
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// ① Link×2
struct LinkWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "split.link", provider: Provider()) { e in
            Divided(tag: "① Link×2") {
                Link(destination: URL(string: "splitproto://link/left")!) {
                    Half(symbol: "figure.walk", title: "左", value: "A")
                }
            } right: {
                Link(destination: URL(string: "splitproto://link/right")!) {
                    Half(symbol: "battery.75", title: "右", value: "B")
                }
            }
        }
        .configurationDisplayName("① Link×2")
        .description("左右に別の URL")
        .supportedFamilies([.accessoryRectangular])
    }
}

// ② Button(intent:)×2
struct ButtonWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "split.button", provider: Provider()) { e in
            Divided(tag: "② ボタン×2") {
                Button(intent: TapSideIntent(side: "left")) {
                    Half(symbol: "figure.walk", title: "左", value: "\(e.left)")
                }.buttonStyle(.plain)
            } right: {
                Button(intent: TapSideIntent(side: "right")) {
                    Half(symbol: "battery.75", title: "右", value: "\(e.right)")
                }.buttonStyle(.plain)
            }
        }
        .configurationDisplayName("② ボタン×2")
        .description("押すと数字が増えれば成功")
        .supportedFamilies([.accessoryRectangular])
    }
}

// ③ Toggle(isOn:intent:)×2
struct ToggleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "split.toggle", provider: Provider()) { e in
            Divided(tag: "③ トグル×2") {
                Toggle(isOn: e.leftOn, intent: ToggleSideIntent(side: "left")) {
                    Half(symbol: "figure.walk", title: "左", value: e.leftOn ? "ON" : "off")
                }.toggleStyle(.button)
            } right: {
                Toggle(isOn: e.rightOn, intent: ToggleSideIntent(side: "right")) {
                    Half(symbol: "battery.75", title: "右", value: e.rightOn ? "ON" : "off")
                }.toggleStyle(.button)
            }
        }
        .configurationDisplayName("③ トグル×2")
        .description("押すと ON/off が変われば成功")
        .supportedFamilies([.accessoryRectangular])
    }
}

// ④ widgetURL（全体で1つ。比べる基準）
struct WholeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "split.whole", provider: Provider()) { _ in
            Divided(tag: "④ 全体で1つ") {
                Half(symbol: "figure.walk", title: "左", value: "A")
            } right: {
                Half(symbol: "battery.75", title: "右", value: "B")
            }
            .widgetURL(URL(string: "splitproto://whole")!)
        }
        .configurationDisplayName("④ 全体で1つ")
        .description("widgetURL だけ（基準）")
        .supportedFamilies([.accessoryRectangular])
    }
}

@main
struct SplitWidgets: WidgetBundle {
    var body: some Widget {
        LinkWidget()
        ButtonWidget()
        ToggleWidget()
        WholeWidget()
    }
}
