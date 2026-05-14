import Foundation

struct CombinationDetector {
    func findMatchingGroups(on board: Board, target: Int) -> [[GridPosition]] {
        guard target > 0 else { return [] }

        let occupied = board.allOccupiedPositions().sorted(by: positionLess)
        let occupiedSet = Set(occupied)
        var seenKeys = Set<String>()
        var result: [[GridPosition]] = []

        for anchor in occupied {
            guard let anchorValue = board.cell(at: anchor)?.value else { continue }
            if anchorValue > target { continue }

            let anchorIndex = linearIndex(anchor, columns: board.columns)
            var group = Set([anchor])
            var frontier = Set(neighbors(of: anchor, board: board).filter {
                occupiedSet.contains($0) && linearIndex($0, columns: board.columns) >= anchorIndex
            })

            search(
                board: board,
                target: target,
                anchorIndex: anchorIndex,
                currentSum: anchorValue,
                group: &group,
                frontier: &frontier,
                occupiedSet: occupiedSet,
                seenKeys: &seenKeys,
                result: &result
            )
        }

        result.sort(by: groupLess)
        return result
    }

    private func search(
        board: Board,
        target: Int,
        anchorIndex: Int,
        currentSum: Int,
        group: inout Set<GridPosition>,
        frontier: inout Set<GridPosition>,
        occupiedSet: Set<GridPosition>,
        seenKeys: inout Set<String>,
        result: inout [[GridPosition]]
    ) {
        if currentSum == target {
            let sorted = group.sorted(by: positionLess)
            let key = makeKey(sorted)
            if seenKeys.insert(key).inserted {
                result.append(sorted)
            }
            return
        }

        if currentSum > target || frontier.isEmpty {
            return
        }

        let candidates = frontier.sorted(by: positionLess)

        for candidate in candidates {
            guard let value = board.cell(at: candidate)?.value else { continue }
            let nextSum = currentSum + value
            if nextSum > target { continue }

            let oldFrontier = frontier
            group.insert(candidate)
            frontier.remove(candidate)

            for neighbor in neighbors(of: candidate, board: board) {
                let index = linearIndex(neighbor, columns: board.columns)
                if occupiedSet.contains(neighbor), !group.contains(neighbor), index >= anchorIndex {
                    frontier.insert(neighbor)
                }
            }

            search(
                board: board,
                target: target,
                anchorIndex: anchorIndex,
                currentSum: nextSum,
                group: &group,
                frontier: &frontier,
                occupiedSet: occupiedSet,
                seenKeys: &seenKeys,
                result: &result
            )

            group.remove(candidate)
            frontier = oldFrontier
        }
    }

    private func neighbors(of position: GridPosition, board: Board) -> [GridPosition] {
        [
            position.translated(rowDelta: -1, columnDelta: 0),
            position.translated(rowDelta: 1, columnDelta: 0),
            position.translated(rowDelta: 0, columnDelta: -1),
            position.translated(rowDelta: 0, columnDelta: 1)
        ].filter { board.isInside($0) }
    }

    private func linearIndex(_ position: GridPosition, columns: Int) -> Int {
        position.row * columns + position.column
    }

    private func positionLess(_ lhs: GridPosition, _ rhs: GridPosition) -> Bool {
        if lhs.row != rhs.row { return lhs.row < rhs.row }
        return lhs.column < rhs.column
    }

    private func groupLess(_ lhs: [GridPosition], _ rhs: [GridPosition]) -> Bool {
        let left = makeKey(lhs)
        let right = makeKey(rhs)
        return left < right
    }

    private func makeKey(_ group: [GridPosition]) -> String {
        group.map { "\($0.row):\($0.column)" }.joined(separator: "|")
    }
}
