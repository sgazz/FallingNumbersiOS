import SpriteKit
import UIKit

final class TileNode: SKNode {
#if DEBUG
    // Local diagnostics toggle for TileNode label layout.
    // Keep false by default to avoid noisy logs.
    private static let enableTileLabelLogs = false
#endif

    private let shadowNode = SKShapeNode()
    private let shapeNode = SKShapeNode()
    private let labelShadowNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let labelNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var cachedKind: TileKind?
    private var cachedSize: CGFloat = 0
    private var cachedIsActive: Bool = false

    init(kind: TileKind, size: CGFloat, isActive: Bool) {
        super.init()

        addChild(shadowNode)
        addChild(shapeNode)
        addChild(labelShadowNode)
        addChild(labelNode)

        labelShadowNode.verticalAlignmentMode = .center
        labelShadowNode.horizontalAlignmentMode = .center
        labelShadowNode.fontColor = UIColor(red: 0.08, green: 0.10, blue: 0.18, alpha: 0.45)
        labelShadowNode.zPosition = 1.8

        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        labelNode.fontColor = UIColor(red: 0.99, green: 0.99, blue: 1.0, alpha: 0.98)
        labelNode.zPosition = 2

        update(kind: kind, size: size, isActive: isActive)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func update(kind: TileKind, size: CGFloat, isActive: Bool) {
        let valueChanged = cachedKind != kind
        let sizeChanged = abs(cachedSize - size) > 0.001
        let activeChanged = cachedIsActive != isActive

        guard valueChanged || sizeChanged || activeChanged else { return }

        cachedKind = kind
        cachedSize = size
        cachedIsActive = isActive

        let rect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
        let roundedPath = CGPath(
            roundedRect: rect,
            cornerWidth: size * 0.2,
            cornerHeight: size * 0.2,
            transform: nil
        )

        shadowNode.path = roundedPath
        shadowNode.fillColor = UIColor(red: 0.21, green: 0.13, blue: 0.09, alpha: 0.18)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(x: 0, y: -size * 0.05)

        shapeNode.path = roundedPath
        shapeNode.fillColor = NeonTheme.tileColor(for: kind)
        shapeNode.strokeColor = NeonTheme.tileStroke
        shapeNode.lineWidth = max(1.2, size * 0.036)
        shapeNode.glowWidth = isActive ? size * 0.045 : size * 0.03

        if activeChanged {
            removeAction(forKey: "activeScale")
            if isActive {
                shapeNode.alpha = 1.0
                run(SKAction.scale(to: 1.035, duration: 0.08), withKey: "activeScale")
            } else {
                shapeNode.alpha = 0.94
                run(SKAction.scale(to: 1.0, duration: 0.08), withKey: "activeScale")
            }
        } else {
            shapeNode.alpha = isActive ? 1.0 : 0.94
        }

        let labelSize = size * (isActive ? 0.72 : 0.68)
        labelNode.text = kind.displayText
        labelNode.fontName = "AvenirNext-Bold"
        labelNode.fontSize = labelSize
        labelNode.position = .zero

        labelShadowNode.text = kind.displayText
        labelShadowNode.fontName = "AvenirNext-Bold"
        labelShadowNode.fontSize = labelSize
        labelShadowNode.position = CGPoint(x: 0, y: -size * 0.016)
#if DEBUG
        if Self.enableTileLabelLogs, isActive {
            print("DEBUG tile label: kind=\(kind.debugName) size=\(Int(size)) font=\(Int(labelSize)) pos=(\(Int(labelNode.position.x)),\(Int(labelNode.position.y)))")
        }
#endif
    }

    func runClearAnimationAndRemove(highlightDuration: TimeInterval, clearDuration: TimeInterval) {
        removeAction(forKey: "move")
        removeAction(forKey: "activeScale")
        shapeNode.removeAllActions()
        labelNode.removeAllActions()
        labelShadowNode.removeAllActions()

        let warmOverlay: SKShapeNode? = {
            guard let path = shapeNode.path else { return nil }
            let overlay = SKShapeNode(path: path)
            overlay.fillColor = UIColor(red: 1.0, green: 0.82, blue: 0.42, alpha: 0.0)
            overlay.strokeColor = .clear
            overlay.zPosition = shapeNode.zPosition + 0.2
            addChild(overlay)
            return overlay
        }()

        let highlightPulse = SKAction.group([
            SKAction.sequence([
                SKAction.scale(to: 1.04, duration: highlightDuration * 0.45),
                SKAction.scale(to: 1.0, duration: highlightDuration * 0.55)
            ]),
            SKAction.run { [weak self] in
                self?.labelNode.alpha = 1.0
                self?.labelShadowNode.alpha = 1.0
                self?.shapeNode.glowWidth = (self?.cachedSize ?? 0) * 0.065
            }
        ])
        let warmPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.42, duration: highlightDuration * 0.6),
            SKAction.fadeOut(withDuration: clearDuration)
        ])

        warmOverlay?.run(SKAction.sequence([warmPulse, .removeFromParent()]))

        run(SKAction.sequence([
            highlightPulse,
            SKAction.group([
                SKAction.scale(to: 1.08, duration: clearDuration * 0.45),
                SKAction.fadeAlpha(to: 0.22, duration: clearDuration * 0.7)
            ]),
            SKAction.group([
                SKAction.scale(to: 0.9, duration: clearDuration * 0.55),
                SKAction.fadeOut(withDuration: clearDuration * 0.55)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}
