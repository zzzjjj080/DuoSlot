import AppKit
import CoreGraphics
import Foundation

// Duo Slot のアイコン案。「1つの横長の枠に、2つのものが並ぶ」を形だけで伝える。
// Apple 製品（Watch）の絵は描かない（5.2.5 で却下される。引き継ぎ書 4-115）。SF Symbols も使わない。
// watchOS では円に切り抜かれ、ホーム画面では 40px まで縮むので、面の色と太い形だけで作る。
//
//   swift Tools-MakeIcon.swift sheet            → store/icon/candidates.png（見本）
//   swift Tools-MakeIcon.swift final <案の番号>  → AppIcon を書き出す

let S: CGFloat = 1024

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF)/255, green: CGFloat((hex >> 8) & 0xFF)/255,
            blue: CGFloat(hex & 0xFF)/255, alpha: a)
}
func ctx(_ w: Int, _ h: Int) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}
func save(_ image: CGImage, _ path: String) {
    try! NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}
func rr(_ r: CGRect, _ radius: CGFloat) -> CGPath { CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil) }
func fill(_ c: CGContext, _ p: CGPath, _ hex: UInt32, _ a: CGFloat = 1) { c.addPath(p); c.setFillColor(color(hex, a)); c.fillPath() }

let ORANGE: UInt32 = 0xFF9F0A, GREEN: UInt32 = 0x30D158, CYAN: UInt32 = 0x64D2FF
let INK: UInt32 = 0x101418, WHITE: UInt32 = 0xFFFFFF

/// 左：歩数を思わせる3本の棒、右：電池の形
func steps(_ c: CGContext, in r: CGRect, _ hex: UInt32) {
    let w = r.width * 0.18, gap = r.width * 0.09
    let hs: [CGFloat] = [0.45, 0.7, 1.0]
    let total = w * 3 + gap * 2
    for (i, h) in hs.enumerated() {
        let x = r.midX - total / 2 + CGFloat(i) * (w + gap)
        let hh = r.height * h
        fill(c, rr(CGRect(x: x, y: r.minY, width: w, height: hh), w * 0.3), hex)
    }
}
func battery(_ c: CGContext, in r: CGRect, _ hex: UInt32, ground: UInt32) {
    let body = CGRect(x: r.minX, y: r.midY - r.height * 0.3, width: r.width * 0.88, height: r.height * 0.6)
    fill(c, rr(body, body.height * 0.22), hex)
    fill(c, rr(body.insetBy(dx: body.height * 0.13, dy: body.height * 0.13), body.height * 0.12), ground)
    let level = body.insetBy(dx: body.height * 0.22, dy: body.height * 0.22)
    fill(c, rr(CGRect(x: level.minX, y: level.minY, width: level.width * 0.7, height: level.height), body.height * 0.06), hex)
    fill(c, rr(CGRect(x: body.maxX + r.width * 0.02, y: r.midY - r.height * 0.1, width: r.width * 0.08, height: r.height * 0.2), r.width * 0.03), hex)
}

/// 足あと2つ（歩数の印）。SF Symbols は使わず自分で描く
func footprints(_ c: CGContext, in r: CGRect, _ hex: UInt32) {
    func foot(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat) {
        c.setFillColor(color(hex))
        c.addEllipse(in: CGRect(x: x, y: y + w * 0.62, width: w, height: w * 1.25)); c.fillPath()   // つま先側
        c.addEllipse(in: CGRect(x: x + w * 0.1, y: y, width: w * 0.8, height: w * 0.62)); c.fillPath() // かかと
    }
    let w = r.width * 0.36
    foot(r.minX, r.minY, w)
    foot(r.minX + r.width * 0.5, r.minY + r.height * 0.28, w)
}

func text(_ c: CGContext, _ s: String, at p: CGPoint, size: CGFloat, _ hex: UInt32) {
    let font = NSFont.systemFont(ofSize: size, weight: .bold)
    let rounded = NSFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor, size: size) ?? font
    let a = NSAttributedString(string: s, attributes: [.font: rounded, .foregroundColor: NSColor(cgColor: color(hex))!, .kern: -size * 0.03])
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: c, flipped: false)
    a.draw(at: p)
    NSGraphicsContext.restoreGraphicsState()
}

/// コンプリケーションの見た目そのもの：左に歩数、右に電池。上に色の付いた印、下に大きい数字
func complication(_ c: CGContext, panel: CGRect, ground: UInt32, panelFill: UInt32?, numbersColored: Bool, labels: Bool) {
    if let panelFill { fill(c, rr(panel, 90), panelFill) }
    let half = panel.width / 2
    let top = panel.maxY - 150
    // 左：歩数
    footprints(c, in: CGRect(x: panel.minX + 60, y: top - 20, width: 110, height: 120), ORANGE)
    if labels { text(c, "STEPS", at: CGPoint(x: panel.minX + 185, y: top + 5), size: 56, ORANGE) }
    text(c, "8,432", at: CGPoint(x: panel.minX + 48, y: panel.minY + 55), size: 150, numbersColored ? ORANGE : WHITE)
    // 仕切り
    fill(c, CGPath(rect: CGRect(x: panel.midX - 5, y: panel.minY + 60, width: 10, height: panel.height - 120), transform: nil), WHITE, 0.3)
    // 右：電池
    battery(c, in: CGRect(x: panel.minX + half + 55, y: top - 10, width: 160, height: 110), GREEN, ground: panelFill ?? ground)
    text(c, "82%", at: CGPoint(x: panel.minX + half + 55, y: panel.minY + 55), size: 150, numbersColored ? GREEN : WHITE)
}

func draw(_ n: Int, _ c: CGContext) {
    let full = CGRect(x: 0, y: 0, width: S, height: S)
    switch n {
    case 1: // 黒地にそのまま（文字盤の上の見た目）
        fill(c, CGPath(rect: full, transform: nil), 0x000000)
        complication(c, panel: CGRect(x: 40, y: 280, width: 944, height: 464), ground: 0x000000, panelFill: nil, numbersColored: false, labels: false)
    case 2: // 黒地に、濃い灰色の枠
        fill(c, CGPath(rect: full, transform: nil), 0x000000)
        complication(c, panel: CGRect(x: 40, y: 280, width: 944, height: 464), ground: 0x000000, panelFill: 0x1F2226, numbersColored: false, labels: false)
    case 3: // 数字も色で
        fill(c, CGPath(rect: full, transform: nil), 0x000000)
        complication(c, panel: CGRect(x: 40, y: 280, width: 944, height: 464), ground: 0x000000, panelFill: 0x1F2226, numbersColored: true, labels: false)
    default: // 4：紺の地に枠
        c.drawLinearGradient(CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [color(0x1B2A44), color(0x0A0F1A)] as CFArray, locations: [0, 1])!,
                             start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])
        complication(c, panel: CGRect(x: 40, y: 280, width: 944, height: 464), ground: 0x0A0F1A, panelFill: 0x000000, numbersColored: false, labels: false)
    }
}

func icon(_ n: Int, _ size: Int = 1024) -> CGImage {
    let c = ctx(size, size)
    c.scaleBy(x: CGFloat(size) / S, y: CGFloat(size) / S)
    draw(n, c)
    return c.makeImage()!
}

let args = CommandLine.arguments
if args.count > 1 && args[1] == "final" {
    let n = Int(args[2])!
    for dir in ["Phone/Assets.xcassets/AppIcon.appiconset", "WatchApp/Assets.xcassets/AppIcon.appiconset"] {
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        save(icon(n), "\(dir)/icon-1024.png")
    }
    exit(0)
}

// 見本：案ごとに 大（角丸）・Watch（円）・ホーム画面の実寸（60px）
let N = 4, cell: CGFloat = 400, W = Int(cell) * 2, H = Int(cell + 90) * 2
let sheet = ctx(W, H)
sheet.setFillColor(color(0xE9EAEE)); sheet.fill(CGRect(x: 0, y: 0, width: W, height: H))
for n in 1...N {
    let col = CGFloat((n - 1) % 2), row = CGFloat((n - 1) / 2)
    let ox = col * cell, oy = CGFloat(H) - (row + 1) * (cell + 90)
    let big = CGRect(x: ox + 30, y: oy + 110, width: 250, height: 250)
    sheet.saveGState(); sheet.addPath(rr(big, 56)); sheet.clip(); sheet.draw(icon(n, 512), in: big); sheet.restoreGState()
    let circle = CGRect(x: ox + 295, y: oy + 230, width: 90, height: 90)
    sheet.saveGState(); sheet.addEllipse(in: circle); sheet.clip(); sheet.draw(icon(n, 256), in: circle); sheet.restoreGState()
    let small = CGRect(x: ox + 310, y: oy + 130, width: 60, height: 60)
    sheet.saveGState(); sheet.addPath(rr(small, 13)); sheet.clip(); sheet.draw(icon(n, 128), in: small); sheet.restoreGState()
    let label = NSAttributedString(string: "案\(n)", attributes: [.font: NSFont.boldSystemFont(ofSize: 40), .foregroundColor: NSColor.black])
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: sheet, flipped: false)
    label.draw(at: CGPoint(x: ox + 30, y: oy + 40))
    NSGraphicsContext.restoreGraphicsState()
}
save(sheet.makeImage()!, "store/icon/candidates-2.png")
