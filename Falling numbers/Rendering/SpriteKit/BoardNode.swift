import SpriteKit

final class BoardNode: SKNode {
    private enum VisualTiming {
        static let beginnerHighlight: TimeInterval = 0.52
        static let expertHighlight: TimeInterval = 0.27
        static let clearDuration: TimeInterval = 0.22
    }

    private var tileNodes: [UUID: TileNode] = [:]
    private let boardBackgroundNode = SKShapeNode()
    private let gridNode = SKNode()
    private var cellSize: CGFloat = 0
    private var boardSize: CGSize = .zero
    private var lastRunID: UUID?
    private var previousActiveID: UUID?
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

    func render(state: GameState, sceneSize: CGSize, reduceMotion: Bool = false) {
        guard state.board.columns > 0 && state.board.rows > 0 else { return }

        if lastRunID != state.runID {
            for node in children where node !== boardBackgroundNode && node !== gridNode {
                node.removeAllActions()
                node.removeFromParent()
            }
            tileNodes.removeAll()
            previousActiveID = nil
            lastPowerUpEventToken = -1
            lastRunID = state.runID
        }

        let maxBoardWidth = sceneSize.width
        let maxBoardHeight = sceneSize.height
        cellSize = min(maxBoardWidth / CGFloat(state.board.columns), maxBoardHeight / CGFloat(state.board.rows))

        boardSize = CGSize(
            width: CGFloat(state.board.columns) * cellSize,
            height: CGFloat(state.board.rows) * cellSize
        )

        let geometryKey = "\(ArcadeTheme.appearanceKey)|\(state.board.rows)x\(state.board.columns)|\(Int(cellSize * 100))"
        if geometryKey != lastGeometryKey {
            drawBoardBackground()
            drawGrid(board: state.board)
            lastGeometryKey = geometryKey
        }

        if reduceMotion {
            // Also stop effects already running when the preference changes.
            for node in children where node !== boardBackgroundNode && node !== gridNode {
                if let tile = node as? TileNode, tileNodes.values.contains(where: { $0 === tile }) {
                    tile.removeAllActions()
                    tile.setScale(1)
                    tile.zRotation = 0
                    tile.alpha = 1
                } else {
                    node.removeAllActions()
                    node.removeFromParent()
                }
            }
        }

        let powerUpChanged = state.powerUpEventToken != lastPowerUpEventToken
        lastPowerUpEventToken = state.powerUpEventToken
        if !reduceMotion, powerUpChanged, let activation = state.lastPowerUpActivation {
            switch activation.type {
            case .rowClear:
                if let row = activation.row { playRowClearSweep(row: row) }
            case .columnClear:
                if let column = activation.column { playColumnClearSweep(column: column) }
            case .reorder:
                playReorderHint()
            }
        }

        var tiles: [UUID: (position: GridPosition, kind: TileKind, isActive: Bool)] = [:]
        for position in state.board.allOccupiedPositions() {
            guard let cell = state.board.cell(at: position) else { continue }
            tiles[cell.id] = (position, cell.kind, false)
        }
        if let active = state.activePiece {
            tiles[active.id] = (active.position, active.kind, true)
        }

        let highlightDuration = state.gameMode == .beginner ? VisualTiming.beginnerHighlight : VisualTiming.expertHighlight
        let clearDuration = VisualTiming.clearDuration

        for (id, node) in tileNodes where tiles[id] == nil {
            tileNodes.removeValue(forKey: id)
            if reduceMotion {
                node.removeAllActions()
                node.removeFromParent()
                continue
            }
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

        for (id, tile) in tiles {
            let position = tile.position
            let kind = tile.kind
            let isActive = tile.isActive
            let point = pointFor(position: position)
            if let node = tileNodes[id] {
                let wasActive = previousActiveID == id
                node.update(kind: kind, size: cellSize * 0.92, isActive: isActive, reduceMotion: reduceMotion)
                if reduceMotion {
                    node.position = point
                } else if node.position != point {
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
                if !reduceMotion, wasActive, !isActive {
                    // Lock feedback: tiny settle animation, no board shake.
                    node.run(SKAction.sequence([
                        SKAction.scale(to: 0.97, duration: 0.05),
                        SKAction.scale(to: 1.02, duration: 0.06),
                        SKAction.scale(to: 1.0, duration: 0.04)
                    ]))
                }
            } else {
                let node = TileNode(kind: kind, size: cellSize * 0.92, isActive: isActive, reduceMotion: reduceMotion)
                node.name = id.uuidString
                node.position = point
                node.alpha = reduceMotion ? 1 : 0
                node.setScale(reduceMotion ? 1 : 0.82)
                addChild(node)
                tileNodes[id] = node
                node.removeAction(forKey: "move")
                if !reduceMotion {
                    node.run(
                        SKAction.group([
                            SKAction.fadeIn(withDuration: 0.09),
                            SKAction.scale(to: isActive ? 1.03 : 1.0, duration: 0.09)
                        ])
                    )
                }
            }
        }

        previousActiveID = state.activePiece?.id

#if DEBUG
        if Self.enableRenderWarnings, let active = state.activePiece, tileNodes[active.id] == nil {
            print("[RENDER-WARN] active tile node missing at r\(active.position.row)c\(active.position.column)")
        }
#endif
    }

    // Power-up animation hooks for v1 integration points.
    func playRowClearSweep(row: Int) {
        guard row >= 0 else { return }
        let y = pointFor(position: GridPosition(row: row, column: 0)).y
        let width = boardSize.width * 0.92
        let height = max(6, cellSize * 0.22)
        let sweep = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height * 0.5)
        sweep.fillColor = ArcadeTheme.rowSweep
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
        sweep.fillColor = ArcadeTheme.columnSweep
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

        boardBackgroundNode.path = CGPath(rect: rect, transform: nil)
        boardBackgroundNode.fillColor = ArcadeTheme.boardFill
        boardBackgroundNode.strokeColor = .clear
        boardBackgroundNode.lineWidth = 0
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
            line.strokeColor = ArcadeTheme.gridLine
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
            line.strokeColor = ArcadeTheme.gridLine
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


}

private extension SKAction {
    func withTimingMode(_ mode: SKActionTimingMode) -> SKAction {
        timingMode = mode
        return self
    }
}
