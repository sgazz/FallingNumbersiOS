import SpriteKit

final class GameScene: SKScene {
    private var boardNode: BoardNode?
    private var latestState: GameState?

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill

        if boardNode == nil {
            let node = BoardNode()
            addChild(node)
            boardNode = node
        }
        refreshBoardGeometry()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        refreshBoardGeometry()
    }

    func render(state: GameState) {
        latestState = state
        refreshBoardGeometry()
    }

    private func refreshBoardGeometry() {
        boardNode?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        if let latestState {
            boardNode?.render(state: latestState, sceneSize: size)
        }
    }
}
