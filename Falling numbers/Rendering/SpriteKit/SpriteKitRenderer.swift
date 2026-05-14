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
        context.coordinator.scene?.render(state: state)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var scene: GameScene?
    }
}
