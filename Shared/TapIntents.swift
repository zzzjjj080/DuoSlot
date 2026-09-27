import AppIntents
import WidgetKit

/// 枠の中の Button から呼ぶ。アプリを開かずに拡張の中で走る（効けば数字だけが増える）
struct TapSideIntent: AppIntent {
    static var title: LocalizedStringResource = "左右を押した"
    static var isDiscoverable = false

    @Parameter(title: "側") var side: String

    init() {}
    init(side: String) { self.side = side }

    func perform() async throws -> some IntentResult {
        TapLog.bump(side)
        TapLog.add("Intent ボタン: \(side == "left" ? "左" : "右")")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// 枠の中の Toggle から呼ぶ
struct ToggleSideIntent: SetValueIntent {
    static var title: LocalizedStringResource = "左右を切り替えた"
    static var isDiscoverable = false

    @Parameter(title: "側") var side: String
    @Parameter(title: "値") var value: Bool

    init() {}
    init(side: String) { self.side = side }

    func perform() async throws -> some IntentResult {
        TapLog.setOn(side, value)
        TapLog.add("Intent トグル: \(side == "left" ? "左" : "右") → \(value ? "オン" : "オフ")")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
