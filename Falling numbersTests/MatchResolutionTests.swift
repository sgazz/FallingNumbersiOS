import Testing
import CoreGraphics
import Foundation
import SpriteKit
@testable import Falling_numbers

@MainActor
struct MatchResolutionTests {
    @Test
    func initialLayoutDoesNotAutoClear() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10, startingLayoutSeed: 1)
        let engine = GameEngine(config: config)
        let lines = CombinationDetector().findMatchingGroups(on: engine.state.board, target: engine.state.targetNumber)

        #expect(lines.isEmpty)
    }

    @Test
    func chainReactionWorksAfterGravity() {
        let config = GameConfig(columns: 3, rows: 4, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.totalClearedTiles = 0

        state.board.setCell(Cell(value: 3), at: GridPosition(row: 3, column: 0))
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 3, column: 1))
        state.board.setCell(Cell(value: 7), at: GridPosition(row: 2, column: 1))
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.totalClearedTiles >= 4)
        #expect(engine.state.cascadeCount >= 2)
        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 0)) == nil)
        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 1)) == nil)
    }

    @Test
    func beginnerCascadeStopsAtCapSixAndLeavesRemainingLine() {
        let config = GameConfig(columns: 3, rows: 12, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: .beginner)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.targetNumber = 10
        state.totalClearedTiles = 0

        // Build 6 potential clears in one gravity chain:
        // first clear must include locked tile; five more are prefilled above.
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 11, column: 0))
        for row in 6...10 {
            state.board.setCell(Cell(value: 6), at: GridPosition(row: row, column: 0))
            state.board.setCell(Cell(value: 4), at: GridPosition(row: row, column: 1))
        }
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        // Beginner cap is 6 steps, so one valid pair should remain.
        #expect(engine.state.cascadeCount <= 6)
        let remainingMatches = CombinationDetector().findMatchingGroups(on: engine.state.board, target: 10)
        #expect(!remainingMatches.isEmpty)
        #expect(engine.state.totalClearedTiles <= 12)
    }

    @Test
    func expertCascadeCapIsStricterThanBeginnerOnSameBoard() {
        let config = GameConfig(columns: 3, rows: 12, tickInterval: 0.5, baseTargetNumber: 10)
        func seededState(mode: GameMode) -> GameState {
            var state = GameState.initial(config: config, mode: mode)
            state.board = Board(rows: config.rows, columns: config.columns)
            state.targetNumber = 10
            state.totalClearedTiles = 0
            state.board.setCell(Cell(value: 6), at: GridPosition(row: 11, column: 0))
            for row in 3...10 {
                state.board.setCell(Cell(value: 6), at: GridPosition(row: row, column: 0))
                state.board.setCell(Cell(value: 4), at: GridPosition(row: row, column: 1))
            }
            state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 1))
            return state
        }

        var beginnerEngine = GameEngine(state: seededState(mode: .beginner), config: config)
        beginnerEngine.send(.hardDrop)

        var expertEngine = GameEngine(state: seededState(mode: .expert), config: config)
        expertEngine.send(.hardDrop)

        #expect(beginnerEngine.state.cascadeCount <= 6)
        #expect(expertEngine.state.cascadeCount <= 5)
        #expect(expertEngine.state.totalClearedTiles <= beginnerEngine.state.totalClearedTiles)
    }

    @Test
    func expertCascadeNoLongerChainsAfterGravityButGravityStillApplies() {
        let config = GameConfig(columns: 3, rows: 12, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: .expert)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.targetNumber = 10
        state.totalClearedTiles = 0

        state.board.setCell(Cell(value: 6), at: GridPosition(row: 11, column: 0))
        for row in 8...10 {
            state.board.setCell(Cell(value: 6), at: GridPosition(row: row, column: 0))
            state.board.setCell(Cell(value: 4), at: GridPosition(row: row, column: 1))
        }
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.totalClearedTiles <= 4)
        #expect(engine.state.cascadeCount <= 1)
        let remainingMatches = CombinationDetector().findMatchingGroups(on: engine.state.board, target: 10)
        #expect(!remainingMatches.isEmpty)
    }

    @Test
    func cascadeResetsAfterSeveralLocksWithoutClear() {
        let config = GameConfig(columns: 4, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.cascadeCount = 3
        state.specialSpawnChance = 0.12
        state.board = Board(rows: config.rows, columns: config.columns)
        state.activePiece = FallingPiece(value: 1, position: GridPosition(row: 0, column: 0))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)
        engine.send(.hardDrop)
        engine.send(.hardDrop)

        #expect(engine.state.cascadeCount == 0)
        #expect(engine.state.specialSpawnChance == 0.02)
    }

    @Test
    func perfectClearTriggersAndAwardsBonus() {
        let config = GameConfig(columns: 4, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 4, column: 1))
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.didPerfectClear)
        #expect(engine.state.lastPerfectClearBonus == 350)
        #expect(engine.state.board.allOccupiedPositions().isEmpty)
        #expect(engine.state.score == 380)
    }

    @Test
    func rowClearTileRemovesOnlyLandingRowAndAppliesGravity() {
        let config = GameConfig(columns: 4, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: .expert)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 2), at: GridPosition(row: 4, column: 0))
        state.board.setCell(Cell(value: 3), at: GridPosition(row: 4, column: 2))
        state.board.setCell(Cell(value: 8), at: GridPosition(row: 3, column: 0))
        state.activePiece = FallingPiece(kind: .rowClear, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 0))?.value == 8)
        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 1)) == nil)
        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 2)) == nil)
    }

    @Test
    func columnClearTileRemovesOnlyLandingColumnAndAppliesGravity() {
        let config = GameConfig(columns: 4, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: .expert)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 7), at: GridPosition(row: 4, column: 1))
        state.board.setCell(Cell(value: 5), at: GridPosition(row: 2, column: 1))
        state.board.setCell(Cell(value: 9), at: GridPosition(row: 1, column: 0))
        state.activePiece = FallingPiece(kind: .columnClear, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 1)) == nil)
        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 1)) == nil)
        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 0))?.value == 9)
    }

    @Test
    func reorderTileKeepsValuesAndDeterministicallyReordersOccupiedCells() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: .expert)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 9), at: GridPosition(row: 5, column: 0))
        state.board.setCell(Cell(value: 4), at: GridPosition(row: 4, column: 2))
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 3, column: 1))
        state.board.setCell(Cell(value: 2), at: GridPosition(row: 5, column: 3))
        state.activePiece = FallingPiece(kind: .reorder, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        let beforeValues = engine.state.board.allOccupiedPositions().compactMap { engine.state.board.cell(at: $0)?.value }.sorted()
        engine.send(.hardDrop)
        let afterPositions = engine.state.board.allOccupiedPositions().sorted {
            if $0.row != $1.row { return $0.row > $1.row }
            return $0.column < $1.column
        }
        let afterValues = afterPositions.compactMap { engine.state.board.cell(at: $0)?.value }

        #expect(afterValues.sorted() == beforeValues)
        #expect(afterValues == beforeValues)
    }

    @Test
    func powerUpActivationDoesNotRequireTargetLineMatch() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 20)
        var state = GameState.initial(config: config, mode: .expert)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 8), at: GridPosition(row: 3, column: 0))
        state.board.setCell(Cell(value: 1), at: GridPosition(row: 3, column: 1))
        state.activePiece = FallingPiece(kind: .rowClear, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 0)) == nil)
        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 1)) == nil)
    }

    @Test
    func beginnerNormalClearEmitsSumLabelEvent() {
        let config = GameConfig(columns: 5, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: .beginner)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 4, column: 1))
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.sumClearEventToken > 0)
        #expect(engine.state.lastSumClearEvent?.target == 10)
        #expect(engine.state.lastSumClearEvent?.values == [6, 4])
    }

    @Test
    func expertNormalClearDoesNotEmitSumLabelEvent() {
        let config = GameConfig(columns: 5, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: .expert)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 4, column: 1))
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.sumClearEventToken == 0)
        #expect(engine.state.lastSumClearEvent == nil)
    }

    @Test
    func powerUpClearDoesNotEmitSumLabelEvent() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: .beginner)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 2), at: GridPosition(row: 3, column: 0))
        state.board.setCell(Cell(value: 3), at: GridPosition(row: 3, column: 1))
        state.activePiece = FallingPiece(kind: .rowClear, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.sumClearEventToken == 0)
        #expect(engine.state.lastSumClearEvent == nil)
    }

    @Test
    func horizontalSumLabelValuesAreLeftToRight() {
        let config = GameConfig(columns: 5, rows: 4, tickInterval: 0.65, baseTargetNumber: 12)
        var state = GameState.initial(config: config, mode: .beginner)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.targetNumber = 12
        state.board.setCell(Cell(value: 3), at: GridPosition(row: 3, column: 0))
        state.board.setCell(Cell(value: 4), at: GridPosition(row: 3, column: 1))
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.lastSumClearEvent?.values == [3, 4, 5])
    }

    @Test
    func verticalSumLabelValuesAreTopToBottom() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: .beginner)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.targetNumber = 10
        state.board.setCell(Cell(value: 3), at: GridPosition(row: 3, column: 2))
        state.board.setCell(Cell(value: 2), at: GridPosition(row: 4, column: 2))
        state.board.setCell(Cell(value: 9), at: GridPosition(row: 5, column: 2)) // blocker forces lock at row 2
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.lastSumClearEvent?.values == [5, 3, 2])
        #expect(engine.state.lastSumClearEvent?.target == 10)
    }

    @Test
    func perfectClearDoesNotTriggerWhenBoardStillHasTiles() {
        let config = GameConfig(columns: 4, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 4, column: 1))
        state.board.setCell(Cell(value: 9), at: GridPosition(row: 4, column: 3))
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.didPerfectClear == false)
        #expect(engine.state.lastPerfectClearBonus == 0)
        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 3))?.value == 9)
    }

    @Test
    func deterministicClearOrderingUsesLongerLineFirst() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.totalClearedTiles = 0

        // Anchor at row2,col1 participates in two possible lines:
        // longer horizontal: row2 => 2 + 5 + 3
        // shorter vertical: col1 => 5 + 5
        state.board.setCell(Cell(value: 5), at: GridPosition(row: 3, column: 1)) // stopper + vertical partner
        state.board.setCell(Cell(value: 2), at: GridPosition(row: 2, column: 0))
        state.board.setCell(Cell(value: 3), at: GridPosition(row: 2, column: 2))
        state.activePiece = FallingPiece(value: 5, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        // Longer horizontal must be selected first, leaving vertical partner intact.
        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 1))?.value == 5)
        #expect(engine.state.board.cell(at: GridPosition(row: 2, column: 0)) == nil)
        #expect(engine.state.board.cell(at: GridPosition(row: 2, column: 1)) == nil)
        #expect(engine.state.board.cell(at: GridPosition(row: 2, column: 2)) == nil)
    }

    @Test
    func prefersLineContainingLockedTileOverLongerUnrelatedLine() {
        let config = GameConfig(columns: 5, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.totalClearedTiles = 0

        // Unrelated longer line (size 3), does not include locked tile:
        // row 3 => 2 + 2 + 6
        state.board.setCell(Cell(value: 2), at: GridPosition(row: 3, column: 1))
        state.board.setCell(Cell(value: 2), at: GridPosition(row: 3, column: 2))
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 3, column: 3))

        // Locked-tile line (size 2): vertical => dropped 4 at (2,3) + existing 6 at (3,3)
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 3))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        // If locked-tile match is preferred first, unrelated line is broken and cells remain.
        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 1))?.value == 2)
        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 2))?.value == 2)
    }

    @Test
    func oldValidLineNotIncludingLockedTileDoesNotClear() {
        let config = GameConfig(columns: 5, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)

        // Existing valid line away from the landing spot: 4 + 6 on bottom-left.
        state.board.setCell(Cell(value: 4), at: GridPosition(row: 4, column: 0))
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 4, column: 1))

        // Locked tile lands on right side and does not form target line.
        state.activePiece = FallingPiece(value: 1, position: GridPosition(row: 0, column: 4))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 0))?.value == 4)
        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 1))?.value == 6)
    }

    @Test
    func anchorHorizontalLineClears() {
        let config = GameConfig(columns: 5, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 4, column: 1))
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 1)) == nil)
        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 2)) == nil)
    }

    @Test
    func anchorVerticalLineClears() {
        let config = GameConfig(columns: 5, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board = Board(rows: config.rows, columns: config.columns)
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 4, column: 2))
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 2)) == nil)
        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 2)) == nil)
    }

    @Test
    func lockedTileTieUsesDeterministicLexicographicTiebreak() {
        let config = GameConfig(columns: 5, rows: 5, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.totalClearedTiles = 0

        // Two equal-size lines that both include the locked tile at (4,2):
        // A: (4,1)=6 + locked(4,2)=4  -> key starts with 4:1
        // B: locked(4,2)=4 + (4,3)=6  -> key starts with 4:2
        // Deterministic tie should choose A first.
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 4, column: 1))
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 4, column: 3))
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 1)) == nil)
        #expect(engine.state.board.cell(at: GridPosition(row: 4, column: 3))?.value == 6)
    }

    @Test
    func comboProgressionIncreasesAcrossChain() {
        let config = GameConfig(columns: 3, rows: 4, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.totalClearedTiles = 0
        state.board.setCell(Cell(value: 3), at: GridPosition(row: 3, column: 0))
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 3, column: 1))
        state.board.setCell(Cell(value: 7), at: GridPosition(row: 2, column: 1))
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 2))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        #expect(engine.state.cascadeCount >= 2)
        #expect(engine.state.totalClearedTiles >= 4)
    }
}
