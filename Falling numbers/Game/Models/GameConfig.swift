import Foundation

struct GameConfig {
    let columns: Int
    let rows: Int
    let tickInterval: TimeInterval
    let baseTargetNumber: Int

    static let `default` = GameConfig(
        columns: 10,
        rows: 20,
        tickInterval: 0.65,
        baseTargetNumber: 10
    )
}
