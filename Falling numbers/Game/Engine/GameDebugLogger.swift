import Foundation

enum MatchDirection: String {
    case horizontal = "H"
    case vertical = "V"
}

enum GameDebugLogger {
#if DEBUG
    private static let prefix = "[GAME-DEBUG]"
    private static let enableVerboseLogs = false
    private static let enableBalanceSampling = true

    static func log(_ message: String) {
        guard enableVerboseLogs else { return }
        print("\(prefix) \(message)")
    }

    static func logPieceSpawn(value: Int, position: GridPosition) {
        log("spawn value=\(value) at r\(position.row)c\(position.column)")
    }

    static func logMove(action: String, from: GridPosition, to: GridPosition?, accepted: Bool) {
        let result = accepted ? "ok" : "blocked"
        if let to {
            log("\(action) \(result) from r\(from.row)c\(from.column) to r\(to.row)c\(to.column)")
        } else {
            log("\(action) \(result) from r\(from.row)c\(from.column)")
        }
    }

    static func logHardDrop(value: Int, finalPosition: GridPosition, droppedRows: Int) {
        log("hard_drop value=\(value) rows=\(droppedRows) final=r\(finalPosition.row)c\(finalPosition.column)")
    }

    static func logLock(value: Int, position: GridPosition) {
        log("lock value=\(value) at r\(position.row)c\(position.column)")
    }

    static func logBoard(_ board: Board, title: String) {
        log(title)
        for row in 0..<board.rows {
            var line = ""
            for column in 0..<board.columns {
                let value = board.cell(at: GridPosition(row: row, column: column))?.value
                line += value.map(String.init) ?? "."
            }
            log(line)
        }
    }

    static func logMatch(
        direction: MatchDirection,
        positions: [GridPosition],
        values: [Int],
        target: Int,
        removed: Int,
        cascade: Int,
        score: Int
    ) {
        let pos = positions.map { "[\($0.row),\($0.column)]" }.joined(separator: "")
        let vals = values.map(String.init).joined(separator: "+")
        print("[MATCH]")
        print("target=\(target)")
        print("dir=\(direction.rawValue)")
        print("values=\(vals)")
        print("positions=\(pos)")
        print("removed=\(removed)")
        print("cascade=\(cascade)")
        print("score=\(score)")
    }

    static func logCascade(step: Int) {
        print("[CASCADE]")
        print("step=\(step)")
    }

    static func logScoreBreakdown(
        cascade: Int,
        lineLength: Int,
        baseScore: Int,
        lengthMultiplier: Double,
        cascadeMultiplier: Double,
        expertMultiplier: Double,
        specialSpawnChance: Double,
        awarded: Int
    ) {
        let chance = Int((specialSpawnChance * 100.0).rounded())
        log("cascade=\(cascade) lineMultiplier=\(lengthMultiplier) cascadeMultiplier=\(cascadeMultiplier) expertMultiplier=\(expertMultiplier) scoreAwarded=\(awarded) specialChance=\(chance)% base=\(baseScore) len=\(lineLength)")
    }

    static func logGameOver(spawnPosition: GridPosition, board: Board) {
        log("game_over spawn_blocked at r\(spawnPosition.row)c\(spawnPosition.column)")
        logBoard(board, title: "board at game over")
    }

    static func logPerfectClear(bonus: Int, cascade: Int, specialSpawnChance: Double) {
        print("[PERFECT CLEAR]")
        print("bonus=\(bonus)")
    }

    static func logPowerUp(type: String, axis: String?, index: Int?, removed: Int) {
        print("[POWERUP]")
        print("type=\(type)")
        if let axis, let index {
            print("\(axis)=\(index)")
        }
        print("removed=\(removed)")
    }

    static func logState(target: Int, spawnColumn: Int, occupancyPercent: Int) {
        print("[STATE]")
        print("target=\(target)")
        print("spawnColumn=\(spawnColumn)")
        print("occupancy=\(occupancyPercent)%")
    }

    static func logBalanceSample(
        level: Int,
        score: Int,
        occupancyPercent: Int,
        target: Int,
        spawnColumn: Int?,
        totalMatches: Int,
        totalPowerUps: Int,
        cascadeCount: Int,
        expertPressureRampActive: Bool,
        expertSpawnPressureTier: Int
    ) {
        guard enableBalanceSampling else { return }
        let spawnText = spawnColumn.map(String.init) ?? "-"
        print(
            "[BALANCE-SAMPLE] level=\(level) score=\(score) occupancy=\(occupancyPercent)% target=\(target) " +
            "spawnColumn=\(spawnText) totalMatches=\(totalMatches) totalPowerUps=\(totalPowerUps) " +
            "cascade=\(cascadeCount) pressureActive=\(expertPressureRampActive) pressureTier=\(expertSpawnPressureTier)"
        )
    }

    static func logBalanceSummary(
        sessionDuration: TimeInterval,
        finalLevel: Int,
        finalScore: Int,
        totalLocks: Int,
        totalMatches: Int,
        totalClearedTiles: Int,
        averageOccupancy: Double,
        maxOccupancy: Int,
        minOccupancy: Int,
        occupancyByLevel: [Int: LevelOccupancyStats],
        powerUpsSpawned: [PowerUpType: Int],
        powerUpsUsed: [PowerUpType: Int],
        matchesByLength: [Int: Int],
        cascadeDepthDistribution: [Int: Int],
        averageScorePerMinute: Double,
        averageClearsPerMinute: Double,
        timeSpentPerLevel: [Int: TimeInterval],
        gameOverReason: GameOverReason?,
        averageOccupancyLast60s: Double,
        timeAbove50Occupancy: TimeInterval,
        timeAbove70Occupancy: TimeInterval,
        topRowsTouchedCount: Int,
        nearDeathEvents: Int,
        expertPressureRampActive: Bool,
        expertSpawnPressureTier: Int
    ) {
        print("[BALANCE-SUMMARY]")
        print("sessionDuration=\(Int(sessionDuration))s finalLevel=\(finalLevel) finalScore=\(finalScore)")
        print("totalLocks=\(totalLocks) totalMatches=\(totalMatches) totalClearedTiles=\(totalClearedTiles)")
        print("occupancy avg=\(String(format: "%.1f", averageOccupancy)) min=\(minOccupancy) max=\(maxOccupancy)")
        print("avgScorePerMinute=\(String(format: "%.2f", averageScorePerMinute)) avgClearsPerMinute=\(String(format: "%.2f", averageClearsPerMinute))")
        print("averageOccupancyLast60s=\(String(format: "%.1f", averageOccupancyLast60s))")
        print("timeAbove50Occupancy=\(Int(timeAbove50Occupancy))s timeAbove70Occupancy=\(Int(timeAbove70Occupancy))s")
        print("topRowsTouchedCount=\(topRowsTouchedCount) nearDeathEvents=\(nearDeathEvents)")
        print("expertPressureRampActive=\(expertPressureRampActive) expertSpawnPressureTier=\(expertSpawnPressureTier)")
        print("gameOverReason=\(gameOverReason?.rawValue ?? "none")")

        let levelLines = occupancyByLevel
            .keys.sorted()
            .compactMap { level -> String? in
                guard let stats = occupancyByLevel[level], stats.sampleCount > 0 else { return nil }
                return "L\(level):avg\(String(format: "%.1f", stats.averageOccupancy)) min\(stats.minOccupancy) max\(stats.maxOccupancy) n\(stats.sampleCount)"
            }
            .joined(separator: " | ")
        print("occupancyByLevel=\(levelLines)")

        let spawned = PowerUpType.allCases
            .map { "\($0.rawValue)=\(powerUpsSpawned[$0] ?? 0)" }
            .joined(separator: ",")
        let used = PowerUpType.allCases
            .map { "\($0.rawValue)=\(powerUpsUsed[$0] ?? 0)" }
            .joined(separator: ",")
        print("powerUpsSpawned=\(spawned)")
        print("powerUpsUsed=\(used)")

        let lengthDist = matchesByLength.keys.sorted().map { "len\($0)=\(matchesByLength[$0] ?? 0)" }.joined(separator: ",")
        let cascadeDist = cascadeDepthDistribution.keys.sorted().map { "c\($0)=\(cascadeDepthDistribution[$0] ?? 0)" }.joined(separator: ",")
        print("matchesByLength=\(lengthDist)")
        print("cascadeDepthDistribution=\(cascadeDist)")

        let levelTime = timeSpentPerLevel.keys.sorted().map {
            "L\($0)=\(Int(timeSpentPerLevel[$0] ?? 0))s"
        }.joined(separator: ",")
        print("timeSpentPerLevel=\(levelTime)")
    }

    static func logSpeed(level: Int, interval: TimeInterval, mode: GameMode) {
        print("[SPEED] level=\(level) interval=\(String(format: "%.2f", interval)) mode=\(mode.rawValue)")
    }

    static func logPowerUpChanceAdjustment(
        mode: GameMode,
        reason: String,
        occupancyPercent: Int,
        baseChance: Double,
        adjustedChance: Double
    ) {
        print(
            "[BALANCE] powerup_chance mode=\(mode.rawValue) reason=\(reason) occupancy=\(occupancyPercent)% " +
            "base=\(String(format: "%.3f", baseChance)) adjusted=\(String(format: "%.3f", adjustedChance))"
        )
    }

    static func logLongCascade(
        level: Int,
        target: Int,
        cascade: Int,
        occupancyBefore: Int,
        occupancyAfter: Int,
        clearedTilesInChain: Int
    ) {
        print(
            "[BALANCE] long_cascade level=\(level) target=\(target) cascade=\(cascade) " +
            "occupancyBefore=\(occupancyBefore)% occupancyAfter=\(occupancyAfter)% " +
            "clearedTilesInChain=\(clearedTilesInChain)"
        )
    }

    static func logFallSpeed(
        mode: GameMode,
        level: Int,
        multiplier: Double,
        baseFallInterval: TimeInterval,
        adjustedFallInterval: TimeInterval
    ) {
        print(
            "[BALANCE] fall_speed mode=\(mode.rawValue) level=\(level) multiplier=\(String(format: "%.3f", multiplier)) " +
            "baseFallInterval=\(String(format: "%.3f", baseFallInterval)) " +
            "adjustedFallInterval=\(String(format: "%.3f", adjustedFallInterval))"
        )
    }

    static func logCascadeCapHit(mode: GameMode, cap: Int, level: Int, cascade: Int) {
        print("[BALANCE] cascade_cap_hit mode=\(mode.rawValue) cap=\(cap) level=\(level) cascade=\(cascade)")
    }

    static func logTargetChange(mode: GameMode, level: Int, from: Int, to: Int, cycle: Int) {
        print("[BALANCE] target_change mode=\(mode.rawValue) level=\(level) cycle=\(cycle) from=\(from) to=\(to)")
    }
#else
    static func log(_ message: String) {}
    static func logPieceSpawn(value: Int, position: GridPosition) {}
    static func logMove(action: String, from: GridPosition, to: GridPosition?, accepted: Bool) {}
    static func logHardDrop(value: Int, finalPosition: GridPosition, droppedRows: Int) {}
    static func logLock(value: Int, position: GridPosition) {}
    static func logBoard(_ board: Board, title: String) {}
    static func logMatch(direction: MatchDirection, positions: [GridPosition], values: [Int], target: Int, removed: Int, cascade: Int, score: Int) {}
    static func logCascade(step: Int) {}
    static func logScoreBreakdown(cascade: Int, lineLength: Int, baseScore: Int, lengthMultiplier: Double, cascadeMultiplier: Double, expertMultiplier: Double, specialSpawnChance: Double, awarded: Int) {}
    static func logGameOver(spawnPosition: GridPosition, board: Board) {}
    static func logPerfectClear(bonus: Int, cascade: Int, specialSpawnChance: Double) {}
    static func logPowerUp(type: String, axis: String?, index: Int?, removed: Int) {}
    static func logState(target: Int, spawnColumn: Int, occupancyPercent: Int) {}
    static func logBalanceSample(level: Int, score: Int, occupancyPercent: Int, target: Int, spawnColumn: Int?, totalMatches: Int, totalPowerUps: Int, cascadeCount: Int, expertPressureRampActive: Bool, expertSpawnPressureTier: Int) {}
    static func logBalanceSummary(sessionDuration: TimeInterval, finalLevel: Int, finalScore: Int, totalLocks: Int, totalMatches: Int, totalClearedTiles: Int, averageOccupancy: Double, maxOccupancy: Int, minOccupancy: Int, occupancyByLevel: [Int: LevelOccupancyStats], powerUpsSpawned: [PowerUpType: Int], powerUpsUsed: [PowerUpType: Int], matchesByLength: [Int: Int], cascadeDepthDistribution: [Int: Int], averageScorePerMinute: Double, averageClearsPerMinute: Double, timeSpentPerLevel: [Int: TimeInterval], gameOverReason: GameOverReason?, averageOccupancyLast60s: Double, timeAbove50Occupancy: TimeInterval, timeAbove70Occupancy: TimeInterval, topRowsTouchedCount: Int, nearDeathEvents: Int, expertPressureRampActive: Bool, expertSpawnPressureTier: Int) {}
    static func logSpeed(level: Int, interval: TimeInterval, mode: GameMode) {}
    static func logPowerUpChanceAdjustment(mode: GameMode, reason: String, occupancyPercent: Int, baseChance: Double, adjustedChance: Double) {}
    static func logLongCascade(level: Int, target: Int, cascade: Int, occupancyBefore: Int, occupancyAfter: Int, clearedTilesInChain: Int) {}
    static func logFallSpeed(mode: GameMode, level: Int, multiplier: Double, baseFallInterval: TimeInterval, adjustedFallInterval: TimeInterval) {}
    static func logCascadeCapHit(mode: GameMode, cap: Int, level: Int, cascade: Int) {}
    static func logTargetChange(mode: GameMode, level: Int, from: Int, to: Int, cycle: Int) {}
#endif
}
