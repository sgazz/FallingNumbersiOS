import SwiftUI

enum GameHUDMetrics {
    static let height: CGFloat = 122
    static let chipWidth: CGFloat = 108
    static let chipHeight: CGFloat = 30
    static let chipSpacing: CGFloat = 4
    static let centerStackSpacing: CGFloat = 1
    static let targetRingSize: CGFloat = 98
    static let targetFontSize: CGFloat = 42
    /// Pull hero into the top safe-area margin; capped so status/notch content stays readable.
    static let topSafeAreaOverlap: CGFloat = 14
    static let topPaddingWithoutSafeArea: CGFloat = 2
}


struct GameHUDView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    var scorePulse: Bool
    var cascadePulse: Bool
    var targetPulse: Bool

    var body: some View {
        let chipWidth = GameHUDMetrics.chipWidth
        let chipHeight = GameHUDMetrics.chipHeight

        return HStack(alignment: .top, spacing: 8) {
            VStack(spacing: GameHUDMetrics.chipSpacing) {
                heroChip(
                    text: "Score \(viewModel.state.score)",
                    style: .score,
                    width: chipWidth,
                    height: chipHeight
                )
                    .scaleEffect(scorePulse ? 1.02 : 1.0)
                    .animation(.easeOut(duration: 0.14), value: scorePulse)
                    .accessibilityLabel("Score \(viewModel.state.score)")

                heroChip(
                    text: "Level \(viewModel.state.level)",
                    style: .level,
                    width: chipWidth,
                    height: chipHeight
                )
                    .accessibilityLabel("Level \(viewModel.state.level)")

                heroChip(
                    text: "Next \(viewModel.state.nextPieceDisplayText)",
                    style: .next,
                    width: chipWidth,
                    height: chipHeight
                )
                    .accessibilityLabel("Next piece \(viewModel.state.nextPieceDisplayText)")
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(spacing: GameHUDMetrics.centerStackSpacing) {
                Text(viewModel.state.formattedTargetChangeCountdown)
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.white.opacity(0.88))
                    .lineLimit(1)

                Text("TARGET")
                    .font(.caption.weight(.heavy))
                    .tracking(1.2)
                    .foregroundStyle(Color.white.opacity(0.95))

                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 1.00, green: 0.73, blue: 0.24),
                                    Color(red: 0.99, green: 0.53, blue: 0.24),
                                    Color(red: 0.98, green: 0.41, blue: 0.65),
                                    Color(red: 0.66, green: 0.41, blue: 0.93),
                                    Color(red: 0.24, green: 0.77, blue: 0.74),
                                    Color(red: 0.23, green: 0.64, blue: 0.98),
                                    Color(red: 1.00, green: 0.73, blue: 0.24)
                                ],
                                center: .center
                            ),
                            lineWidth: 5
                        )
                        .frame(width: GameHUDMetrics.targetRingSize, height: GameHUDMetrics.targetRingSize)
                        .shadow(color: NeonTheme.glowColor.opacity(0.3), radius: 6)

                    Text("\(viewModel.state.targetNumber)")
                        .font(.system(size: GameHUDMetrics.targetFontSize, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white)
                        .minimumScaleFactor(0.75)
                }
                .scaleEffect(targetPulse ? 1.05 : 1.0)
                .animation(.easeOut(duration: 0.2), value: targetPulse)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "Target \(viewModel.state.targetNumber), changes in \(viewModel.state.formattedTargetChangeCountdown)"
            )

            VStack(spacing: GameHUDMetrics.chipSpacing) {
                heroChip(
                    text: "Best \(viewModel.highScore)",
                    style: .best,
                    width: chipWidth,
                    height: chipHeight
                )
                    .accessibilityLabel("High score \(viewModel.highScore)")

                if viewModel.showsCascadeHUD {
                    heroChip(
                        text: "Cascade ×\(max(1, viewModel.state.cascadeCount))",
                        style: .cascade,
                        width: chipWidth,
                        height: chipHeight
                    )
                        .scaleEffect(cascadePulse ? 1.02 : 1.0)
                        .animation(.easeOut(duration: 0.14), value: cascadePulse)
                        .accessibilityLabel("Cascade \(max(1, viewModel.state.cascadeCount))")
                } else {
                    heroChip(
                        text: "Time \(viewModel.state.formattedActivePlayTime)",
                        style: .playTime,
                        width: chipWidth,
                        height: chipHeight
                    )
                        .accessibilityLabel("Play time \(viewModel.state.formattedActivePlayTime)")
                }

                heroPauseChip(width: chipWidth, height: chipHeight)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .topTrailing)
        }
    }

    private func heroChip(text: String, style: HUDChipStyle, width: CGFloat, height: CGFloat) -> some View {
        inlineChip(text: text, style: style, compact: true)
            .frame(width: width, height: height)
    }

    private func heroPauseChip(width: CGFloat, height: CGFloat) -> some View {
        Button {
            viewModel.togglePause()
        } label: {
            heroChip(
                text: "Pause",
                style: .pause,
                width: width,
                height: height
            )
        }
        .accessibilityLabel(viewModel.state.isPaused ? "Resume game" : "Pause game")
    }

    private enum HUDChipStyle {
        case score
        case best
        case level
        case cascade
        case next
        case pause
        case playTime
    }

    private struct HUDChipMetrics {
        let font: Font
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        let cornerRadius: CGFloat
        let strokeLineWidth: CGFloat
        let shadowRadius: CGFloat
        let shadowOpacity: Double
    }

    private func hudChipMetrics(compact: Bool) -> HUDChipMetrics {
        if compact {
            return HUDChipMetrics(
                font: .caption.weight(.semibold),
                horizontalPadding: 8,
                verticalPadding: 2,
                cornerRadius: 9,
                strokeLineWidth: 0.65,
                shadowRadius: 5,
                shadowOpacity: 0.24
            )
        }
        return HUDChipMetrics(
            font: .footnote.weight(.semibold),
            horizontalPadding: 10,
            verticalPadding: 0,
            cornerRadius: 10,
            strokeLineWidth: 0.7,
            shadowRadius: 6,
            shadowOpacity: 0.26
        )
    }

    private func inlineChip(text: String, style: HUDChipStyle, compact: Bool = false) -> some View {
        let metrics = hudChipMetrics(compact: compact)
        let gradient: LinearGradient
        switch style {
        case .score:
            gradient = LinearGradient(
                colors: [Color(red: 0.23, green: 0.64, blue: 0.98), Color(red: 0.28, green: 0.43, blue: 0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .best:
            gradient = LinearGradient(
                colors: [Color(red: 0.54, green: 0.35, blue: 0.92), Color(red: 0.98, green: 0.72, blue: 0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .level:
            gradient = LinearGradient(
                colors: [Color(red: 0.21, green: 0.78, blue: 0.48), Color(red: 0.18, green: 0.60, blue: 0.37)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cascade:
            gradient = LinearGradient(
                colors: [Color(red: 0.98, green: 0.41, blue: 0.65), Color(red: 0.99, green: 0.53, blue: 0.24), Color(red: 0.66, green: 0.41, blue: 0.93)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .next:
            gradient = LinearGradient(
                colors: [Color(red: 0.24, green: 0.77, blue: 0.74), Color(red: 0.47, green: 0.36, blue: 0.89)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pause:
            gradient = LinearGradient(
                colors: [Color(red: 0.36, green: 0.25, blue: 0.73), Color(red: 0.22, green: 0.53, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .playTime:
            gradient = LinearGradient(
                colors: [Color(red: 0.42, green: 0.52, blue: 0.96), Color(red: 0.24, green: 0.36, blue: 0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return Text(text)
            .font(metrics.font)
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.vertical, metrics.verticalPadding)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: metrics.cornerRadius)
                    .fill(gradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: metrics.cornerRadius)
                    .stroke(Color.white.opacity(0.24), lineWidth: metrics.strokeLineWidth)
            )
            .shadow(color: Color.black.opacity(metrics.shadowOpacity), radius: metrics.shadowRadius, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: metrics.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.screen)
            )
    }

}
