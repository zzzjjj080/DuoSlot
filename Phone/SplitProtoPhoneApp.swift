import SwiftUI

/// Watch アプリを届けるための器（Watch へ直接入らないので iPhone 経由で入れる。引き継ぎ書 4-151・4-181）
@main
struct SplitProtoPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Text("SplitProto（試作）").font(.title2.bold())
                Text("Apple Watch の文字盤で、大きい四角の左右を押し分けられるかを確かめる試作です。")
                    .multilineTextAlignment(.center)
                Text(stamp).font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
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
