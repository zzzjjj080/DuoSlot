import Foundation
import WidgetKit

/// 押したときに何が起きたかの記録。アプリ（URL で開いた）と拡張（App Intent が走った）の両方が書く。
/// 文字盤の上で押し分けが効いたかどうかは、ここに残った行で判定する。
enum TapLog {
    static let group = "group.com.zzzjjj080.SplitProto"
    static var defaults: UserDefaults { UserDefaults(suiteName: group) ?? .standard }

    static func add(_ text: String) {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        var lines = defaults.stringArray(forKey: "log") ?? []
        lines.insert("\(f.string(from: Date()))  \(text)", at: 0)
        defaults.set(Array(lines.prefix(40)), forKey: "log")
    }

    static var lines: [String] { defaults.stringArray(forKey: "log") ?? [] }

    static func clear() {
        defaults.removeObject(forKey: "log")
        for k in ["left", "right"] { defaults.removeObject(forKey: "count.\(k)") }
        for k in ["left", "right"] { defaults.removeObject(forKey: "on.\(k)") }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func count(_ side: String) -> Int { defaults.integer(forKey: "count.\(side)") }
    static func bump(_ side: String) { defaults.set(count(side) + 1, forKey: "count.\(side)") }
    static func isOn(_ side: String) -> Bool { defaults.bool(forKey: "on.\(side)") }
    static func setOn(_ side: String, _ v: Bool) { defaults.set(v, forKey: "on.\(side)") }
}
