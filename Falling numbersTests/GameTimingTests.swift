import Testing
import CoreGraphics
import Foundation
import SpriteKit
@testable import Falling_numbers

@MainActor
struct GameTimingTests {
    @Test
    func newGameHasSafeInitialLayout() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10, startingLayoutSeed: 1)
        let engine = GameEngine(config: config)
        let occupied = engine.state.board.allOccupiedPositions()

        #expect((4...8).contains(occupied.count))
        #expect(occupied.allSatisfy { $0.row >= config.rows - 3 })
    }

    @Test
    func targetDoesNotChangeMidFall() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 1))
        let targetBefore = state.targetNumber

        var engine = GameEngine(state: state, config: config)
        engine.send(.tick)

        #expect(engine.state.targetNumber == targetBefore)
        #expect(engine.state.didTargetChange == false)
    }

    @Test
    func targetCanChangeAfterTimerExpires() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.activePiece = FallingPiece(value: 6, position: GridPosition(row: 0, column: 1))
        state.targetTimerRemaining = 0.01

        var engine = GameEngine(state: state, config: config)
        let targetBefore = engine.state.targetNumber
        engine.send(.tick)
        engine.send(.tick)

        #expect(engine.state.targetCycleIndex == 1)
        #expect(engine.state.targetNumber != targetBefore)
        #expect(engine.state.didTargetChange)
    }

    @Test
    func targetChangedEventEmitsOnlyOnActualChange() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var midFallState = GameState.initial(config: config)
        midFallState.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 1))
        var midFallEngine = GameEngine(state: midFallState, config: config)

        // Mid-fall move: no target change event.
        midFallEngine.send(.tick)
        #expect(midFallEngine.state.didTargetChange == false)

        // Timer-expiry change: event should emit once target actually changes.
        var levelUpState = GameState.initial(config: config)
        levelUpState.board = Board(rows: config.rows, columns: config.columns)
        levelUpState.activePiece = FallingPiece(value: 6, position: GridPosition(row: 0, column: 2))
        levelUpState.targetTimerRemaining = 0.01
        var levelUpEngine = GameEngine(state: levelUpState, config: config)
        let before = levelUpEngine.state.targetNumber
        levelUpEngine.send(.tick)
        levelUpEngine.send(.tick)

        #expect(levelUpEngine.state.targetNumber != before)
        #expect(levelUpEngine.state.didTargetChange)
    }

    @Test
    func autoTickStartsLockDelayInsteadOfImmediateLock() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.1, lockDelayDuration: 0.22, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 3, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.tick)

        #expect(engine.state.activePiece != nil)
        #expect(engine.state.isLockDelayActive)
        #expect(engine.state.lockDelayRemaining == config.lockDelayDuration)
    }

    @Test
    func lockOccursAfterDelayExpires() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.1, lockDelayDuration: 0.7, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 3, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.tick) // start delay
        var attempts = 0
        while engine.state.board.cell(at: GridPosition(row: 3, column: 1)) == nil, attempts < 20 {
            engine.send(.tick)
            attempts += 1
        }

        #expect(attempts < 20)
        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 1))?.value == 5)
        #expect(engine.state.isLockDelayActive == false)
    }

    @Test
    func leftRightMoveDuringDelayResetsDelay() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.1, lockDelayDuration: 3.0, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 3, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.tick) // start delay
        engine.send(.tick) // consume some delay
        #expect(engine.state.lockDelayRemaining < config.lockDelayDuration)
        engine.send(.moveRight) // still grounded on bottom row, should reset to full

        #expect(engine.state.isLockDelayActive)
        #expect(engine.state.activePiece?.position == GridPosition(row: 3, column: 2))
        #expect(abs(engine.state.lockDelayRemaining - config.lockDelayDuration) < 0.000_1)
    }

    @Test
    func movingAwayFromGroundCancelsDelay() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.1, lockDelayDuration: 0.7, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 9), at: GridPosition(row: 2, column: 1))
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 1, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.tick) // blocked by cell at row 2, starts delay
        #expect(engine.state.isLockDelayActive)
        engine.send(.moveRight) // now below is empty

        #expect(engine.state.isLockDelayActive == false)
        #expect(engine.state.lockDelayRemaining == 0)
    }

    @Test
    func hardDropBypassesDelay() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.1, lockDelayDuration: 0.22, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 1))?.value == 5)
        #expect(engine.state.isLockDelayActive == false)
    }

    @Test
    func softDropIntoGroundedStartsDelay() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.1, lockDelayDuration: 0.22, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 9), at: GridPosition(row: 2, column: 1))
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.softDrop) // move to row 1, now grounded

        #expect(engine.state.activePiece?.position == GridPosition(row: 1, column: 1))
        #expect(engine.state.isLockDelayActive)
        #expect(engine.state.board.cell(at: GridPosition(row: 1, column: 1)) == nil)
    }

    @Test
    func targetDoesNotChangeBeforeThirtySeconds() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.activePiece = FallingPiece(value: 3, position: GridPosition(row: 0, column: 1))
        var engine = GameEngine(state: state, config: config)
        let ticksBeforeChange = Int((config.targetChangeInterval / engine.state.currentTickInterval).rounded(.down)) - 1
        for _ in 0..<ticksBeforeChange {
            engine.send(.tick)
        }
        #expect(engine.state.targetCycleIndex == 0)
        #expect(engine.state.targetNumber == 10)
    }

    @Test
    func targetChangesAfterThirtySecondsAndAgainAfterSixty() {
        let config = GameConfig(columns: 4, rows: 120, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        let ticksPerCycle = Int((config.targetChangeInterval / config.tickInterval).rounded(.up))
        for _ in 0..<ticksPerCycle { engine.send(.tick) } // expire
        engine.send(.tick) // apply pending change
        let first = engine.state.targetNumber
        #expect(engine.state.targetCycleIndex >= 1)

        for _ in 0..<ticksPerCycle { engine.send(.tick) } // expire again
        engine.send(.tick) // apply pending change
        #expect(engine.state.targetCycleIndex >= 2)
        #expect(engine.state.targetNumber != first || engine.state.targetRepeatCount > 0)
    }

    @Test
    func timerResetsAfterTargetChange() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.activePiece = FallingPiece(value: 1, position: GridPosition(row: 0, column: 1))
        state.targetTimerRemaining = 0.01

        var engine = GameEngine(state: state, config: config)
        engine.send(.tick)
        engine.send(.tick)

        #expect(engine.state.targetCycleIndex == 1)
        #expect(engine.state.targetTimerRemaining > 0)
        #expect(engine.state.targetTimerRemaining <= config.targetChangeInterval)
    }

    @Test
    func timerPausesWhilePaused() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.tick)
        let beforePause = engine.state.targetTimerRemaining
        engine.send(.togglePause)
        engine.send(.tick)
        #expect(engine.state.targetTimerRemaining == beforePause)
    }

    @Test
    func timerDoesNotRunDuringGameOver() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.isGameOver = true
        state.targetTimerRemaining = 5
        var engine = GameEngine(state: state, config: config)
        engine.send(.tick)
        #expect(engine.state.targetTimerRemaining == 5)
    }

    @Test
    func didLevelChangeAndDidTargetChangeAreIndependent() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var levelState = GameState.initial(config: config)
        levelState.score = 399
        levelState.board = Board(rows: config.rows, columns: config.columns)
        levelState.board.setCell(Cell(value: 4), at: GridPosition(row: 3, column: 1))
        levelState.activePiece = FallingPiece(value: 6, position: GridPosition(row: 0, column: 1))
        var levelEngine = GameEngine(state: levelState, config: config)
        levelEngine.send(.hardDrop)
        #expect(levelEngine.state.didLevelChange)
        #expect(levelEngine.state.didTargetChange == false)

        var targetState = GameState.initial(config: config)
        targetState.board = Board(rows: config.rows, columns: config.columns)
        targetState.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 1))
        targetState.targetTimerRemaining = 0.01
        var targetEngine = GameEngine(state: targetState, config: config)
        targetEngine.send(.tick)
        targetEngine.send(.tick)
        #expect(targetEngine.state.didTargetChange)
    }

    @Test
    func targetDoesNotChangeDuringResolveOnlyAfterSafeBoundary() {
        let config = GameConfig(columns: 3, rows: 4, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.targetTimerRemaining = 0.01
        state.board.setCell(Cell(value: 4), at: GridPosition(row: 3, column: 0))
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 3, column: 1))
        state.activePiece = FallingPiece(value: 1, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        // Hard drop path triggers resolve first, target change only on safe boundary after spawn.
        #expect(engine.state.targetCycleIndex == 0)
        let before = engine.state.targetNumber
        engine.send(.tick)
        engine.send(.tick)
        #expect(engine.state.targetCycleIndex == 1)
        #expect(engine.state.targetNumber != before || engine.state.targetRepeatCount > 0)
    }

    @Test
    func formattedTargetChangeCountdownUsesMinutesAndSeconds() {
        var state = GameState.initial(config: GameConfig.default)
        state.targetTimerRemaining = 30
        #expect(state.formattedTargetChangeCountdown == "0:30")
        state.targetTimerRemaining = 0.4
        #expect(state.formattedTargetChangeCountdown == "0:01")
        state.targetTimerRemaining = 91.2
        #expect(state.formattedTargetChangeCountdown == "1:32")
    }

    @Test
    func level15PlusAppliesHigherTargetTimerPressure() {
        let levelSystem = LevelSystem()
        #expect(levelSystem.targetTimerDecrementMultiplier(level: 14, mode: .beginner) == 1.0)
        #expect(levelSystem.targetTimerDecrementMultiplier(level: 15, mode: .beginner) > 1.0)
    }
}
