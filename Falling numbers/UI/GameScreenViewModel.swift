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

    private var engine: GameEngine
    private var timer: Timer?
    private var lastTimerUptime: TimeInterval?
    private var isCurrentRunEligibleForHighScore = true
    private var highScoreStore: HighScoreStoring
    private let settingsStore: SettingsStoring
    private let haptics: HapticsClient
    private let audio: AudioClient
    private var pausedByLifecycle = false
    private(set) var timerStartCount = 0
    private var runStartingBest: Int
    var isNewBestForCurrentGameOver: Bool {
        isCurrentRunEligibleForHighScore && state.isGameOver && state.score > runStartingBest
    }

    var showsCascadeHUD: Bool {
        state.gameMode == .beginner
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
        isCurrentRunEligibleForHighScore = true
        engine.send(.newGame)
        syncFromEngine(previous: state)
        runStartingBest = highScore
        didSetNewBestInRun = false
        showsStartOverlay = false
    }

    func setMode(_ mode: GameMode) {
        if settings.isSoundEnabled { audio.trigger(.buttonTap) }
        isCurrentRunEligibleForHighScore = true
        engine.send(.setMode(mode))
        syncFromEngine(previous: state)
        runStartingBest = highScore
        didSetNewBestInRun = false
        showsStartOverlay = false
    }

    func playFromMenu(mode: GameMode) {
        pausedByLifecycle = false
        if state.gameMode != mode || state.isGameOver {
            setMode(mode)
        } else {
            showsStartOverlay = false
            if state.isPaused { togglePause() }
        }
    }

    func pauseForMenu() {
        pausedByLifecycle = false
        if !state.isPaused, !state.isGameOver { togglePause() }
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
        runStartingBest = 0
        didSetNewBestInRun = false
        isCurrentRunEligibleForHighScore = false
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

        if isCurrentRunEligibleForHighScore, state.score > highScore {
            highScore = state.score
            highScoreStore.save(highScore, for: state.gameMode)
        }

        if let previous {
            if state.telemetry.totalLocks > previous.telemetry.totalLocks {
                if settings.isHapticsEnabled { haptics.pieceLocked() }
                if settings.isSoundEnabled { audio.trigger(.lock) }
            }
            if state.linesCleared > previous.linesCleared {
                if state.gameMode == .beginner {
                    if settings.isHapticsEnabled { haptics.cleared(combo: state.cascadeCount) }
                    if settings.isSoundEnabled {
                        audio.trigger(.clear)
                        if state.cascadeCount >= 2 {
                            audio.trigger(.cascade(level: state.cascadeCount))
                        }
                    }
                    comboPulseToken &+= 1
                } else {
                    if settings.isHapticsEnabled { haptics.cleared(combo: 1) }
                    if settings.isSoundEnabled { audio.trigger(.clear) }
                }
                targetPulseToken &+= 1
            }
            if !previous.isGameOver, state.isGameOver {
                if settings.isHapticsEnabled { haptics.gameOver() }
                if settings.isSoundEnabled { audio.trigger(.gameOver) }
                didSetNewBestInRun = isCurrentRunEligibleForHighScore && state.score > runStartingBest
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
            if state.sumClearEventToken != previous.sumClearEventToken {
                lastSumClearEvent = state.lastSumClearEvent
                sumClearPulseToken &+= 1
            }
        }

        restartTimerIfNeeded()
    }

    private func startTimer() {
        timerStartCount += 1
        lastTimerUptime = ProcessInfo.processInfo.systemUptime
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let previous = self.state
                let now = ProcessInfo.processInfo.systemUptime
                guard let last = self.lastTimerUptime else { return }
                self.lastTimerUptime = now
                self.engine.send(.advanceTime(now - last))
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
        lastTimerUptime = nil
    }

    private func restartTimerIfNeeded() {
        if state.isPaused || state.isGameOver {
            stopTimer()
            return
        }

        guard timer != nil else {
            startTimer()
            return
        }

        // The clock measures elapsed time independently of the current fall speed.

    }
}
