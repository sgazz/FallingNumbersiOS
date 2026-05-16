import Foundation

struct SpawnSystem {
    func makePiece(
        on board: Board,
        kind: TileKind,
        mode: GameMode = .beginner,
        pressureTier: Int = 0,
        preferredColumn overrideColumn: Int? = nil
    ) -> FallingPiece? {
        let preferredColumn = overrideColumn ?? nextSpawnColumn(columns: board.columns, mode: mode, pressureTier: pressureTier)
        if let column = bestAvailableSpawnColumn(on: board, preferredColumn: preferredColumn) {
            let spawn = GridPosition(row: 0, column: column)
            return FallingPiece(kind: kind, position: spawn)
        }
        return nil
    }

    func makePiece(on board: Board, value: Int) -> FallingPiece? {
        makePiece(on: board, kind: .number(value))
    }

    func nextTileKind(level: Int, mode: GameMode, specialSpawnChance: Double) -> TileKind {
        let allowsSpecial: Bool
        if mode == .expert {
            allowsSpecial = level >= 3
        } else {
            allowsSpecial = level >= 6
        }

        if allowsSpecial, Double.random(in: 0...1) < specialSpawnChance {
            let roll = Double.random(in: 0...1)
            if roll < 0.4 { return .rowClear }
            if roll < 0.8 { return .columnClear }
            return .reorder
        }

        return .number(nextValue(level: level, mode: mode))
    }

    func nextValue(level: Int, mode: GameMode) -> Int {
        if mode == .expert {
            return Int.random(in: 1...9)
        }

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

    func nextSpawnColumn(columns: Int, mode: GameMode = .beginner, pressureTier: Int = 0) -> Int {
        guard columns > 0 else { return 0 }
        let weights = spawnWeights(columns: columns, mode: mode, pressureTier: pressureTier)
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

    func expertBurstLength(pressureTier: Int, occupancyPercent: Int) -> Int {
        guard pressureTier > 0 else { return 1 }
        let roll = Int.random(in: 0..<100)
        if pressureTier >= 2 {
            if occupancyPercent < 30 {
                if roll < 12 { return 3 }
                if roll < 50 { return 2 }
                return 1
            } else {
                if roll < 8 { return 3 }
                if roll < 38 { return 2 }
                return 1
            }
        }
        if roll < 28 { return 2 }
        return 1
    }

    private func spawnWeights(columns: Int, mode: GameMode, pressureTier: Int) -> [Int] {
        if columns == 10 {
            if mode == .expert, pressureTier >= 2 {
                // Less forgiving: pushes more traffic into central columns.
                return [3, 5, 9, 16, 22, 22, 16, 9, 5, 3]
            }
            if mode == .expert, pressureTier == 1 {
                return [4, 7, 11, 16, 20, 20, 16, 11, 7, 4]
            }
            // Beginner / base profile.
            return [5, 8, 12, 15, 18, 18, 15, 12, 8, 5]
        }

        let center = Double(columns - 1) / 2.0
        return (0..<columns).map { column in
            let distance = abs(Double(column) - center)
            return max(3, Int((12.0 - distance * 2.0).rounded()))
        }
    }
}
