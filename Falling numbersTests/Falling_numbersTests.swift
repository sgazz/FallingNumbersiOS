import Testing
import CoreGraphics
import Foundation
@testable import Falling_numbers

struct FallingNumbersTests {

    @Test
    func findsTwoTileSubsetInsideLargerConnectedComponent() {
        var board = Board(rows: 3, columns: 3)
        board.setCell(Cell(value: 4), at: GridPosition(row: 1, column: 0))
        board.setCell(Cell(value: 6), at: GridPosition(row: 1, column: 1))
        board.setCell(Cell(value: 3), at: GridPosition(row: 0, column: 1))
        board.setCell(Cell(value: 7), at: GridPosition(row: 2, column: 1))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.map(groupKey).contains(groupKey([
            GridPosition(row: 1, column: 0),
            GridPosition(row: 1, column: 1)
        ])))
    }

    @Test
    func findsThreeTileSubsetInsideLargerConnectedComponent() {
        var board = Board(rows: 3, columns: 4)
        board.setCell(Cell(value: 2), at: GridPosition(row: 1, column: 1))
        board.setCell(Cell(value: 3), at: GridPosition(row: 1, column: 2))
        board.setCell(Cell(value: 5), at: GridPosition(row: 1, column: 3))
        board.setCell(Cell(value: 8), at: GridPosition(row: 0, column: 2))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.map(groupKey).contains(groupKey([
            GridPosition(row: 1, column: 1),
            GridPosition(row: 1, column: 2),
            GridPosition(row: 1, column: 3)
        ])))
    }

    @Test
    func doesNotIncludeDiagonalOnlyConnections() {
        var board = Board(rows: 3, columns: 3)
        board.setCell(Cell(value: 4), at: GridPosition(row: 0, column: 0))
        board.setCell(Cell(value: 6), at: GridPosition(row: 1, column: 1))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.isEmpty)
    }

    @Test
    func doesNotReturnDuplicateGroups() {
        var board = Board(rows: 2, columns: 2)
        board.setCell(Cell(value: 5), at: GridPosition(row: 0, column: 0))
        board.setCell(Cell(value: 5), at: GridPosition(row: 0, column: 1))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.count == 1)
        #expect(groupKey(matches[0]) == groupKey([GridPosition(row: 0, column: 0), GridPosition(row: 0, column: 1)]))
    }

    @Test
    func multiplePossibleGroupsAreDeterministic() {
        var board = Board(rows: 3, columns: 4)
        board.setCell(Cell(value: 4), at: GridPosition(row: 1, column: 0))
        board.setCell(Cell(value: 6), at: GridPosition(row: 1, column: 1))
        board.setCell(Cell(value: 3), at: GridPosition(row: 1, column: 2))
        board.setCell(Cell(value: 7), at: GridPosition(row: 1, column: 3))

        let first = CombinationDetector().findMatchingGroups(on: board, target: 10)
        let keys = first.map(groupKey)

        #expect(keys == keys.sorted())
        #expect(keys.contains(groupKey([GridPosition(row: 1, column: 0), GridPosition(row: 1, column: 1)])))
        #expect(keys.contains(groupKey([GridPosition(row: 1, column: 2), GridPosition(row: 1, column: 3)])))
    }

    @Test
    func chainReactionWorksAfterGravity() {
        let config = GameConfig(columns: 3, rows: 4, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.totalClearedTiles = 48

        state.board.setCell(Cell(value: 4), at: GridPosition(row: 3, column: 0))
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 3, column: 1))
        state.board.setCell(Cell(value: 3), at: GridPosition(row: 2, column: 0))
        state.board.setCell(Cell(value: 7), at: GridPosition(row: 2, column: 1))
        state.activePiece = FallingPiece(value: 1, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.totalClearedTiles >= 52)
        #expect(engine.state.comboCount >= 2)
        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 2))?.value == 1)
    }

    @Test
    func hardDropLocksCorrectly() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.activePiece = FallingPiece(value: 8, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.board.cell(at: GridPosition(row: 5, column: 1))?.value == 8)
        #expect(engine.state.activePiece != nil)
    }

    @Test
    func levelProgressionChangesSpeedAndTarget() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10)

        var lowState = GameState.initial(config: config)
        lowState.totalClearedTiles = 0
        let lowEngine = GameEngine(state: lowState, config: config)

        var highState = GameState.initial(config: config)
        highState.totalClearedTiles = 80
        let highEngine = GameEngine(state: highState, config: config)

        #expect(lowEngine.state.level < highEngine.state.level)
        #expect(lowEngine.state.currentTickInterval > highEngine.state.currentTickInterval)
        #expect(lowEngine.state.targetNumber != highEngine.state.targetNumber)
        #expect((5...20).contains(lowEngine.state.targetNumber))
        #expect((5...20).contains(highEngine.state.targetNumber))
    }

    @Test
    func pausedStateBlocksHardDrop() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.activePiece = FallingPiece(value: 8, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.togglePause)
        let before = engine.state
        engine.send(.hardDrop)

        #expect(engine.state.activePiece == before.activePiece)
        #expect(engine.state.board == before.board)
    }

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
        #expect(store.savedValue == viewModel.highScore)
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
    func gameOverWhenSpawnCellIsBlocked() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        let blockedSpawn = GridPosition(row: 0, column: config.columns / 2)
        state.board.setCell(Cell(value: 7), at: blockedSpawn)

        var engine = GameEngine(state: state, config: config)
        engine.send(.start)

        #expect(engine.state.isGameOver)
        #expect(engine.state.activePiece == nil)
    }

    @Test
    func deterministicClearOrderingUsesLargestGroupFirst() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.totalClearedTiles = 48

        // Two valid groups share one tile:
        // Large group: (0,0)=4 + (0,1)=2 + (1,1)=4
        // Small group: (0,0)=4 + (1,0)=6
        state.board.setCell(Cell(value: 4), at: GridPosition(row: 0, column: 0))
        state.board.setCell(Cell(value: 2), at: GridPosition(row: 0, column: 1))
        state.board.setCell(Cell(value: 4), at: GridPosition(row: 1, column: 1))
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 1, column: 0))
        state.activePiece = FallingPiece(value: 1, position: GridPosition(row: 0, column: 3))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        // If largest-group-first is used, the remaining board includes value 6
        // rather than preserving the 2+4 pair.
        let remainingValues = (0..<config.rows).flatMap { row in
            (0..<config.columns).compactMap { col in
                engine.state.board.cell(at: GridPosition(row: row, column: col))?.value
            }
        }
        #expect(remainingValues.contains(6))
    }

    @Test
    func comboProgressionIncreasesAcrossChain() {
        let config = GameConfig(columns: 3, rows: 4, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.totalClearedTiles = 48
        state.board.setCell(Cell(value: 4), at: GridPosition(row: 3, column: 0))
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 3, column: 1))
        state.board.setCell(Cell(value: 3), at: GridPosition(row: 2, column: 0))
        state.board.setCell(Cell(value: 7), at: GridPosition(row: 2, column: 1))
        state.activePiece = FallingPiece(value: 1, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.comboCount >= 2)
        #expect(engine.state.totalClearedTiles >= 52)
    }

    @Test
    func nextPieceConsistencyUsesPreviewedValue() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.nextPieceValue = 8

        var engine = GameEngine(state: state, config: config)
        engine.send(.start)

        #expect(engine.state.activePiece?.value == 8)
        #expect((1...9).contains(engine.state.nextPieceValue))
    }

    @Test
    func levelPacingBoundsStayPlayable() {
        let levelSystem = LevelSystem()
        let base: TimeInterval = 0.65

        let level1 = levelSystem.tickInterval(base: base, level: 1)
        let level5 = levelSystem.tickInterval(base: base, level: 5)
        let level12 = levelSystem.tickInterval(base: base, level: 12)
        let level40 = levelSystem.tickInterval(base: base, level: 40)

        #expect(level1 > level5)
        #expect(level5 > level12)
        #expect(level12 >= 0.26)
        #expect(level40 == 0.26)
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
        #expect(highScoreStore.savedValue == 0)
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
    func deterministicRestartState() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10)
        var engine = GameEngine(config: config)
        engine.send(.start)
        engine.send(.hardDrop)
        engine.send(.newGame)

        #expect(engine.state.score == 0)
        #expect(engine.state.comboCount == 0)
        #expect(engine.state.totalClearedTiles == 0)
        #expect(!engine.state.isGameOver)
        #expect(!engine.state.isPaused)
        #expect(engine.state.activePiece != nil)
        #expect((1...9).contains(engine.state.nextPieceValue))
    }

    private func groupKey(_ group: [GridPosition]) -> String {
        group
            .sorted { lhs, rhs in
                if lhs.row != rhs.row { return lhs.row < rhs.row }
                return lhs.column < rhs.column
            }
            .map { "\($0.row):\($0.column)" }
            .joined(separator: "|")
    }
}

@MainActor
final class TestHighScoreStore: HighScoreStoring {
    private(set) var savedValue: Int

    init(initial: Int) {
        savedValue = initial
    }

    func load() -> Int {
        savedValue
    }

    func save(_ value: Int) {
        savedValue = value
    }
}

@MainActor
final class TestSettingsStore: SettingsStoring {
    private(set) var savedSettings: AppSettings

    init(initial: AppSettings) {
        savedSettings = initial
    }

    func load() -> AppSettings {
        savedSettings
    }

    func save(_ settings: AppSettings) {
        savedSettings = settings
    }
}
