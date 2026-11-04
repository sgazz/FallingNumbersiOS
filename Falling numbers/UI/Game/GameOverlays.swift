import SwiftUI

struct GameOverlays: View {
    enum Kind { case start, pause, gameOver }
    @ObservedObject var viewModel: GameScreenViewModel
    var kind: Kind
    var onMainMenu: (() -> Void)?
    var onSettings: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ArcadeTheme.overlayScrim.ignoresSafeArea()
                ScrollView {
                    VStack {
                        switch kind {
                        case .start: startOverlay
                        case .pause: pauseOverlay
                        case .gameOver: gameOverOverlay
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - 32))
                    .padding(.vertical, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .transaction { transaction in
            if reduceMotion {
                transaction.animation = nil
            }
        }
    }

    @ViewBuilder
    private var startOverlay: some View {
        VStack(spacing: 12) {
            Text("Fall, Number… Fall!")
                .font(.title.bold())
                .foregroundStyle(ArcadeTheme.textPrimary)
            Text("Make horizontal or vertical sums to match the target.")
                .font(.subheadline)
                .foregroundStyle(ArcadeTheme.textSecondary)
            startLineHint
            Button("Play", action: viewModel.startGameFromOverlay)
                .buttonStyle(.borderedProminent)
                .tint(ArcadeTheme.controlsTint)
                .accessibilityLabel("Start game")
        }
        .padding(22)
        .background(ArcadeTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .frame(maxWidth: 320)
        .scaleEffect(0.985)
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(ArcadeTheme.cardStroke, lineWidth: 1)
        }
    }

    private var startLineHint: some View {
        HStack(spacing: 8) {
            hintChip("4")
            Text("+")
                .font(.footnote.weight(.bold))
                .foregroundStyle(ArcadeTheme.textSecondary)
            hintChip("6")
            Text("=")
                .font(.footnote.weight(.bold))
                .foregroundStyle(ArcadeTheme.textSecondary)
            hintChip("10")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example line sum, four plus six equals ten.")
    }

    private func hintChip(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.bold))
            .foregroundStyle(ArcadeTheme.textPrimary)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(ArcadeTheme.chipFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ArcadeTheme.chipStroke, lineWidth: 0.8)
            )
    }

    @ViewBuilder
    private var pauseOverlay: some View {
        VStack(spacing: 14) {
            Text("Paused")
                .font(.title2.bold())
                .foregroundStyle(ArcadeTheme.textPrimary)

            VStack(spacing: 10) {
                pauseActionButton(
                    title: "Resume",
                    style: .primary,
                    action: viewModel.togglePause
                )

                pauseActionButton(
                    title: "Settings",
                    style: .secondary
                ) {
                    onSettings()
                }

                pauseActionButton(
                    title: "New Game",
                    style: .secondary,
                    action: viewModel.newGame
                )

                if let onMainMenu {
                    pauseActionButton(
                        title: "Main Menu",
                        style: .secondary
                    ) {
                        onMainMenu()
                    }
                }
            }
            .frame(maxWidth: 260)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background(ArcadeTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(ArcadeTheme.cardStroke, lineWidth: 1)
        }
        .frame(maxWidth: 320)
    }

    private enum PauseButtonStyleKind {
        case primary
        case secondary
    }

    private func pauseActionButton(
        title: String,
        style: PauseButtonStyleKind,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(style == .primary ? Color.white : ArcadeTheme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(style == .primary ? AnyShapeStyle(ArcadeTheme.buttonFill) : AnyShapeStyle(ArcadeTheme.chipFill))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style == .primary ? Color.white.opacity(0.26) : ArcadeTheme.chipStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var gameOverOverlay: some View {
        VStack(spacing: 14) {
            Text("Game Over")
                .font(.title.bold())
                .foregroundStyle(ArcadeTheme.textPrimary)

            VStack(spacing: 8) {
                Text("Final Score")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(ArcadeTheme.textSecondary)
                Text("\(viewModel.state.score)")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(ArcadeTheme.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("Best \(viewModel.highScore)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ArcadeTheme.textSecondary)
                if viewModel.didSetNewBestInRun || viewModel.isNewBestForCurrentGameOver {
                    Text("New Best!")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(ArcadeTheme.controlsTint)
                }
                Text("Mode: \(viewModel.state.gameMode.title)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(ArcadeTheme.textSecondary)
            }
            .padding(.vertical, 4)

            VStack(spacing: 6) {
                recapRow(title: "Lines Cleared", value: "\(viewModel.state.linesCleared)")
                recapRow(title: "Perfect Clears", value: "\(viewModel.state.perfectClearsCount)")
                if viewModel.showsCascadeHUD {
                    recapRow(title: "Highest Cascade", value: "×\(max(1, viewModel.state.highestCascade))")
                }
                recapRow(title: "Longest Line", value: "\(viewModel.state.longestLineCleared)")
                recapRow(title: "Game Over Reason", value: gameOverReasonLabel)
            }
            .padding(10)
            .background(ArcadeTheme.chipFill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ArcadeTheme.chipStroke, lineWidth: 0.8)
            )

            VStack(spacing: 10) {
                pauseActionButton(
                    title: "Retry",
                    style: .primary,
                    action: viewModel.newGame
                )

                if let onMainMenu {
                    pauseActionButton(
                        title: "Main Menu",
                        style: .secondary
                    ) {
                        viewModel.triggerButtonTapSound()
                        onMainMenu()
                    }
                }

                pauseActionButton(
                    title: "Settings",
                    style: .secondary
                ) {
                    viewModel.triggerButtonTapSound()
                    onSettings()
                }
            }
            .frame(maxWidth: 260)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background(ArcadeTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(ArcadeTheme.cardStroke, lineWidth: 1)
        }
        .frame(maxWidth: 320)
    }

    private func recapRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(ArcadeTheme.textSecondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.footnote.weight(.heavy))
                .foregroundStyle(ArcadeTheme.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }

    private var gameOverReasonLabel: String {
        switch viewModel.state.telemetry.gameOverReason {
        case .columnFilledToTop: return "Board reached the top"
        case .spawnBlocked: return "No space to spawn"
        case .unknown, .none: return "Unknown"
        }
    }

}
