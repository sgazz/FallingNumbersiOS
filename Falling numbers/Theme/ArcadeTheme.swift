import SwiftUI

enum ArcadeTheme {
    static let ink = Color(red: 0.10, green: 0.17, blue: 0.20)
    static let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.98, green: 0.97, blue: 0.93), Color(red: 0.94, green: 0.95, blue: 0.91)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let accentPrimary = Color(red: 0.00, green: 0.43, blue: 0.44)
    static let accentSecondary = Color(red: 0.78, green: 0.29, blue: 0.22)
    static let glowColor = accentPrimary
    static let textPrimary = ink
    static let textSecondary = Color(red: 0.35, green: 0.41, blue: 0.42)
    static let chipFill = Color(red: 0.92, green: 0.94, blue: 0.90)
    static let chipStroke = ink.opacity(0.12)
    static let cardFill = Color(red: 1.00, green: 0.995, blue: 0.97)
    static let cardStroke = ink.opacity(0.12)
    static let panelFill = cardFill
    static let overlayScrim = ink.opacity(0.52)
    static let controlsTint = accentPrimary
    static let buttonFill = LinearGradient(colors: [accentPrimary, Color(red: 0.00, green: 0.36, blue: 0.38)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
    static let boardFill = UIColor(red: 0.10, green: 0.17, blue: 0.20, alpha: 1)
    static let gridLine = UIColor(white: 1, alpha: 0.075)
    static let tileStroke = UIColor(white: 1, alpha: 0.24)

    static var colorBlindModeEnabled: Bool {
        UserDefaults.standard.bool(forKey: "falling_numbers_color_blind_enabled")
    }

    static func tileColor(for value: Int) -> UIColor {
        let colors: [UInt32] = colorBlindModeEnabled
            ? [0x0072B2, 0xD55E00, 0x009E73, 0xCC79A7, 0xE69F00, 0x56B4E9, 0x000000, 0xF0E442, 0x7F3C8D]
            : [0x007F7A, 0xC34D3B, 0x4669B5, 0x8461A8, 0xA84677,
                                0x946B18, 0x3D8055, 0xBA4E33, 0x416E87]
        let hex = colors[min(8, max(0, value - 1))]
        return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                       green: CGFloat((hex >> 8) & 255) / 255,
                       blue: CGFloat(hex & 255) / 255, alpha: 1)
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
