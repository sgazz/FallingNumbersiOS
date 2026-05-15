import Foundation

struct SpawnSystem {
    func makePiece(on board: Board, value: Int) -> FallingPiece? {
        let preferredColumn = nextSpawnColumn(columns: board.columns)
        if let column = bestAvailableSpawnColumn(on: board, preferredColumn: preferredColumn) {
            let spawn = GridPosition(row: 0, column: column)
            return FallingPiece(value: value, position: spawn)
        }
        return nil
    }

    func nextValue(level: Int) -> Int {
        // Board pressure tuning: keep early game approachable,
        // then gradually lift value floor and range for denser arithmetic decisions.
        let range: ClosedRange<Int>
        switch max(1, level) {
        case ...3:
            range = 1...5
        case 4...6:
            range = 2...7
        case 7...10:
            range = 3...8
        default:
            range = 4...9
        }
        return Int.random(in: range)
    }

    func nextSpawnColumn(columns: Int) -> Int {
        guard columns > 0 else { return 0 }
        let weights = spawnWeights(columns: columns)
        let total = max(1, weights.reduce(0, +))
        var roll = Int.random(in: 0..<total)
        for (index, weight) in weights.enumerated() {
            if roll < weight { return index }
            roll -= weight
        }
        return min(columns - 1, columns / 2)
    }

    private func bestAvailableSpawnColumn(on board: Board, preferredColumn: Int) -> Int? {
        guard board.columns > 0 else { return nil }
        let clampedPreferred = min(max(0, preferredColumn), board.columns - 1)
        if board.canPlace(at: GridPosition(row: 0, column: clampedPreferred)) {
            return clampedPreferred
        }

        for offset in 1..<board.columns {
            let left = clampedPreferred - offset
            if left >= 0, board.canPlace(at: GridPosition(row: 0, column: left)) {
                return left
            }
            let right = clampedPreferred + offset
            if right < board.columns, board.canPlace(at: GridPosition(row: 0, column: right)) {
                return right
            }
        }
        return nil
    }

    private func spawnWeights(columns: Int) -> [Int] {
        if columns == 10 {
            // Slight center preference without center-lock repetition.
            return [5, 8, 12, 15, 18, 18, 15, 12, 8, 5]
        }

        let center = Double(columns - 1) / 2.0
        return (0..<columns).map { column in
            let distance = abs(Double(column) - center)
            return max(3, Int((12.0 - distance * 2.0).rounded()))
        }
    }
}
