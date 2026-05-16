import Foundation

enum PowerUpType: String, Equatable, Hashable {
    case rowClear
    case columnClear
    case reorder
}

struct PowerUpActivation: Equatable, Hashable {
    let type: PowerUpType
    let row: Int?
    let column: Int?
}

