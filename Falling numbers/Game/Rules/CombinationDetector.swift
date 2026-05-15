import Foundation

struct CombinationDetector {
    // Valid matches are contiguous horizontal or vertical lines (length >= 2)
    // whose sum equals the target.
    // Detection order is stable: horizontal scan first (top-to-bottom, left-to-right),
    // then vertical scan (left-to-right, top-to-bottom).
    func findMatchingGroups(on board: Board, target: Int) -> [[GridPosition]] {
        guard target > 0 else { return [] }
        var matches: [[GridPosition]] = []

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
                        matches.append(group)
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
                        matches.append(group)
                    }

                    if sum >= target { break }
                }
            }
        }

        return matches
    }
}
