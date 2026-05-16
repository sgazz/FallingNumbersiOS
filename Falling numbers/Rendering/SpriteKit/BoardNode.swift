import SpriteKit

final class BoardNode: SKNode {
    private enum VisualTiming {
        static let beginnerHighlight: TimeInterval = 0.52
        static let expertHighlight: TimeInterval = 0.27
        static let clearDuration: TimeInterval = 0.22
    }

    private var tileNodes: [GridPosition: TileNode] = [:]
    private let boardBackgroundNode = SKShapeNode()
    private let gridNode = SKNode()
    private var cellSize: CGFloat = 0
    private var boardSize: CGSize = .zero
    private var previousActivePositions: Set<GridPosition> = []
    private var previousBoardKinds: [GridPosition: TileKind] = [:]
    private var lastGeometryKey: String?
    private var lastPowerUpEventToken: Int = -1
#if DEBUG
    private static let enableRenderWarnings = true
#endif

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

        if state.powerUpEventToken != lastPowerUpEventToken,
           let activation = state.lastPowerUpActivation {
            lastPowerUpEventToken = state.powerUpEventToken
            switch activation.type {
            case .rowClear:
                if let row = activation.row { playRowClearSweep(row: row) }
            case .columnClear:
                if let column = activation.column { playColumnClearSweep(column: column) }
            case .reorder:
                playReorderHint()
            }
        }

        let occupiedPositions = state.board.allOccupiedPositions()
        let occupied = Set(occupiedPositions)
        var currentBoardKinds: [GridPosition: TileKind] = [:]
        currentBoardKinds.reserveCapacity(occupiedPositions.count)
        for position in occupiedPositions {
            if let kind = state.board.cell(at: position)?.kind {
                currentBoardKinds[position] = kind
            }
        }

        let highlightDuration = state.gameMode == .beginner ? VisualTiming.beginnerHighlight : VisualTiming.expertHighlight
        let clearDuration = VisualTiming.clearDuration

        let movedPairs = detectColumnGravityMoves(from: previousBoardKinds, to: currentBoardKinds, columns: state.board.columns)
        for (from, to) in movedPairs {
            guard let node = tileNodes[from], tileNodes[to] == nil else { continue }
            tileNodes.removeValue(forKey: from)
            tileNodes[to] = node
            node.removeAction(forKey: "move")
            let dropDistance = abs(CGFloat(to.row - from.row)) * cellSize
            let duration = max(0.08, min(0.12, Double(dropDistance / max(1, cellSize)) * 0.04))
            let moveAction = SKAction.move(to: pointFor(position: to), duration: duration).withTimingMode(.easeOut)
            node.run(moveAction, withKey: "move")
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
        if let previousActive,
           let activePosition,
           previousActive != activePosition,
           let oldNode = tileNodes[previousActive],
           tileNodes[activePosition] != nil {
            // Ensure only one active node survives to avoid ghosting.
            oldNode.removeAllActions()
            oldNode.removeFromParent()
            tileNodes.removeValue(forKey: previousActive)
        }

        for (position, node) in tileNodes where !needed.contains(position) {
            tileNodes.removeValue(forKey: position)
            // Safer clear strategy:
            // remove node from live board map immediately and animate it as independent snapshot.
            node.removeAllActions()
            node.removeAction(forKey: "move")
            node.zPosition = 20
            node.name = "clearing_snapshot"
            node.runClearAnimationAndRemove(highlightDuration: highlightDuration, clearDuration: clearDuration)
#if DEBUG
            if Self.enableRenderWarnings {
                // Snapshot must disappear quickly; warn if it leaks.
                node.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: highlightDuration + clearDuration + 0.9),
                        SKAction.run { [weak node] in
                            if let node, node.parent != nil {
                                print("[RENDER-WARN] stale clearing snapshot > expected lifetime")
                            }
                        }
                    ])
                )
            }
#endif
        }

        for position in needed {
            let kind: TileKind
            let isActive: Bool
            if let active = state.activePiece, active.position == position {
                kind = active.kind
                isActive = true
            } else if let cellKind = state.board.cell(at: position)?.kind {
                kind = cellKind
                isActive = false
            } else {
                continue
            }

            let point = pointFor(position: position)
            if let node = tileNodes[position] {
                let wasActive = previousActivePositions.contains(position)
                node.update(kind: kind, size: cellSize * 0.92, isActive: isActive)
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
                        let moveAction = SKAction.move(to: point, duration: duration).withTimingMode(.easeOut)
                        node.run(moveAction, withKey: "move")
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
                let node = TileNode(kind: kind, size: cellSize * 0.92, isActive: isActive)
                node.position = point
                node.alpha = 0
                node.setScale(0.82)
                addChild(node)
                tileNodes[position] = node
                node.removeAction(forKey: "move")
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
        previousBoardKinds = currentBoardKinds

#if DEBUG
        if Self.enableRenderWarnings {
            if let active = state.activePiece, tileNodes[active.position] == nil {
                print("[RENDER-WARN] active tile node missing at r\(active.position.row)c\(active.position.column)")
            }

            var keyCounts: [String: Int] = [:]
            for (position, _) in tileNodes {
                let key = "\(position.row):\(position.column)"
                keyCounts[key, default: 0] += 1
            }
            if keyCounts.values.contains(where: { $0 > 1 }) {
                print("[RENDER-WARN] duplicate tileNodes mapped to same board position")
            }
        }
#endif
    }

    private func neededPositionSet(state: GameState) -> Set<GridPosition> {
        var needed = Set(state.board.allOccupiedPositions())
        if let active = state.activePiece {
            needed.insert(active.position)
        }
        return needed
    }

    // Power-up animation hooks for v1 integration points.
    func playRowClearSweep(row: Int) {
        guard row >= 0 else { return }
        let y = pointFor(position: GridPosition(row: row, column: 0)).y
        let width = boardSize.width * 0.92
        let height = max(6, cellSize * 0.22)
        let sweep = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height * 0.5)
        sweep.fillColor = UIColor(red: 1.0, green: 0.80, blue: 0.36, alpha: 0.62)
        sweep.strokeColor = .clear
        sweep.blendMode = .alpha
        sweep.position = CGPoint(x: 0, y: y)
        sweep.zPosition = 9
        sweep.alpha = 0
        addChild(sweep)

        let pulse = SKAction.group([
            SKAction.fadeAlpha(to: 0.9, duration: 0.06),
            SKAction.scaleX(to: 1.02, duration: 0.06)
        ])
        let fade = SKAction.fadeOut(withDuration: 0.12)
        sweep.run(SKAction.sequence([pulse, fade, .removeFromParent()]))
    }

    func playColumnClearSweep(column: Int) {
        guard column >= 0 else { return }
        let x = pointFor(position: GridPosition(row: 0, column: column)).x
        let width = max(6, cellSize * 0.22)
        let height = boardSize.height * 0.92
        let sweep = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: width * 0.5)
        sweep.fillColor = UIColor(red: 0.50, green: 0.86, blue: 1.0, alpha: 0.6)
        sweep.strokeColor = .clear
        sweep.blendMode = .alpha
        sweep.position = CGPoint(x: x, y: 0)
        sweep.zPosition = 9
        sweep.alpha = 0
        addChild(sweep)

        let pulse = SKAction.group([
            SKAction.fadeAlpha(to: 0.88, duration: 0.06),
            SKAction.scaleY(to: 1.02, duration: 0.06)
        ])
        let fade = SKAction.fadeOut(withDuration: 0.12)
        sweep.run(SKAction.sequence([pulse, fade, .removeFromParent()]))
    }

    func playReorderHint() {
        let action = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.04, duration: 0.07),
                SKAction.rotate(byAngle: 0.06, duration: 0.07)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.09),
                SKAction.rotate(toAngle: 0, duration: 0.09)
            ])
        ])
        for node in tileNodes.values {
            node.removeAction(forKey: "reorder_hint")
            node.run(action, withKey: "reorder_hint")
        }
    }

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
        from old: [GridPosition: TileKind],
        to new: [GridPosition: TileKind],
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
