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

func draw(_ n: Int, _ c: CGContext) {
    let full = CGRect(x: 0, y: 0, width: S, height: S)
    switch n {
    case 1: // 濃い地に、横長の枠。左右で色を分ける
        fill(c, CGPath(rect: full, transform: nil), INK)
        let slot = CGRect(x: 120, y: 330, width: 784, height: 364)
        c.saveGState(); c.addPath(rr(slot, 110)); c.clip()
        fill(c, CGPath(rect: CGRect(x: slot.minX, y: slot.minY, width: slot.width/2, height: slot.height), transform: nil), ORANGE)
        fill(c, CGPath(rect: CGRect(x: slot.midX, y: slot.minY, width: slot.width/2, height: slot.height), transform: nil), GREEN)
        c.restoreGState()
        fill(c, CGPath(rect: CGRect(x: slot.midX - 14, y: slot.minY, width: 28, height: slot.height), transform: nil), INK)
    case 2: // 濃い地に、枠の輪郭と、左右に形
        fill(c, CGPath(rect: full, transform: nil), INK)
        let slot = CGRect(x: 100, y: 312, width: 824, height: 400)
        c.addPath(rr(slot, 120)); c.setStrokeColor(color(WHITE, 0.9)); c.setLineWidth(34); c.strokePath()
        fill(c, CGPath(rect: CGRect(x: slot.midX - 12, y: slot.minY + 70, width: 24, height: slot.height - 140), transform: nil), WHITE, 0.5)
        steps(c, in: CGRect(x: 190, y: 400, width: 230, height: 224), ORANGE)
        battery(c, in: CGRect(x: 580, y: 400, width: 260, height: 224), GREEN, ground: INK)
    case 3: // 全面を左右で塗り分け
        fill(c, CGPath(rect: CGRect(x: 0, y: 0, width: S/2, height: S), transform: nil), ORANGE)
        fill(c, CGPath(rect: CGRect(x: S/2, y: 0, width: S/2, height: S), transform: nil), GREEN)
        steps(c, in: CGRect(x: 130, y: 390, width: 260, height: 250), WHITE)
        battery(c, in: CGRect(x: 610, y: 390, width: 290, height: 250), WHITE, ground: GREEN)
    case 4: // 濃い地に、2つの丸（2つ同時）
        fill(c, CGPath(rect: full, transform: nil), INK)
        let slot = CGRect(x: 110, y: 342, width: 804, height: 340)
        fill(c, rr(slot, 170), 0x2A3038)
        c.addEllipse(in: CGRect(x: 160, y: 382, width: 260, height: 260)); c.setFillColor(color(ORANGE)); c.fillPath()
        c.addEllipse(in: CGRect(x: 604, y: 382, width: 260, height: 260)); c.setFillColor(color(CYAN)); c.fillPath()
    case 5: // 白地に、色の枠
        fill(c, CGPath(rect: full, transform: nil), 0xF4F5F7)
        let slot = CGRect(x: 110, y: 322, width: 804, height: 380)
        fill(c, rr(slot, 110), INK)
        steps(c, in: CGRect(x: 190, y: 400, width: 230, height: 224), ORANGE)
        fill(c, CGPath(rect: CGRect(x: slot.midX - 10, y: slot.minY + 70, width: 20, height: slot.height - 140), transform: nil), WHITE, 0.35)
        battery(c, in: CGRect(x: 590, y: 400, width: 250, height: 224), GREEN, ground: INK)
    default: // 6：枠の左右に色を分け、形は濃い色で
        fill(c, CGPath(rect: full, transform: nil), INK)
        let slot = CGRect(x: 90, y: 300, width: 844, height: 424)
        c.saveGState(); c.addPath(rr(slot, 120)); c.clip()
        fill(c, CGPath(rect: CGRect(x: slot.minX, y: slot.minY, width: slot.width/2, height: slot.height), transform: nil), ORANGE)
        fill(c, CGPath(rect: CGRect(x: slot.midX, y: slot.minY, width: slot.width/2, height: slot.height), transform: nil), GREEN)
        c.restoreGState()
        fill(c, CGPath(rect: CGRect(x: slot.midX - 12, y: slot.minY, width: 24, height: slot.height), transform: nil), INK)
        steps(c, in: CGRect(x: 180, y: 400, width: 250, height: 224), INK)
        battery(c, in: CGRect(x: 580, y: 400, width: 270, height: 224), INK, ground: GREEN)
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
let N = 6, cell: CGFloat = 400, W = Int(cell) * 3, H = Int(cell + 90) * 2
let sheet = ctx(W, H)
sheet.setFillColor(color(0xE9EAEE)); sheet.fill(CGRect(x: 0, y: 0, width: W, height: H))
for n in 1...N {
    let col = CGFloat((n - 1) % 3), row = CGFloat((n - 1) / 3)
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
save(sheet.makeImage()!, "store/icon/candidates.png")
