import Foundation

struct GameState {
    var board: Board
    var activePiece: FallingPiece?
    var lastLockedPosition: GridPosition?
    var isLockDelayActive: Bool
    var lockDelayRemaining: TimeInterval
    var nextPieceValue: Int
    var hasPlayerMoved: Bool
    var score: Int
    var level: Int
    var totalClearedTiles: Int
    var targetTimerRemaining: TimeInterval
    var targetCycleIndex: Int
    var comboCount: Int
    var targetNumber: Int
    var targetRepeatCount: Int
    var didLevelChange: Bool
    var didTargetChange: Bool
    var currentTickInterval: TimeInterval
    var isGameOver: Bool
    var isPaused: Bool

    static func initial(config: GameConfig) -> GameState {
        GameState(
            board: Board(rows: config.rows, columns: config.columns),
            activePiece: nil,
            lastLockedPosition: nil,
            isLockDelayActive: false,
            lockDelayRemaining: 0,
            nextPieceValue: 1,
            hasPlayerMoved: false,
            score: 0,
            level: 1,
            totalClearedTiles: 0,
            targetTimerRemaining: config.targetChangeInterval,
            targetCycleIndex: 0,
            comboCount: 0,
            targetNumber: config.baseTargetNumber,
            targetRepeatCount: 0,
            didLevelChange: false,
            didTargetChange: false,
            currentTickInterval: config.tickInterval,
            isGameOver: false,
            isPaused: false
        )
    }
}
