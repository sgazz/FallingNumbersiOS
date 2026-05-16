import Foundation

protocol HighScoreStoring {
    func load(for mode: GameMode) -> Int
    func save(_ value: Int, for mode: GameMode)
}

extension HighScoreStoring {
    func load() -> Int { load(for: .beginner) }
    func save(_ value: Int) { save(value, for: .beginner) }
}

struct UserDefaultsHighScoreStore: HighScoreStoring {
    private let defaults: UserDefaults
    private let beginnerKey: String
    private let expertKey: String

    init(
        defaults: UserDefaults = .standard,
        beginnerKey: String = "falling_numbers_high_score_beginner",
        expertKey: String = "falling_numbers_high_score_expert"
    ) {
        self.defaults = defaults
        self.beginnerKey = beginnerKey
        self.expertKey = expertKey
    }

    func load(for mode: GameMode) -> Int {
        max(0, defaults.integer(forKey: key(for: mode)))
    }

    func save(_ value: Int, for mode: GameMode) {
        defaults.set(max(0, value), forKey: key(for: mode))
    }

    private func key(for mode: GameMode) -> String {
        switch mode {
        case .beginner:
            return beginnerKey
        case .expert:
            return expertKey
        }
    }
}
