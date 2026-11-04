import SwiftUI
import SpriteKit

struct SpriteKitRenderer: UIViewRepresentable {
    @Binding var state: GameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.allowsTransparency = true

        let scene = GameScene(size: CGSize(width: 320, height: 640))
        scene.scaleMode = .resizeFill
        view.presentScene(scene)

        context.coordinator.scene = scene
        scene.render(state: state, reduceMotion: reduceMotion)

        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // Rendering boundary: SpriteKit only mirrors immutable engine state.
        // It never mutates gameplay logic and skips redundant redraws by signature.
        let signature = context.coordinator.makeSignature(for: state) + "|rm:\(reduceMotion)"
        guard signature != context.coordinator.lastSignature else { return }
        context.coordinator.lastSignature = signature
        context.coordinator.scene?.render(state: state, reduceMotion: reduceMotion)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var scene: GameScene?
        var lastSignature: String?

        func makeSignature(for state: GameState) -> String {
            let occupied = state.board
                .allOccupiedPositions()
                .sorted { lhs, rhs in
                    if lhs.row != rhs.row { return lhs.row < rhs.row }
                    return lhs.column < rhs.column
                }
                .map { position in
                    let cell = state.board.cell(at: position)
                    return "\(cell?.id.uuidString ?? "none"):\(position.row):\(position.column):\(cell?.kind.displayText ?? ".")"
                }
                .joined(separator: ",")

            let active = state.activePiece.map { "\($0.id.uuidString):\($0.position.row):\($0.position.column):\($0.kind.displayText)" } ?? "none"
            let colorBlindMode = UserDefaults.standard.bool(forKey: "falling_numbers_color_blind_enabled")
            return "\(state.runID.uuidString)|\(occupied)|a:\(active)|lvl:\(state.level)|t:\(state.targetNumber)|p:\(state.isPaused)|g:\(state.isGameOver)|pu:\(state.powerUpEventToken)|cb:\(colorBlindMode)"
        }
    }
}

final class GameScene: SKScene {
    private var boardNode: BoardNode?
    private var latestState: GameState?
    private var reduceMotion = false

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

    func render(state: GameState, reduceMotion: Bool = false) {
        self.reduceMotion = reduceMotion
        latestState = state
        refreshBoardGeometry()
    }

    private func refreshBoardGeometry() {
        boardNode?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        if let latestState {
            boardNode?.render(state: latestState, sceneSize: size, reduceMotion: reduceMotion)
        }
    }
}
