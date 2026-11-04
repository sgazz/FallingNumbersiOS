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
    @Test
    func repeatedNumbersKeepTheirOwnNodesAfterGravity() throws {
        var state = GameState.initial(config: GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10))
        let upper = Cell(value: 5)
        let lower = Cell(value: 5)
        state.board.setCell(upper, at: GridPosition(row: 2, column: 1))
        state.board.setCell(lower, at: GridPosition(row: 5, column: 1))
        let board = BoardNode()
        let size = CGSize(width: 200, height: 400)
        board.render(state: state, sceneSize: size)
        let upperNode = try #require(board.childNode(withName: upper.id.uuidString))
        let lowerNode = try #require(board.childNode(withName: lower.id.uuidString))
        state.board.setCell(nil, at: GridPosition(row: 5, column: 1))
        var gravity = GravitySystem()
        gravity.collapse(board: &state.board)
        board.render(state: state, sceneSize: size)

        #expect(state.board.cell(at: GridPosition(row: 5, column: 1))?.id == upper.id)
        #expect(board.childNode(withName: upper.id.uuidString) === upperNode)
        #expect(lowerNode.name == "clearing_snapshot")
        #expect(board.childNode(withName: lower.id.uuidString) == nil)
    }

    @Test
    func lockingPreservesTileIdentityAndCreatesDistinctNextTile() throws {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var state = GameState.initial(config: config)
        let piece = FallingPiece(value: 8, position: GridPosition(row: 0, column: 1))
        state.activePiece = piece
        var engine = GameEngine(state: state, config: config)
        engine.send(.hardDrop)
        #expect(engine.state.board.cell(at: GridPosition(row: 5, column: 1))?.id == piece.id)
        #expect(try #require(engine.state.activePiece).id != piece.id)
    }

    @Test
    func newRunRemovesOldNodesAndClearSnapshotsImmediately() {
        let config = GameConfig(columns: 4, rows: 6, tickInterval: 0.65, baseTargetNumber: 10)
        var first = GameState.initial(config: config)
        let cell = Cell(value: 5)
        first.board.setCell(cell, at: GridPosition(row: 5, column: 1))
        let board = BoardNode()
        let size = CGSize(width: 200, height: 400)
        board.render(state: first, sceneSize: size)
        first.board.setCell(nil, at: GridPosition(row: 5, column: 1))
        board.render(state: first, sceneSize: size)
        #expect(board.childNode(withName: "clearing_snapshot") != nil)
        let second = GameState.initial(config: config)
        board.render(state: second, sceneSize: size)
        #expect(board.childNode(withName: "clearing_snapshot") == nil)
        #expect(board.children.compactMap { $0 as? TileNode }.isEmpty)
    }

    @Test
    func reorderPreservesNumberTileIdentities() {
        var state = GameState.initial(config: .default)
        let first = Cell(value: 7)
        let second = Cell(value: 2)
        state.board.setCell(first, at: GridPosition(row: 14, column: 0))
        state.board.setCell(second, at: GridPosition(row: 14, column: 1))
        let powerUp = GridPosition(row: 14, column: 2)
        state.board.setCell(Cell(kind: .reorder), at: powerUp)
        PowerUpSystem.activateReorder(state: &state, at: powerUp)
        #expect(state.board.cell(at: GridPosition(row: 14, column: 0))?.id == second.id)
        #expect(state.board.cell(at: GridPosition(row: 14, column: 1))?.id == first.id)
    }

    @Test(arguments: [GameMode.beginner, GameMode.expert])
    func boardUsesFullViewportWithoutBorderOrInset(mode: GameMode) throws {
        let state = GameState.initial(config: .default, mode: mode)
        let size = CGSize(width: state.board.columns * 40, height: state.board.rows * 40)
        let board = BoardNode()
        board.render(state: state, sceneSize: size)
        let background = try #require(board.children.compactMap { $0 as? SKShapeNode }.first)
        let rect = try #require(background.path).boundingBox
        #expect(rect.size == size)
        #expect(rect.origin == CGPoint(x: -size.width / 2, y: -size.height / 2))
        #expect(background.lineWidth == 0)
        #expect(background.strokeColor.cgColor.alpha == 0)
    }

}
