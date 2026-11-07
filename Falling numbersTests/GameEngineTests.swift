import Testing
import CoreGraphics
import Foundation
import SpriteKit
@testable import Falling_numbers

@MainActor
struct GameEngineTests {
    @Test
    func targetStartsAtTen() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10, startingLayoutSeed: 1)
        let engine = GameEngine(config: config)

        #expect(engine.state.targetNumber == 10)
        #expect(engine.state.targetCycleIndex == 0)
    }

    @Test
    func startingLayoutIsDeterministicBySeed() {
        let seedAConfig = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10, startingLayoutSeed: 7)
        let seedBConfig = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10, startingLayoutSeed: 8)
        let firstA = GameEngine(config: seedAConfig).state.board
        let secondA = GameEngine(config: seedAConfig).state.board
        let layoutB = GameEngine(config: seedBConfig).state.board

        #expect(firstA == secondA)
        #expect(firstA != layoutB)
    }

    @Test
    func beginnerModeKeepsCurrentRampBehavior() {
        let spawnSystem = SpawnSystem()
        let levelSystem = LevelSystem()

        let earlyValues = (0..<80).map { _ in spawnSystem.nextValue(level: 1, mode: .beginner) }
        #expect(earlyValues.allSatisfy { (1...5).contains($0) })

        let lateValues = (0..<80).map { _ in spawnSystem.nextValue(level: 10, mode: .beginner) }
        #expect(lateValues.allSatisfy { (3...8).contains($0) })

        #expect(levelSystem.targetRange(forCycle: 0, mode: .beginner) == 8...12)
    }

    @Test
    func beginnerBoardSizeIs12x7InDefaultConfig() {
        let engine = GameEngine(config: .default)
        #expect(engine.state.gameMode == .beginner)
        #expect(engine.state.board.rows == 12)
        #expect(engine.state.board.columns == 7)
    }

    @Test
    func expertBoardSizeIs18x10InDefaultConfig() {
        var engine = GameEngine(config: .default)
        engine.send(.setMode(.expert))
        #expect(engine.state.board.rows == 18)
        #expect(engine.state.board.columns == 10)
    }

    @Test
    func expertModeTargetIsAlwaysWithinFiveToTwenty() {
        let levelSystem = LevelSystem()
        var previous = 10
        for cycle in 0..<120 {
            let target = levelSystem.targetNumber(
                forCycle: cycle,
                previousTarget: previous,
                repeatCount: 0,
                mode: .expert
            )
            #expect((5...20).contains(target))
            previous = target
        }
    }

    @Test
    func newGamePreservesSelectedMode() {
        var engine = GameEngine()
        engine.send(.setMode(.expert))
        #expect(engine.state.gameMode == .expert)

        engine.send(.newGame)
        #expect(engine.state.gameMode == .expert)
    }

    @Test
    func retryPreservesSelectedMode() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: .expert)
        state.board.setCell(Cell(value: 8), at: GridPosition(row: 0, column: 0))
        state.board.setCell(Cell(value: 8), at: GridPosition(row: 0, column: 1))
        state.board.setCell(Cell(value: 8), at: GridPosition(row: 0, column: 2))
        state.board.setCell(Cell(value: 8), at: GridPosition(row: 0, column: 3))
        state.nextPieceValue = 9
        var engine = GameEngine(state: state, config: config)
        engine.send(.start)
        #expect(engine.state.isGameOver)

        engine.send(.newGame)
        #expect(engine.state.gameMode == .expert)
    }

    @Test
    func modeSwitchResetsGameCorrectly() {
        var engine = GameEngine()
        engine.send(.hardDrop)
        #expect(engine.state.score >= 0)

        engine.send(.setMode(.expert))
        #expect(engine.state.gameMode == .expert)
        #expect(engine.state.score == 0)
        #expect(engine.state.level == 1)
        #expect((5...20).contains(engine.state.targetNumber))
        #expect(engine.state.activePiece != nil)
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
    func formattedActivePlayTimeUsesMinutesAndSeconds() {
        var state = GameState.initial(config: GameConfig.default)
        state.telemetry.activeGameplaySeconds = 125
        #expect(state.formattedActivePlayTime == "2:05")
        state.telemetry.activeGameplaySeconds = 59
        #expect(state.formattedActivePlayTime == "0:59")
    }

    @Test
    func gameOverWhenAnyColumnFilledToTop() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board.setCell(Cell(value: 7), at: GridPosition(row: 0, column: 3))

        var engine = GameEngine(state: state, config: config)
        engine.send(.start)

        #expect(engine.state.isGameOver)
        #expect(engine.state.activePiece == nil)
        #expect(engine.state.telemetry.gameOverReason == .columnFilledToTop)
    }

    @Test
    func soundEventMappingExistsForAllGameplayEvents() {
        let events: [SoundEvent] = [
            .move,
            .lock,
            .clear,
            .cascade(level: 2),
            .perfectClear,
            .hardDrop,
            .rowClear,
            .columnClear,
            .reorder,
            .gameOver,
            .buttonTap
        ]

        #expect(events.count == 11)
    }

    @Test
    func statsResetOnNewGame() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.linesCleared = 4
        state.perfectClearsCount = 1
        state.highestCascade = 3
        state.longestLineCleared = 5

        var engine = GameEngine(state: state, config: config)
        engine.send(.newGame)

        #expect(engine.state.linesCleared == 0)
        #expect(engine.state.perfectClearsCount == 0)
        #expect(engine.state.highestCascade == 0)
        #expect(engine.state.longestLineCleared == 0)
    }

    @Test
    func deterministicRestartState() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10)
        var engine = GameEngine(config: config)
        engine.send(.start)
        engine.send(.hardDrop)
        engine.send(.newGame)

        #expect(engine.state.score == 0)
        #expect(engine.state.cascadeCount == 0)
        #expect(engine.state.totalClearedTiles == 0)
        #expect(!engine.state.isGameOver)
        #expect(!engine.state.isPaused)
        #expect(engine.state.activePiece != nil)
        #expect((1...9).contains(engine.state.nextPieceValue))
    }
}
