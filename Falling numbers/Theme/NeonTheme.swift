import SwiftUI

enum NeonTheme {
    static let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.06, blue: 0.11), Color(red: 0.01, green: 0.01, blue: 0.03)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let boardFill = UIColor(red: 0.07, green: 0.08, blue: 0.14, alpha: 0.9)
    static let boardStroke = UIColor.white.withAlphaComponent(0.18)
    static let gridLine = UIColor.white.withAlphaComponent(0.07)
    static let tileStroke = UIColor.white.withAlphaComponent(0.45)
    static let controlsTint = Color(red: 0.11, green: 0.55, blue: 0.98)

    static func tileColor(for value: Int) -> UIColor {
        switch value {
        case 1: return UIColor(red: 0.18, green: 0.79, blue: 0.98, alpha: 1)
        case 2: return UIColor(red: 0.00, green: 0.92, blue: 0.67, alpha: 1)
        case 3: return UIColor(red: 0.50, green: 0.93, blue: 0.20, alpha: 1)
        case 4: return UIColor(red: 0.97, green: 0.82, blue: 0.15, alpha: 1)
        case 5: return UIColor(red: 0.99, green: 0.61, blue: 0.08, alpha: 1)
        case 6: return UIColor(red: 0.98, green: 0.34, blue: 0.40, alpha: 1)
        case 7: return UIColor(red: 0.96, green: 0.25, blue: 0.70, alpha: 1)
        case 8: return UIColor(red: 0.72, green: 0.36, blue: 0.99, alpha: 1)
        default: return UIColor(red: 0.48, green: 0.55, blue: 1.00, alpha: 1)
        }
    }
}
