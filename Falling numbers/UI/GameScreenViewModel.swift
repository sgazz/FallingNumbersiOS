import Foundation
import Combine
import CoreGraphics

@MainActor
final class GameScreenViewModel: ObservableObject {
    @Published private(set) var state: GameState
    @Published private(set) var highScore: Int
    @Published private(set) var boardShakeToken: Int = 0
    @Published private(set) var comboPulseToken: Int = 0
    @Published private(set) var targetPulseToken: Int = 0

    private var engine: GameEngine
    private var timer: Timer?
    private var highScoreStore: HighScoreStoring
    private let haptics: HapticsClient
    private let audio: AudioClient

    init(
        engine: GameEngine? = nil,
        highScoreStore: HighScoreStoring? = nil,
        haptics: HapticsClient? = nil,
        audio: AudioClient? = nil
    ) {
        let resolvedEngine = engine ?? GameEngine()
        let resolvedHighScoreStore = highScoreStore ?? UserDefaultsHighScoreStore()

        self.engine = resolvedEngine
        self.state = resolvedEngine.state
        self.highScoreStore = resolvedHighScoreStore
        self.highScore = resolvedHighScoreStore.load()
        self.haptics = haptics ?? UIKitHapticsClient()
        self.audio = audio ?? NoopAudioClient()

        self.engine.send(.start)
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
            haptics.moved()
            audio.trigger(.move)
        }
    }

    func moveRight() {
        let before = state.activePiece?.position
        engine.send(.moveRight)
        syncFromEngine(previous: state)
        if state.activePiece?.position != before {
            haptics.moved()
            audio.trigger(.move)
        }
    }

    func softDrop() {
        let before = state.activePiece?.position
        engine.send(.softDrop)
        syncFromEngine(previous: state)
        if state.activePiece?.position != before {
            haptics.moved()
        }
    }

    func hardDrop() {
        guard !state.isPaused, !state.isGameOver else { return }
        engine.send(.hardDrop)
        syncFromEngine(previous: state)
        boardShakeToken &+= 1
        audio.trigger(.hardDrop)
    }

    func togglePause() {
        engine.send(.togglePause)
        syncFromEngine(previous: state)
    }

    func newGame() {
        engine.send(.newGame)
        syncFromEngine(previous: state)
    }

    func handleDrag(translation: CGSize) {
        guard !state.isPaused, !state.isGameOver else { return }

        let horizontal = translation.width
        let vertical = translation.height

        guard max(abs(horizontal), abs(vertical)) >= 20 else { return }

        if abs(horizontal) > abs(vertical) {
            if horizontal < 0 {
                moveLeft()
            } else {
                moveRight()
            }
            return
        }

        if vertical > 90 {
            hardDrop()
        } else if vertical > 20 {
            softDrop()
        }
    }

    private func syncFromEngine(previous: GameState?) {
        state = engine.state

        if state.score > highScore {
            highScore = state.score
            highScoreStore.save(highScore)
        }

        if let previous {
            if previous.activePiece != nil, state.activePiece == nil {
                haptics.pieceLocked()
                audio.trigger(.lock)
            }
            if state.comboCount > previous.comboCount, state.comboCount > 0 {
                haptics.cleared(combo: state.comboCount)
                audio.trigger(.clear(combo: state.comboCount))
                comboPulseToken &+= 1
                targetPulseToken &+= 1
            }
            if !previous.isGameOver, state.isGameOver {
                haptics.gameOver()
                audio.trigger(.gameOver)
            }
        }

        restartTimerIfNeeded()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: state.currentTickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let previous = self.state
                self.engine.send(.tick)
                self.syncFromEngine(previous: previous)
            }
        }
    }

    private func restartTimerIfNeeded() {
        guard let timer else { return }
        let epsilon = 0.0001
        if abs(timer.timeInterval - state.currentTickInterval) > epsilon {
            timer.invalidate()
            startTimer()
        }
    }
}
