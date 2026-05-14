import SpriteKit

final class BoardNode: SKNode {
    private var tileNodes: [GridPosition: TileNode] = [:]
    private let boardBackgroundNode = SKShapeNode()
    private let gridNode = SKNode()
    private var cellSize: CGFloat = 0
    private var boardSize: CGSize = .zero
    private var previousActivePositions: Set<GridPosition> = []

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

        drawBoardBackground()
        drawGrid(board: state.board)

        let occupied = Set(state.board.allOccupiedPositions())
        var needed = occupied
        if let active = state.activePiece {
            needed.insert(active.position)
        }
        let activePosition = state.activePiece?.position

        for (position, node) in tileNodes where !needed.contains(position) {
            tileNodes.removeValue(forKey: position)
            node.run(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.fadeOut(withDuration: 0.09),
                        SKAction.scale(to: 0.78, duration: 0.09)
                    ]),
                    SKAction.removeFromParent()
                ])
            )
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
                    node.run(SKAction.move(to: point, duration: 0.07), withKey: "move")
                }
                if wasActive, !isActive {
                    node.run(SKAction.sequence([
                        SKAction.scale(to: 1.05, duration: 0.05),
                        SKAction.scale(to: 1.0, duration: 0.07)
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
                        SKAction.fadeIn(withDuration: 0.08),
                        SKAction.scale(to: isActive ? 1.04 : 1.0, duration: 0.08)
                    ])
                )
            }
        }

        if let activePosition {
            previousActivePositions = [activePosition]
        } else {
            previousActivePositions.removeAll()
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
}
