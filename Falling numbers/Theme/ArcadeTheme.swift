import SwiftUI

enum AppTheme: String, CaseIterable {
    case classic
    case cappuccino
    case carnival
    case neon

    static let storageKey = "falling_numbers_theme"

    var title: String {
        switch self {
        case .classic: return "Classic"
        case .cappuccino: return "Cappuccino"
        case .carnival: return "Carnival"
        case .neon: return "Neon"
        }
    }

    var detail: String {
        switch self {
        case .classic: return "Colorful tiles and arcade accents."
        case .cappuccino: return "Warm cream, ochre, and coffee. A calm, minimal palette."
        case .carnival: return "Nine bold tile colors, candy accents, and a playful pastel backdrop."
        case .neon: return "Midnight colors, electric outlines, and a soft neon glow."
        }
    }
}

enum ArcadeTheme {
    static var selected: AppTheme {
        AppTheme(rawValue: UserDefaults.standard.string(forKey: AppTheme.storageKey) ?? "") ?? .classic
    }
    static var isNeon: Bool { selected == .neon }
    static var isCarnival: Bool { selected == .carnival }
    static var isCappuccino: Bool { selected == .cappuccino }
    static var appearanceKey: String { "\(selected.rawValue)|\(colorBlindModeEnabled)" }

    private static func uiColor(_ hex: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: alpha)
    }

    static var ink: Color { isNeon ? Color(uiColor(0xF1F5FF)) : isCarnival ? Color(uiColor(0x282047)) : isCappuccino ? Color(uiColor(0x3D3027)) : Color(red: 0.10, green: 0.17, blue: 0.20) }
    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: isNeon
            ? [Color(uiColor(0x080B18)), Color(uiColor(0x17112E))]
            : isCarnival
            ? [Color(uiColor(0xFFF0DB)), Color(uiColor(0xDBFFF3)), Color(uiColor(0xEBDDFF))]
            : isCappuccino
            ? [Color(uiColor(0xF5EFE5)), Color(uiColor(0xF5EFE5))]
            : [Color(red: 0.98, green: 0.97, blue: 0.93), Color(red: 0.94, green: 0.95, blue: 0.91)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var accentPrimary: Color { isNeon ? Color(uiColor(0x33F5EE)) : isCarnival ? Color(uiColor(0x7C3AED)) : isCappuccino ? Color(uiColor(0x87643D)) : Color(red: 0.00, green: 0.43, blue: 0.44) }
    static var accentSecondary: Color { isNeon ? Color(uiColor(0xFF63CB)) : isCarnival ? Color(uiColor(0xC51E64)) : isCappuccino ? Color(uiColor(0x87643D)) : Color(red: 0.78, green: 0.29, blue: 0.22) }
    static var glowColor: Color { accentPrimary }
    static var textPrimary: Color { ink }
    static var textSecondary: Color { isNeon ? Color(uiColor(0xAFB8D5)) : isCarnival ? Color(uiColor(0x63577C)) : isCappuccino ? Color(uiColor(0x71604F)) : Color(red: 0.35, green: 0.41, blue: 0.42) }
    static var chipFill: Color { isNeon ? Color(uiColor(0x20243E)) : isCarnival ? Color(uiColor(0xEAE0FF)) : isCappuccino ? Color(uiColor(0xE8DECF)) : Color(red: 0.92, green: 0.94, blue: 0.90) }
    static var chipStroke: Color { ink.opacity(0.12) }
    static var cardFill: Color { isNeon ? Color(uiColor(0x15192D)) : isCarnival ? Color(uiColor(0xFFFBFF)) : isCappuccino ? Color(uiColor(0xFBF7F0)) : Color(red: 1.00, green: 0.995, blue: 0.97) }
    static var cardStroke: Color { ink.opacity(0.12) }
    static var panelFill: Color { cardFill }
    static var overlayScrim: Color { isNeon ? Color.black.opacity(0.72) : ink.opacity(0.52) }
    static var controlsTint: Color { isNeon ? Color(uiColor(0x6D28D9)) : accentPrimary }
    static var buttonFill: LinearGradient {
        LinearGradient(colors: isNeon ? [Color(uiColor(0x6D28D9)), Color(uiColor(0xAE197E))] : [accentPrimary, isCarnival ? accentSecondary : isCappuccino ? accentPrimary : Color(red: 0.00, green: 0.36, blue: 0.38)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var boardFill: UIColor { isNeon ? uiColor(0x090D1B) : isCarnival ? uiColor(0x20204B) : isCappuccino ? uiColor(0xE5DAC9) : UIColor(red: 0.10, green: 0.17, blue: 0.20, alpha: 1) }
    static var gridLine: UIColor { isNeon ? uiColor(0x66E7FF, alpha: 0.12) : isCarnival ? uiColor(0xCEBBFF, alpha: 0.16) : isCappuccino ? uiColor(0x6D553E, alpha: 0.16) : UIColor(white: 1, alpha: 0.075) }
    static var tileStroke: UIColor { isCarnival ? UIColor(white: 1, alpha: 0.4) : isCappuccino ? uiColor(0x503B28, alpha: 0.16) : UIColor(white: 1, alpha: 0.24) }
    static var tileShadow: UIColor { isNeon ? .clear : isCarnival ? uiColor(0x0F0D30, alpha: 0.3) : isCappuccino ? .clear : UIColor(red: 0.21, green: 0.13, blue: 0.09, alpha: 0.18) }
    static var clearHighlight: UIColor { isNeon ? uiColor(0x33F5EE) : isCarnival ? uiColor(0xFFD166) : isCappuccino ? uiColor(0xC8A675) : UIColor(red: 1.0, green: 0.82, blue: 0.42, alpha: 1) }
    static var rowSweep: UIColor { isNeon ? uiColor(0xFF63CB, alpha: 0.75) : isCarnival ? uiColor(0xFF70B5, alpha: 0.7) : isCappuccino ? uiColor(0xC8A675, alpha: 0.5) : UIColor(red: 1.0, green: 0.80, blue: 0.36, alpha: 0.62) }
    static var columnSweep: UIColor { isNeon ? uiColor(0x33F5EE, alpha: 0.75) : isCarnival ? uiColor(0x5EF0CC, alpha: 0.7) : isCappuccino ? rowSweep : UIColor(red: 0.50, green: 0.86, blue: 1.0, alpha: 0.6) }
    static var feedbackGlow: Color { isNeon ? accentPrimary : isCarnival ? Color(uiColor(0xFFD166)) : isCappuccino ? accentPrimary : .orange }
    static var dangerTint: Color { isCappuccino ? ink : .red }

    static var colorBlindModeEnabled: Bool {
        UserDefaults.standard.bool(forKey: "falling_numbers_color_blind_enabled")
    }

    static func tileColor(for value: Int, theme: AppTheme? = nil, colorBlind: Bool? = nil) -> UIColor {
        // Cappuccino uses one readable tile color; values and symbols carry the meaning.
        let resolvedTheme = theme ?? selected
        if resolvedTheme == .cappuccino { return uiColor(0x87643D) }
        if resolvedTheme == .neon {
            let accent = tileAccent(for: value, theme: .neon, colorBlind: colorBlind)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            accent.getRed(&r, green: &g, blue: &b, alpha: &a)
            return UIColor(red: 0.025 + r * 0.18, green: 0.035 + g * 0.18,
                           blue: 0.065 + b * 0.18, alpha: 1)
        }
        let colors: [UInt32] = (colorBlind ?? colorBlindModeEnabled)
            ? [0x0072B2, 0xD55E00, 0x009E73, 0xCC79A7, 0xE69F00, 0x56B4E9, 0x000000, 0xF0E442, 0x7F3C8D]
            : resolvedTheme == .carnival
                ? [0xC51E64, 0xB84900, 0x7C3AED, 0x1764D9, 0x007F83, 0x9B6800, 0x188343, 0xD02C41, 0x4F46CC]
                : [0x007F7A, 0xC34D3B, 0x4669B5, 0x8461A8, 0xA84677, 0x946B18, 0x3D8055, 0xBA4E33, 0x416E87]
        return uiColor(colors[min(8, max(0, value - 1))])
    }

    static func tileAccent(for value: Int, theme: AppTheme? = nil, colorBlind: Bool? = nil) -> UIColor {
        guard (theme ?? selected) == .neon else { return tileStroke }
        if colorBlind ?? colorBlindModeEnabled {
            if value == 7 { return .white } // Keep the black accessibility swatch visible on midnight surfaces.
            return tileColor(for: value, theme: .classic, colorBlind: true)
        }
        let colors: [UInt32] = [0x33F5EE, 0xFF63CB, 0xB295FF, 0x75ADFF, 0x6CFF9E,
                                0xFFE66D, 0xFFAD66, 0xFF6E8C, 0x8DEAFF]
        return uiColor(colors[min(8, max(0, value - 1))])
    }

    static func tileAccent(for kind: TileKind) -> UIColor {
        switch kind {
        case .number(let value): return tileAccent(for: value)
        case .rowClear: return tileAccent(for: 6)
        case .columnClear: return tileAccent(for: 2)
        case .reorder: return tileAccent(for: 4)
        }
    }

    static func tileColor(for kind: TileKind) -> UIColor {
        switch kind {
        case .number(let value): return tileColor(for: value)
        case .rowClear: return tileColor(for: 6)
        case .columnClear: return tileColor(for: 2)
        case .reorder: return tileColor(for: 4)
        }
    }
}
