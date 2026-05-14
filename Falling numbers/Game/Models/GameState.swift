import Foundation

struct GameState {
    var board: Board
    var activePiece: FallingPiece?
    var nextPieceValue: Int
    var hasPlayerMoved: Bool
    var score: Int
    var level: Int
    var totalClearedTiles: Int
    var comboCount: Int
    var targetNumber: Int
    var currentTickInterval: TimeInterval
    var isGameOver: Bool
    var isPaused: Bool

    static func initial(config: GameConfig) -> GameState {
        GameState(
            board: Board(rows: config.rows, columns: config.columns),
            activePiece: nil,
            nextPieceValue: 1,
            hasPlayerMoved: false,
            score: 0,
            level: 1,
            totalClearedTiles: 0,
            comboCount: 0,
            targetNumber: config.baseTargetNumber,
            currentTickInterval: config.tickInterval,
            isGameOver: false,
            isPaused: false
        )
    }
}
