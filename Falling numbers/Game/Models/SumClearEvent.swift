import Foundation

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

