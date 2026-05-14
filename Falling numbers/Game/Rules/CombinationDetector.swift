import Foundation

struct CombinationDetector {
    // Line-matching behavior:
    // valid groups are contiguous horizontal or vertical sequences (length >= 2)
    // whose sum equals the target.
    func findMatchingGroups(on board: Board, target: Int) -> [[GridPosition]] {
        guard target > 0 else { return [] }
        var matches: [[GridPosition]] = []
        var seen = Set<String>()

        for row in 0..<board.rows {
            for startColumn in 0..<board.columns {
                var sum = 0
                var group: [GridPosition] = []

                for column in startColumn..<board.columns {
                    let position = GridPosition(row: row, column: column)
                    guard let value = board.cell(at: position)?.value else { break }
                    sum += value
                    group.append(position)

                    if group.count >= 2, sum == target {
                        let key = makeKey(group)
                        if seen.insert(key).inserted {
                            matches.append(group)
                        }
                    }

                    if sum >= target { break }
                }
            }
        }

        for column in 0..<board.columns {
            for startRow in 0..<board.rows {
                var sum = 0
                var group: [GridPosition] = []

                for row in startRow..<board.rows {
                    let position = GridPosition(row: row, column: column)
                    guard let value = board.cell(at: position)?.value else { break }
                    sum += value
                    group.append(position)

                    if group.count >= 2, sum == target {
                        let key = makeKey(group)
                        if seen.insert(key).inserted {
                            matches.append(group)
                        }
                    }

                    if sum >= target { break }
                }
            }
        }

        matches.sort(by: groupLess)
        return matches
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
