import SwiftUI

enum NeonTheme {
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.11, green: 0.14, blue: 0.36),
            Color(red: 0.16, green: 0.10, blue: 0.32),
            Color(red: 0.07, green: 0.17, blue: 0.34)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let boardFill = UIColor(red: 0.09, green: 0.12, blue: 0.22, alpha: 0.96)
    static let boardStroke = UIColor(red: 0.48, green: 0.62, blue: 1.00, alpha: 0.28)
    static let gridLine = UIColor(red: 0.52, green: 0.72, blue: 1.00, alpha: 0.13)
    static let tileStroke = UIColor(red: 0.94, green: 0.97, blue: 1.00, alpha: 0.36)
    static let controlsTint = Color(red: 0.98, green: 0.62, blue: 0.22)

    static let accentPrimary = Color(red: 0.98, green: 0.62, blue: 0.22)
    static let accentSecondary = Color(red: 0.33, green: 0.83, blue: 0.98)
    static let glowColor = Color(red: 0.96, green: 0.78, blue: 0.32)

    static let textPrimary = Color(red: 0.95, green: 0.97, blue: 1.00)
    static let textSecondary = Color(red: 0.78, green: 0.84, blue: 0.98).opacity(0.92)
    static let chipFill = Color(red: 0.17, green: 0.23, blue: 0.44).opacity(0.78)
    static let chipStroke = Color(red: 0.56, green: 0.72, blue: 1.00).opacity(0.40)
    static let overlayScrim = Color(red: 0.03, green: 0.05, blue: 0.14).opacity(0.52)
    static let cardFill = Color(red: 0.16, green: 0.20, blue: 0.40).opacity(0.94)
    static let cardStroke = Color(red: 0.58, green: 0.70, blue: 1.00).opacity(0.34)
    static let panelFill = Color(red: 0.15, green: 0.19, blue: 0.39).opacity(0.90)
    static let buttonFill = LinearGradient(
        colors: [Color(red: 1.00, green: 0.66, blue: 0.26), Color(red: 0.96, green: 0.49, blue: 0.21)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func tileColor(for value: Int) -> UIColor {
        switch value {
        case 1: return UIColor(red: 0.98, green: 0.48, blue: 0.28, alpha: 1)
        case 2: return UIColor(red: 0.99, green: 0.66, blue: 0.21, alpha: 1)
        case 3: return UIColor(red: 0.22, green: 0.77, blue: 0.97, alpha: 1)
        case 4: return UIColor(red: 0.67, green: 0.45, blue: 0.96, alpha: 1)
        case 5: return UIColor(red: 0.97, green: 0.37, blue: 0.68, alpha: 1)
        case 6: return UIColor(red: 0.98, green: 0.80, blue: 0.24, alpha: 1)
        case 7: return UIColor(red: 0.32, green: 0.85, blue: 0.55, alpha: 1)
        case 8: return UIColor(red: 0.99, green: 0.40, blue: 0.31, alpha: 1)
        default: return UIColor(red: 0.36, green: 0.67, blue: 1.00, alpha: 1)
        }
    }

    static func tileColor(for kind: TileKind) -> UIColor {
        switch kind {
        case .number(let value):
            return tileColor(for: value)
        case .rowClear:
            return UIColor(red: 0.99, green: 0.73, blue: 0.33, alpha: 1.0)
        case .columnClear:
            return UIColor(red: 0.98, green: 0.58, blue: 0.38, alpha: 1.0)
        case .reorder:
            return UIColor(red: 0.58, green: 0.79, blue: 0.98, alpha: 1.0)
        }
    }
}
