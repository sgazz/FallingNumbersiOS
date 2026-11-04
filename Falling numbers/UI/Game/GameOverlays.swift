import SwiftUI

struct GameOverlays: View {
    enum Kind { case start, pause, gameOver }
    @ObservedObject var viewModel: GameScreenViewModel
    var kind: Kind
    var onMainMenu: (() -> Void)?
    var onSettings: () -> Void

    @ViewBuilder
    var body: some View {
        switch kind {
        case .start: startOverlay
        case .pause: pauseOverlay
        case .gameOver: gameOverOverlay
        }
    }

    @ViewBuilder
    private var startOverlay: some View {
        NeonTheme.overlayScrim
            .ignoresSafeArea()

        VStack(spacing: 12) {
            Text("Fall, Number… Fall!")
                .font(.title.bold())
                .foregroundStyle(NeonTheme.textPrimary)
            Text("Make horizontal or vertical sums to match the target.")
                .font(.subheadline)
                .foregroundStyle(NeonTheme.textSecondary)
            startLineHint
            Button("Play", action: viewModel.startGameFromOverlay)
                .buttonStyle(.borderedProminent)
                .tint(NeonTheme.controlsTint)
                .accessibilityLabel("Start game")
        }
        .padding(22)
        .background(NeonTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(0.985)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(NeonTheme.cardStroke, lineWidth: 1)
        }
    }

    private var startLineHint: some View {
        HStack(spacing: 8) {
            hintChip("4")
            Text("+")
                .font(.footnote.weight(.bold))
                .foregroundStyle(NeonTheme.textSecondary)
            hintChip("6")
            Text("=")
                .font(.footnote.weight(.bold))
                .foregroundStyle(NeonTheme.textSecondary)
            hintChip("10")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example line sum, four plus six equals ten.")
    }

    private func hintChip(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.bold))
            .foregroundStyle(NeonTheme.textPrimary)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(NeonTheme.chipFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(NeonTheme.chipStroke, lineWidth: 0.8)
            )
    }

    @ViewBuilder
    private var pauseOverlay: some View {
        NeonTheme.overlayScrim
            .ignoresSafeArea()

        VStack(spacing: 14) {
            Text("Paused")
                .font(.title2.bold())
                .foregroundStyle(NeonTheme.textPrimary)

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
        .padding(.vertical, 24)
        .background(NeonTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(NeonTheme.cardStroke, lineWidth: 1)
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
                .foregroundStyle(style == .primary ? Color.white : NeonTheme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(style == .primary ? AnyShapeStyle(NeonTheme.buttonFill) : AnyShapeStyle(NeonTheme.chipFill))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style == .primary ? Color.white.opacity(0.26) : NeonTheme.chipStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var gameOverOverlay: some View {
        NeonTheme.overlayScrim
            .ignoresSafeArea()

        VStack(spacing: 14) {
            Text("Game Over")
                .font(.title.bold())
                .foregroundStyle(NeonTheme.textPrimary)

            VStack(spacing: 8) {
                Text("Final Score")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(NeonTheme.textSecondary)
                Text("\(viewModel.state.score)")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(NeonTheme.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("Best \(viewModel.highScore)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(NeonTheme.textSecondary)
                if viewModel.didSetNewBestInRun || viewModel.isNewBestForCurrentGameOver {
                    Text("New Best!")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(NeonTheme.controlsTint)
                }
                Text("Mode: \(viewModel.state.gameMode.title)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(NeonTheme.textSecondary)
            }
            .padding(.vertical, 4)

            VStack(spacing: 6) {
                recapRow(title: "Lines Cleared", value: "\(viewModel.state.linesCleared)")
                recapRow(title: "Perfect Clears", value: "\(viewModel.state.perfectClearsCount)")
                if viewModel.showsCascadeHUD {
                    recapRow(title: "Highest Cascade", value: "×\(max(1, viewModel.state.highestCascade))")
                }
                recapRow(title: "Longest Line", value: "\(viewModel.state.longestLineCleared)")
            }
            .padding(10)
            .background(NeonTheme.chipFill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(NeonTheme.chipStroke, lineWidth: 0.8)
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
        .padding(.vertical, 24)
        .background(NeonTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(NeonTheme.cardStroke, lineWidth: 1)
        }
        .frame(maxWidth: 320)
    }

    private func recapRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(NeonTheme.textSecondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.footnote.weight(.heavy))
                .foregroundStyle(NeonTheme.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }

}
