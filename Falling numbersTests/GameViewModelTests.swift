import Testing
import CoreGraphics
import Foundation
import SpriteKit
@testable import Falling_numbers

@MainActor
struct GameViewModelTests {
    @Test
    @MainActor
    func highScoreUpdatesFromScore() {
        let store = TestHighScoreStore(initial: 5)

        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.activePiece = FallingPiece(value: 8, position: GridPosition(row: 0, column: 1))
        let engine = GameEngine(state: state, config: config)

        let viewModel = GameScreenViewModel(engine: engine, highScoreStore: store)
        viewModel.startGameFromOverlay()
        viewModel.hardDrop()

        #expect(viewModel.highScore > 5)
        #expect(store.savedValue(for: .beginner) == viewModel.highScore)
    }

    @Test
    @MainActor
    func beginnerAndExpertHighScoresAreSeparate() {
        let store = TestHighScoreStore(initialBeginner: 80, initialExpert: 140)
        let viewModel = GameScreenViewModel(engine: GameEngine(), highScoreStore: store)

        #expect(viewModel.highScore == 80)
        viewModel.setMode(.expert)
        #expect(viewModel.highScore == 140)

        viewModel.resetHighScore()
        #expect(store.savedValue(for: .expert) == 0)
        #expect(store.savedValue(for: .beginner) == 80)
    }

    @Test
    @MainActor
    func cascadeHUDOnlyInBeginnerMode() {
        let viewModel = GameScreenViewModel(engine: GameEngine(), highScoreStore: TestHighScoreStore(initial: 0))
        #expect(viewModel.state.gameMode == .beginner)
        #expect(viewModel.showsCascadeHUD)
        viewModel.setMode(.expert)
        #expect(viewModel.state.gameMode == .expert)
        #expect(!viewModel.showsCascadeHUD)
    }

    @Test
    @MainActor
    func pausedStateBlocksGestures() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 1))
        let engine = GameEngine(state: state, config: config)

        let viewModel = GameScreenViewModel(engine: engine, highScoreStore: TestHighScoreStore(initial: 0))
        viewModel.startGameFromOverlay()
        viewModel.togglePause()

        let before = viewModel.state.activePiece
        viewModel.handleDrag(translation: CGSize(width: 0, height: 120))

        #expect(viewModel.state.activePiece == before)
    }

    @Test
    @MainActor
    func swipeLeftMovesExactlyOneColumn() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 2))
        let engine = GameEngine(state: state, config: config)

        let viewModel = GameScreenViewModel(engine: engine, highScoreStore: TestHighScoreStore(initial: 0))
        viewModel.startGameFromOverlay()
        let before = viewModel.state.activePiece!.position

        viewModel.handleDrag(translation: CGSize(width: -60, height: 8))
        let after = viewModel.state.activePiece!.position

        #expect(after.column == before.column - 1)
        #expect(after.row == before.row)
    }

    @Test
    @MainActor
    func swipeRightMovesExactlyOneColumn() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 1))
        let engine = GameEngine(state: state, config: config)

        let viewModel = GameScreenViewModel(engine: engine, highScoreStore: TestHighScoreStore(initial: 0))
        viewModel.startGameFromOverlay()
        let before = viewModel.state.activePiece!.position

        viewModel.handleDrag(translation: CGSize(width: 64, height: 10))
        let after = viewModel.state.activePiece!.position

        #expect(after.column == before.column + 1)
        #expect(after.row == before.row)
    }

    @Test
    @MainActor
    func shortSwipeDownSoftDropsOneRow() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 1))
        let engine = GameEngine(state: state, config: config)

        let viewModel = GameScreenViewModel(engine: engine, highScoreStore: TestHighScoreStore(initial: 0))
        viewModel.startGameFromOverlay()
        let before = viewModel.state.activePiece!.position

        viewModel.handleDrag(translation: CGSize(width: 6, height: 46))
        let after = viewModel.state.activePiece!.position

        #expect(after.row == before.row + 1)
        #expect(after.column == before.column)
    }

    @Test
    @MainActor
    func longSwipeDownHardDrops() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.activePiece = FallingPiece(value: 8, position: GridPosition(row: 0, column: 1))
        let engine = GameEngine(state: state, config: config)

        let viewModel = GameScreenViewModel(engine: engine, highScoreStore: TestHighScoreStore(initial: 0))
        viewModel.startGameFromOverlay()

        viewModel.handleDrag(translation: CGSize(width: 0, height: 140))

        #expect(viewModel.state.board.cell(at: GridPosition(row: 5, column: 1))?.value == 8)
    }

    @Test
    @MainActor
    func lifecyclePauseAndResumeBehavior() {
        let viewModel = GameScreenViewModel(
            engine: GameEngine(),
            highScoreStore: TestHighScoreStore(initial: 0),
            settingsStore: TestSettingsStore(initial: .default),
            haptics: NoopHapticsClient(),
            audio: NoopAudioClient()
        )

        viewModel.startGameFromOverlay()
        #expect(!viewModel.state.isPaused)

        viewModel.appDidEnterBackground()
        #expect(viewModel.state.isPaused)

        viewModel.appDidBecomeActive()
        #expect(!viewModel.state.isPaused)
    }

    @Test
    @MainActor
    func settingsPersistenceAndResetHighScore() {
        let highScoreStore = TestHighScoreStore(initial: 120)
        let settingsStore = TestSettingsStore(initial: AppSettings(isSoundEnabled: true, isHapticsEnabled: true))
        let viewModel = GameScreenViewModel(
            engine: GameEngine(),
            highScoreStore: highScoreStore,
            settingsStore: settingsStore,
            haptics: NoopHapticsClient(),
            audio: NoopAudioClient()
        )

        viewModel.setSoundEnabled(false)
        viewModel.setHapticsEnabled(false)
        viewModel.resetHighScore()

        #expect(settingsStore.savedSettings == AppSettings(isSoundEnabled: false, isHapticsEnabled: false))
        #expect(viewModel.highScore == 0)
        #expect(highScoreStore.savedValue(for: .beginner) == 0)
    }

    @Test
    @MainActor
    func foregroundDoesNotCreateDuplicateTimers() {
        let viewModel = GameScreenViewModel(
            engine: GameEngine(),
            highScoreStore: TestHighScoreStore(initial: 0),
            settingsStore: TestSettingsStore(initial: .default),
            haptics: NoopHapticsClient(),
            audio: NoopAudioClient()
        )

        let startCount = viewModel.timerStartCount
        viewModel.appDidBecomeActive()
        viewModel.appDidBecomeActive()

        #expect(viewModel.timerStartCount == startCount)
    }

    @Test
    @MainActor
    func soundTogglePreventsEventTrigger() {
        let audio = RecordingAudioClient()
        let viewModel = GameScreenViewModel(
            engine: GameEngine(),
            highScoreStore: TestHighScoreStore(initial: 0),
            settingsStore: TestSettingsStore(initial: AppSettings(isSoundEnabled: true, isHapticsEnabled: false)),
            haptics: NoopHapticsClient(),
            audio: audio
        )

        viewModel.setSoundEnabled(false)
        viewModel.togglePause()
        viewModel.hardDrop()

        #expect(audio.events.isEmpty)
    }

    @Test
    @MainActor
    func newBestDetectionAtGameOver() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.isGameOver = true
        state.score = 240
        let viewModel = GameScreenViewModel(
            engine: GameEngine(state: state, config: config),
            highScoreStore: TestHighScoreStore(initial: 120),
            settingsStore: TestSettingsStore(initial: .default),
            haptics: NoopHapticsClient(),
            audio: NoopAudioClient()
        )

        #expect(viewModel.isNewBestForCurrentGameOver)
    }

    @Test(arguments: [GameMode.beginner, GameMode.expert])
    @MainActor
    func lockAndRepeatedClearProduceFeedback(mode: GameMode) {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 60, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: mode)
        state.cascadeCount = 2
        state.linesCleared = 1
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 5, column: 1))
        state.board.setCell(Cell(value: 9), at: GridPosition(row: 5, column: 3))
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 1))
        let audio = RecordingAudioClient()
        let haptics = RecordingHapticsClient()
        let viewModel = GameScreenViewModel(
            engine: GameEngine(state: state, config: config),
            highScoreStore: TestHighScoreStore(initial: 10000),
            settingsStore: TestSettingsStore(initial: .default),
            haptics: haptics,
            audio: audio
        )
        viewModel.startGameFromOverlay()
        viewModel.hardDrop()

        #expect(viewModel.state.activePiece != nil)
        #expect(viewModel.state.linesCleared == 2)
        #expect(audio.events.filter { $0 == .lock }.count == 1)
        #expect(audio.events.filter { $0 == .clear }.count == 1)
        #expect(haptics.lockCount == 1)
        #expect(haptics.clearCount == 1)
        viewModel.togglePause()
        viewModel.hardDrop()
        #expect(haptics.lockCount == 1)
        #expect(haptics.clearCount == 1)
    }
}
