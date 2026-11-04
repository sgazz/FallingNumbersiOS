import Foundation

enum PowerUpSystem {
    static func activateRowClear(state: inout GameState, gravitySystem: inout GravitySystem, at position: GridPosition) {
        state.lastPowerUpActivation = PowerUpActivation(type: .rowClear, row: position.row, column: nil)
        state.powerUpEventToken &+= 1
        state.telemetry.powerUpsUsed[.rowClear, default: 0] += 1
        var removed = 0
        for column in 0..<state.board.columns {
            let target = GridPosition(row: position.row, column: column)
            if state.board.cell(at: target) != nil {
                removed += 1
                state.board.setCell(nil, at: target)
            }
        }
        if removed > 0 {
            state.score += removed * 15
            state.totalClearedTiles += removed
            GameDebugLogger.logPowerUp(type: "rowClear", axis: "row", index: position.row, removed: removed)
            gravitySystem.collapse(board: &state.board)
        }
    }

    static func activateColumnClear(state: inout GameState, gravitySystem: inout GravitySystem, at position: GridPosition) {
        state.lastPowerUpActivation = PowerUpActivation(type: .columnClear, row: nil, column: position.column)
        state.powerUpEventToken &+= 1
        state.telemetry.powerUpsUsed[.columnClear, default: 0] += 1
        var removed = 0
        for row in 0..<state.board.rows {
            let target = GridPosition(row: row, column: position.column)
            if state.board.cell(at: target) != nil {
                removed += 1
                state.board.setCell(nil, at: target)
            }
        }
        if removed > 0 {
            state.score += removed * 15
            state.totalClearedTiles += removed
            GameDebugLogger.logPowerUp(type: "columnClear", axis: "column", index: position.column, removed: removed)
            gravitySystem.collapse(board: &state.board)
        }
    }

    static func activateReorder(state: inout GameState, at position: GridPosition) {
        state.lastPowerUpActivation = PowerUpActivation(type: .reorder, row: nil, column: nil)
        state.powerUpEventToken &+= 1
        state.telemetry.powerUpsUsed[.reorder, default: 0] += 1
        // Power-up tile disappears on activation.
        state.board.setCell(nil, at: position)

        let positions = state.board
            .allOccupiedPositions()
            .sorted { lhs, rhs in
                if lhs.row != rhs.row { return lhs.row > rhs.row }
                return lhs.column < rhs.column
            }

        var values = positions.compactMap { state.board.cell(at: $0)?.kind.numericValue }
        guard !values.isEmpty else {
            GameDebugLogger.logPowerUp(type: "reorder", axis: nil, index: nil, removed: 0)
            return
        }

        values.sort()
        for target in positions {
            state.board.setCell(nil, at: target)
        }

        for (index, target) in positions.enumerated() where index < values.count {
            state.board.setCell(Cell(value: values[index]), at: target)
        }

        let affected = values.count
        if affected >= 5 {
            state.score += 100
        }
        GameDebugLogger.logPowerUp(type: "reorder", axis: nil, index: nil, removed: affected)
    }

}
