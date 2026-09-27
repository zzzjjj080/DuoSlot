import AppKit
import ImageIO
import UniformTypeIdentifiers

// iPhone 用のストア画像を、Watch の画面（store/raw/<言語>-<名前>.png）から合成する。
// Duo Slot は Watch のアプリなので、iPhone の枠にも Watch の画面を大きく載せる。
// Apple Watch の本体の絵は描かない（5.2.5。引き継ぎ書 4-115）。画面を角丸で切り抜くだけ。
//
//   swift Tools-MakeScreenshots.swift
//   → store/phone-<名前>.png（日本語）・store/en/phone-<名前>.png（英語）・store/65/… と store/en/65/…（6.5インチ）
//   → store/watch-<名前>.png・store/en/watch-<名前>.png（Watch の枠へそのまま）
//   → store/tip-review.png（投げ銭の審査用）

let root = "/Users/jin/Claude/DuoSlot/store/"
let shots = ["face1", "face2", "face3", "steps"]
let captions: [String: [String: (String, String)]] = [
    "ja": ["face1": ("1つの枠に、2つ。", "文字盤の大きい四角に、左右で別々のもの"),
           "face2": ("電池と、次の予定。", "電池・歩数・次の予定から2つ選べます"),
           "face3": ("組み合わせは自由。", "文字盤の編集画面で選ぶだけ。左右の順も"),
           "steps": ("押した側が開く。", "左を押せば左、右を押せば右の画面"),
           "tip":   ("コーヒーを奢る", "任意の投げ銭。送っても機能は変わりません")],
    "en": ["face1": ("Two in one slot.", "Two different things in the large rectangle"),
           "face2": ("Battery and next event.", "Pick any two: Battery, Steps, Next Event"),
           "face3": ("Any pair, any order.", "Choose it right in the watch face editor"),
           "steps": ("Tap a side to open it.", "Left opens left, right opens right"),
           "tip":   ("Buy me a coffee", "An optional tip. Nothing in the app changes")],
]

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF)/255, green: CGFloat((hex >> 8) & 0xFF)/255, blue: CGFloat(hex & 0xFF)/255, alpha: 1)
}

func draw(_ text: String, font: NSFont, color: NSColor, in rect: NSRect) {
    let style = NSMutableParagraphStyle(); style.alignment = .center
    var size = font.pointSize
    var attrs: [NSAttributedString.Key: Any] = [:]
    // 1行に収まるまで縮める（言語で長さが倍ほど違う。4-179）
    repeat {
        attrs = [.font: NSFont(descriptor: font.fontDescriptor, size: size)!, .foregroundColor: color, .paragraphStyle: style]
        if (text as NSString).size(withAttributes: attrs).width <= rect.width { break }
        size -= 2
    } while size > 20
    (text as NSString).draw(in: rect, withAttributes: attrs)
}

func compose(lang: String, name: String, width: Int, height: Int, out: String) {
    let W = CGFloat(width), H = CGFloat(height)
    // 画面の倍率に左右されないよう、ピクセル数を指定した画像へ直接描く
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: W, height: H)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGradient(starting: color(0x1D2530), ending: color(0x05070A))!.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)
    let (title, sub) = captions[lang]![name]!
    let rounded = { (s: CGFloat, w: NSFont.Weight) -> NSFont in
        let f = NSFont.systemFont(ofSize: s, weight: w)
        return NSFont(descriptor: f.fontDescriptor.withDesign(.rounded) ?? f.fontDescriptor, size: s)!
    }
    draw(title, font: rounded(118, .heavy), color: .white, in: NSRect(x: 60, y: H - 380, width: W - 120, height: 160))
    draw(sub, font: rounded(56, .semibold), color: color(0xFFB340), in: NSRect(x: 60, y: H - 480, width: W - 120, height: 80))
    if let shot = NSImage(contentsOfFile: root + "raw/\(lang)-\(name).png") {
        let sw = W * 0.86, sh = sw * shot.size.height / shot.size.width
        let r = NSRect(x: (W - sw) / 2, y: (H - 560 - sh) / 2 + 40, width: sw, height: sh)
        let path = NSBezierPath(roundedRect: r, xRadius: sw * 0.2, yRadius: sw * 0.2)
        NSGraphicsContext.saveGraphicsState(); path.addClip(); shot.draw(in: r); NSGraphicsContext.restoreGraphicsState()
        color(0x3A4452).setStroke(); path.lineWidth = 8; path.stroke()
    }
    NSGraphicsContext.restoreGraphicsState()
    try? FileManager.default.createDirectory(atPath: (out as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
    // 透明の層を持たない PNG にする（ストアの画像は透過を嫌う）
    let flat = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                         space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    flat.draw(rep.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, flat.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
}

for lang in ["ja", "en"] {
    let dir = root + (lang == "ja" ? "" : "en/")
    for name in shots {
        compose(lang: lang, name: name, width: 1320, height: 2868, out: dir + "phone-\(name).png")
        compose(lang: lang, name: name, width: 1284, height: 2778, out: dir + "65/phone-\(name).png")
        try? FileManager.default.removeItem(atPath: dir + "watch-\(name).png")
        try! FileManager.default.copyItem(atPath: root + "raw/\(lang)-\(name).png", toPath: dir + "watch-\(name).png")
    }
}
compose(lang: "ja", name: "tip", width: 1320, height: 2868, out: root + "tip-review.png")
print("done")
