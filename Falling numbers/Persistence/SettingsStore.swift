import Foundation

struct AppSettings: Equatable {
    var isSoundEnabled: Bool
    var isHapticsEnabled: Bool

    static let `default` = AppSettings(isSoundEnabled: true, isHapticsEnabled: true)
}

protocol SettingsStoring {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

struct UserDefaultsSettingsStore: SettingsStoring {
    private let defaults: UserDefaults
    private let soundKey: String
    private let hapticsKey: String

    init(
        defaults: UserDefaults = .standard,
        soundKey: String = "falling_numbers_sound_enabled",
        hapticsKey: String = "falling_numbers_haptics_enabled"
    ) {
        self.defaults = defaults
        self.soundKey = soundKey
        self.hapticsKey = hapticsKey
    }

    func load() -> AppSettings {
        let hasSound = defaults.object(forKey: soundKey) != nil
        let hasHaptics = defaults.object(forKey: hapticsKey) != nil

        return AppSettings(
            isSoundEnabled: hasSound ? defaults.bool(forKey: soundKey) : AppSettings.default.isSoundEnabled,
            isHapticsEnabled: hasHaptics ? defaults.bool(forKey: hapticsKey) : AppSettings.default.isHapticsEnabled
        )
    }

    func save(_ settings: AppSettings) {
        defaults.set(settings.isSoundEnabled, forKey: soundKey)
        defaults.set(settings.isHapticsEnabled, forKey: hapticsKey)
    }
}
