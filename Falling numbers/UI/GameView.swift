import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    @State private var scorePulse = false
    @State private var comboPulse = false
    @State private var targetPulse = false
    @State private var boardOffsetX: CGFloat = 0

    var body: some View {
        ZStack {
            NeonTheme.backgroundGradient
                .ignoresSafeArea()

            GeometryReader { proxy in
                let horizontalPadding: CGFloat = 16
                let boardWidth = max(220, proxy.size.width - horizontalPadding * 2)

                VStack(spacing: 14) {
                    HUDView(
                        score: viewModel.state.score,
                        highScore: viewModel.highScore,
                        target: viewModel.state.targetNumber,
                        level: viewModel.state.level,
                        combo: viewModel.state.comboCount,
                        next: viewModel.state.nextPieceValue,
                        targetPulsing: targetPulse
                    )
                    .padding(.horizontal, horizontalPadding)
                    .scaleEffect(scorePulse || comboPulse ? 1.03 : 1.0)
                    .animation(.easeOut(duration: 0.16), value: scorePulse)
                    .animation(.easeOut(duration: 0.16), value: comboPulse)

                    SpriteKitRenderer(state: Binding(
                        get: { viewModel.state },
                        set: { _ in }
                    ))
                    .frame(width: boardWidth, height: boardWidth * 2)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .gesture(
                        DragGesture(minimumDistance: 18)
                            .onEnded { value in
                                viewModel.handleDrag(translation: value.translation)
                            }
                    )
                    .offset(x: boardOffsetX)

                    HStack(spacing: 10) {
                        Button("Left") { viewModel.moveLeft() }
                        Button("Down") { viewModel.softDrop() }
                        Button("Drop") { viewModel.hardDrop() }
                        Button("Right") { viewModel.moveRight() }
                        Button(viewModel.state.isPaused ? "Resume" : "Pause") { viewModel.togglePause() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(NeonTheme.controlsTint)
                    .padding(.bottom, 8)

                    if !viewModel.state.hasPlayerMoved && !viewModel.state.isGameOver {
                        Text("Match connected numbers to the target.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.78))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, max(12, proxy.safeAreaInsets.top))
                .padding(.bottom, max(10, proxy.safeAreaInsets.bottom))
            }

            if viewModel.state.isPaused, !viewModel.state.isGameOver {
                overlayCard(
                    title: "Paused",
                    subtitle: "Score \(viewModel.state.score)  •  Best \(viewModel.highScore)",
                    buttonTitle: "Resume",
                    action: viewModel.togglePause
                )
            }

            if viewModel.state.isGameOver {
                overlayCard(
                    title: "Game Over",
                    subtitle: "Final \(viewModel.state.score)  •  Best \(viewModel.highScore)",
                    buttonTitle: "New Game",
                    action: viewModel.newGame
                )
            }
        }
        .onChange(of: viewModel.state.score) { _, _ in
            pulseScore()
        }
        .onChange(of: viewModel.state.comboCount) { _, newValue in
            if newValue > 0 {
                pulseCombo()
            }
        }
        .onChange(of: viewModel.comboPulseToken) { _, _ in
            pulseCombo()
        }
        .onChange(of: viewModel.targetPulseToken) { _, _ in
            pulseTarget()
        }
        .onChange(of: viewModel.boardShakeToken) { _, _ in
            shakeBoard()
        }
    }

    private func pulseScore() {
        scorePulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            scorePulse = false
        }
    }

    private func pulseCombo() {
        comboPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            comboPulse = false
        }
    }

    private func pulseTarget() {
        targetPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            targetPulse = false
        }
    }

    private func shakeBoard() {
        withAnimation(.linear(duration: 0.04)) { boardOffsetX = 5 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            withAnimation(.linear(duration: 0.04)) { boardOffsetX = -4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeOut(duration: 0.08)) { boardOffsetX = 0 }
        }
    }

    @ViewBuilder
    private func overlayCard(title: String, subtitle: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        Color.black.opacity(0.58)
            .ignoresSafeArea()

        VStack(spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))

            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
                .tint(NeonTheme.controlsTint)
        }
        .padding(22)
        .background(Color.black.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
    }
}
