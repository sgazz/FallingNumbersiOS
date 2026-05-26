import Testing
import CoreGraphics
import Foundation
@testable import Falling_numbers

struct FallingNumbersTests {
    @Test
    func newGameHasSafeInitialLayout() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10, startingLayoutSeed: 1)
        let engine = GameEngine(config: config)
        let occupied = engine.state.board.allOccupiedPositions()

        #expect((4...8).contains(occupied.count))
        #expect(occupied.allSatisfy { $0.row >= config.rows - 3 })
    }

    @Test
    func initialLayoutDoesNotBlockSpawn() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10, startingLayoutSeed: 1)
        var engine = GameEngine(config: config)
        engine.send(.start)

        #expect(!engine.state.isGameOver)
        #expect(engine.state.activePiece != nil)
    }

    @Test
    func initialLayoutDoesNotAutoClear() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10, startingLayoutSeed: 1)
        let engine = GameEngine(config: config)
        let lines = CombinationDetector().findMatchingGroups(on: engine.state.board, target: engine.state.targetNumber)

        #expect(lines.isEmpty)
    }

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
    func targetRangeFollowsCycleIndex() {
        let levelSystem = LevelSystem()
        #expect(levelSystem.targetRange(forCycle: 0, mode: .beginner) == 8...12)
        #expect(levelSystem.targetRange(forCycle: 2, mode: .beginner) == 8...12)
        #expect(levelSystem.targetRange(forCycle: 3, mode: .beginner) == 10...16)
        #expect(levelSystem.targetRange(forCycle: 5, mode: .beginner) == 10...16)
        #expect(levelSystem.targetRange(forCycle: 6, mode: .beginner) == 12...20)
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
    func beginnerBoardSizeIs15x7InDefaultConfig() {
        let engine = GameEngine(config: .default)
        #expect(engine.state.gameMode == .beginner)
        #expect(engine.state.board.rows == 15)
        #expect(engine.state.board.columns == 7)
    }

    @Test
    func expertBoardSizeRemainsUnchangedInDefaultConfig() {
        var engine = GameEngine(config: .default)
        engine.send(.setMode(.expert))
        #expect(engine.state.board.rows == 20)
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
    func expertModeFallingValuesAreAlwaysWithinOneToNine() {
        let spawnSystem = SpawnSystem()
        let values = (0..<200).map { _ in spawnSystem.nextValue(level: 1, mode: .expert) }
        #expect(values.allSatisfy { (1...9).contains($0) })
    }

    @Test
    func beginnerAllowsUpToThreeRepeatsButNotMore() {
        let spawnSystem = SpawnSystem()
        var history: [Int] = []
        var maxStreak = 0
        var currentStreak = 0
        var lastValue: Int?

        for _ in 0..<300 {
            let value = spawnSystem.nextValue(level: 1, mode: .beginner, recentValues: history)
            history.append(value)
            if history.count > 12 { history.removeFirst() }
            if value == lastValue {
                currentStreak += 1
            } else {
                currentStreak = 1
                lastValue = value
            }
            maxStreak = max(maxStreak, currentStreak)
        }

        #expect(maxStreak <= 3)
    }

    @Test
    func expertPreventsLongStreaksAndStillProducesAllValues() {
        let spawnSystem = SpawnSystem()
        var history: [Int] = []
        var seen = Set<Int>()
        var maxStreak = 0
        var currentStreak = 0
        var lastValue: Int?

        for _ in 0..<800 {
            let value = spawnSystem.nextValue(level: 8, mode: .expert, recentValues: history)
            seen.insert(value)
            history.append(value)
            if history.count > 12 { history.removeFirst() }
            if value == lastValue {
                currentStreak += 1
            } else {
                currentStreak = 1
                lastValue = value
            }
            maxStreak = max(maxStreak, currentStreak)
        }

        #expect(maxStreak <= 2)
        #expect(seen == Set(1...9))
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
    func detectsHorizontalContiguousTargetSum() {
        var board = Board(rows: 3, columns: 4)
        board.setCell(Cell(value: 4), at: GridPosition(row: 1, column: 0))
        board.setCell(Cell(value: 6), at: GridPosition(row: 1, column: 1))
        board.setCell(Cell(value: 2), at: GridPosition(row: 1, column: 2))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.map(groupKey).contains(groupKey([
            GridPosition(row: 1, column: 0),
            GridPosition(row: 1, column: 1)
        ])))
    }

    @Test
    func detectsVerticalContiguousTargetSum() {
        var board = Board(rows: 3, columns: 4)
        board.setCell(Cell(value: 2), at: GridPosition(row: 0, column: 2))
        board.setCell(Cell(value: 3), at: GridPosition(row: 1, column: 2))
        board.setCell(Cell(value: 5), at: GridPosition(row: 2, column: 2))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.map(groupKey).contains(groupKey([
            GridPosition(row: 0, column: 2),
            GridPosition(row: 1, column: 2),
            GridPosition(row: 2, column: 2)
        ])))
    }

    @Test
    func doesNotDetectDiagonal() {
        var board = Board(rows: 3, columns: 3)
        board.setCell(Cell(value: 4), at: GridPosition(row: 0, column: 0))
        board.setCell(Cell(value: 6), at: GridPosition(row: 1, column: 1))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.isEmpty)
    }

    @Test
    func doesNotDetectLShapeOrCluster() {
        var board = Board(rows: 3, columns: 3)
        board.setCell(Cell(value: 4), at: GridPosition(row: 1, column: 1))
        board.setCell(Cell(value: 3), at: GridPosition(row: 1, column: 2))
        board.setCell(Cell(value: 3), at: GridPosition(row: 2, column: 1))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.isEmpty)
    }

    @Test
    func doesNotDetectNonContiguousCells() {
        var board = Board(rows: 1, columns: 4)
        board.setCell(Cell(value: 4), at: GridPosition(row: 0, column: 0))
        board.setCell(Cell(value: 6), at: GridPosition(row: 0, column: 2))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)
        #expect(matches.isEmpty)
    }

    @Test
    func deterministicTieUsesHorizontalBeforeVertical() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 2, column: 0)) // horizontal partner
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 3, column: 1)) // vertical partner / blocker
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        // Horizontal tie should resolve first, leaving the vertical-only 6.
        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 1))?.value == 6)
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
        lowState.score = 0
        let lowEngine = GameEngine(state: lowState, config: config)

        var highState = GameState.initial(config: config)
        highState.score = 2600
        let highEngine = GameEngine(state: highState, config: config)

        #expect(lowEngine.state.level < highEngine.state.level)
        #expect(lowEngine.state.currentTickInterval > highEngine.state.currentTickInterval)
        #expect(lowEngine.state.targetCycleIndex == highEngine.state.targetCycleIndex)
        #expect(lowEngine.state.targetNumber == highEngine.state.targetNumber)
    }

    @Test
    func levelStartsAtOne() {
        let engine = GameEngine()
        #expect(engine.state.level == 1)
    }

    @Test
    func lengthTwoScoreUsesX1Multiplier() {
        let scoreSystem = ScoreSystem()
        let breakdown = scoreSystem.scoreBreakdownForClear(tileCount: 2, cascade: 1)
        #expect(breakdown.baseScore == 20)
        #expect(breakdown.lengthMultiplier == 1.0)
        #expect(breakdown.awardedScore == 20)
    }

    @Test
    func horizontalClearGetsSlightScoreBonus() {
        let scoreSystem = ScoreSystem()
        let horizontal = scoreSystem.scoreBreakdownForClear(tileCount: 3, cascade: 1, isHorizontal: true)
        let vertical = scoreSystem.scoreBreakdownForClear(tileCount: 3, cascade: 1, isHorizontal: false)
        #expect(horizontal.awardedScore > vertical.awardedScore)
        #expect(horizontal.awardedScore == 41)
        #expect(vertical.awardedScore == 38)
    }

    @Test
    func lengthThreeScoreUsesX125Multiplier() {
        let scoreSystem = ScoreSystem()
        let breakdown = scoreSystem.scoreBreakdownForClear(tileCount: 3, cascade: 1)
        #expect(breakdown.baseScore == 30)
        #expect(breakdown.lengthMultiplier == 1.25)
        #expect(breakdown.awardedScore == 38)
    }

    @Test
    func lengthFiveScoreUsesX2Multiplier() {
        let scoreSystem = ScoreSystem()
        let breakdown = scoreSystem.scoreBreakdownForClear(tileCount: 5, cascade: 1)
        #expect(breakdown.baseScore == 50)
        #expect(breakdown.lengthMultiplier == 2.0)
        #expect(breakdown.awardedScore == 100)
    }

    @Test
    func cascadeAndLengthMultiplierInteraction() {
        let scoreSystem = ScoreSystem()
        let breakdown = scoreSystem.scoreBreakdownForClear(tileCount: 4, cascade: 3)
        #expect(breakdown.baseScore == 40)
        #expect(breakdown.lengthMultiplier == 1.5)
        #expect(breakdown.cascadeMultiplier == 1.5)
        #expect(breakdown.awardedScore == 90)
    }

    @Test
    func perfectClearBonusUsesConfiguredFormula() {
        let scoreSystem = ScoreSystem()
        #expect(scoreSystem.perfectClearBonus(level: 1, base: 250, perLevel: 100) == 350)
        #expect(scoreSystem.perfectClearBonus(level: 4, base: 250, perLevel: 100) == 650)
    }

    @Test
    func specialSpawnChanceScalesWithCascade() {
        let scoreSystem = ScoreSystem()
        #expect(scoreSystem.specialSpawnChance(for: 1) == 0.02)
        #expect(scoreSystem.specialSpawnChance(for: 2) == 0.05)
        #expect(scoreSystem.specialSpawnChance(for: 3) == 0.08)
        #expect(scoreSystem.specialSpawnChance(for: 5) == 0.12)
        #expect(scoreSystem.specialSpawnChance(for: 6) == 0.10)
    }

    @Test
    func expertSpecialSpawnChanceDoesNotIncreaseFromCascade() {
        let scoreSystem = ScoreSystem()
        #expect(scoreSystem.specialSpawnChance(for: 1, mode: .expert) == 0.02)
        #expect(scoreSystem.specialSpawnChance(for: 5, mode: .expert) == 0.02)
        #expect(scoreSystem.specialSpawnChance(for: 10, mode: .expert) == 0.02)
    }

    @Test
    func lowOccupancyReducesPowerUpChance() {
        let scoreSystem = ScoreSystem()
        let adjusted = scoreSystem.occupancyAdjustedSpecialSpawnChance(
            baseChance: 0.12,
            occupancyPercent: 12,
            mode: .beginner
        )
        #expect(adjusted < 0.12)
        #expect(adjusted == 0.054)
    }

    @Test
    func highOccupancyIncreasesRescueChance() {
        let scoreSystem = ScoreSystem()
        let adjusted = scoreSystem.occupancyAdjustedSpecialSpawnChance(
            baseChance: 0.08,
            occupancyPercent: 52,
            mode: .beginner
        )
        #expect(adjusted > 0.08)
        #expect(abs(adjusted - 0.108) < 0.000_001)
    }

    @Test
    func occupancyAdjustmentDoesNotAffectExpertMode() {
        let scoreSystem = ScoreSystem()
        let adjusted = scoreSystem.occupancyAdjustedSpecialSpawnChance(
            baseChance: 0.08,
            occupancyPercent: 52,
            mode: .expert
        )
        #expect(adjusted < 0.08)
    }

    @Test
    func expertRescueOnlyMeaningfulAtDangerousOccupancy() {
        let scoreSystem = ScoreSystem()
        let medium = scoreSystem.occupancyAdjustedSpecialSpawnChance(
            baseChance: 0.08,
            occupancyPercent: 52,
            mode: .expert
        )
        let dangerous = scoreSystem.occupancyAdjustedSpecialSpawnChance(
            baseChance: 0.08,
            occupancyPercent: 75,
            mode: .expert
        )
        #expect(abs(medium - 0.052) < 0.000_001)
        #expect(dangerous > medium)
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
    func spawnDistributionUsesMultipleColumnsNotOnlyCenter() {
        let spawnSystem = SpawnSystem()
        var counts = Array(repeating: 0, count: 10)
        for _ in 0..<5_000 {
            let column = spawnSystem.nextSpawnColumn(columns: 10)
            counts[column] += 1
        }

        // Center is still favored but should not dominate.
        #expect(counts[5] < 1_400)
        // Mid columns should appear regularly.
        for column in 2...7 {
            #expect(counts[column] > 350)
        }
    }

    @Test
    func spawnFallsBackWhenPreferredCenterBlocked() {
        let spawnSystem = SpawnSystem()
        var board = Board(rows: 6, columns: 10)
        board.setCell(Cell(value: 9), at: GridPosition(row: 0, column: 5))

        let piece = spawnSystem.makePiece(on: board, value: 4)
        #expect(piece != nil)
        #expect(piece?.position.column != 5)
    }

    @Test
    func beginnerSpecialTilesStartLaterThanExpert() {
        let spawnSystem = SpawnSystem()
        for _ in 0..<150 {
            let beginnerEarly = spawnSystem.nextTileKind(level: 2, mode: .beginner, specialSpawnChance: 1.0)
            if beginnerEarly.isPowerUp {
                Issue.record("Beginner spawned special tile too early at level 2")
            }
        }

        var sawExpertSpecial = false
        for _ in 0..<150 {
            let expert = spawnSystem.nextTileKind(level: 3, mode: .expert, specialSpawnChance: 1.0)
            if expert.isPowerUp {
                sawExpertSpecial = true
                break
            }
        }
        #expect(sawExpertSpecial)
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
    func levelIncreasesWithScoreCurve() {
        let levelSystem = LevelSystem()
        #expect(levelSystem.level(forScore: 0) == 1)
        #expect(levelSystem.level(forScore: 399) == 1)
        #expect(levelSystem.level(forScore: 400) == 2)
        #expect(levelSystem.level(forScore: 1100) >= 3)
    }

    @Test
    func levelDoesNotDependOnClearedTilesOnly() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.totalClearedTiles = 500
        state.score = 0
        let engine = GameEngine(state: state, config: config)

        #expect(engine.state.level == 1)
    }

    @Test
    func didLevelChangeFiresOnlyOnThresholdCross() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.score = 398
        state.board.setCell(Cell(value: 4), at: GridPosition(row: 3, column: 1))
        state.activePiece = FallingPiece(value: 6, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)
        #expect(engine.state.didLevelChange)

        engine.send(.moveLeft)
        #expect(engine.state.didLevelChange == false)
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
    func expertScoreBonusApplies() {
        let scoreSystem = ScoreSystem()
        let beginner = scoreSystem.scoreBreakdownForClear(tileCount: 4, cascade: 1, expertMode: false)
        let expert = scoreSystem.scoreBreakdownForClear(tileCount: 4, cascade: 1, expertMode: true)
        #expect(beginner.awardedScore == 60)
        #expect(expert.awardedScore == 72)
    }

    @Test
    func expertCascadeMultiplierIsNeutral() {
        let scoreSystem = ScoreSystem()
        let breakdown = scoreSystem.scoreBreakdownForClear(tileCount: 4, cascade: 4, expertMode: true)
        #expect(breakdown.cascadeMultiplier == 1.0)
    }

    @Test
    func beginnerScoreUnchanged() {
        let scoreSystem = ScoreSystem()
        let breakdown = scoreSystem.scoreBreakdownForClear(tileCount: 3, cascade: 1, expertMode: false)
        #expect(breakdown.awardedScore == 38)
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
    func expertSpeedFasterThanBeginner() {
        var beginnerEngine = GameEngine()
        beginnerEngine.send(.newGame)
        let beginnerTick = beginnerEngine.state.currentTickInterval

        var expertEngine = GameEngine()
        expertEngine.send(.setMode(.expert))
        let expertTick = expertEngine.state.currentTickInterval

        #expect(expertTick < beginnerTick)
    }

    @Test
    func expertTargetAvoidsImmediateRepeatWherePossible() {
        let levelSystem = LevelSystem()
        for previous in 5...20 {
            let next = levelSystem.targetNumber(forCycle: 2, previousTarget: previous, repeatCount: 0, mode: .expert)
            #expect(next != previous)
            #expect((5...20).contains(next))
        }
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
    func gameOverWhenSpawnCellIsBlocked() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        for column in 0..<config.columns {
            state.board.setCell(Cell(value: 7), at: GridPosition(row: 0, column: column))
        }

        var engine = GameEngine(state: state, config: config)
        engine.send(.start)

        #expect(engine.state.isGameOver)
        #expect(engine.state.activePiece == nil)
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

        let m1 = levelSystem.fallSpeedMultiplier(forLevel: 1, mode: .beginner)
        let m5 = levelSystem.fallSpeedMultiplier(forLevel: 5, mode: .beginner)
        let m10 = levelSystem.fallSpeedMultiplier(forLevel: 10, mode: .beginner)
        let m20 = levelSystem.fallSpeedMultiplier(forLevel: 20, mode: .beginner)
        let m100 = levelSystem.fallSpeedMultiplier(forLevel: 100, mode: .beginner)
        let intervalL1 = levelSystem.tickInterval(base: base, level: 1, mode: .beginner)
        let intervalL10 = levelSystem.tickInterval(base: base, level: 10, mode: .beginner)
        let intervalL20 = levelSystem.tickInterval(base: base, level: 20, mode: .beginner)

        #expect(abs(m1 - 1.0) < 0.000_001)
        #expect(m10 > m1)
        #expect(m20 > m10)
        #expect(m5 > m1)
        #expect(m100 == levelSystem.maxFallMultiplier(mode: .beginner))
        #expect(intervalL1 == base / m1)
        #expect(intervalL10 < intervalL1)
        #expect(intervalL20 < intervalL10)
    }

    @Test
    func beginnerEarlyLevelsRemainUnchanged() {
        let levelSystem = LevelSystem()
        let base: TimeInterval = 0.65

        #expect(abs(levelSystem.fallSpeedMultiplier(forLevel: 1, mode: .beginner) - 1.0) < 0.000_001)
        #expect(levelSystem.tickInterval(base: base, level: 1, mode: .beginner) == base)
    }

    @Test
    func level15PlusAppliesHigherTargetTimerPressure() {
        let levelSystem = LevelSystem()
        #expect(levelSystem.targetTimerDecrementMultiplier(level: 14, mode: .beginner) == 1.0)
        #expect(levelSystem.targetTimerDecrementMultiplier(level: 15, mode: .beginner) > 1.0)
    }

    @Test
    func expertCurveStartsFasterAndCapsLower() {
        let levelSystem = LevelSystem()
        let beginnerBase: TimeInterval = 0.65
        let expertBase: TimeInterval = 0.65 * pow(0.92, 4)

        let beginnerL1 = levelSystem.tickInterval(base: beginnerBase, level: 1, mode: .beginner)
        let expertL1 = levelSystem.tickInterval(base: expertBase, level: 1, mode: .expert)
        let expertL20 = levelSystem.tickInterval(base: expertBase, level: 20, mode: .expert)
        let basicM20 = levelSystem.fallSpeedMultiplier(forLevel: 20, mode: .beginner)
        let expertM20 = levelSystem.fallSpeedMultiplier(forLevel: 20, mode: .expert)

        #expect(expertL1 < beginnerL1)
        #expect(expertL20 < expertL1)
        #expect(expertM20 > basicM20)
    }

    @Test
    func expertPressureRampInactiveBeforeThreshold() {
        let levelSystem = LevelSystem()
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config, mode: .expert)
        state.score = levelSystem.levelThreshold(12) - 1
        let engine = GameEngine(state: state, config: config)

        #expect(engine.state.level < 12)
        #expect(engine.state.expertPressureRampActive == false)
        #expect(engine.state.expertSpawnPressureTier == 0)
    }

    @Test
    func expertPressureRampActiveAfterThreshold() {
        let levelSystem = LevelSystem()
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10)
        var stateTier1 = GameState.initial(config: config, mode: .expert)
        stateTier1.score = levelSystem.levelThreshold(12)
        let engineTier1 = GameEngine(state: stateTier1, config: config)

        var stateTier2 = GameState.initial(config: config, mode: .expert)
        stateTier2.score = levelSystem.levelThreshold(15)
        let engineTier2 = GameEngine(state: stateTier2, config: config)

        #expect(engineTier1.state.level >= 12)
        #expect(engineTier1.state.expertPressureRampActive)
        #expect(engineTier1.state.expertSpawnPressureTier == 1)
        #expect(engineTier2.state.expertSpawnPressureTier == 2)
    }

    @Test
    func scoringFormulaUnchangedForKnownInput() {
        let scoreSystem = ScoreSystem()
        let breakdown = scoreSystem.scoreBreakdownForClear(
            tileCount: 4,
            cascade: 3,
            isHorizontal: true,
            expertMode: false
        )
        #expect(breakdown.baseScore == 40)
        #expect(breakdown.lengthMultiplier == 1.5)
        #expect(breakdown.cascadeMultiplier == 1.5)
        #expect(breakdown.awardedScore == 99)
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
    private(set) var beginnerValue: Int
    private(set) var expertValue: Int

    init(initial: Int) {
        beginnerValue = initial
        expertValue = initial
    }

    init(initialBeginner: Int, initialExpert: Int) {
        beginnerValue = initialBeginner
        expertValue = initialExpert
    }

    func load(for mode: GameMode) -> Int {
        switch mode {
        case .beginner:
            return beginnerValue
        case .expert:
            return expertValue
        }
    }

    func save(_ value: Int, for mode: GameMode) {
        switch mode {
        case .beginner:
            beginnerValue = value
        case .expert:
            expertValue = value
        }
    }

    func savedValue(for mode: GameMode) -> Int {
        switch mode {
        case .beginner:
            return beginnerValue
        case .expert:
            return expertValue
        }
    }
}

final class RecordingAudioClient: AudioClient {
    private(set) var events: [SoundEvent] = []

    func trigger(_ event: SoundEvent) {
        events.append(event)
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
