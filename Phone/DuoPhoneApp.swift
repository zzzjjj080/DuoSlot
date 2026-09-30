import SwiftUI

/// Watch アプリを届けるための器（watchOS 単体は App Store に出せない。4-91）
@main
struct DuoPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    Section("使い方") {
                        Text("1. Apple Watch の文字盤を長押しして「編集」")
                        Text("2. 大きい四角を押し、このアプリを選ぶ")
                        Text("3. 左右の組み合わせ（例：歩数｜電池）を選ぶ")
                    }
                    Section { Text("文字盤で左右を押すと、押した側の画面が Watch で開きます。") }
                    Section {
                        // 投げ銭の代わり。控えめな1行（2026-09-30 本人判断で投げ銭は廃止）
                        Link(destination: URL(string: "https://apps.apple.com/jp/developer/jin-nakamura/id6802013586")!) {
                            Label("作者の他のアプリ", systemImage: "square.grid.2x2")
                                .font(.footnote)
                        }
                    }
                    Text(verbatim: stamp).font(.footnote).foregroundStyle(.secondary)
                }
                .navigationTitle(Text(verbatim: "Duo Slot"))
            }
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
