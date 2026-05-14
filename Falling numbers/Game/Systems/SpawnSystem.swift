import Foundation

struct SpawnSystem {
    func makePiece(on board: Board, value: Int) -> FallingPiece? {
        let spawn = GridPosition(row: 0, column: board.columns / 2)
        guard board.canPlace(at: spawn) else { return nil }
        return FallingPiece(value: value, position: spawn)
    }

    func nextValue(level: Int) -> Int {
        // Early levels intentionally bias toward mid values to teach matching flow.
        // Value variety expands as level rises while staying deterministic for tests.
        let cap = min(9, 5 + ((max(1, level) - 1) / 2))
        return Int.random(in: 1...cap)
    }
}
