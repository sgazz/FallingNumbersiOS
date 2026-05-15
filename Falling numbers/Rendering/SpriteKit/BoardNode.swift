import SpriteKit

final class BoardNode: SKNode {
    private var tileNodes: [GridPosition: TileNode] = [:]
    private let boardBackgroundNode = SKShapeNode()
    private let gridNode = SKNode()
    private var cellSize: CGFloat = 0
    private var boardSize: CGSize = .zero
    private var previousActivePositions: Set<GridPosition> = []
    private var previousBoardValues: [GridPosition: Int] = [:]
    private var lastGeometryKey: String?

    override init() {
        super.init()
        addChild(boardBackgroundNode)
        addChild(gridNode)
        boardBackgroundNode.zPosition = -2
        gridNode.zPosition = -1
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func render(state: GameState, sceneSize: CGSize) {
        guard state.board.columns > 0 && state.board.rows > 0 else { return }

        let maxBoardWidth = sceneSize.width * 0.92
        let maxBoardHeight = sceneSize.height * 0.96
        cellSize = min(maxBoardWidth / CGFloat(state.board.columns), maxBoardHeight / CGFloat(state.board.rows))

        boardSize = CGSize(
            width: CGFloat(state.board.columns) * cellSize,
            height: CGFloat(state.board.rows) * cellSize
        )

        let geometryKey = "\(state.board.rows)x\(state.board.columns)|\(Int(cellSize * 100))"
        if geometryKey != lastGeometryKey {
            drawBoardBackground()
            drawGrid(board: state.board)
            lastGeometryKey = geometryKey
        }

        let occupiedPositions = state.board.allOccupiedPositions()
        let occupied = Set(occupiedPositions)
        var currentBoardValues: [GridPosition: Int] = [:]
        currentBoardValues.reserveCapacity(occupiedPositions.count)
        for position in occupiedPositions {
            if let value = state.board.cell(at: position)?.value {
                currentBoardValues[position] = value
            }
        }

        let movedPairs = detectColumnGravityMoves(from: previousBoardValues, to: currentBoardValues, columns: state.board.columns)
        for (from, to) in movedPairs {
            guard let node = tileNodes[from], tileNodes[to] == nil else { continue }
            tileNodes.removeValue(forKey: from)
            tileNodes[to] = node
            node.removeAction(forKey: "move")
            let dropDistance = abs(CGFloat(to.row - from.row)) * cellSize
            let duration = max(0.08, min(0.12, Double(dropDistance / max(1, cellSize)) * 0.04))
            node.run(
                SKAction.move(to: pointFor(position: to), duration: duration).withTimingMode(.easeOut),
                withKey: "move"
            )
        }

        var needed = occupied
        if let active = state.activePiece {
            needed.insert(active.position)
        }
        let activePosition = state.activePiece?.position
        let previousActive = previousActivePositions.first

        // Keep one active tile node alive while it moves across cells.
        // This prevents the old cell node from fade-out trailing behind the active piece.
        if let previousActive,
           let activePosition,
           previousActive != activePosition,
           tileNodes[activePosition] == nil,
           state.board.cell(at: previousActive) == nil,
           let activeNode = tileNodes[previousActive] {
            tileNodes.removeValue(forKey: previousActive)
            tileNodes[activePosition] = activeNode
        }

        for (position, node) in tileNodes where !needed.contains(position) {
            tileNodes.removeValue(forKey: position)
            // Clear feedback: short warm pulse + scale up + fade out.
            node.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.06, duration: 0.08),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.06)
                ]),
                SKAction.group([
                    SKAction.scale(to: 0.86, duration: 0.13),
                    SKAction.fadeOut(withDuration: 0.13)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        for position in needed {
            let value: Int
            let isActive: Bool
            if let active = state.activePiece, active.position == position {
                value = active.value
                isActive = true
            } else if let cellValue = state.board.cell(at: position)?.value {
                value = cellValue
                isActive = false
            } else {
                continue
            }

            let point = pointFor(position: position)
            if let node = tileNodes[position] {
                let wasActive = previousActivePositions.contains(position)
                node.update(value: value, size: cellSize * 0.92, isActive: isActive)
                if node.position != point {
                    node.removeAction(forKey: "move")
                    let distanceCells = max(1, Int(ceil(hypot(node.position.x - point.x, node.position.y - point.y) / max(1, cellSize))))
                    let duration: TimeInterval
                    if isActive {
                        duration = distanceCells >= 3 ? 0.06 : max(0.05, min(0.08, 0.045 + Double(distanceCells) * 0.015))
                    } else {
                        duration = max(0.08, min(0.12, 0.07 + Double(distanceCells) * 0.015))
                    }
                    // Snap when target is almost reached to avoid micro-drift blur.
                    if hypot(node.position.x - point.x, node.position.y - point.y) < cellSize * 0.12 {
                        node.position = point
                    } else {
                        node.run(
                            SKAction.move(to: point, duration: duration).withTimingMode(.easeOut),
                            withKey: "move"
                        )
                    }
                }
                if wasActive, !isActive {
                    // Lock feedback: tiny settle animation, no board shake.
                    node.run(SKAction.sequence([
                        SKAction.scale(to: 0.97, duration: 0.05),
                        SKAction.scale(to: 1.02, duration: 0.06),
                        SKAction.scale(to: 1.0, duration: 0.04)
                    ]))
                }
            } else {
                let node = TileNode(value: value, size: cellSize * 0.92, isActive: isActive)
                node.position = point
                node.alpha = 0
                node.setScale(0.82)
                addChild(node)
                tileNodes[position] = node
                node.run(
                    SKAction.group([
                        SKAction.fadeIn(withDuration: 0.09),
                        SKAction.scale(to: isActive ? 1.03 : 1.0, duration: 0.09)
                    ])
                )
            }
        }

        if let activePosition {
            previousActivePositions = [activePosition]
        } else {
            previousActivePositions.removeAll()
        }
        previousBoardValues = currentBoardValues
    }

    // Power-up animation hooks for v1 integration points.
    // They are intentionally lightweight and can be invoked by future visual event payloads.
    func playRowClearSweep(row: Int) {}
    func playColumnClearSweep(column: Int) {}
    func playReorderHint() {}

    private func drawBoardBackground() {
        let rect = CGRect(
            x: -boardSize.width / 2,
            y: -boardSize.height / 2,
            width: boardSize.width,
            height: boardSize.height
        )

        boardBackgroundNode.path = CGPath(roundedRect: rect, cornerWidth: 14, cornerHeight: 14, transform: nil)
        boardBackgroundNode.fillColor = NeonTheme.boardFill
        boardBackgroundNode.strokeColor = NeonTheme.boardStroke
        boardBackgroundNode.lineWidth = 1.2
    }

    private func drawGrid(board: Board) {
        gridNode.removeAllChildren()

        let originX = -boardSize.width / 2
        let originY = boardSize.height / 2

        for column in 1..<board.columns {
            let x = originX + CGFloat(column) * cellSize
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: originY))
            path.addLine(to: CGPoint(x: x, y: originY - boardSize.height))
            line.path = path
            line.strokeColor = NeonTheme.gridLine
            line.lineWidth = 0.8
            gridNode.addChild(line)
        }

        for row in 1..<board.rows {
            let y = originY - CGFloat(row) * cellSize
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: originX, y: y))
            path.addLine(to: CGPoint(x: originX + boardSize.width, y: y))
            line.path = path
            line.strokeColor = NeonTheme.gridLine
            line.lineWidth = 0.8
            gridNode.addChild(line)
        }
    }

    private func pointFor(position: GridPosition) -> CGPoint {
        let originX = -boardSize.width / 2 + cellSize / 2
        let originY = boardSize.height / 2 - cellSize / 2

        return CGPoint(
            x: originX + CGFloat(position.column) * cellSize,
            y: originY - CGFloat(position.row) * cellSize
        )
    }

    private func detectColumnGravityMoves(
        from old: [GridPosition: Int],
        to new: [GridPosition: Int],
        columns: Int
    ) -> [(from: GridPosition, to: GridPosition)] {
        guard !old.isEmpty, !new.isEmpty else { return [] }
        var results: [(from: GridPosition, to: GridPosition)] = []

        for column in 0..<columns {
            let oldColumn = old
                .filter { $0.key.column == column }
                .map { ($0.key.row, $0.value) }
                .sorted { $0.0 < $1.0 }
            let newColumn = new
                .filter { $0.key.column == column }
                .map { ($0.key.row, $0.value) }
                .sorted { $0.0 < $1.0 }

            if oldColumn.isEmpty || newColumn.isEmpty { continue }

            var usedOld: Set<Int> = []
            for (newRow, newValue) in newColumn {
                if let stationary = old[GridPosition(row: newRow, column: column)], stationary == newValue {
                    continue
                }
                if let oldMatch = oldColumn.first(where: { pair in
                    !usedOld.contains(pair.0) && pair.1 == newValue && pair.0 < newRow
                }) {
                    usedOld.insert(oldMatch.0)
                    results.append((
                        from: GridPosition(row: oldMatch.0, column: column),
                        to: GridPosition(row: newRow, column: column)
                    ))
                }
            }
        }

        return results
    }
}

private extension SKAction {
    func withTimingMode(_ mode: SKActionTimingMode) -> SKAction {
        timingMode = mode
        return self
    }
}
