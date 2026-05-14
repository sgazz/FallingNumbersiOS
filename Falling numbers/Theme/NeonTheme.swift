import SwiftUI

enum NeonTheme {
    static let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.96, green: 0.92, blue: 0.86), Color(red: 0.90, green: 0.84, blue: 0.76)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let boardFill = UIColor(red: 0.83, green: 0.75, blue: 0.66, alpha: 0.96)
    static let boardStroke = UIColor(red: 0.42, green: 0.31, blue: 0.24, alpha: 0.36)
    static let gridLine = UIColor(red: 0.40, green: 0.30, blue: 0.23, alpha: 0.16)
    static let tileStroke = UIColor(red: 0.31, green: 0.21, blue: 0.16, alpha: 0.52)
    static let controlsTint = Color(red: 0.56, green: 0.41, blue: 0.31)

    static let textPrimary = Color(red: 0.21, green: 0.14, blue: 0.10)
    static let textSecondary = Color(red: 0.28, green: 0.19, blue: 0.14).opacity(0.78)
    static let chipFill = Color(red: 0.98, green: 0.94, blue: 0.88).opacity(0.80)
    static let chipStroke = Color(red: 0.45, green: 0.33, blue: 0.25).opacity(0.28)
    static let overlayScrim = Color(red: 0.13, green: 0.09, blue: 0.07).opacity(0.38)
    static let cardFill = Color(red: 0.97, green: 0.92, blue: 0.85).opacity(0.95)
    static let cardStroke = Color(red: 0.44, green: 0.31, blue: 0.23).opacity(0.30)

    static func tileColor(for value: Int) -> UIColor {
        switch value {
        case 1: return UIColor(red: 0.88, green: 0.46, blue: 0.32, alpha: 1)
        case 2: return UIColor(red: 0.81, green: 0.58, blue: 0.30, alpha: 1)
        case 3: return UIColor(red: 0.74, green: 0.62, blue: 0.29, alpha: 1)
        case 4: return UIColor(red: 0.62, green: 0.66, blue: 0.34, alpha: 1)
        case 5: return UIColor(red: 0.44, green: 0.66, blue: 0.44, alpha: 1)
        case 6: return UIColor(red: 0.39, green: 0.62, blue: 0.62, alpha: 1)
        case 7: return UIColor(red: 0.46, green: 0.54, blue: 0.74, alpha: 1)
        case 8: return UIColor(red: 0.58, green: 0.48, blue: 0.72, alpha: 1)
        default: return UIColor(red: 0.72, green: 0.44, blue: 0.58, alpha: 1)
        }
    }
}
