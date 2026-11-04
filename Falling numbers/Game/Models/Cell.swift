import Foundation

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
