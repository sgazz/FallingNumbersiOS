import Foundation

struct GravitySystem {
    mutating func collapse(board: inout Board) {
        for column in 0..<board.columns {
            var writeRow = board.rows - 1

            for row in stride(from: board.rows - 1, through: 0, by: -1) {
                let readPosition = GridPosition(row: row, column: column)
                guard let cell = board.cell(at: readPosition) else { continue }

                if writeRow != row {
                    board.setCell(cell, at: GridPosition(row: writeRow, column: column))
                }
                writeRow -= 1
            }

            if writeRow >= 0 {
                for row in stride(from: writeRow, through: 0, by: -1) {
                    board.setCell(nil, at: GridPosition(row: row, column: column))
                }
            }
        }
    }
}
