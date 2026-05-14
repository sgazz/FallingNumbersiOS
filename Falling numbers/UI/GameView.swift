import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var isSettingsPresented = false
    @State private var scorePulse = false
    @State private var comboPulse = false
    @State private var targetPulse = false
    @State private var boardOffsetY: CGFloat = 0
    @State private var boardScale: CGFloat = 1.0
#if DEBUG
    @State private var controlsFrame: CGRect = .zero
    @State private var boardFrame: CGRect = .zero
#endif

    var body: some View {
        ZStack {
            NeonTheme.backgroundGradient
                .ignoresSafeArea()

            GeometryReader { proxy in
                let sidePadding: CGFloat = 8
                let contentPadding: CGFloat = 12
                let topInset = max(2, proxy.safeAreaInsets.top)

                let topRowHeight: CGFloat = 32
                let secondRowHeight: CGFloat = 30
                let boardTopGap: CGFloat = 8
                let controlsReservedHeight: CGFloat = voiceOverEnabled ? 66 : 8
                let verticalSpacing: CGFloat = 6

                let fixedVertical = topInset
                    + topRowHeight
                    + secondRowHeight
                    + boardTopGap
                    + controlsReservedHeight
                    + verticalSpacing * 2

                let availableBoardHeight = max(220, proxy.size.height - fixedVertical)
                let maxBoardWidth = max(170, proxy.size.width - sidePadding * 2)
                let boardHeight = min(availableBoardHeight, maxBoardWidth * 2)
                let boardWidth = boardHeight * 0.5

                VStack(spacing: verticalSpacing) {
                    scoreBestLayer
                        .frame(height: topRowHeight)
                        .padding(.horizontal, contentPadding)

                    compactStatsLayer
                        .frame(height: secondRowHeight)
                        .padding(.horizontal, contentPadding)

                    Color.clear.frame(height: boardTopGap)

                    SpriteKitRenderer(state: Binding(
                        get: { viewModel.state },
                        set: { _ in }
                    ))
                    .frame(width: boardWidth, height: boardHeight)
                    .overlay {
                        invisibleControlZones
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(NeonTheme.chipStroke, lineWidth: 0.8)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .scaleEffect(boardScale)
                    .offset(y: boardOffsetY)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: BoardFramePreferenceKey.self, value: geo.frame(in: .global))
                        }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, topInset)
                .padding(.horizontal, sidePadding)
                .overlay(alignment: .bottom) {
                    helperHintOverlay
                        .padding(.bottom, 6)
                }

#if DEBUG
                if viewModel.diagnosticsEnabled {
                    diagnosticsOverlay(
                        screenHeight: proxy.size.height,
                        boardHeight: boardHeight,
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
        .onPreferenceChange(BoardFramePreferenceKey.self) { frame in
#if DEBUG
            boardFrame = frame
            if viewModel.diagnosticsEnabled {
                print("DEBUG board frame: x=\(Int(frame.minX)) y=\(Int(frame.minY)) w=\(Int(frame.width)) h=\(Int(frame.height))")
            }
#endif
        }
        .safeAreaInset(edge: .bottom) {
            Group {
                if voiceOverEnabled {
                    controlsRow
                        .padding(.horizontal, 14)
                        .padding(.top, 6)
                        .padding(.bottom, 8)
                } else {
                    Color.clear.frame(height: 1)
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ControlsFramePreferenceKey.self, value: geo.frame(in: .global))
                }
            )
        }
        .onPreferenceChange(ControlsFramePreferenceKey.self) { frame in
#if DEBUG
            controlsFrame = frame
            if viewModel.diagnosticsEnabled {
                print("DEBUG controls frame: x=\(Int(frame.minX)) y=\(Int(frame.minY)) w=\(Int(frame.width)) h=\(Int(frame.height))")
            }
#endif
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

    private var scoreBestLayer: some View {
        HStack(spacing: 8) {
            inlineChip(text: "Score \(viewModel.state.score)")
                .scaleEffect(scorePulse ? 1.03 : 1.0)
                .animation(.easeOut(duration: 0.16), value: scorePulse)
                .accessibilityLabel("Score \(viewModel.state.score)")
            iconButton(symbol: "pause.circle", accessibilityLabel: viewModel.state.isPaused ? "Resume game" : "Pause game") {
                viewModel.togglePause()
            }
            iconButton(symbol: "gearshape", accessibilityLabel: "Open settings") {
                isSettingsPresented = true
            }
            inlineChip(text: "Best \(viewModel.highScore)")
                .accessibilityLabel("High score \(viewModel.highScore)")
        }
    }

    private var compactStatsLayer: some View {
        HStack(spacing: 6) {
            inlineChip(text: "Lvl \(viewModel.state.level)")
                .accessibilityLabel("Level \(viewModel.state.level)")
            targetInlineChip
                .accessibilityLabel("Target number \(viewModel.state.targetNumber)")
            inlineChip(text: "Combo \(viewModel.state.comboCount)")
                .scaleEffect(comboPulse ? 1.03 : 1.0)
                .animation(.easeOut(duration: 0.16), value: comboPulse)
                .accessibilityLabel("Combo \(viewModel.state.comboCount)")
            inlineChip(text: "Next \(viewModel.state.nextPieceValue)")
                .accessibilityLabel("Next piece \(viewModel.state.nextPieceValue)")
        }
    }

    private var targetInlineChip: some View {
        Text("TARGET \(viewModel.state.targetNumber)")
            .font(.subheadline.weight(.heavy))
            .tracking(0.4)
            .foregroundStyle(NeonTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(NeonTheme.chipFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(NeonTheme.chipStroke, lineWidth: 1.0)
            )
            .scaleEffect(targetPulse ? 1.06 : 1.0)
            .animation(.easeOut(duration: 0.2), value: targetPulse)
    }

    private var helperHintOverlay: some View {
        Text("Tap sides to move. Swipe down to drop.")
            .font(.footnote)
            .foregroundStyle(NeonTheme.textPrimary.opacity(0.82))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(NeonTheme.chipFill.opacity(0.96))
            .clipShape(Capsule())
            .opacity((!viewModel.state.hasPlayerMoved && !viewModel.state.isGameOver) ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: viewModel.state.hasPlayerMoved)
    }

    private var controlsRow: some View {
        HStack(spacing: 12) {
            controlButton(symbol: "chevron.left", label: "Left", accessibilityLabel: "Move left") {
                viewModel.moveLeft()
            }
            controlButton(symbol: "arrow.down", label: "Down", accessibilityLabel: "Soft drop") {
                viewModel.softDrop()
            }
            controlButton(symbol: "arrow.down.to.line", label: "Drop", accessibilityLabel: "Hard drop") {
                viewModel.hardDrop()
            }
            controlButton(symbol: "chevron.right", label: "Right", accessibilityLabel: "Move right") {
                viewModel.moveRight()
            }
        }
        .frame(height: 48)
    }

    private var invisibleControlZones: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.moveLeft() }
                        .accessibilityHidden(true)

                    Color.clear
                        .accessibilityHidden(true)

                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.moveRight() }
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: width * 0.42, height: height * 0.34)
                    .position(x: width * 0.5, y: height * 0.82)
                    .onTapGesture { viewModel.softDrop() }
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                TapGesture(count: 2).onEnded {
                    viewModel.hardDrop()
                }
            )
            .gesture(
                DragGesture(minimumDistance: GameScreenViewModel.swipeActivationThreshold)
                    .onEnded { value in
                        viewModel.handleDrag(translation: value.translation)
                    }
            )
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
        NeonTheme.overlayScrim
            .ignoresSafeArea()

        VStack(spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(NeonTheme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(NeonTheme.textSecondary)

            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
                .tint(NeonTheme.controlsTint)
        }
        .padding(22)
        .background(NeonTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(NeonTheme.cardStroke, lineWidth: 1)
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
            Text("Match connected numbers to the target.")
                .font(.subheadline)
                .foregroundStyle(NeonTheme.textSecondary)
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

    @ViewBuilder
    private var pauseOverlay: some View {
        NeonTheme.overlayScrim
            .ignoresSafeArea()

        VStack(spacing: 12) {
            Text("Paused")
                .font(.title2.bold())
                .foregroundStyle(NeonTheme.textPrimary)
            HStack(spacing: 10) {
                Button("Resume", action: viewModel.togglePause)
                    .buttonStyle(.borderedProminent)
                    .tint(NeonTheme.controlsTint)
                Button("New Game", action: viewModel.newGame)
                    .buttonStyle(.bordered)
                    .tint(NeonTheme.textPrimary.opacity(0.75))
            }
        }
        .padding(22)
        .background(NeonTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(NeonTheme.cardStroke, lineWidth: 1)
        }
    }

    private func iconButton(symbol: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(NeonTheme.textPrimary.opacity(0.92))
                .frame(width: 32, height: 32)
                .background(NeonTheme.chipFill.opacity(0.98))
                .clipShape(Circle())
                .overlay(Circle().stroke(NeonTheme.chipStroke, lineWidth: 0.8))
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private func inlineChip(text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(NeonTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 10)
            .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(NeonTheme.chipFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(NeonTheme.chipStroke, lineWidth: 0.7)
        )
    }

    private func controlButton(symbol: String, label: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .black))
                Text(label)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(NeonTheme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(NeonTheme.chipFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(NeonTheme.chipStroke, lineWidth: 0.9)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.clear],
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
    private func diagnosticsOverlay(screenHeight: CGFloat, boardHeight: CGFloat, topSpacing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FPS: ~60")
            Text(String(format: "Tick: %.2fs", viewModel.state.currentTickInterval))
            Text("Tiles: \(viewModel.state.board.allOccupiedPositions().count + (viewModel.state.activePiece == nil ? 0 : 1))")
            Text("Combo depth: \(viewModel.state.comboCount)")
            Text(String(format: "Screen H: %.0f", screenHeight))
            Text(String(format: "Board H: %.0f", boardHeight))
            Text(String(format: "Top Spacing: %.0f", topSpacing))
            Text(String(format: "Controls Y: %.0f", controlsFrame.minY))
            Text(String(format: "Board Top: %.0f", boardFrame.minY))
        }
        .font(.caption2.monospacedDigit())
        .padding(8)
                .background(NeonTheme.chipFill.opacity(0.94))
        .foregroundStyle(NeonTheme.textPrimary)
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
                color: Color(red: 0.40, green: 0.29, blue: 0.21).opacity(configuration.isPressed ? 0.22 : 0.0),
                radius: configuration.isPressed ? 6 : 0
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ControlsFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct BoardFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
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
