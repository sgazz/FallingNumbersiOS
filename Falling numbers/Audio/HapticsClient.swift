import Foundation
import UIKit

protocol HapticsClient {
    func moved()
    func pieceLocked()
    func cleared(combo: Int)
    func perfectClear()
    func gameOver()
}

struct NoopHapticsClient: HapticsClient {
    func moved() {}
    func pieceLocked() {}
    func cleared(combo: Int) {}
    func perfectClear() {}
    func gameOver() {}
}

@MainActor
final class UIKitHapticsClient: HapticsClient {
    private let moveGenerator = UIImpactFeedbackGenerator(style: .light)
    private let lockGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let clearGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let comboGenerator = UINotificationFeedbackGenerator()
    private let gameOverGenerator = UINotificationFeedbackGenerator()

    init() {
        moveGenerator.prepare()
        lockGenerator.prepare()
        clearGenerator.prepare()
        comboGenerator.prepare()
        gameOverGenerator.prepare()
    }

    func moved() {
        moveGenerator.impactOccurred(intensity: 0.6)
        moveGenerator.prepare()
    }

    func pieceLocked() {
        lockGenerator.impactOccurred(intensity: 0.9)
        lockGenerator.prepare()
    }

    func cleared(combo: Int) {
        if combo >= 3 {
            comboGenerator.notificationOccurred(.success)
            comboGenerator.prepare()
            return
        }
        clearGenerator.impactOccurred(intensity: 0.95)
        clearGenerator.prepare()
    }

    func perfectClear() {
        comboGenerator.notificationOccurred(.success)
        comboGenerator.prepare()
    }

    func gameOver() {
        gameOverGenerator.notificationOccurred(.warning)
        gameOverGenerator.prepare()
    }
}
