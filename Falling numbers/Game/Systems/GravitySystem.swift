import Foundation

struct GravitySystem {
    mutating func collapse(board: inout Board) {
        for column in 0..<board.columns {
            var values: [Int] = []
            for row in (0..<board.rows).reversed() {
                let position = GridPosition(row: row, column: column)
                if let value = board.cell(at: position)?.value {
                    values.append(value)
                }
            }

            var writeRow = board.rows - 1
            for value in values {
                board.setCell(Cell(value: value), at: GridPosition(row: writeRow, column: column))
                writeRow -= 1
            }

            if writeRow >= 0 {
                for row in 0...writeRow {
                    board.setCell(nil, at: GridPosition(row: row, column: column))
                }
            }
        }
    }
}
