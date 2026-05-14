import Foundation

struct Board: Equatable {
    let rows: Int
    let columns: Int
    private(set) var cells: [Cell?]

    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        self.cells = Array(repeating: nil, count: rows * columns)
    }

    func isInside(_ position: GridPosition) -> Bool {
        position.row >= 0 && position.row < rows && position.column >= 0 && position.column < columns
    }

    func cell(at position: GridPosition) -> Cell? {
        guard let index = index(for: position) else { return nil }
        return cells[index]
    }

    func isEmpty(at position: GridPosition) -> Bool {
        cell(at: position) == nil
    }

    func canPlace(at position: GridPosition) -> Bool {
        isInside(position) && isEmpty(at: position)
    }

    mutating func setCell(_ cell: Cell?, at position: GridPosition) {
        guard let index = index(for: position) else { return }
        cells[index] = cell
    }

    func allOccupiedPositions() -> [GridPosition] {
        var positions: [GridPosition] = []
        positions.reserveCapacity(cells.count / 2)

        for row in 0..<rows {
            for column in 0..<columns {
                let position = GridPosition(row: row, column: column)
                if cell(at: position) != nil {
                    positions.append(position)
                }
            }
        }

        return positions
    }

    private func index(for position: GridPosition) -> Int? {
        guard isInside(position) else { return nil }
        return position.row * columns + position.column
    }
}
