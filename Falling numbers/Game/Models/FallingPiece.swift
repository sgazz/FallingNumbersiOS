import Foundation

struct FallingPiece: Equatable {
    var kind: TileKind
    var position: GridPosition

    init(kind: TileKind, position: GridPosition) {
        self.kind = kind
        self.position = position
    }

    init(value: Int, position: GridPosition) {
        self.kind = .number(value)
        self.position = position
    }

    var value: Int {
        kind.numericValue ?? 0
    }
}
