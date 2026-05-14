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
        VStack(spacing: 5) {
            HStack(spacing: 7) {
                secondaryChip(title: "Score", value: "\(score)")
                    .accessibilityLabel("Score \(score)")
                secondaryChip(title: "Best", value: "\(highScore)")
                    .accessibilityLabel("High score \(highScore)")
            }

            primaryTargetCard
                .scaleEffect(targetPulsing ? 1.07 : 1.0)
                .animation(.easeOut(duration: 0.2), value: targetPulsing)
                .accessibilityLabel("Target number \(target)")

            HStack(spacing: 7) {
                tertiaryChip(title: "Level", value: "\(level)")
                    .accessibilityLabel("Level \(level)")
                tertiaryChip(title: "Combo", value: "\(combo)")
                    .accessibilityLabel("Combo \(combo)")
                tertiaryChip(title: "Next", value: "\(next)")
                    .accessibilityLabel("Next piece \(next)")
            }
        }
    }

    private var primaryTargetCard: some View {
        VStack(spacing: 3) {
            Text("TARGET")
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.82))
            Text("\(target)")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.42))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
        )
    }

    private func secondaryChip(title: String, value: String) -> some View {
        chip(title: title, value: value, valueFont: .headline.weight(.bold))
    }

    private func tertiaryChip(title: String, value: String) -> some View {
        chip(title: title, value: value, valueFont: .subheadline.weight(.semibold))
    }

    private func chip(title: String, value: String, valueFont: Font) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.74))
            Text(value)
                .font(valueFont)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.32))
        )
    }
}
