import Foundation

struct Cell: Equatable {
    let kind: TileKind

    init(kind: TileKind) {
        self.kind = kind
    }

    init(value: Int) {
        self.kind = .number(value)
    }

    var value: Int {
        kind.numericValue ?? 0
    }
}
