import Foundation

struct AppSettings: Equatable {
    var isSoundEnabled: Bool
    var isHapticsEnabled: Bool
    var theme: AppTheme
    var isColorBlindModeEnabled: Bool

    init(isSoundEnabled: Bool, isHapticsEnabled: Bool, isColorBlindModeEnabled: Bool = false, theme: AppTheme = .classic) {
        self.theme = theme
        self.isSoundEnabled = isSoundEnabled
        self.isHapticsEnabled = isHapticsEnabled
        self.isColorBlindModeEnabled = isColorBlindModeEnabled
    }

    static let `default` = AppSettings(isSoundEnabled: true, isHapticsEnabled: true, isColorBlindModeEnabled: false)
}

protocol SettingsStoring {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

struct UserDefaultsSettingsStore: SettingsStoring {
    private let defaults: UserDefaults
    private let soundKey: String
    private let hapticsKey: String
    private let colorBlindKey: String

    init(
        defaults: UserDefaults = .standard,
        soundKey: String = "falling_numbers_sound_enabled",
        hapticsKey: String = "falling_numbers_haptics_enabled",
        colorBlindKey: String = "falling_numbers_color_blind_enabled"
    ) {
        self.defaults = defaults
        self.soundKey = soundKey
        self.hapticsKey = hapticsKey
        self.colorBlindKey = colorBlindKey
    }

    func load() -> AppSettings {
        let hasSound = defaults.object(forKey: soundKey) != nil
        let hasHaptics = defaults.object(forKey: hapticsKey) != nil
        let hasColorBlind = defaults.object(forKey: colorBlindKey) != nil

        return AppSettings(
            isSoundEnabled: hasSound ? defaults.bool(forKey: soundKey) : AppSettings.default.isSoundEnabled,
            isHapticsEnabled: hasHaptics ? defaults.bool(forKey: hapticsKey) : AppSettings.default.isHapticsEnabled,
            isColorBlindModeEnabled: hasColorBlind ? defaults.bool(forKey: colorBlindKey) : AppSettings.default.isColorBlindModeEnabled,
            theme: AppTheme(rawValue: defaults.string(forKey: AppTheme.storageKey) ?? "") ?? .classic
        )
    }

    func save(_ settings: AppSettings) {
        defaults.set(settings.theme.rawValue, forKey: AppTheme.storageKey)
        defaults.set(settings.isSoundEnabled, forKey: soundKey)
        defaults.set(settings.isHapticsEnabled, forKey: hapticsKey)
        defaults.set(settings.isColorBlindModeEnabled, forKey: colorBlindKey)
    }
}

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
