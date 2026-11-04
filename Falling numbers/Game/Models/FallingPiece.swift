import Foundation

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
