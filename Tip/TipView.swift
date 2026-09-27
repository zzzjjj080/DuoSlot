import SwiftUI

/// 投げ銭（コーヒーを奢る）の画面。Watch と iPhone で同じものを出す。
/// 金額は App Store が返す表示価格をそのまま出す（国で通貨も額も変わる。¥200 と決め打ちしない）。
/// 送っても機能は変わらない。「寄付」「Donation」とは書かない（引き継ぎ書 11-5）
struct TipView: View {
    @Bindable var tipJar: TipJar
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            switch tipJar.state {
            case .thanks:
                Image(systemName: "heart.fill").font(.system(size: 28)).foregroundStyle(.orange)
                Text("ありがとうございます").font(.headline).multilineTextAlignment(.center)
                close
            case .failed:
                Text("うまくいきませんでした").multilineTextAlignment(.center)
                close
            case .unavailable:
                Text("いまは受け付けられません").multilineTextAlignment(.center)
                close
            case .loading, .purchasing:
                ProgressView()
            default:
                Text("気に入ったら").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                Button {
                    Task { await tipJar.tip() }
                } label: {
                    VStack(spacing: 1) {
                        Text("コーヒーを奢る").font(.headline)
                        if let price = tipJar.displayPrice {
                            Text(price).font(.caption.weight(.semibold)).monospacedDigit().opacity(0.8)
                        }
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(Capsule().fill(.orange))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tipBuy")
                Text("送っても機能は変わりません。").font(.caption2).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if tipJar.cups > 0 {
                    // 消耗型は復元されない。この端末での回数だとはっきり書く
                    Text("この端末で \(tipJar.cups)").font(.caption2).monospacedDigit().foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .task { await tipJar.load() }
        .sensoryFeedback(.success, trigger: tipJar.cups)
    }

    private var close: some View {
        Button("閉じる") {
            tipJar.dismissThanks()
            onClose()
        }
    }
}
