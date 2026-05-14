import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    @State private var isSettingsPresented = false
    @State private var scorePulse = false
    @State private var comboPulse = false
    @State private var targetPulse = false
    @State private var boardOffsetY: CGFloat = 0
    @State private var boardScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            NeonTheme.backgroundGradient
                .ignoresSafeArea()

            GeometryReader { proxy in
                let contentHorizontalPadding: CGFloat = 14
                let boardHorizontalPadding: CGFloat = 8
                let topInset = max(4, proxy.safeAreaInsets.top)
                let bottomInset = max(10, proxy.safeAreaInsets.bottom)

                let topBarHeight: CGFloat = 30
                let hudHeight: CGFloat = 58
                let controlsHeight: CGFloat = 48
                let helperHeight: CGFloat = (!viewModel.state.hasPlayerMoved && !viewModel.state.isGameOver) ? 24 : 0
                let spacingBudget: CGFloat = (!viewModel.state.hasPlayerMoved && !viewModel.state.isGameOver) ? 24 : 18
                let fixedVertical = topInset + bottomInset + topBarHeight + hudHeight + controlsHeight + helperHeight + spacingBudget

                let availableBoardHeight = max(220, proxy.size.height - fixedVertical)
                let maxBoardWidthFromScreen = max(170, proxy.size.width - boardHorizontalPadding * 2)
                let boardHeight = min(availableBoardHeight, maxBoardWidthFromScreen * 2)
                let boardWidth = boardHeight * 0.5

                VStack(spacing: 6) {
                    HStack {
                        Spacer()
                        iconButton(symbol: "pause.circle", accessibilityLabel: viewModel.state.isPaused ? "Resume game" : "Pause game") {
                            viewModel.togglePause()
                        }
                        iconButton(symbol: "gearshape", accessibilityLabel: "Open settings") {
                            isSettingsPresented = true
                        }
                    }
                    .padding(.horizontal, contentHorizontalPadding)
                    .frame(height: topBarHeight)

                    HUDView(
                        score: viewModel.state.score,
                        highScore: viewModel.highScore,
                        target: viewModel.state.targetNumber,
                        level: viewModel.state.level,
                        combo: viewModel.state.comboCount,
                        next: viewModel.state.nextPieceValue,
                        targetPulsing: targetPulse
                    )
                    .padding(.horizontal, contentHorizontalPadding)
                    .scaleEffect(scorePulse || comboPulse ? 1.03 : 1.0)
                    .animation(.easeOut(duration: 0.16), value: scorePulse)
                    .animation(.easeOut(duration: 0.16), value: comboPulse)

                    SpriteKitRenderer(state: Binding(
                        get: { viewModel.state },
                        set: { _ in }
                    ))
                    .frame(width: boardWidth, height: boardHeight)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.14), lineWidth: 0.7)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .gesture(
                        DragGesture(minimumDistance: 18)
                            .onEnded { value in
                                viewModel.handleDrag(translation: value.translation)
                            }
                    )
                    .scaleEffect(boardScale)
                    .offset(y: boardOffsetY)

                    HStack(spacing: 12) {
                        controlButton(symbol: "chevron.left", label: "Left", accessibilityLabel: "Move left", action: viewModel.moveLeft)
                        controlButton(symbol: "arrow.down", label: "Down", accessibilityLabel: "Soft drop", action: viewModel.softDrop)
                        controlButton(symbol: "arrow.down.to.line", label: "Drop", accessibilityLabel: "Hard drop", action: viewModel.hardDrop)
                        controlButton(symbol: "chevron.right", label: "Right", accessibilityLabel: "Move right", action: viewModel.moveRight)
                    }
                    .frame(height: controlsHeight)
                    .padding(.horizontal, contentHorizontalPadding)

                    if !viewModel.state.hasPlayerMoved && !viewModel.state.isGameOver {
                        Text("Match connected numbers to the target.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.78))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, topInset)
                .padding(.bottom, bottomInset)

#if DEBUG
                if viewModel.diagnosticsEnabled {
                    diagnosticsOverlay(
                        screenHeight: proxy.size.height,
                        boardHeight: boardHeight,
                        controlsHeight: controlsHeight,
                        topSpacing: topInset
                    )
                }
#endif
            }

            if viewModel.state.isPaused, !viewModel.state.isGameOver {
                pauseOverlay
            }

            if viewModel.state.isGameOver {
                overlayCard(
                    title: "Game Over",
                    subtitle: "Final \(viewModel.state.score)  •  Best \(viewModel.highScore)",
                    buttonTitle: "Play Again",
                    action: viewModel.newGame
                )
            }

            if viewModel.showsStartOverlay {
                startOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.32), value: viewModel.showsStartOverlay)
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
            hardDropFeedback()
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(viewModel: viewModel)
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

    private func hardDropFeedback() {
        withAnimation(.easeOut(duration: 0.05)) {
            boardOffsetY = 4
            boardScale = 0.992
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.1)) {
                boardOffsetY = 0
                boardScale = 1.0
            }
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

    @ViewBuilder
    private var startOverlay: some View {
        Color.black.opacity(0.58)
            .ignoresSafeArea()

        VStack(spacing: 12) {
            Text("Fall, Number… Fall!")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("Match connected numbers to the target.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
            Button("Play", action: viewModel.startGameFromOverlay)
                .buttonStyle(.borderedProminent)
                .tint(NeonTheme.controlsTint)
                .accessibilityLabel("Start game")
        }
        .padding(22)
        .background(Color.black.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(0.985)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var pauseOverlay: some View {
        Color.black.opacity(0.58)
            .ignoresSafeArea()

        VStack(spacing: 12) {
            Text("Paused")
                .font(.title2.bold())
                .foregroundStyle(.white)
            HStack(spacing: 10) {
                Button("Resume", action: viewModel.togglePause)
                    .buttonStyle(.borderedProminent)
                    .tint(NeonTheme.controlsTint)
                Button("New Game", action: viewModel.newGame)
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.85))
            }
        }
        .padding(22)
        .background(Color.black.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
    }

    private func iconButton(symbol: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .frame(width: 32, height: 32)
                .background(Color.black.opacity(0.38))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 0.8))
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private func controlButton(symbol: String, label: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .black))
                Text(label)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.38))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.42, green: 0.82, blue: 0.98).opacity(0.34), lineWidth: 0.9)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
        }
        .buttonStyle(ControlPadButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }

#if DEBUG
    private func diagnosticsOverlay(screenHeight: CGFloat, boardHeight: CGFloat, controlsHeight: CGFloat, topSpacing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FPS: ~60")
            Text(String(format: "Tick: %.2fs", viewModel.state.currentTickInterval))
            Text("Tiles: \(viewModel.state.board.allOccupiedPositions().count + (viewModel.state.activePiece == nil ? 0 : 1))")
            Text("Combo depth: \(viewModel.state.comboCount)")
            Text(String(format: "Screen H: %.0f", screenHeight))
            Text(String(format: "Board H: %.0f", boardHeight))
            Text(String(format: "Controls H: %.0f", controlsHeight))
            Text(String(format: "Top Spacing: %.0f", topSpacing))
        }
        .font(.caption2.monospacedDigit())
        .padding(8)
        .background(Color.black.opacity(0.55))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
    }
#endif
}

private struct ControlPadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: Color(red: 0.42, green: 0.82, blue: 0.98).opacity(configuration.isPressed ? 0.28 : 0.0),
                radius: configuration.isPressed ? 8 : 0
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#if DEBUG
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GameView(viewModel: GameScreenViewModel())
                .previewDisplayName("iPhone SE")
                .previewDevice("iPhone SE (3rd generation)")

            GameView(viewModel: GameScreenViewModel())
                .previewDisplayName("iPhone 16")
                .previewDevice("iPhone 16")

            GameView(viewModel: GameScreenViewModel())
                .previewDisplayName("iPhone 16 Pro Max")
                .previewDevice("iPhone 16 Pro Max")
        }
    }
}
#endif
