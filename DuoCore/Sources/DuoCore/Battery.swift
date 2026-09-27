import Foundation

public struct BatteryReading: Codable, Equatable, Sendable {
    /// 0...1。読めないときは nil（watchOS は監視を入れる前や一部の状況で -1 を返す）
    public var level: Double?
    public var charging: Bool

    public init(level: Double?, charging: Bool) {
        self.level = level
        self.charging = charging
    }

    /// `WKInterfaceDevice.batteryLevel` の生の値から作る
    public init(raw: Float, charging: Bool) {
        self.level = (raw >= 0 && raw <= 1) ? Double(raw) : nil
        self.charging = charging
    }

    public var percentText: String {
        guard let level else { return "--" }
        return "\(Int((level * 100).rounded()))%"
    }

    public var symbol: String {
        if charging { return "battery.100percent.bolt" }
        guard let level else { return "battery.0percent" }
        switch level {
        case ..<0.13: return "battery.0percent"
        case ..<0.38: return "battery.25percent"
        case ..<0.63: return "battery.50percent"
        case ..<0.88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    /// 少ないとき色を変えるか（標準の電池と同じく 10% 以下）
    public var isLow: Bool { !charging && (level ?? 1) <= 0.10 }
}
