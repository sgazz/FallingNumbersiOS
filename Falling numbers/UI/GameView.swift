import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    var onMainMenu: (() -> Void)? = nil
    var showsEmbeddedStartOverlay: Bool = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var isSettingsPresented = false
    @State private var scorePulse = false
    @State private var cascadePulse = false
    @State private var targetPulse = false
    @State private var perfectClearVisible = false
    @State private var cascadeBannerText: String?
    @State private var powerUpBannerText: String?
    @State private var sumBannerText: String?
    @State private var sumBannerX: CGFloat = 0.5
    @State private var sumBannerY: CGFloat = 0.5
    @State private var sumBannerRise: CGFloat = 0
    @State private var boardOffsetY: CGFloat = 0
    @State private var boardScale: CGFloat = 1.0
    @State private var transientBoardGlow: Double = 0
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

                let topRowHeight: CGFloat = 36
                let secondRowHeight: CGFloat = 36
                let thirdRowHeight: CGFloat = 30
                let boardTopGap: CGFloat = 8
                let controlsReservedHeight: CGFloat = voiceOverEnabled ? 66 : 8
                let verticalSpacing: CGFloat = 6

                let fixedVertical = topInset
                    + topRowHeight
                    + secondRowHeight
                    + thirdRowHeight
                    + boardTopGap
                    + controlsReservedHeight
                    + verticalSpacing * 3

                let availableBoardHeight = max(220, proxy.size.height - fixedVertical)
                let maxBoardWidth = max(170, proxy.size.width - sidePadding * 2)
                let boardHeight = min(availableBoardHeight, maxBoardWidth * 2)
                let boardWidth = boardHeight * 0.5

                VStack(spacing: verticalSpacing) {
                    topPrimaryLayer
                        .frame(height: topRowHeight)
                        .padding(.horizontal, contentPadding)

                    targetRowLayer
                        .frame(height: secondRowHeight)
                        .padding(.horizontal, contentPadding)

                    topStatusLayer
                        .frame(height: thirdRowHeight)
                        .padding(.horizontal, contentPadding)

                    Color.clear.frame(height: boardTopGap)

                    SpriteKitRenderer(state: Binding(
                        get: { viewModel.state },
                        set: { _ in }
                    ))
                    .frame(width: boardWidth, height: boardHeight)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                Color.orange.opacity(
                                    min(
                                        0.16,
                                        Double(max(0, (viewModel.state.gameMode == .expert ? 1 : viewModel.state.cascadeCount) - 1)) * 0.03
                                    ) + transientBoardGlow
                                )
                            )
                            .allowsHitTesting(false)
                    }
                    .overlay {
                        invisibleControlZones
                    }
                    .overlay(alignment: .center) {
                        if perfectClearVisible {
                            Text("Perfect Clear!")
                                .font(.title3.weight(.heavy))
                                .tracking(1.0)
                                .foregroundStyle(NeonTheme.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(NeonTheme.chipFill.opacity(0.96))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(NeonTheme.chipStroke, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                        }
                    }
                    .overlay(alignment: .top) {
                        if let cascadeBannerText {
                            Text(cascadeBannerText)
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(NeonTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(NeonTheme.chipFill.opacity(0.97))
                                .overlay(
                                    Capsule()
                                        .stroke(NeonTheme.chipStroke, lineWidth: 0.9)
                                )
                                .clipShape(Capsule())
                                .padding(.top, 10)
                                .transition(.opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .overlay(alignment: .center) {
                        if let powerUpBannerText {
                            Text(powerUpBannerText)
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(NeonTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(NeonTheme.chipFill.opacity(0.98))
                                .overlay(
                                    Capsule()
                                        .stroke(NeonTheme.chipStroke, lineWidth: 1)
                                )
                                .clipShape(Capsule())
                                .transition(.opacity.combined(with: .scale(scale: 0.93)))
                        }
                    }
                    .overlay {
                        if let sumBannerText {
                            GeometryReader { geo in
                                Text(sumBannerText)
                                    .font(.headline.weight(.heavy))
                                    .foregroundStyle(NeonTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(NeonTheme.chipFill.opacity(0.98))
                                    .overlay(
                                        Capsule()
                                            .stroke(NeonTheme.chipStroke, lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                                    .position(
                                        x: max(46, min(geo.size.width - 46, geo.size.width * sumBannerX)),
                                        y: max(26, min(geo.size.height - 26, geo.size.height * sumBannerY + sumBannerRise))
                                    )
                            }
                            .transition(.opacity)
                        }
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
                gameOverOverlay
            }

            if showsEmbeddedStartOverlay, viewModel.showsStartOverlay {
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
        .onChange(of: viewModel.state.cascadeCount) { _, newValue in
            if newValue > 0 {
                pulseCascade()
            }
        }
        .onChange(of: viewModel.comboPulseToken) { _, _ in
            pulseCascade()
        }
        .onChange(of: viewModel.targetPulseToken) { _, _ in
            pulseTarget()
        }
        .onChange(of: viewModel.perfectClearToken) { _, _ in
            showPerfectClearFeedback()
        }
        .onChange(of: viewModel.powerUpPulseToken) { _, _ in
            showPowerUpFeedback()
        }
        .onChange(of: viewModel.sumClearPulseToken) { _, _ in
            showBeginnerSumFeedback()
        }
        .onChange(of: viewModel.boardShakeToken) { _, _ in
            hardDropFeedback()
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(viewModel: viewModel)
        }
    }

    private var topPrimaryLayer: some View {
        HStack(spacing: 8) {
            inlineChip(text: "Score \(viewModel.state.score)", style: .score)
                .scaleEffect(scorePulse ? 1.03 : 1.0)
                .animation(.easeOut(duration: 0.16), value: scorePulse)
                .accessibilityLabel("Score \(viewModel.state.score)")
            iconButton(symbol: "pause.circle", accessibilityLabel: viewModel.state.isPaused ? "Resume game" : "Pause game") {
                viewModel.togglePause()
            }
            .frame(maxWidth: .infinity)
            inlineChip(text: "Best \(viewModel.highScore)", style: .best)
                .accessibilityLabel("High score \(viewModel.highScore)")
        }
    }

    private var topStatusLayer: some View {
        HStack(spacing: 6) {
            inlineChip(text: "Lvl \(viewModel.state.level)", style: .level)
                .accessibilityLabel("Level \(viewModel.state.level)")
            if viewModel.showsCascadeHUD {
                inlineChip(text: "Cascade ×\(max(1, viewModel.state.cascadeCount))", style: .cascade)
                    .scaleEffect(cascadePulse ? 1.03 : 1.0)
                    .animation(.easeOut(duration: 0.16), value: cascadePulse)
                    .accessibilityLabel("Cascade \(max(1, viewModel.state.cascadeCount))")
            }
            inlineChip(text: "Next \(viewModel.state.nextPieceDisplayText)", style: .next)
                .accessibilityLabel("Next piece \(viewModel.state.nextPieceDisplayText)")
        }
    }

    private var targetRowLayer: some View {
        HStack(spacing: 6) {
            targetInlineChip
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Target \(viewModel.state.targetNumber)")
        }
    }

    private var targetInlineChip: some View {
        Text("TARGET \(viewModel.state.targetNumber)")
            .font(.subheadline.weight(.heavy))
            .tracking(0.4)
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [NeonTheme.accentPrimary, NeonTheme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1.0)
            )
            .shadow(color: NeonTheme.glowColor.opacity(0.35), radius: 8)
            .scaleEffect(targetPulse ? 1.06 : 1.0)
            .animation(.easeOut(duration: 0.2), value: targetPulse)
    }

    private var helperHintOverlay: some View {
        Text("Make horizontal or vertical sums to match the target.")
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

    private func pulseCascade() {
        guard viewModel.state.gameMode == .beginner else { return }
        cascadePulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            cascadePulse = false
        }
        if viewModel.state.cascadeCount >= 2 {
            withAnimation(.easeOut(duration: 0.14)) {
                cascadeBannerText = "Cascade ×\(viewModel.state.cascadeCount)"
                transientBoardGlow = 0.11
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
                withAnimation(.easeOut(duration: 0.2)) {
                    cascadeBannerText = nil
                    transientBoardGlow = 0
                }
            }
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

    private func showPerfectClearFeedback() {
        withAnimation(.easeOut(duration: 0.14)) {
            transientBoardGlow = 0.2
        }
        withAnimation(.easeInOut(duration: 0.18)) {
            perfectClearVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.22)) {
                perfectClearVisible = false
                transientBoardGlow = 0
            }
        }
    }

    private func showPowerUpFeedback() {
        powerUpBannerText = viewModel.lastPowerUpLabel
        withAnimation(.easeOut(duration: 0.18)) {}
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.2)) {
                powerUpBannerText = nil
            }
        }
    }

    private func showBeginnerSumFeedback() {
        guard let event = viewModel.lastSumClearEvent, !event.values.isEmpty else { return }
        let expression = event.values.map(String.init).joined(separator: " + ")
        sumBannerText = "\(expression) = \(event.target)"

        let avgRow = event.positions.map(\.row).reduce(0, +) / max(1, event.positions.count)
        let avgColumn = event.positions.map(\.column).reduce(0, +) / max(1, event.positions.count)
        let rowFraction = CGFloat(avgRow + 1) / CGFloat(max(1, viewModel.state.board.rows))
        let colFraction = CGFloat(avgColumn + 1) / CGFloat(max(1, viewModel.state.board.columns))
        sumBannerX = colFraction
        sumBannerY = rowFraction
        sumBannerRise = 0

        withAnimation(.easeOut(duration: 0.28)) {
            sumBannerRise = -24
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.easeIn(duration: 0.2)) {
                sumBannerText = nil
                sumBannerRise = 0
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
                    isSettingsPresented = true
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
                recapRow(title: "Highest Cascade", value: "×\(max(1, viewModel.state.highestCascade))")
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
                    isSettingsPresented = true
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

    private func iconButton(symbol: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.94))
                .frame(width: 30, height: 30)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.36, green: 0.25, blue: 0.73),
                            Color(red: 0.22, green: 0.53, blue: 0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 0.8))
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private enum HUDChipStyle {
        case score
        case best
        case level
        case cascade
        case next
    }

    private func inlineChip(text: String, style: HUDChipStyle) -> some View {
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
        }

        return Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 10)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(gradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.24), lineWidth: 0.7)
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
            Text("Cascade depth: \(viewModel.state.cascadeCount)")
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
