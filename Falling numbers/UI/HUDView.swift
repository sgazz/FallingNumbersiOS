import SwiftUI

struct HUDView: View {
    let score: Int
    let highScore: Int
    let target: Int
    let level: Int
    let combo: Int
    let next: Int
    let targetPulsing: Bool

    var body: some View {
        HStack(spacing: 12) {
            stat(title: "Score", value: "\(score)")
            stat(title: "Best", value: "\(highScore)")
            stat(title: "Target", value: "\(target)")
                .scaleEffect(targetPulsing ? 1.07 : 1.0)
                .animation(.easeOut(duration: 0.2), value: targetPulsing)
            stat(title: "Level", value: "\(level)")
            stat(title: "Combo", value: "\(combo)")
            stat(title: "Next", value: "\(next)")
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}
