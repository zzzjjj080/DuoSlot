import Foundation

/// 大きい四角の左右に出せるもの。**`rawValue` は保存・URL・設定に使うので変えない。**
public enum Slot: String, CaseIterable, Codable, Sendable, Identifiable {
    case battery
    case steps
    case nextEvent

    public var id: String { rawValue }

    /// SF Symbols の名前
    public var symbol: String {
        switch self {
        case .battery: "battery.75percent"
        case .steps: "figure.walk"
        case .nextEvent: "calendar"
        }
    }

    /// 文字盤で押したときに開く先（アプリの `onOpenURL` で受ける）
    public var url: URL { URL(string: "\(Slot.scheme)://\(rawValue)")! }

    public static let scheme = "duoslot"

    public init?(url: URL) {
        guard url.scheme == Slot.scheme, let host = url.host(), let s = Slot(rawValue: host) else { return nil }
        self = s
    }
}

/// 左右の組み合わせ。左右に同じものは置かない
public struct SlotPair: Hashable, Codable, Sendable {
    public var left: Slot
    public var right: Slot

    public init(left: Slot, right: Slot) {
        self.left = left
        self.right = right
    }

    /// 文字盤の編集画面に並べる候補（左右の順も区別して全部）
    public static var all: [SlotPair] {
        Slot.allCases.flatMap { l in
            Slot.allCases.filter { $0 != l }.map { SlotPair(left: l, right: $0) }
        }
    }

    public static let `default` = SlotPair(left: .steps, right: .battery)
}
