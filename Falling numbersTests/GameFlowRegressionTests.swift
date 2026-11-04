import Testing
import Foundation
@testable import Falling_numbers

@MainActor
struct GameFlowRegressionTests {
    @Test
    func resettingRecordExcludesCurrentRunUntilNewGame() {
        let config = GameConfig(columns: 4, rows: 8, tickInterval: 60, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.score = 75
        let store = TestHighScoreStore(initial: 120)
        let model = GameScreenViewModel(
            engine: GameEngine(state: state, config: config), highScoreStore: store,
            settingsStore: TestSettingsStore(initial: .default),
            haptics: NoopHapticsClient(), audio: NoopAudioClient()
        )
        model.resetHighScore()
        model.startGameFromOverlay()
        model.hardDrop()
        model.togglePause()
        #expect(model.state.score > 75)
        #expect(model.highScore == 0)
        #expect(store.savedValue(for: .beginner) == 0)
        #expect(!model.isNewBestForCurrentGameOver)
        model.newGame()
        model.hardDrop()
        #expect(model.highScore > 0)
        #expect(store.savedValue(for: .beginner) == model.highScore)
        model.pauseForMenu()
    }

    @Test
    func menuPlayResumesSameRunAndModeSwitchStartsNewRun() {
        let model = GameScreenViewModel(
            highScoreStore: TestHighScoreStore(initial: 0),
            haptics: NoopHapticsClient(), audio: NoopAudioClient()
        )
        model.playFromMenu(mode: .beginner)
        model.hardDrop()
        let score = model.state.score
        let board = model.state.board
        model.pauseForMenu()
        #expect(model.state.isPaused)
        model.playFromMenu(mode: .beginner)
        #expect(!model.state.isPaused)
        #expect(model.state.board == board)
        #expect(model.state.score == score)
        model.pauseForMenu()
        model.playFromMenu(mode: .expert)
        #expect(model.state.gameMode == .expert)
        #expect(model.state.score == 0)
        #expect(!model.state.isPaused)
        model.pauseForMenu()
    }

    @Test(arguments: [0.65, 0.15])
    func lockDelayUsesElapsedTimeRegardlessOfFallSpeed(fallInterval: Double) {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: fallInterval,
                                lockDelayDuration: 0.22, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.activePiece = FallingPiece(value: 8, position: GridPosition(row: 4, column: 1))
        var engine = GameEngine(state: state, config: config)
        engine.send(.softDrop)
        engine.send(.advanceTime(0.20))
        #expect(engine.state.telemetry.totalLocks == 0)
        engine.send(.advanceTime(0.02))
        #expect(engine.state.telemetry.totalLocks == 1)
        #expect(engine.state.board.cell(at: GridPosition(row: 5, column: 1))?.value == 8)
    }

    @Test
    func elapsedClockDoesNotMoveBeforeFallIntervalOrWhilePaused() {
        let config = GameConfig(columns: 4, rows: 8, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.activePiece = FallingPiece(value: 8, position: GridPosition(row: 0, column: 1))
        var engine = GameEngine(state: state, config: config)
        engine.send(.advanceTime(0.30))
        #expect(engine.state.activePiece?.position.row == 0)
        engine.send(.togglePause)
        engine.send(.advanceTime(10))
        #expect(abs(engine.state.telemetry.activeGameplaySeconds - 0.30) < 0.000_001)
        engine.send(.togglePause)
        engine.send(.advanceTime(0.35))
        #expect(engine.state.activePiece?.position.row == 1)
    }

    @Test
    func telemetryTracksDurationOccupancyAndNearDeathTransitions() {
        let config = GameConfig(columns: 2, rows: 4, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board.setCell(Cell(value: 4), at: GridPosition(row: 0, column: 0))
        BalanceTelemetrySystem.recordActiveGameplayTime(state: &state, elapsed: 2.0)

        #expect(state.telemetry.activeGameplaySeconds == 2.0)
        #expect(state.telemetry.timeSpentPerLevel[1] == 2.0)
        #expect(state.telemetry.nearDeathEvents == 1)
        #expect(state.telemetry.topRowsTouchedCount == 1)
        #expect(state.telemetry.averageOccupancyLast60s > 0)

        BalanceTelemetrySystem.recordActiveGameplayTime(state: &state, elapsed: 1.0)
        #expect(state.telemetry.nearDeathEvents == 1)
        #expect(state.telemetry.topRowsTouchedCount == 1)
    }

    @Test
    func levelProgressReflectsScoreBetweenThresholds() {
        let config = GameConfig(columns: 4, rows: 8, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.score = 200
        let model = GameScreenViewModel(
            engine: GameEngine(state: state, config: config),
            highScoreStore: TestHighScoreStore(initial: 0),
            settingsStore: TestSettingsStore(initial: .default),
            haptics: NoopHapticsClient(), audio: NoopAudioClient()
        )
        #expect(model.levelProgress > 0)
        #expect(model.levelProgress < 1)
    }
}
