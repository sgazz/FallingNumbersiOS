import Testing
import CoreGraphics
import Foundation
import SpriteKit
@testable import Falling_numbers

@MainActor
struct RenderingTests {
    @Test
    @MainActor
    func sceneResizesBoardWithoutGameplayChange() throws {
        let scene = GameScene(size: CGSize(width: 320, height: 640))
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        view.presentScene(scene)
        var state = GameState.initial(config: .default)
        state.isPaused = true
        scene.render(state: state)
        let board = try #require(scene.children.compactMap { $0 as? BoardNode }.first)
        let background = try #require(board.children.compactMap { $0 as? SKShapeNode }.first)
        let oldWidth = try #require(background.path).boundingBox.width

        scene.size = CGSize(width: 200, height: 400)

        #expect(board.position == CGPoint(x: 100, y: 200))
        let newWidth = try #require(background.path).boundingBox.width
        #expect(newWidth < oldWidth)
        #expect(abs(newWidth / oldWidth - 0.625) < 0.001)
    }
}
