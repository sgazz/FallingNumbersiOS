import Foundation

struct GridPosition: Hashable {
    let row: Int
    let column: Int

    func translated(rowDelta: Int, columnDelta: Int) -> GridPosition {
        GridPosition(row: row + rowDelta, column: column + columnDelta)
    }
}
