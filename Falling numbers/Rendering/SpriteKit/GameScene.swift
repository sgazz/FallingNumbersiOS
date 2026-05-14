import SpriteKit

final class GameScene: SKScene {
    private var boardNode: BoardNode?

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill

        let boardNode = BoardNode()
        addChild(boardNode)
        self.boardNode = boardNode
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        boardNode?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
    }

    func render(state: GameState) {
        boardNode?.render(state: state, sceneSize: size)
    }
}
