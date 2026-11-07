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
    @Published private(set) var comboPulseToken: Int = 0
    @Published private(set) var targetPulseToken: Int = 0
    @Published private(set) var targetChangeToken: Int = 0
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

    var targetTimerProgress: Double {
        guard engine.config.targetChangeInterval > 0 else { return 0 }
        return min(1, max(0, state.targetTimerRemaining / engine.config.targetChangeInterval))
    }

    var levelProgress: Double {
        LevelSystem().progressToNextLevel(score: state.score)
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
        syncFromEngine(previous: state, hardDrop: true)
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
        if !enabled { audio.stop() }
        settingsStore.save(settings)
    }

    func triggerButtonTapSound() {
        if settings.isSoundEnabled { audio.trigger(.buttonTap) }
    }

    func setHapticsEnabled(_ enabled: Bool) {
        settings.isHapticsEnabled = enabled
        settingsStore.save(settings)
    }

    func setColorBlindModeEnabled(_ enabled: Bool) {
        settings.isColorBlindModeEnabled = enabled
        settingsStore.save(settings)
        objectWillChange.send()
    }

    func resetHighScore() {
        highScoreStore.save(0, for: state.gameMode)
        highScore = 0
        runStartingBest = 0
        didSetNewBestInRun = false
        isCurrentRunEligibleForHighScore = false
    }

    func appDidEnterBackground() {
        audio.stop()
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

    private func syncFromEngine(previous: GameState?, hardDrop: Bool = false) {
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
            deliverFeedback(previous: previous, hardDrop: hardDrop)
            if state.linesCleared > previous.linesCleared {
                if state.gameMode == .beginner { comboPulseToken &+= 1 }
                targetPulseToken &+= 1
            }
            if state.didTargetChange {
                targetChangeToken &+= 1
            }
            if !previous.isGameOver, state.isGameOver {
                didSetNewBestInRun = isCurrentRunEligibleForHighScore && state.score > runStartingBest
            }
            if state.didPerfectClear {
                perfectClearToken &+= 1
            }
            if state.powerUpEventToken != previous.powerUpEventToken,
               let activation = state.lastPowerUpActivation {
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

    private func deliverFeedback(previous: GameState, hardDrop: Bool) {
        // A resolved turn gets one primary effect, rather than overlapping impacts and tones.
        let sound: SoundEvent
        let haptic: () -> Void
        if !previous.isGameOver, state.isGameOver {
            sound = .gameOver
            haptic = {
                if self.isCurrentRunEligibleForHighScore && self.state.score > self.runStartingBest {
                    self.haptics.newBest()
                } else {
                    self.haptics.gameOver()
                }
            }
        } else if state.didPerfectClear {
            sound = .perfectClear
            haptic = { self.haptics.perfectClear() }
        } else if state.powerUpEventToken != previous.powerUpEventToken,
                  let activation = state.lastPowerUpActivation {
            switch activation.type {
            case .rowClear: sound = .rowClear
            case .columnClear: sound = .columnClear
            case .reorder: sound = .reorder
            }
            haptic = { self.haptics.powerUpActivated(activation.type) }
        } else if state.linesCleared > previous.linesCleared {
            let combo = state.gameMode == .beginner ? state.cascadeCount : 1
            sound = combo >= 2 ? .cascade(level: combo) : .clear
            haptic = { self.haptics.cleared(combo: combo) }
        } else if state.telemetry.totalLocks > previous.telemetry.totalLocks {
            sound = hardDrop ? .hardDrop : .lock
            haptic = { self.haptics.pieceLocked() }
        } else {
            return
        }
        if settings.isSoundEnabled { audio.trigger(sound) }
        if settings.isHapticsEnabled {
            // A warning replaces the ordinary placement impact; stronger outcomes keep their feedback.
            if (sound == .lock || sound == .hardDrop),
               occupancyRatio(previous) < 0.70, occupancyRatio(state) >= 0.70 {
                haptics.warning()
            } else {
                haptic()
            }
        }
    }

    private func occupancyRatio(_ state: GameState) -> Double {
        let capacity = max(1, state.board.rows * state.board.columns)
        return Double(state.board.allOccupiedPositions().count) / Double(capacity)
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
