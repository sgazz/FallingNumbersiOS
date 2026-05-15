import Foundation

enum MatchDirection: String {
    case horizontal = "H"
    case vertical = "V"
}

enum GameDebugLogger {
#if DEBUG
    private static let prefix = "[GAME-DEBUG]"
    private static let enableVerboseLogs = false

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
        specialSpawnChance: Double,
        awarded: Int
    ) {
        let chance = Int((specialSpawnChance * 100.0).rounded())
        log("cascade=\(cascade) lineMultiplier=\(lengthMultiplier) cascadeMultiplier=\(cascadeMultiplier) scoreAwarded=\(awarded) specialChance=\(chance)% base=\(baseScore) len=\(lineLength)")
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
#else
    static func log(_ message: String) {}
    static func logPieceSpawn(value: Int, position: GridPosition) {}
    static func logMove(action: String, from: GridPosition, to: GridPosition?, accepted: Bool) {}
    static func logHardDrop(value: Int, finalPosition: GridPosition, droppedRows: Int) {}
    static func logLock(value: Int, position: GridPosition) {}
    static func logBoard(_ board: Board, title: String) {}
    static func logMatch(direction: MatchDirection, positions: [GridPosition], values: [Int], target: Int, removed: Int, cascade: Int, score: Int) {}
    static func logCascade(step: Int) {}
    static func logScoreBreakdown(cascade: Int, lineLength: Int, baseScore: Int, lengthMultiplier: Double, cascadeMultiplier: Double, specialSpawnChance: Double, awarded: Int) {}
    static func logGameOver(spawnPosition: GridPosition, board: Board) {}
    static func logPerfectClear(bonus: Int, cascade: Int, specialSpawnChance: Double) {}
    static func logPowerUp(type: String, axis: String?, index: Int?, removed: Int) {}
    static func logState(target: Int, spawnColumn: Int, occupancyPercent: Int) {}
#endif
}
