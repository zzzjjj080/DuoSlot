import DuoCore
import SwiftUI
import WidgetKit

@main
struct DuoWatchApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    @Environment(\.scenePhase) private var phase
    @State private var snapshot = Snapshot(battery: BatteryReading(level: nil, charging: false), steps: nil, events: nil)
    @State private var path: [Slot] = []
    @State private var lastShown: String?

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    PairView(pair: .default, snapshot: snapshot, now: .now, linked: false)
                        .frame(height: 50)
                } footer: {
                    Text("文字盤の大きい四角に置くと、左右で別々のものが出ます。押した側の画面が開きます。")
                }
                ForEach(Slot.allCases) { slot in
                    NavigationLink(value: slot) { Label(slot.title, systemImage: slot.symbol) }
                }
                Text(Stamp.text).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            .navigationTitle("Duo Slot")
            .navigationDestination(for: Slot.self) { DetailView(slot: $0, snapshot: snapshot) }
        }
        .task { await firstLaunch() }
        .onOpenURL { url in
            if let slot = Slot(url: url) { path = [slot] }
        }
        .onChange(of: phase) { _, p in
            if p == .active { Task { await refresh() } }
            // 出るときは必ず描き直しを頼む（中と外で数字を食い違わせない。4-168）
            if p == .inactive || p == .background { reloadIfChanged() }
        }
    }

    private func firstLaunch() async {
        await StepsReader.requestAuthorization()
        if !EventsReader.authorized { _ = await EventsReader.requestAuthorization() }
        await refresh()
    }

    private func refresh() async {
        snapshot = Snapshot(battery: BatteryReader.read(), steps: await StepsReader.read(), events: EventsReader.readOrStored())
    }

    private func reloadIfChanged() {
        let key = "\(snapshot.battery.percentText)|\(snapshot.steps ?? -1)|\(snapshot.events?.count ?? -1)"
        guard key != lastShown else { return }
        lastShown = key
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct DetailView: View {
    let slot: Slot
    let snapshot: Snapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                switch slot {
                case .battery:
                    Label(snapshot.battery.charging ? "充電中" : "電池", systemImage: snapshot.battery.symbol)
                    Text(snapshot.battery.percentText).font(.system(size: 44, weight: .semibold, design: .rounded))
                case .steps:
                    Label("今日の歩数", systemImage: "figure.walk")
                    Text(StepsText.format(snapshot.steps)).font(.system(size: 40, weight: .semibold, design: .rounded))
                    Text("ヘルスケアの合計（iPhone のぶんも含む）").font(.footnote).foregroundStyle(.secondary)
                case .nextEvent:
                    if let events = snapshot.events {
                        let upcoming = events.filter { !$0.isAllDay && $0.end > .now }.sorted { $0.start < $1.start }
                        if upcoming.isEmpty { Text("36時間以内の予定はありません").foregroundStyle(.secondary) }
                        ForEach(Array(upcoming.prefix(8).enumerated()), id: \.offset) { _, e in
                            let d = NextEvent.display([e], now: .now)
                            VStack(alignment: .leading) {
                                Text(d.when).font(.caption).foregroundStyle(.cyan)
                                Text(d.title).font(.headline)
                            }
                        }
                    } else {
                        Text("カレンダーの許可がありません。Watch の「設定 → プライバシーとセキュリティ → カレンダー」でオンにしてください。")
                            .font(.footnote)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(slot.title)
    }
}

enum Stamp {
    static var text: String {
        let i = Bundle.main.infoDictionary ?? [:]
        let v = i["CFBundleShortVersionString"] as? String ?? "?"
        let b = i["CFBundleVersion"] as? String ?? "?"
        let s = (i["SPBuildStamp"] as? String).flatMap { $0.isEmpty ? nil : " · \($0)" } ?? ""
        return "\(v) (\(b))\(s)"
    }
}
