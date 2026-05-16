import Foundation

enum TileKind: Equatable {
    case number(Int)
    case rowClear
    case columnClear
    case reorder

    var numericValue: Int? {
        if case .number(let value) = self { return value }
        return nil
    }

    var displayText: String {
        switch self {
        case .number(let value):
            return "\(value)"
        case .rowClear:
            return "↔"
        case .columnClear:
            return "↕"
        case .reorder:
            return "⟳"
        }
    }

    var debugName: String {
        switch self {
        case .number:
            return "number"
        case .rowClear:
            return "rowClear"
        case .columnClear:
            return "columnClear"
        case .reorder:
            return "reorder"
        }
    }

    var isPowerUp: Bool {
        switch self {
        case .number:
            return false
        case .rowClear, .columnClear, .reorder:
            return true
        }
    }
}
