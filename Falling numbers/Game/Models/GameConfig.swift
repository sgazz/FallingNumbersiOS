import Foundation

struct GameConfig {
    let columns: Int
    let rows: Int
    let tickInterval: TimeInterval
    let expertStartingTickInterval: TimeInterval
    let lockDelayDuration: TimeInterval
    let targetChangeInterval: TimeInterval
    let baseTargetNumber: Int
    let startingLayoutSeed: Int
    let perfectClearBonusBase: Int
    let perfectClearBonusPerLevel: Int
    let beginnerColumnsOverride: Int?
    let beginnerRowsOverride: Int?

    init(
        columns: Int,
        rows: Int,
        tickInterval: TimeInterval,
        expertStartingTickInterval: TimeInterval? = nil,
        lockDelayDuration: TimeInterval = 0.22,
        targetChangeInterval: TimeInterval = 30.0,
        baseTargetNumber: Int,
        startingLayoutSeed: Int = 1,
        perfectClearBonusBase: Int = 250,
        perfectClearBonusPerLevel: Int = 100,
        beginnerColumnsOverride: Int? = nil,
        beginnerRowsOverride: Int? = nil
    ) {
        self.columns = columns
        self.rows = rows
        self.tickInterval = tickInterval
        self.expertStartingTickInterval = expertStartingTickInterval ?? (tickInterval * pow(0.92, 4))
        self.lockDelayDuration = lockDelayDuration
        self.targetChangeInterval = targetChangeInterval
        self.baseTargetNumber = baseTargetNumber
        self.startingLayoutSeed = startingLayoutSeed
        self.perfectClearBonusBase = perfectClearBonusBase
        self.perfectClearBonusPerLevel = perfectClearBonusPerLevel
        self.beginnerColumnsOverride = beginnerColumnsOverride
        self.beginnerRowsOverride = beginnerRowsOverride
    }

    static let `default` = GameConfig(
        columns: 10,
        rows: 20,
        tickInterval: 0.65,
        expertStartingTickInterval: 0.65 * pow(0.92, 4),
        lockDelayDuration: 0.22,
        targetChangeInterval: 30.0,
        baseTargetNumber: 10,
        startingLayoutSeed: 1,
        perfectClearBonusBase: 250,
        perfectClearBonusPerLevel: 100,
        beginnerColumnsOverride: 7,
        beginnerRowsOverride: 15
    )

    func columns(for mode: GameMode) -> Int {
        switch mode {
        case .beginner:
            return beginnerColumnsOverride ?? columns
        case .expert:
            return columns
        }
    }

    func rows(for mode: GameMode) -> Int {
        switch mode {
        case .beginner:
            return beginnerRowsOverride ?? rows
        case .expert:
            return rows
        }
    }
}
