import Foundation
import Testing
import UIKit
@testable import Falling_numbers

@MainActor
struct ThemeTests {
    @Test
    func settingsDefaultAndUnknownThemeFallBackToClassic() throws {
        let name = "ThemeTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = UserDefaultsSettingsStore(defaults: defaults)
        #expect(store.load().theme == .classic)
        defaults.set("unknown-future-theme", forKey: AppTheme.storageKey)
        #expect(store.load().theme == .classic)
    }

    @Test(arguments: AppTheme.allCases)
    func themeSurvivesSettingsReloadAndOtherChanges(theme: AppTheme) throws {
        let name = "ThemeTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = UserDefaultsSettingsStore(defaults: defaults)
        var settings = store.load()
        settings.theme = theme
        settings.isColorBlindModeEnabled = true
        settings.isSoundEnabled = false
        store.save(settings)
        #expect(UserDefaultsSettingsStore(defaults: defaults).load() == settings)
        settings.isHapticsEnabled = false
        store.save(settings)
        #expect(store.load().theme == theme)
    }

    @Test(arguments: AppTheme.allCases)
    func choosingThemePreservesCurrentRunAndFeedbackSettings(theme: AppTheme) {
        let store = TestSettingsStore(initial: AppSettings(isSoundEnabled: false, isHapticsEnabled: false))
        let vm = GameScreenViewModel(settingsStore: store, haptics: NoopHapticsClient(), audio: NoopAudioClient())
        let before = vm.state
        vm.setTheme(theme)
        #expect(vm.settings.theme == theme)
        #expect(store.savedSettings.theme == theme)
        #expect(!vm.settings.isSoundEnabled && !vm.settings.isHapticsEnabled)
        #expect(vm.state.runID == before.runID)
        #expect(vm.state.board == before.board)
        #expect(vm.state.activePiece == before.activePiece)
        #expect(vm.state.score == before.score)
        vm.setTheme(.classic)
        #expect(store.savedSettings.theme == .classic)
    }

    @Test
    func cappuccinoTilesUseOneColorWithReadableWhiteText() {
        let color = ArcadeTheme.tileColor(for: 1, theme: .cappuccino)
        for value in 1...9 {
            #expect(ArcadeTheme.tileColor(for: value, theme: .cappuccino) == color)
            #expect(ArcadeTheme.tileColor(for: value, theme: .cappuccino, colorBlind: true) == color)
        }
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func linear(_ value: CGFloat) -> Double {
            let v = Double(value)
            return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        #expect(1.05 / (luminance + 0.05) >= 4.5)
        #expect(ArcadeTheme.tileColor(for: 1, theme: .classic, colorBlind: false)
            != ArcadeTheme.tileColor(for: 2, theme: .classic, colorBlind: false))
    }
    @Test
    func carnivalHasNineDistinctReadableColorsAndSupportsColorBlindPalette() {
        var colors: [UIColor] = []
        for value in 1...9 {
            let color = ArcadeTheme.tileColor(for: value, theme: .carnival, colorBlind: false)
            #expect(!colors.contains(color))
            colors.append(color)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            func linear(_ v: CGFloat) -> Double {
                let d = Double(v)
                return d <= 0.04045 ? d / 12.92 : pow((d + 0.055) / 1.055, 2.4)
            }
            let luminance = 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
            #expect(1.05 / (luminance + 0.05) >= 4.5)
            #expect(ArcadeTheme.tileColor(for: value, theme: .carnival, colorBlind: true)
                == ArcadeTheme.tileColor(for: value, theme: .classic, colorBlind: true))
        }
    }

    @Test(arguments: [false, true])
    func neonTilesKeepWhiteNumbersReadableAndUseDistinctOutlines(colorBlind: Bool) {
        var accents: [UIColor] = []
        for value in 1...9 {
            let fill = ArcadeTheme.tileColor(for: value, theme: .neon, colorBlind: colorBlind)
            let accent = ArcadeTheme.tileAccent(for: value, theme: .neon, colorBlind: colorBlind)
            #expect(!accents.contains(accent))
            accents.append(accent)
            func luminance(_ color: UIColor) -> Double {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                func linear(_ v: CGFloat) -> Double {
                    let d = Double(v)
                    return d <= 0.04045 ? d / 12.92 : pow((d + 0.055) / 1.055, 2.4)
                }
                return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
            }
            #expect(1.05 / (luminance(fill) + 0.05) >= 7)
            #expect(luminance(accent) > luminance(fill))
        }
    }

}
