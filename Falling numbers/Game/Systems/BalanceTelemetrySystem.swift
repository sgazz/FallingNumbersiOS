import Foundation

enum BalanceTelemetrySystem {
    static func occupancyPercent(state: GameState) -> Int {
        let occupied = state.board.allOccupiedPositions().count
        let capacity = max(1, state.board.rows * state.board.columns)
        return Int((Double(occupied) / Double(capacity) * 100.0).rounded())
    }

    static func recordActiveGameplayTime(state: inout GameState, elapsed: TimeInterval) {
        state.telemetry.activeGameplaySeconds += elapsed
        state.telemetry.timeSpentPerLevel[state.level, default: 0] += elapsed
        let occupancy = occupancyPercent(state: state)
        if occupancy >= 50 {
            state.telemetry.timeAbove50Occupancy += elapsed
        }
        if occupancy >= 70 {
            state.telemetry.timeAbove70Occupancy += elapsed
        }
        let topTouched = boardTouchesTopRows(state: state)
        if topTouched, !state.telemetry.wasTopRowsTouched {
            state.telemetry.topRowsTouchedCount += 1
        }
        state.telemetry.wasTopRowsTouched = topTouched
        let nearDeath = boardNearDeath(state: state)
        if nearDeath, !state.telemetry.wasNearDeath {
            state.telemetry.nearDeathEvents += 1
        }
        state.telemetry.wasNearDeath = nearDeath
        state.telemetry.recentOccupancySamples.append(
            OccupancySample(time: state.telemetry.activeGameplaySeconds, occupancyPercent: occupancy)
        )
        let cutoff = state.telemetry.activeGameplaySeconds - 60.0
        state.telemetry.recentOccupancySamples.removeAll { $0.time < cutoff }
        if state.telemetry.recentOccupancySamples.isEmpty {
            state.telemetry.averageOccupancyLast60s = 0
        } else {
            let sum = state.telemetry.recentOccupancySamples.reduce(0) { $0 + $1.occupancyPercent }
            state.telemetry.averageOccupancyLast60s = Double(sum) / Double(state.telemetry.recentOccupancySamples.count)
        }
    }

    private static func boardTouchesTopRows(state: GameState) -> Bool {
        let rowsToCheck = min(3, state.board.rows)
        for row in 0..<rowsToCheck {
            for column in 0..<state.board.columns {
                if state.board.cell(at: GridPosition(row: row, column: column)) != nil {
                    return true
                }
            }
        }
        return false
    }

    private static func boardNearDeath(state: GameState) -> Bool {
        (0..<state.board.columns).contains { column in
            state.board.cell(at: GridPosition(row: 0, column: column)) != nil
        }
    }

    static func recordOccupancySample(state: inout GameState) {
        let occupied = state.board.allOccupiedPositions().count
        state.telemetry.occupancySampleCount += 1
        state.telemetry.occupancySum += occupied
        state.telemetry.maxOccupancy = max(state.telemetry.maxOccupancy, occupied)
        state.telemetry.minOccupancy = min(state.telemetry.minOccupancy, occupied)
        var levelStats = state.telemetry.occupancyByLevel[state.level] ?? .empty
        levelStats.record(occupied)
        state.telemetry.occupancyByLevel[state.level] = levelStats
    }

    static func logPeriodicBalanceSample(state: inout GameState, triggeredByLevelChange: Bool, spawnColumn: Int?) {
        let everyNLocks = 25
        guard triggeredByLevelChange || (state.telemetry.totalLocks > 0 && state.telemetry.totalLocks % everyNLocks == 0) else { return }
        let occupied = state.board.allOccupiedPositions().count
        let capacity = max(1, state.board.rows * state.board.columns)
        let occupancyPercent = Int((Double(occupied) / Double(capacity) * 100.0).rounded())
        let totalPowerUps = state.telemetry.powerUpsSpawned.values.reduce(0, +)
        GameDebugLogger.logBalanceSample(
            level: state.level,
            score: state.score,
            occupancyPercent: occupancyPercent,
            target: state.targetNumber,
            spawnColumn: spawnColumn,
            totalMatches: state.telemetry.totalMatches,
            totalPowerUps: totalPowerUps,
            cascadeCount: state.cascadeCount,
            expertPressureRampActive: state.expertPressureRampActive,
            expertSpawnPressureTier: state.expertSpawnPressureTier
        )
    }

    static func logBalanceSummaryIfNeeded(state: inout GameState) {
        guard !state.telemetry.didPrintSummary else { return }
        state.telemetry.didPrintSummary = true

        let duration = max(0.001, state.telemetry.activeGameplaySeconds)
        let avgOcc: Double
        if state.telemetry.occupancySampleCount > 0 {
            avgOcc = Double(state.telemetry.occupancySum) / Double(state.telemetry.occupancySampleCount)
        } else {
            avgOcc = 0
        }
        let minOcc = state.telemetry.minOccupancy == Int.max ? 0 : state.telemetry.minOccupancy
        let scorePerMinute = Double(state.score) / (duration / 60.0)
        let clearsPerMinute = Double(state.telemetry.totalMatches) / (duration / 60.0)

        GameDebugLogger.logBalanceSummary(
            sessionDuration: duration,
            finalLevel: state.level,
            finalScore: state.score,
            totalLocks: state.telemetry.totalLocks,
            totalMatches: state.telemetry.totalMatches,
            totalClearedTiles: state.totalClearedTiles,
            averageOccupancy: avgOcc,
            maxOccupancy: state.telemetry.maxOccupancy,
            minOccupancy: minOcc,
            occupancyByLevel: state.telemetry.occupancyByLevel,
            powerUpsSpawned: state.telemetry.powerUpsSpawned,
            powerUpsUsed: state.telemetry.powerUpsUsed,
            matchesByLength: state.telemetry.matchesByLength,
            cascadeDepthDistribution: state.telemetry.cascadeDepthDistribution,
            averageScorePerMinute: scorePerMinute,
            averageClearsPerMinute: clearsPerMinute,
            timeSpentPerLevel: state.telemetry.timeSpentPerLevel,
            gameOverReason: state.telemetry.gameOverReason,
            averageOccupancyLast60s: state.telemetry.averageOccupancyLast60s,
            timeAbove50Occupancy: state.telemetry.timeAbove50Occupancy,
            timeAbove70Occupancy: state.telemetry.timeAbove70Occupancy,
            topRowsTouchedCount: state.telemetry.topRowsTouchedCount,
            nearDeathEvents: state.telemetry.nearDeathEvents,
            expertPressureRampActive: state.telemetry.expertPressureRampActive,
            expertSpawnPressureTier: state.telemetry.expertSpawnPressureTier
        )
    }}
