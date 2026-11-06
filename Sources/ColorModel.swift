import AppKit
import SwiftUI

/// An 8-bit sRGB color. Everything shown in the UI (hex, rgb, hsl, ...) is
/// derived from these three integers, so every format always agrees.
struct RGB: Hashable {
    let r: Int
    let g: Int
    let b: Int

    init(r: Int, g: Int, b: Int) {
        self.r = max(0, min(255, r))
        self.g = max(0, min(255, g))
        self.b = max(0, min(255, b))
    }

    /// Converts whatever color space the screen sampler returns (often
    /// Display P3) into sRGB, which is what hex codes on the web mean.
    init?(nsColor: NSColor) {
        guard let c = nsColor.usingColorSpace(.sRGB) else { return nil }
        self.init(
            r: Int((c.redComponent * 255).rounded()),
            g: Int((c.greenComponent * 255).rounded()),
            b: Int((c.blueComponent * 255).rounded())
        )
    }

    init?(hex raw: String) {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.lowercased().hasPrefix("0x") { s.removeFirst(2) }
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        guard s.count == 6, s.allSatisfy(\.isHexDigit), let v = Int(s, radix: 16) else { return nil }
        self.init(r: (v >> 16) & 0xFF, g: (v >> 8) & 0xFF, b: v & 0xFF)
    }

    /// Accepts "#1A2B3C", "1a2b3c", "#abc", "rgb(26, 43, 60)" or "26 43 60".
    static func parse(_ input: String) -> RGB? {
        if let c = RGB(hex: input) { return c }
        let lower = input.lowercased()
        if lower.contains("hs") { return nil }
        let nums = input.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard nums.count == 3, nums.allSatisfy({ (0...255).contains($0) }) else { return nil }
        return RGB(r: nums[0], g: nums[1], b: nums[2])
    }

    func hex(uppercase: Bool = true, hash: Bool = true) -> String {
        let s = String(format: "%02X%02X%02X", r, g, b)
        return (hash ? "#" : "") + (uppercase ? s : s.lowercased())
    }

    private var unit: (Double, Double, Double) { (Double(r) / 255, Double(g) / 255, Double(b) / 255) }

    private func hueDegrees(max mx: Double, delta d: Double) -> Double {
        let (rf, gf, bf) = unit
        guard d > 0 else { return 0 }
        var h: Double
        if mx == rf { h = ((gf - bf) / d).truncatingRemainder(dividingBy: 6) }
        else if mx == gf { h = (bf - rf) / d + 2 }
        else { h = (rf - gf) / d + 4 }
        h *= 60
        if h < 0 { h += 360 }
        return h
    }

    var hsl: (h: Int, s: Int, l: Int) {
        let (rf, gf, bf) = unit
        let mx = max(rf, gf, bf), mn = min(rf, gf, bf), d = mx - mn
        let l = (mx + mn) / 2
        let s = d == 0 ? 0 : d / (1 - abs(2 * l - 1))
        return (Int(hueDegrees(max: mx, delta: d).rounded()) % 360, Int((s * 100).rounded()), Int((l * 100).rounded()))
    }

    var hsb: (h: Int, s: Int, b: Int) {
        let (rf, gf, bf) = unit
        let mx = max(rf, gf, bf), mn = min(rf, gf, bf), d = mx - mn
        let s = mx == 0 ? 0 : d / mx
        return (Int(hueDegrees(max: mx, delta: d).rounded()) % 360, Int((s * 100).rounded()), Int((mx * 100).rounded()))
    }

    /// WCAG relative luminance.
    var luminance: Double {
        func lin(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        let (rf, gf, bf) = unit
        return 0.2126 * lin(rf) + 0.7152 * lin(gf) + 0.0722 * lin(bf)
    }

    func contrast(with other: RGB) -> Double {
        let a = luminance, b = other.luminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    var color: Color { Color(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1) }
    var nsColor: NSColor { NSColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1) }

    static let white = RGB(r: 255, g: 255, b: 255)
    static let black = RGB(r: 0, g: 0, b: 0)
}

enum ColorFormat: String, CaseIterable, Identifiable {
    case hex = "HEX"
    case rgb = "RGB"
    case hsl = "HSL"
    case hsb = "HSB"
    case swiftUI = "SwiftUI"

    var id: String { rawValue }

    func string(_ c: RGB, uppercase: Bool, hash: Bool) -> String {
        switch self {
        case .hex:
            return c.hex(uppercase: uppercase, hash: hash)
        case .rgb:
            return "rgb(\(c.r), \(c.g), \(c.b))"
        case .hsl:
            let v = c.hsl
            return "hsl(\(v.h), \(v.s)%, \(v.l)%)"
        case .hsb:
            let v = c.hsb
            return "hsb(\(v.h), \(v.s)%, \(v.b)%)"
        case .swiftUI:
            return String(format: "Color(red: %.3f, green: %.3f, blue: %.3f)",
                          Double(c.r) / 255, Double(c.g) / 255, Double(c.b) / 255)
        }
    }
}
