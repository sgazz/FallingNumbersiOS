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
        let allowLateralFallback = mode != .expert
        if let column = bestAvailableSpawnColumn(
            on: board,
            preferredColumn: preferredColumn,
            allowLateralFallback: allowLateralFallback
        ) {
            let spawn = GridPosition(row: 0, column: column)
            return FallingPiece(kind: kind, position: spawn)
        }
        return nil
    }

    func makePiece(on board: Board, value: Int) -> FallingPiece? {
        makePiece(on: board, kind: .number(value))
    }

    func nextTileKind(level: Int, mode: GameMode, specialSpawnChance: Double) -> TileKind {
        nextTileKind(level: level, mode: mode, specialSpawnChance: specialSpawnChance, recentValues: [])
    }

    func nextTileKind(
        level: Int,
        mode: GameMode,
        specialSpawnChance: Double,
        recentValues: [Int]
    ) -> TileKind {
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

        return .number(nextValue(level: level, mode: mode, recentValues: recentValues))
    }

    func nextValue(level: Int, mode: GameMode) -> Int {
        nextValue(level: level, mode: mode, recentValues: [])
    }

    func nextValue(level: Int, mode: GameMode, recentValues: [Int]) -> Int {
        let maxRepeat = mode == .expert ? 2 : 3
        let historyWindow = mode == .expert ? 10 : 6
        let history = Array(recentValues.suffix(historyWindow))
        let streakValue = history.last
        let streakCount = trailingStreakCount(in: history)

        if mode == .expert {
            let counts = Dictionary(grouping: history, by: { $0 }).mapValues(\.count)
            let choices = Array(1...9)
            let weights: [Double] = choices.map { value in
                if streakValue == value, streakCount >= maxRepeat { return 0.0 }
                let count = counts[value, default: 0]
                return max(0.12, 1.0 - (Double(count) * 0.11))
            }
            return weightedChoice(choices: choices, weights: weights) ?? Int.random(in: 1...9)
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
        var candidate = Int.random(in: range)
        if streakValue == candidate, streakCount >= maxRepeat {
            let filtered = Array(range).filter { $0 != candidate }
            if let pick = filtered.randomElement() {
                candidate = pick
            }
        }
        return candidate
    }

    func expertSpawnColumn(columns: Int) -> Int {
        guard columns > 0 else { return 0 }
        return columns / 2
    }

    func nextSpawnColumn(columns: Int, mode: GameMode = .beginner, pressureTier: Int = 0) -> Int {
        guard columns > 0 else { return 0 }
        if mode == .expert {
            return expertSpawnColumn(columns: columns)
        }
        let weights = spawnWeights(columns: columns, mode: mode, pressureTier: pressureTier)
        let total = max(1, weights.reduce(0, +))
        var roll = Int.random(in: 0..<total)
        for (index, weight) in weights.enumerated() {
            if roll < weight { return index }
            roll -= weight
        }
        return min(columns - 1, columns / 2)
    }

    private func bestAvailableSpawnColumn(
        on board: Board,
        preferredColumn: Int,
        allowLateralFallback: Bool = true
    ) -> Int? {
        guard board.columns > 0 else { return nil }
        let clampedPreferred = min(max(0, preferredColumn), board.columns - 1)
        if board.canPlace(at: GridPosition(row: 0, column: clampedPreferred)) {
            return clampedPreferred
        }
        guard allowLateralFallback else { return nil }

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

    private func trailingStreakCount(in values: [Int]) -> Int {
        guard let last = values.last else { return 0 }
        var count = 0
        for value in values.reversed() {
            if value != last { break }
            count += 1
        }
        return count
    }

    private func weightedChoice(choices: [Int], weights: [Double]) -> Int? {
        guard choices.count == weights.count, !choices.isEmpty else { return nil }
        let positive = zip(choices, weights).filter { $0.1 > 0 }
        guard !positive.isEmpty else { return nil }
        let total = positive.reduce(0.0) { $0 + $1.1 }
        guard total > 0 else { return nil }
        var roll = Double.random(in: 0..<total)
        for (value, weight) in positive {
            if roll < weight { return value }
            roll -= weight
        }
        return positive.last?.0
    }
}
