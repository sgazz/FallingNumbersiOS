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

struct Cell: Equatable {
    let id: UUID
    let kind: TileKind

    init(kind: TileKind, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
    }

    init(value: Int, id: UUID = UUID()) {
        self.id = id
        self.kind = .number(value)
    }

    // Board equality describes game contents; rendering tracks identity separately.
    static func == (lhs: Cell, rhs: Cell) -> Bool { lhs.kind == rhs.kind }

    var value: Int {
        kind.numericValue ?? 0
    }
}

struct FallingPiece: Equatable {
    let id: UUID
    var kind: TileKind
    var position: GridPosition

    init(kind: TileKind, position: GridPosition, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.position = position
    }

    init(value: Int, position: GridPosition, id: UUID = UUID()) {
        self.id = id
        self.kind = .number(value)
        self.position = position
    }

    var value: Int {
        kind.numericValue ?? 0
    }
}
