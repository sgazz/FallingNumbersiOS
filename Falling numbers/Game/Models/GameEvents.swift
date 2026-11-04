import Foundation

enum PowerUpType: String, Equatable, Hashable, CaseIterable {
    case rowClear
    case columnClear
    case reorder
}

struct PowerUpActivation: Equatable, Hashable {
    let type: PowerUpType
    let row: Int?
    let column: Int?
}

enum SumClearDirection: String, Equatable, Hashable {
    case horizontal
    case vertical
}

struct SumClearEvent: Equatable, Hashable {
    let values: [Int]
    let target: Int
    let direction: SumClearDirection
    let positions: [GridPosition]
    let cascade: Int
}

enum MatchDirection: String {
    case horizontal = "H"
    case vertical = "V"
}
