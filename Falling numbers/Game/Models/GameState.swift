import Foundation

struct GameState {
    var gameMode: GameMode
    var board: Board
    var activePiece: FallingPiece?
    var lastLockedPosition: GridPosition?
    var isLockDelayActive: Bool
    var lockDelayRemaining: TimeInterval
    var nextPieceKind: TileKind
    var hasPlayerMoved: Bool
    var score: Int
    var level: Int
    var totalClearedTiles: Int
    var linesCleared: Int
    var perfectClearsCount: Int
    var highestCascade: Int
    var longestLineCleared: Int
    var targetTimerRemaining: TimeInterval
    var targetCycleIndex: Int
    var cascadeCount: Int
    var movesWithoutClear: Int
    var specialSpawnChance: Double
    var lastClearLength: Int
    var lastClearLengthMultiplier: Double
    var targetNumber: Int
    var targetRepeatCount: Int
    var didLevelChange: Bool
    var didTargetChange: Bool
    var didPerfectClear: Bool
    var lastPerfectClearBonus: Int
    var lastPowerUpActivation: PowerUpActivation?
    var powerUpEventToken: Int
    var lastSumClearEvent: SumClearEvent?
    var sumClearEventToken: Int
    var expertPressureRampActive: Bool
    var expertSpawnPressureTier: Int
    var expertBurstRemaining: Int
    var expertBurstColumn: Int?
    var spawnedNumberHistory: [Int]
    var telemetry: SessionTelemetry
    var currentTickInterval: TimeInterval
    var isGameOver: Bool
    var isPaused: Bool

    static func initial(config: GameConfig) -> GameState {
        initial(config: config, mode: .beginner)
    }

    static func initial(config: GameConfig, mode: GameMode) -> GameState {
        GameState(
            gameMode: mode,
            board: Board(rows: config.rows(for: mode), columns: config.columns(for: mode)),
            activePiece: nil,
            lastLockedPosition: nil,
            isLockDelayActive: false,
            lockDelayRemaining: 0,
            nextPieceKind: .number(1),
            hasPlayerMoved: false,
            score: 0,
            level: 1,
            totalClearedTiles: 0,
            linesCleared: 0,
            perfectClearsCount: 0,
            highestCascade: 0,
            longestLineCleared: 0,
            targetTimerRemaining: config.targetChangeInterval,
            targetCycleIndex: 0,
            cascadeCount: 0,
            movesWithoutClear: 0,
            specialSpawnChance: 0.02,
            lastClearLength: 0,
            lastClearLengthMultiplier: 1.0,
            targetNumber: config.baseTargetNumber,
            targetRepeatCount: 0,
            didLevelChange: false,
            didTargetChange: false,
            didPerfectClear: false,
            lastPerfectClearBonus: 0,
            lastPowerUpActivation: nil,
            powerUpEventToken: 0,
            lastSumClearEvent: nil,
            sumClearEventToken: 0,
            expertPressureRampActive: false,
            expertSpawnPressureTier: 0,
            expertBurstRemaining: 0,
            expertBurstColumn: nil,
            spawnedNumberHistory: [],
            telemetry: .initial,
            currentTickInterval: config.tickInterval,
            isGameOver: false,
            isPaused: false
        )
    }

    var nextPieceValue: Int {
        get { nextPieceKind.numericValue ?? 1 }
        set { nextPieceKind = .number(newValue) }
    }

    var nextPieceDisplayText: String {
        nextPieceKind.displayText
    }

    var formattedActivePlayTime: String {
        let total = max(0, Int(telemetry.activeGameplaySeconds.rounded(.down)))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedTargetChangeCountdown: String {
        let total = max(0, Int(targetTimerRemaining.rounded(.up)))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
