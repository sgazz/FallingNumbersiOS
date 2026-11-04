import Testing
import CoreGraphics
import Foundation
import SpriteKit
@testable import Falling_numbers

@MainActor
struct ScoringAndProgressionTests {
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
    func levelThresholdAndProgressBoundariesAreStable() {
        let levelSystem = LevelSystem()
        let levelTwoThreshold = levelSystem.levelThreshold(2)
        let levelThreeThreshold = levelSystem.levelThreshold(3)

        #expect(levelTwoThreshold > 0)
        #expect(levelThreeThreshold > levelTwoThreshold)
        #expect(levelSystem.level(forScore: levelTwoThreshold - 1) == 1)
        #expect(levelSystem.level(forScore: levelTwoThreshold) == 2)
        #expect(levelSystem.progressToNextLevel(score: levelTwoThreshold) == 0)
        #expect(levelSystem.progressToNextLevel(score: levelThreeThreshold - 1) < 1)
        #expect(levelSystem.progressToNextLevel(score: levelThreeThreshold + 500) == 1)
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

    @Test(arguments: [41, 45])
    func midOccupancyUsesStableBasePowerUpChance(occupancy: Int) {
        let scoreSystem = ScoreSystem()
        let adjusted = scoreSystem.occupancyAdjustedSpecialSpawnChance(
            baseChance: 0.08,
            occupancyPercent: occupancy,
            mode: .beginner
        )
        #expect(adjusted == 0.08)
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
}
