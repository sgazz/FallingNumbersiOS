import SpriteKit

final class TileNode: SKNode {
    private let shadowNode = SKShapeNode()
    private let shapeNode = SKShapeNode()
    private let labelNode = SKLabelNode(fontNamed: "AvenirNext-Heavy")

    init(value: Int, size: CGFloat, isActive: Bool) {
        super.init()

        addChild(shadowNode)
        addChild(shapeNode)
        addChild(labelNode)

        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        labelNode.fontColor = .white
        labelNode.zPosition = 2

        update(value: value, size: size, isActive: isActive)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func update(value: Int, size: CGFloat, isActive: Bool) {
        let rect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
        let roundedPath = CGPath(
            roundedRect: rect,
            cornerWidth: size * 0.2,
            cornerHeight: size * 0.2,
            transform: nil
        )

        shadowNode.path = roundedPath
        shadowNode.fillColor = UIColor.black.withAlphaComponent(0.28)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(x: 0, y: -size * 0.05)

        shapeNode.path = roundedPath
        shapeNode.fillColor = NeonTheme.tileColor(for: value)
        shapeNode.strokeColor = NeonTheme.tileStroke
        shapeNode.lineWidth = max(1.2, size * 0.04)
        shapeNode.glowWidth = isActive ? size * 0.26 : size * 0.15

        if isActive {
            shapeNode.alpha = 1.0
            run(SKAction.scale(to: 1.04, duration: 0.06), withKey: "activeScale")
        } else {
            shapeNode.alpha = 0.94
            run(SKAction.scale(to: 1.0, duration: 0.06), withKey: "activeScale")
        }

        labelNode.text = "\(value)"
        labelNode.fontSize = size * 0.5

        let stroke = NSAttributedString.Key.strokeColor
        let strokeWidth = NSAttributedString.Key.strokeWidth
        let foregroundColor = NSAttributedString.Key.foregroundColor
        labelNode.attributedText = NSAttributedString(
            string: "\(value)",
            attributes: [
                foregroundColor: UIColor.white,
                stroke: UIColor.black.withAlphaComponent(0.65),
                strokeWidth: -3.5
            ]
        )
    }
}
