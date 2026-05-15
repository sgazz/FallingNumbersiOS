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
    private var cachedValue: Int?
    private var cachedSize: CGFloat = 0
    private var cachedIsActive: Bool = false

    init(value: Int, size: CGFloat, isActive: Bool) {
        super.init()

        addChild(shadowNode)
        addChild(shapeNode)
        addChild(labelShadowNode)
        addChild(labelNode)

        labelShadowNode.verticalAlignmentMode = .center
        labelShadowNode.horizontalAlignmentMode = .center
        labelShadowNode.fontColor = UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 0.28)
        labelShadowNode.zPosition = 1.8

        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        labelNode.fontColor = UIColor(red: 0.15, green: 0.09, blue: 0.06, alpha: 0.98)
        labelNode.zPosition = 2

        update(value: value, size: size, isActive: isActive)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func update(value: Int, size: CGFloat, isActive: Bool) {
        let valueChanged = cachedValue != value
        let sizeChanged = abs(cachedSize - size) > 0.001
        let activeChanged = cachedIsActive != isActive

        guard valueChanged || sizeChanged || activeChanged else { return }

        cachedValue = value
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
        shapeNode.fillColor = NeonTheme.tileColor(for: value)
        shapeNode.strokeColor = NeonTheme.tileStroke
        shapeNode.lineWidth = max(1.2, size * 0.036)
        shapeNode.glowWidth = isActive ? size * 0.045 : size * 0.03

        if activeChanged {
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
        labelNode.text = "\(value)"
        labelNode.fontName = "AvenirNext-Bold"
        labelNode.fontSize = labelSize
        labelNode.position = .zero

        labelShadowNode.text = "\(value)"
        labelShadowNode.fontName = "AvenirNext-Bold"
        labelShadowNode.fontSize = labelSize
        labelShadowNode.position = CGPoint(x: 0, y: -size * 0.016)
#if DEBUG
        if Self.enableTileLabelLogs, isActive {
            print("DEBUG tile label: value=\(value) size=\(Int(size)) font=\(Int(labelSize)) pos=(\(Int(labelNode.position.x)),\(Int(labelNode.position.y)))")
        }
#endif
    }
}
