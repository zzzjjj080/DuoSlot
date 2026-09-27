import Foundation

public enum StepsText {
    /// 3桁区切り。文字盤の半分の幅に収めるため、単位は付けない
    public static func format(_ steps: Int?) -> String {
        guard let steps else { return "--" }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.groupingSize = 3
        f.groupingSeparator = ","
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: NSNumber(value: max(0, steps))) ?? "\(steps)"
    }
}

/// ヘルスケアと Watch の歩数計を合わせる（引き継ぎ書 4-168。StepNow と同じ式）。
/// **「ヘルスケアの Watch の最後の時刻まで」＋「そこから今までの Watch の歩数計」**
public enum StepCombiner {
    public static func steps(healthTotal: Int?, watchSince: Int?, watchToday: Int?) -> Int? {
        if let healthTotal, let watchSince {
            return max(healthTotal + watchSince, watchToday ?? 0)
        }
        return watchToday ?? healthTotal
    }
}
