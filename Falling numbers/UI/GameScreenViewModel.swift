import Foundation
import Combine
import CoreGraphics

@MainActor
final class GameScreenViewModel: ObservableObject {
    static let swipeActivationThreshold: CGFloat = 30
    static let hardDropSwipeThreshold: CGFloat = 105

    @Published private(set) var state: GameState
    @Published private(set) var showsStartOverlay: Bool
    @Published private(set) var highScore: Int
    @Published private(set) var boardShakeToken: Int = 0
    @Published private(set) var comboPulseToken: Int = 0
    @Published private(set) var targetPulseToken: Int = 0
    @Published private(set) var perfectClearToken: Int = 0
    @Published private(set) var powerUpPulseToken: Int = 0
    @Published private(set) var lastPowerUpLabel: String?
    @Published private(set) var sumClearPulseToken: Int = 0
    @Published private(set) var lastSumClearEvent: SumClearEvent?
    @Published private(set) var didSetNewBestInRun: Bool = false
    @Published private(set) var settings: AppSettings
#if DEBUG
    @Published var diagnosticsEnabled = false
#endif

    private var engine: GameEngine
    private var timer: Timer?
    private var highScoreStore: HighScoreStoring
    private let settingsStore: SettingsStoring
    private let haptics: HapticsClient
    private let audio: AudioClient
    private var pausedByLifecycle = false
    private(set) var timerStartCount = 0
    private var runStartingBest: Int
    var isNewBestForCurrentGameOver: Bool {
        state.isGameOver && state.score > runStartingBest
    }

    init(
        engine: GameEngine? = nil,
        highScoreStore: HighScoreStoring? = nil,
        settingsStore: SettingsStoring? = nil,
        haptics: HapticsClient? = nil,
        audio: AudioClient? = nil
    ) {
        let resolvedEngine = engine ?? GameEngine()
        let resolvedHighScoreStore = highScoreStore ?? UserDefaultsHighScoreStore()
        let resolvedSettingsStore = settingsStore ?? UserDefaultsSettingsStore()
        let initialMode = resolvedEngine.state.gameMode
        let initialHighScore = resolvedHighScoreStore.load(for: initialMode)

        self.engine = resolvedEngine
        self.state = resolvedEngine.state
        self.highScoreStore = resolvedHighScoreStore
        self.highScore = initialHighScore
        self.runStartingBest = initialHighScore
        self.settingsStore = resolvedSettingsStore
        self.settings = resolvedSettingsStore.load()
        self.haptics = haptics ?? UIKitHapticsClient()
        self.audio = audio ?? UIKitAudioClient()
        self.showsStartOverlay = true

        self.engine.send(.start)
        syncFromEngine(previous: nil)
        self.engine.send(.togglePause)
        syncFromEngine(previous: nil)

        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    func moveLeft() {
        let before = state.activePiece?.position
        engine.send(.moveLeft)
        syncFromEngine(previous: state)
        if state.activePiece?.position != before {
            if settings.isHapticsEnabled { haptics.moved() }
            if settings.isSoundEnabled { audio.trigger(.move) }
        }
    }

    func moveRight() {
        let before = state.activePiece?.position
        engine.send(.moveRight)
        syncFromEngine(previous: state)
        if state.activePiece?.position != before {
            if settings.isHapticsEnabled { haptics.moved() }
            if settings.isSoundEnabled { audio.trigger(.move) }
        }
    }

    func softDrop() {
        let before = state.activePiece?.position
        engine.send(.softDrop)
        syncFromEngine(previous: state)
        if state.activePiece?.position != before {
            if settings.isHapticsEnabled { haptics.moved() }
        }
    }

    func hardDrop() {
        guard !state.isPaused, !state.isGameOver else { return }
        engine.send(.hardDrop)
        syncFromEngine(previous: state)
        boardShakeToken &+= 1
        if settings.isSoundEnabled { audio.trigger(.hardDrop) }
    }

    func togglePause() {
        if settings.isSoundEnabled { audio.trigger(.buttonTap) }
        engine.send(.togglePause)
        syncFromEngine(previous: state)
    }

    func newGame() {
        if settings.isSoundEnabled { audio.trigger(.buttonTap) }
        engine.send(.newGame)
        syncFromEngine(previous: state)
        runStartingBest = highScore
        didSetNewBestInRun = false
        showsStartOverlay = false
    }

    func setMode(_ mode: GameMode) {
        if settings.isSoundEnabled { audio.trigger(.buttonTap) }
        engine.send(.setMode(mode))
        syncFromEngine(previous: state)
        runStartingBest = highScore
        didSetNewBestInRun = false
        showsStartOverlay = false
    }

    func startGameFromOverlay() {
        guard showsStartOverlay else { return }
        if settings.isSoundEnabled { audio.trigger(.buttonTap) }
        showsStartOverlay = false
        if state.isPaused {
            engine.send(.togglePause)
            syncFromEngine(previous: state)
        }
    }

    func handleDrag(translation: CGSize) {
        guard !state.isPaused, !state.isGameOver else { return }

        let horizontal = translation.width
        let vertical = translation.height
        let swipeThreshold = Self.swipeActivationThreshold
        let hardDropThreshold = Self.hardDropSwipeThreshold

        guard max(abs(horizontal), abs(vertical)) >= swipeThreshold else { return }

        if abs(horizontal) > abs(vertical) {
            if horizontal < 0 {
                moveLeft()
            } else {
                moveRight()
            }
            return
        }

        if vertical > hardDropThreshold {
            hardDrop()
        } else if vertical > swipeThreshold {
            softDrop()
        }
    }

    func setSoundEnabled(_ enabled: Bool) {
        settings.isSoundEnabled = enabled
        settingsStore.save(settings)
    }

    func triggerButtonTapSound() {
        if settings.isSoundEnabled { audio.trigger(.buttonTap) }
    }

    func setHapticsEnabled(_ enabled: Bool) {
        settings.isHapticsEnabled = enabled
        settingsStore.save(settings)
    }

    func resetHighScore() {
        highScoreStore.save(0, for: state.gameMode)
        highScore = 0
    }

    func appDidEnterBackground() {
        stopTimer()
        guard !state.isPaused, !state.isGameOver else { return }
        pausedByLifecycle = true
        engine.send(.togglePause)
        syncFromEngine(previous: state)
    }

    func appDidBecomeActive() {
        if pausedByLifecycle, state.isPaused, !state.isGameOver {
            pausedByLifecycle = false
            engine.send(.togglePause)
            syncFromEngine(previous: state)
        } else {
            startTimerIfNeeded()
        }
    }

    private func syncFromEngine(previous: GameState?) {
        state = engine.state

        if let previous, previous.gameMode != state.gameMode {
            highScore = highScoreStore.load(for: state.gameMode)
            runStartingBest = highScore
            didSetNewBestInRun = false
        }

        if state.score > highScore {
            highScore = state.score
            highScoreStore.save(highScore, for: state.gameMode)
        }

        if let previous {
            if previous.activePiece != nil, state.activePiece == nil {
                if settings.isHapticsEnabled { haptics.pieceLocked() }
                if settings.isSoundEnabled { audio.trigger(.lock) }
            }
            if state.cascadeCount > previous.cascadeCount, state.cascadeCount > 0 {
                if settings.isHapticsEnabled { haptics.cleared(combo: state.cascadeCount) }
                if settings.isSoundEnabled {
                    audio.trigger(.clear)
                    if state.cascadeCount >= 2 {
                        audio.trigger(.cascade(level: state.cascadeCount))
                    }
                }
                comboPulseToken &+= 1
                targetPulseToken &+= 1
            }
            if !previous.isGameOver, state.isGameOver {
                if settings.isHapticsEnabled { haptics.gameOver() }
                if settings.isSoundEnabled { audio.trigger(.gameOver) }
                didSetNewBestInRun = state.score > runStartingBest
                if didSetNewBestInRun, settings.isHapticsEnabled { haptics.newBest() }
            }
            if state.didPerfectClear {
                if settings.isHapticsEnabled { haptics.perfectClear() }
                if settings.isSoundEnabled { audio.trigger(.perfectClear) }
                perfectClearToken &+= 1
            }
            if state.powerUpEventToken != previous.powerUpEventToken,
               let activation = state.lastPowerUpActivation {
                if settings.isHapticsEnabled {
                    haptics.powerUpActivated(activation.type)
                }
                if settings.isSoundEnabled {
                    switch activation.type {
                    case .rowClear: audio.trigger(.rowClear)
                    case .columnClear: audio.trigger(.columnClear)
                    case .reorder: audio.trigger(.reorder)
                    }
                }
                lastPowerUpLabel = {
                    switch activation.type {
                    case .rowClear: return "Row Clear!"
                    case .columnClear: return "Column Clear!"
                    case .reorder: return "Reorder!"
                    }
                }()
                powerUpPulseToken &+= 1
            }
            if state.sumClearEventToken != previous.sumClearEventToken,
               state.gameMode == .beginner {
                lastSumClearEvent = state.lastSumClearEvent
                sumClearPulseToken &+= 1
            }
        }

        restartTimerIfNeeded()
    }

    private func startTimer() {
        timerStartCount += 1
        timer = Timer.scheduledTimer(withTimeInterval: state.currentTickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let previous = self.state
                self.engine.send(.tick)
                self.syncFromEngine(previous: previous)
            }
        }
    }

    private func startTimerIfNeeded() {
        guard timer == nil, !state.isPaused, !state.isGameOver else { return }
        startTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimerIfNeeded() {
        if state.isPaused || state.isGameOver {
            stopTimer()
            return
        }

        guard let timer else {
            startTimer()
            return
        }

        let epsilon = 0.0001
        if abs(timer.timeInterval - state.currentTickInterval) > epsilon {
            stopTimer()
            startTimer()
        }
    }
}
