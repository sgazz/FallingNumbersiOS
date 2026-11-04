import Foundation

enum StartingLayoutSystem {
    static func apply(state: inout GameState, seed: Int) {
        guard state.gameMode == .beginner else { return }
        // Early-game pacing:
        // add a small deterministic prefill near the bottom to reduce empty-start feel,
        // while keeping spawn safe and avoiding immediate target clears.
        let templates: [[(rowFromBottom: Int, column: Int, value: Int)]] = [
            // 7x15 beginner board: avoid immediate target=10 line clears.
            [(1, 1, 4), (1, 2, 5), (1, 4, 3), (1, 5, 4), (2, 2, 2), (2, 3, 7)],
            [(1, 0, 3), (1, 1, 5), (1, 4, 5), (1, 6, 4), (2, 2, 2), (2, 5, 4)],
            [(1, 1, 1), (1, 2, 8), (1, 4, 2), (1, 5, 7), (2, 2, 3), (2, 3, 5), (2, 6, 1)]
        ]

        let template = templates[Int(seed.magnitude % UInt(templates.count))]
        for item in template {
            let row = state.board.rows - item.rowFromBottom
            let position = GridPosition(row: row, column: item.column)
            guard state.board.isInside(position) else { continue }
            if state.board.cell(at: position) == nil {
                state.board.setCell(Cell(value: item.value), at: position)
            }
        }
    }

}
