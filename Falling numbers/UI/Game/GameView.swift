import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    var onMainMenu: (() -> Void)? = nil
    var showsEmbeddedStartOverlay: Bool = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSettingsPresented = false
    @State private var scorePulse = false
    @State private var cascadePulse = false
    @State private var targetPulse = false
    @State private var perfectClearVisible = false
    @State private var cascadeBannerText: String?
    @State private var targetChangeBannerText: String?
    @State private var powerUpBannerText: String?
    /// Beginner-only: friendly “how the sum works” banner above the lower board edge.
    private struct SumLearnBanner: Equatable {
        let mainLine: String
        let subLine: String
        let accessibilitySummary: String
    }

    @State private var sumBannerTask: Task<Void, Never>?
    @State private var sumLearnBanner: SumLearnBanner?
    @State private var sumBannerBottomOffset: CGFloat = 12
    @State private var boardOffsetY: CGFloat = 0
    @State private var boardScale: CGFloat = 1.0
    @State private var transientBoardGlow: Double = 0

    var body: some View {
        ZStack {
            ArcadeTheme.backgroundGradient
                .ignoresSafeArea()

            GeometryReader { proxy in
                let isWide = proxy.size.width > proxy.size.height
                let hudWidth: CGFloat? = isWide ? min(300, proxy.size.width * 0.42) : nil
                let layout = isWide
                    ? AnyLayout(HStackLayout(alignment: .center, spacing: 16))
                    : AnyLayout(VStackLayout(spacing: 0))
                let sidePadding: CGFloat = 8
                let contentPadding: CGFloat = 2
                let heroTopPadding: CGFloat = 4
                let heroHeight = GameHUDMetrics.height
                let boardTopGap: CGFloat = 6
                let controlsReservedHeight: CGFloat = voiceOverEnabled ? 10 : 0
                let aspect = CGFloat(viewModel.state.board.columns) / CGFloat(viewModel.state.board.rows)
                let availableBoardHeight = max(1, proxy.size.height - (isWide ? 0 : heroTopPadding + heroHeight + boardTopGap) - controlsReservedHeight)
                let maxBoardWidth = max(1, proxy.size.width - sidePadding * 2 - (isWide ? (hudWidth ?? 0) + 20 : 0))
                let boardHeight = min(availableBoardHeight, maxBoardWidth / aspect)
                let boardWidth = boardHeight * aspect

                layout {
                    GameHUDView(viewModel: viewModel, scorePulse: scorePulse,
                                cascadePulse: cascadePulse, targetPulse: targetPulse)
                        .frame(width: hudWidth, height: heroHeight, alignment: .top)
                        .padding(.horizontal, contentPadding)

                    if !isWide { Color.clear.frame(height: boardTopGap) }

                    SpriteKitRenderer(state: Binding(
                            get: { viewModel.state },
                            set: { _ in }
                        ))
                        .frame(width: boardWidth, height: boardHeight)
                        .clipShape(Rectangle())
                        .overlay {
                            Rectangle()
                                .fill(
                                    Color.orange.opacity(
                                        (viewModel.showsCascadeHUD
                                            ? min(0.16, Double(max(0, viewModel.state.cascadeCount - 1)) * 0.03)
                                            : 0)
                                        + transientBoardGlow
                                    )
                                )
                                .allowsHitTesting(false)
                        }
                        .overlay {
                            GameGestureControls(viewModel: viewModel)
                        }
                        .overlay(alignment: .center) {
                            if perfectClearVisible {
                                Text("Perfect Clear!")
                                    .font(.title3.weight(.heavy))
                                    .tracking(1.0)
                                    .foregroundStyle(ArcadeTheme.textPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(ArcadeTheme.chipFill.opacity(0.96))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ArcadeTheme.chipStroke, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                            }
                        }
                        .overlay(alignment: .top) {
                            if let bannerText = targetChangeBannerText ?? cascadeBannerText {
                                Text(bannerText)
                                    .font(.headline.weight(.heavy))
                                    .foregroundStyle(ArcadeTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(ArcadeTheme.chipFill.opacity(0.97))
                                    .overlay(
                                        Capsule()
                                            .stroke(ArcadeTheme.chipStroke, lineWidth: 0.9)
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
                                    .foregroundStyle(ArcadeTheme.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(ArcadeTheme.chipFill.opacity(0.98))
                                    .overlay(
                                        Capsule()
                                            .stroke(ArcadeTheme.chipStroke, lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                                    .transition(.opacity.combined(with: .scale(scale: 0.93)))
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if let sumLearnBanner {
                                VStack(spacing: 6) {
                                    Text(sumLearnBanner.mainLine)
                                        .font(.title3.weight(.heavy))
                                        .foregroundStyle(ArcadeTheme.textPrimary)
                                        .multilineTextAlignment(.center)
                                        .minimumScaleFactor(0.68)
                                        .lineLimit(2)
                                    Text(sumLearnBanner.subLine)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(ArcadeTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(ArcadeTheme.chipFill.opacity(0.97))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(ArcadeTheme.chipStroke, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .padding(.horizontal, 6)
                                .padding(.bottom, sumBannerBottomOffset)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel(sumLearnBanner.accessibilitySummary)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .scaleEffect(boardScale)
                        .offset(y: boardOffsetY)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isWide ? .center : .top)
                .padding(.top, heroTopPadding)
                .padding(.horizontal, sidePadding)

            }

            if viewModel.state.isPaused, !viewModel.state.isGameOver {
                GameOverlays(viewModel: viewModel, kind: .pause,
                             onMainMenu: onMainMenu, onSettings: { isSettingsPresented = true })
            }

            if viewModel.state.isGameOver {
                GameOverlays(viewModel: viewModel, kind: .gameOver,
                             onMainMenu: onMainMenu, onSettings: { isSettingsPresented = true })
            }

            if showsEmbeddedStartOverlay, viewModel.showsStartOverlay {
                GameOverlays(viewModel: viewModel, kind: .start,
                             onMainMenu: onMainMenu, onSettings: { isSettingsPresented = true })
                    .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Group {
                if voiceOverEnabled {
                    GameControlsView(viewModel: viewModel)
                        .padding(.horizontal, 14)
                        .padding(.top, 6)
                        .padding(.bottom, 8)
                }
            }
        }
        .animation(.easeInOut(duration: 0.32), value: viewModel.showsStartOverlay)
        .onChange(of: viewModel.state.score) { _, _ in
            pulseScore()
        }
        .onChange(of: viewModel.state.cascadeCount) { _, newValue in
            if viewModel.showsCascadeHUD, newValue > 0 {
                pulseCascade()
            }
        }
        .onChange(of: viewModel.comboPulseToken) { _, _ in
            pulseCascade()
        }
        .onChange(of: viewModel.targetPulseToken) { _, _ in
            pulseTarget()
        }
        .onChange(of: viewModel.targetChangeToken) { _, _ in
            showTargetChangeFeedback()
        }
        .onChange(of: viewModel.perfectClearToken) { _, _ in
            showPerfectClearFeedback()
        }
        .onChange(of: viewModel.powerUpPulseToken) { _, _ in
            showPowerUpFeedback()
        }
        .onChange(of: viewModel.sumClearPulseToken) { _, _ in
            showSumClearFeedback()
        }
        .onChange(of: viewModel.boardShakeToken) { _, _ in
            hardDropFeedback()
        }
        .onChange(of: viewModel.state.runID) { _, _ in
            sumBannerTask?.cancel()
            sumLearnBanner = nil
        }
        .onDisappear {
            sumBannerTask?.cancel()
            sumBannerTask = nil
            sumLearnBanner = nil
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(viewModel: viewModel)
        }
        .transaction { transaction in
            if reduceMotion {
                transaction.animation = nil
            }
        }
    }

    private func pulseScore() {
        scorePulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            scorePulse = false
        }
    }

    private func pulseCascade() {
        guard viewModel.showsCascadeHUD else { return }
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

    private func showTargetChangeFeedback() {
        withAnimation(.easeOut(duration: 0.18)) {
            targetChangeBannerText = "New target: \(viewModel.state.targetNumber)"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.2)) {
                targetChangeBannerText = nil
            }
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

    private func showSumClearFeedback() {
        guard let event = viewModel.lastSumClearEvent, !event.values.isEmpty else { return }
        let expression = event.values.map(String.init).joined(separator: " + ")
        let mainLine = "\(expression) = \(event.target)"

        let lineKindSentence = event.direction == .horizontal ? "along one row" : "in one column"
        let countWord = event.values.count == 1 ? "tile" : "tiles"
        let subLine: String
        if event.cascade > 1 {
            subLine = "Together they make \(event.target), your target • chain step \(event.cascade)"
        } else if event.values.count >= 3 {
            subLine =
                "\(event.values.count) \(countWord) \(lineKindSentence) add up to your target \(event.target). Nice!"
        } else {
            subLine = "Tiles \(lineKindSentence) reached your target \(event.target) • line clears!"
        }

        let spell = NumberFormatter()
        spell.locale = Locale(identifier: "en_US")
        spell.numberStyle = .spellOut
        let spokenParts = event.values.compactMap { spell.string(from: NSNumber(value: $0)) }
        let spokenSum = spokenParts.joined(separator: ", plus ")
        let targetSpoken = spell.string(from: NSNumber(value: event.target)) ?? "\(event.target)"
        let directionSpoken = event.direction == .horizontal ? "horizontal row" : "vertical column"
        let chainSpoken = event.cascade > 1 ? " Chain step \(event.cascade)." : ""
        let accessibilitySummary =
            "\(spokenSum), equals \(targetSpoken), your target. \(directionSpoken).\(chainSpoken)"

        sumLearnBanner = SumLearnBanner(
            mainLine: mainLine,
            subLine: subLine,
            accessibilitySummary: accessibilitySummary
        )
        sumBannerBottomOffset = 4

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            sumBannerBottomOffset = 14
        }
        sumBannerTask?.cancel()
        sumBannerTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(2.15))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.22)) {
                sumLearnBanner = nil
                sumBannerBottomOffset = 12
            }
        }
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
