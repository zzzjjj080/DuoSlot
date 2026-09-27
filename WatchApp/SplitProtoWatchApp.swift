import SwiftUI
import WidgetKit

@main
struct SplitProtoWatchApp: App {
    var body: some Scene {
        WindowGroup { LogView() }
    }
}

/// 押した結果の記録を出すだけの画面。
/// 文字盤で押す → アプリが開いたら「URL: …」、開かずに数字が変わったら「Intent …」が並ぶ
struct LogView: View {
    @Environment(\.scenePhase) private var phase
    @State private var lines = TapLog.lines
    @State private var opened: String?

    var body: some View {
        List {
            if let opened {
                Section("いま開いた行き先") { Text(opened).font(.headline) }
            }
            Section("記録（新しい順）") {
                if lines.isEmpty { Text("まだ何もありません").foregroundStyle(.secondary) }
                ForEach(lines, id: \.self) { Text($0).font(.footnote) }
            }
            Button("記録を消す", role: .destructive) {
                TapLog.clear()
                lines = []
                opened = nil
            }
            Text(stamp).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .onOpenURL { url in
            let name = url.absoluteString.replacingOccurrences(of: "splitproto://", with: "")
            TapLog.add("URL: \(name)")
            opened = name
            lines = TapLog.lines
        }
        .onChange(of: phase) { _, p in
            if p == .active { lines = TapLog.lines }
            if p != .active { opened = nil }
        }
    }

    private var stamp: String {
        let i = Bundle.main.infoDictionary ?? [:]
        let v = i["CFBundleShortVersionString"] as? String ?? "?"
        let b = i["CFBundleVersion"] as? String ?? "?"
        let s = (i["SPBuildStamp"] as? String).flatMap { $0.isEmpty ? nil : " · \($0)" } ?? ""
        return "\(v) (\(b))\(s)"
    }
}
