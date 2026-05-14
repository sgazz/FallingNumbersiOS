import Foundation

enum MatchDirection: String {
    case horizontal = "H"
    case vertical = "V"
}

enum GameDebugLogger {
#if DEBUG
    private static let prefix = "[GAME-DEBUG]"

    static func log(_ message: String) {
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
        sum: Int,
        target: Int
    ) {
        let pos = positions.map { "r\($0.row)c\($0.column)" }.joined(separator: ",")
        let vals = values.map(String.init).joined(separator: "+")
        log("match \(direction.rawValue) target=\(target) sum=\(sum) vals=\(vals) pos=[\(pos)]")
    }

    static func logResolvePass(
        pass: Int,
        selected: [GridPosition],
        scoreGained: Int,
        combo: Int,
        continued: Bool
    ) {
        let pos = selected.map { "r\($0.row)c\($0.column)" }.joined(separator: ",")
        log("resolve pass=\(pass) clear=[\(pos)] score+\(scoreGained) combo=\(combo) continued=\(continued)")
    }

    static func logGameOver(spawnPosition: GridPosition, board: Board) {
        log("game_over spawn_blocked at r\(spawnPosition.row)c\(spawnPosition.column)")
        logBoard(board, title: "board at game over")
    }
#else
    static func log(_ message: String) {}
    static func logPieceSpawn(value: Int, position: GridPosition) {}
    static func logMove(action: String, from: GridPosition, to: GridPosition?, accepted: Bool) {}
    static func logHardDrop(value: Int, finalPosition: GridPosition, droppedRows: Int) {}
    static func logLock(value: Int, position: GridPosition) {}
    static func logBoard(_ board: Board, title: String) {}
    static func logMatch(direction: MatchDirection, positions: [GridPosition], values: [Int], sum: Int, target: Int) {}
    static func logResolvePass(pass: Int, selected: [GridPosition], scoreGained: Int, combo: Int, continued: Bool) {}
    static func logGameOver(spawnPosition: GridPosition, board: Board) {}
#endif
}
