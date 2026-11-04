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
                        settingsCard(title: "Feedback") {
                            Toggle("Sound", isOn: Binding(
                                get: { viewModel.settings.isSoundEnabled },
                                set: { viewModel.setSoundEnabled($0) }
                            ))
                            .tint(ArcadeTheme.accentPrimary)
                            .foregroundStyle(ArcadeTheme.textPrimary)
                            .accessibilityLabel("Sound")

                            Divider()
                                .overlay(ArcadeTheme.chipStroke.opacity(0.8))

                            Toggle("Haptics", isOn: Binding(
                                get: { viewModel.settings.isHapticsEnabled },
                                set: { viewModel.setHapticsEnabled($0) }
                            ))
                            .tint(ArcadeTheme.accentSecondary)
                            .foregroundStyle(ArcadeTheme.textPrimary)
                            .accessibilityLabel("Haptics")
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
            .toolbarColorScheme(.light, for: .navigationBar)
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
