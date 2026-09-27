import DuoCore
import SwiftUI
import WidgetKit

@main
struct DuoWatchApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if let shot = Shot.current { ShotView(shot: shot) } else { RootView() }
            #else
            RootView()
            #endif
        }
    }
}

struct RootView: View {
    @Environment(\.scenePhase) private var phase
    @State private var snapshot = Snapshot(battery: BatteryReading(level: nil, charging: false), steps: nil, events: nil)
    @State private var path: [Slot] = []
    @State private var lastShown: String?
    @State private var showTip = false
    @State private var tipJar = TipJar(productID: TipJar.duoSlot)

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
                Button { showTip = true } label: {
                    Label("コーヒーを奢る", systemImage: "heart")
                }
                Text(verbatim: Stamp.text).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            .navigationTitle(Text(verbatim: "Duo Slot"))
            .navigationDestination(for: Slot.self) { DetailView(slot: $0, snapshot: snapshot) }
            .sheet(isPresented: $showTip) { TipView(tipJar: tipJar) { showTip = false } }
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
                    Label(snapshot.battery.charging ? String(localized: "充電中") : Slot.battery.title, systemImage: snapshot.battery.symbol)
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
                                Text(d.whenText ?? "").font(.caption).foregroundStyle(.cyan)
                                Text(d.titleText).font(.headline)
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

#if DEBUG
/// ストア用の撮影モード。**DEBUG 構成にしか無い**。`SIMCTL_CHILD_DS_SHOT=face1` などで起動する。
/// 数字は見本（歩数 8,432・電池 82%・予定は2時間後）。許可のダイアログは出さない
enum Shot: String {
    case face1, face2, face3, list, steps, tip

    static var current: Shot? { ProcessInfo.processInfo.environment["DS_SHOT"].flatMap(Shot.init) }

    static var sample: Snapshot {
        let start = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: .now) ?? .now
        return Snapshot(battery: BatteryReading(level: 0.82, charging: false), steps: 8432,
                        events: [CalEvent(title: String(localized: "打ち合わせ"),
                                          start: start, end: start.addingTimeInterval(3600))])
    }

    /// 撮影時刻は 10:09 に見せる（予定は 14:30 なので「次の予定」になる）
    static var now: Date { Calendar.current.date(bySettingHour: 10, minute: 9, second: 0, of: .now) ?? .now }
}

struct ShotView: View {
    let shot: Shot
    @State private var tipJar = TipJar(productID: TipJar.duoSlot)

    var body: some View {
        switch shot {
        case .face1: FaceMock(pair: SlotPair(left: .steps, right: .battery))
        case .face2: FaceMock(pair: SlotPair(left: .battery, right: .nextEvent))
        case .face3: FaceMock(pair: SlotPair(left: .nextEvent, right: .steps))
        case .list:
            NavigationStack {
                List {
                    Section {
                        PairView(pair: .default, snapshot: Shot.sample, now: Shot.now, linked: false).frame(height: 50)
                    } footer: { Text("文字盤の大きい四角に置くと、左右で別々のものが出ます。押した側の画面が開きます。") }
                    ForEach(Slot.allCases) { Label($0.title, systemImage: $0.symbol) }
                }
                .navigationTitle(Text(verbatim: "Duo Slot"))
            }
        case .steps: NavigationStack { DetailView(slot: .steps, snapshot: Shot.sample) }
        case .tip: TipView(tipJar: tipJar) {}
        }
    }
}

/// 文字盤に置いたときの見た目（撮影用）。時刻はシステムが右上に出すものをそのまま使う
/// （Watch のシミュレータは status_bar の上書きが効かず、時刻を消すこともできない）
struct FaceMock: View {
    let pair: SlotPair

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Date.now.formatted(.dateTime.weekday(.abbreviated).day()))
                .font(.system(size: 18, weight: .semibold)).foregroundStyle(.orange)
                .frame(height: 30)
            PairView(pair: pair, snapshot: Shot.sample, now: Shot.now, linked: false)
                .frame(height: 58)
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.12)))
            Spacer(minLength: 0)
            Text("1つの枠に、2つ。")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.bottom, 18)
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
    }
}
#endif
