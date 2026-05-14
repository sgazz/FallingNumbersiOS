import SwiftUI
import SpriteKit

struct SpriteKitRenderer: UIViewRepresentable {
    @Binding var state: GameState

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.allowsTransparency = true

        let scene = GameScene(size: CGSize(width: 320, height: 640))
        scene.scaleMode = .resizeFill
        view.presentScene(scene)

        context.coordinator.scene = scene
        scene.render(state: state)

        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // Rendering boundary: SpriteKit only mirrors immutable engine state.
        // It never mutates gameplay logic and skips redundant redraws by signature.
        let signature = context.coordinator.makeSignature(for: state)
        guard signature != context.coordinator.lastSignature else { return }
        context.coordinator.lastSignature = signature
        context.coordinator.scene?.render(state: state)
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
                    let value = state.board.cell(at: position)?.value ?? 0
                    return "\(position.row):\(position.column):\(value)"
                }
                .joined(separator: ",")

            let active = state.activePiece.map { "\($0.position.row):\($0.position.column):\($0.value)" } ?? "none"
            return "\(occupied)|a:\(active)|lvl:\(state.level)|t:\(state.targetNumber)|p:\(state.isPaused)|g:\(state.isGameOver)"
        }
    }
}
