import Testing
import CoreGraphics
import Foundation
import SpriteKit
@testable import Falling_numbers

@MainActor
struct CombinationDetectorTests {
    @Test
    func detectsHorizontalContiguousTargetSum() {
        var board = Board(rows: 3, columns: 4)
        board.setCell(Cell(value: 4), at: GridPosition(row: 1, column: 0))
        board.setCell(Cell(value: 6), at: GridPosition(row: 1, column: 1))
        board.setCell(Cell(value: 2), at: GridPosition(row: 1, column: 2))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.map(groupKey).contains(groupKey([
            GridPosition(row: 1, column: 0),
            GridPosition(row: 1, column: 1)
        ])))
    }

    @Test
    func detectsVerticalContiguousTargetSum() {
        var board = Board(rows: 3, columns: 4)
        board.setCell(Cell(value: 2), at: GridPosition(row: 0, column: 2))
        board.setCell(Cell(value: 3), at: GridPosition(row: 1, column: 2))
        board.setCell(Cell(value: 5), at: GridPosition(row: 2, column: 2))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.map(groupKey).contains(groupKey([
            GridPosition(row: 0, column: 2),
            GridPosition(row: 1, column: 2),
            GridPosition(row: 2, column: 2)
        ])))
    }

    @Test
    func doesNotDetectDiagonal() {
        var board = Board(rows: 3, columns: 3)
        board.setCell(Cell(value: 4), at: GridPosition(row: 0, column: 0))
        board.setCell(Cell(value: 6), at: GridPosition(row: 1, column: 1))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.isEmpty)
    }

    @Test
    func doesNotDetectLShapeOrCluster() {
        var board = Board(rows: 3, columns: 3)
        board.setCell(Cell(value: 4), at: GridPosition(row: 1, column: 1))
        board.setCell(Cell(value: 3), at: GridPosition(row: 1, column: 2))
        board.setCell(Cell(value: 3), at: GridPosition(row: 2, column: 1))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)

        #expect(matches.isEmpty)
    }

    @Test
    func doesNotDetectNonContiguousCells() {
        var board = Board(rows: 1, columns: 4)
        board.setCell(Cell(value: 4), at: GridPosition(row: 0, column: 0))
        board.setCell(Cell(value: 6), at: GridPosition(row: 0, column: 2))

        let matches = CombinationDetector().findMatchingGroups(on: board, target: 10)
        #expect(matches.isEmpty)
    }

    @Test
    func deterministicTieUsesHorizontalBeforeVertical() {
        let config = GameConfig(columns: 4, rows: 4, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 2, column: 0)) // horizontal partner
        state.board.setCell(Cell(value: 6), at: GridPosition(row: 3, column: 1)) // vertical partner / blocker
        state.activePiece = FallingPiece(value: 4, position: GridPosition(row: 0, column: 1))

        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)

        // Horizontal tie should resolve first, leaving the vertical-only 6.
        #expect(engine.state.board.cell(at: GridPosition(row: 3, column: 1))?.value == 6)
    }

    private func groupKey(_ group: [GridPosition]) -> String {
        group
            .sorted { lhs, rhs in
                if lhs.row != rhs.row { return lhs.row < rhs.row }
                return lhs.column < rhs.column
            }
            .map { "\($0.row):\($0.column)" }
            .joined(separator: "|")
    }
}
