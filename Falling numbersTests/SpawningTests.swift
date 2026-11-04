import Testing
import CoreGraphics
import Foundation
import SpriteKit
@testable import Falling_numbers

@MainActor
struct SpawningTests {
    @Test
    func initialLayoutDoesNotBlockSpawn() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.65, baseTargetNumber: 10, startingLayoutSeed: 1)
        var engine = GameEngine(config: config)
        engine.send(.start)

        #expect(!engine.state.isGameOver)
        #expect(engine.state.activePiece != nil)
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
    func expertSpawnUsesSingleFixedColumn() {
        let spawnSystem = SpawnSystem()
        let column = spawnSystem.expertSpawnColumn(columns: 10)
        #expect(column == 5)

        for offset in 0..<200 {
            #expect(spawnSystem.nextSpawnColumn(columns: 10, mode: .expert) == column)
            let piece = spawnSystem.makePiece(
                on: Board(rows: 20, columns: 10),
                kind: .number(offset % 9 + 1),
                mode: .expert
            )
            #expect(piece?.position.column == column)
        }
    }

    @Test
    func expertDoesNotSpawnFromAdjacentWhenSpawnPointBlocked() {
        let spawnSystem = SpawnSystem()
        var board = Board(rows: 6, columns: 10)
        let spawnColumn = spawnSystem.expertSpawnColumn(columns: board.columns)
        board.setCell(Cell(value: 9), at: GridPosition(row: 0, column: spawnColumn))

        let piece = spawnSystem.makePiece(on: board, kind: .number(4), mode: .expert)
        #expect(piece == nil)
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
    func gameOverWhenAllSpawnCellsBlocked() {
        let config = GameConfig(columns: 10, rows: 20, tickInterval: 0.5, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        for column in 0..<config.columns {
            state.board.setCell(Cell(value: 7), at: GridPosition(row: 0, column: column))
        }

        var engine = GameEngine(state: state, config: config)
        engine.send(.start)

        #expect(engine.state.isGameOver)
        #expect(engine.state.activePiece == nil)
        #expect(engine.state.telemetry.gameOverReason == .columnFilledToTop)
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
}
