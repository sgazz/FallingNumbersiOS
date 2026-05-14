import Foundation

struct GameConfig {
    let columns: Int
    let rows: Int
    let tickInterval: TimeInterval
    let lockDelayDuration: TimeInterval
    let targetChangeInterval: TimeInterval
    let baseTargetNumber: Int
    let startingLayoutSeed: Int

    init(
        columns: Int,
        rows: Int,
        tickInterval: TimeInterval,
        lockDelayDuration: TimeInterval = 0.22,
        targetChangeInterval: TimeInterval = 30.0,
        baseTargetNumber: Int,
        startingLayoutSeed: Int = 1
    ) {
        self.columns = columns
        self.rows = rows
        self.tickInterval = tickInterval
        self.lockDelayDuration = lockDelayDuration
        self.targetChangeInterval = targetChangeInterval
        self.baseTargetNumber = baseTargetNumber
        self.startingLayoutSeed = startingLayoutSeed
    }

    static let `default` = GameConfig(
        columns: 10,
        rows: 20,
        tickInterval: 0.65,
        lockDelayDuration: 0.22,
        targetChangeInterval: 30.0,
        baseTargetNumber: 10,
        startingLayoutSeed: 1
    )
}
