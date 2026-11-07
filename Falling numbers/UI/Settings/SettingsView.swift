import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ArcadeTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        settingsCard(title: "Appearance") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(AppTheme.allCases, id: \.self) { theme in
                                    let isSelected = viewModel.settings.theme == theme
                                    Button { viewModel.setTheme(theme) } label: {
                                        HStack(spacing: 6) {
                                            Text(theme.title)
                                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.85)
                                            if isSelected {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.weight(.bold))
                                            }
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .foregroundStyle(isSelected
                                            ? (ArcadeTheme.isNeon ? Color.black : Color.white)
                                            : ArcadeTheme.textPrimary)
                                        .background(isSelected ? ArcadeTheme.accentPrimary : ArcadeTheme.chipFill,
                                                    in: RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(theme.title)
                                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                                }
                            }
                            .accessibilityIdentifier("settings.theme")

                            HStack(spacing: 8) {
                                ForEach(1...3, id: \.self) { number in
                                    Text("\(number)")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                        .frame(width: 42, height: 42)
                                        .background(Color(ArcadeTheme.tileColor(for: number, theme: viewModel.settings.theme,
                                                                               colorBlind: viewModel.settings.isColorBlindModeEnabled)),
                                                    in: RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(ArcadeTheme.tileAccent(for: number, theme: viewModel.settings.theme,
                                                                                colorBlind: viewModel.settings.isColorBlindModeEnabled)), lineWidth: 1.5))
                                }
                                Spacer()
                            }
                            .accessibilityHidden(true)
                            Text(viewModel.settings.theme.detail)
                                .font(.footnote)
                                .foregroundStyle(ArcadeTheme.textSecondary)
                        }

                        settingsCard(title: "Feedback") {
                            Toggle("Sound", isOn: Binding(
                                get: { viewModel.settings.isSoundEnabled },
                                set: { viewModel.setSoundEnabled($0) }
                            ))
                            .tint(ArcadeTheme.accentPrimary)
                            .foregroundStyle(ArcadeTheme.textPrimary)
                            .accessibilityLabel("Sound")

                            Button(action: viewModel.testSound) {
                                Label("Test Sound", systemImage: "speaker.wave.2.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .foregroundStyle(ArcadeTheme.textPrimary)
                                    .background(ArcadeTheme.chipFill, in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .disabled(!viewModel.settings.isSoundEnabled)
                            .opacity(viewModel.settings.isSoundEnabled ? 1 : 0.45)
                            .accessibilityLabel("Test sound")
                            Text("Uses media volume, even in Silent Mode. Test Sound plays a short preview.")
                                .font(.footnote)
                                .foregroundStyle(ArcadeTheme.textSecondary)

                            Divider()
                                .overlay(ArcadeTheme.chipStroke.opacity(0.8))

                            Toggle("Haptics", isOn: Binding(
                                get: { viewModel.settings.isHapticsEnabled },
                                set: { viewModel.setHapticsEnabled($0) }
                            ))
                            .tint(ArcadeTheme.accentSecondary)
                            .foregroundStyle(ArcadeTheme.textPrimary)
                            .accessibilityLabel("Haptics")

                            Divider()
                                .overlay(ArcadeTheme.chipStroke.opacity(0.8))

                            Toggle("Color Blind Mode", isOn: Binding(
                                get: { viewModel.settings.isColorBlindModeEnabled },
                                set: { viewModel.setColorBlindModeEnabled($0) }
                            ))
                            .tint(ArcadeTheme.accentPrimary)
                            .foregroundStyle(ArcadeTheme.textPrimary)
                            .accessibilityLabel("Color Blind Mode")
                            Text(viewModel.settings.theme == .cappuccino
                                ? "Cappuccino uses a single tile color. Numbers and symbols distinguish the pieces; this option changes the colorful palettes."
                                : "Uses a high-contrast palette designed to remain distinguishable without relying on color alone.")
                                .font(.footnote)
                                .foregroundStyle(ArcadeTheme.textSecondary)
                        }

                        settingsCard(title: "Data") {
                            Button(action: {
                                viewModel.resetHighScore()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.counterclockwise.circle")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Reset High Score")
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                }
                                .foregroundStyle(ArcadeTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            ArcadeTheme.accentSecondary.opacity(0.10)
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.28), lineWidth: 0.9)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Reset high score")
                            Text("Resets the record for the current mode. This game will no longer set a record; start a new game to set one.")
                                .font(.footnote)
                                .foregroundStyle(ArcadeTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(viewModel.settings.theme == .neon ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(ArcadeTheme.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ArcadeTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(ArcadeTheme.chipFill)
                        )
                        .overlay(
                            Capsule()
                                .stroke(ArcadeTheme.chipStroke, lineWidth: 0.8)
                        )
                        .accessibilityLabel("Done")
                }
            }
        }
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.heavy))
                .tracking(0.8)
                .foregroundStyle(ArcadeTheme.textSecondary)

            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ArcadeTheme.panelFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ArcadeTheme.cardStroke, lineWidth: 1.0)
        )
    }
}
