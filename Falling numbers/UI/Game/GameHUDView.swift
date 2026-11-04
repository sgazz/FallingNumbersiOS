import SwiftUI

enum GameHUDMetrics {
    static let height: CGFloat = 92
}

struct GameHUDView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    var scorePulse: Bool
    var cascadePulse: Bool
    var targetPulse: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title3) private var scoreFontSize: CGFloat = 25
    @ScaledMetric(relativeTo: .title3) private var targetFontSize: CGFloat = 25
    @ScaledMetric(relativeTo: .title3) private var nextFontSize: CGFloat = 24

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text("\(viewModel.state.gameMode.title.uppercased())  /  LEVEL \(viewModel.state.level)")
                    .accessibilityLabel("\(viewModel.state.gameMode.title), Level \(viewModel.state.level)")
                Spacer(minLength: 4)
                if viewModel.showsCascadeHUD {
                    Text("Cascade ×\(max(1, viewModel.state.cascadeCount))")
                        .scaleEffect(!reduceMotion && cascadePulse ? 1.04 : 1)
                        .accessibilityLabel("Cascade \(max(1, viewModel.state.cascadeCount))")
                } else {
                    Text("Time \(viewModel.state.formattedActivePlayTime)")
                        .accessibilityLabel("Play time \(viewModel.state.formattedActivePlayTime)")
                }
            }
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .tracking(1)
            .foregroundStyle(ArcadeTheme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    caption("NEXT LEVEL")
                    Spacer(minLength: 4)
                    Text("\(Int((viewModel.levelProgress * 100).rounded()))%")
                        .font(.system(size: 7, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(ArcadeTheme.textSecondary)
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ArcadeTheme.ink.opacity(0.08))
                        Capsule()
                            .fill(ArcadeTheme.accentPrimary)
                            .frame(width: proxy.size.width * viewModel.levelProgress)
                    }
                }
                .frame(height: 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Level progress \(Int((viewModel.levelProgress * 100).rounded())) percent")
            }

            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    caption("SCORE")
                    Text("\(viewModel.state.score)")
                        .font(.system(size: scoreFontSize, weight: .heavy, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)
                        .contentTransition(.numericText())
                        .scaleEffect(!reduceMotion && scorePulse ? 1.03 : 1)
                        .accessibilityLabel("Score \(viewModel.state.score)")
                    Text("Best \(viewModel.highScore)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(ArcadeTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .accessibilityLabel("High score \(viewModel.highScore)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle().stroke(ArcadeTheme.ink.opacity(0.08), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: viewModel.targetTimerProgress)
                        .stroke(ArcadeTheme.accentSecondary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        caption("TARGET")
                        Text("\(viewModel.state.targetNumber)")
                            .font(.system(size: targetFontSize, weight: .heavy, design: .rounded))
                            .contentTransition(.numericText())
                        Text(viewModel.state.formattedTargetChangeCountdown)
                            .font(.system(size: 8, weight: .medium, design: .rounded).monospacedDigit())
                            .foregroundStyle(ArcadeTheme.textSecondary)
                    }
                }
                .frame(width: 62, height: 62)
                .scaleEffect(!reduceMotion && targetPulse ? 1.04 : 1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Target \(viewModel.state.targetNumber), changes in \(viewModel.state.formattedTargetChangeCountdown)")

                HStack(spacing: 10) {
                    VStack(spacing: 3) {
                        caption("NEXT")
                        Text(viewModel.state.nextPieceDisplayText)
                            .font(.system(size: nextFontSize, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Color(ArcadeTheme.tileColor(for: viewModel.state.nextPieceKind)),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                            .accessibilityLabel("Next piece \(viewModel.state.nextPieceDisplayText)")
                    }
                    Button(action: viewModel.togglePause) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(ArcadeTheme.ink)
                            .frame(width: 44, height: 44)
                            .background(ArcadeTheme.cardFill, in: Circle())
                    }
                    .accessibilityLabel(viewModel.state.isPaused ? "Resume game" : "Pause game")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .foregroundStyle(ArcadeTheme.textPrimary)
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 7, weight: .heavy, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(ArcadeTheme.textSecondary)
            .accessibilityHidden(true)
    }
}
