import Foundation
@testable import Falling_numbers

@MainActor
final class TestHighScoreStore: HighScoreStoring {
    private(set) var beginnerValue: Int
    private(set) var expertValue: Int

    init(initial: Int) {
        beginnerValue = initial
        expertValue = initial
    }

    init(initialBeginner: Int, initialExpert: Int) {
        beginnerValue = initialBeginner
        expertValue = initialExpert
    }

    func load(for mode: GameMode) -> Int {
        switch mode {
        case .beginner:
            return beginnerValue
        case .expert:
            return expertValue
        }
    }

    func save(_ value: Int, for mode: GameMode) {
        switch mode {
        case .beginner:
            beginnerValue = value
        case .expert:
            expertValue = value
        }
    }

    func savedValue(for mode: GameMode) -> Int {
        switch mode {
        case .beginner:
            return beginnerValue
        case .expert:
            return expertValue
        }
    }
}

final class RecordingAudioClient: AudioClient {
    private(set) var events: [SoundEvent] = []

    func trigger(_ event: SoundEvent) {
        events.append(event)
    }
}

@MainActor
final class TestSettingsStore: SettingsStoring {
    private(set) var savedSettings: AppSettings

    init(initial: AppSettings) {
        savedSettings = initial
    }

    func load() -> AppSettings {
        savedSettings
    }

    func save(_ settings: AppSettings) {
        savedSettings = settings
    }
}

@MainActor
final class RecordingHapticsClient: HapticsClient {
    private(set) var lockCount = 0
    private(set) var clearCount = 0
    func moved() {}
    func pieceLocked() { lockCount += 1 }
    func cleared(combo: Int) { clearCount += 1 }
    func perfectClear() {}
    func gameOver() {}
    func newBest() {}
    func powerUpActivated(_ type: PowerUpType) {}
}
