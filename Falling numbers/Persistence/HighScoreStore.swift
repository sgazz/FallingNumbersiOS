import Foundation

protocol HighScoreStoring {
    func load() -> Int
    func save(_ value: Int)
}

struct UserDefaultsHighScoreStore: HighScoreStoring {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "falling_numbers_high_score") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> Int {
        max(0, defaults.integer(forKey: key))
    }

    func save(_ value: Int) {
        defaults.set(max(0, value), forKey: key)
    }
}
