import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NeonTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        settingsCard(title: "Feedback") {
                            Toggle("Sound", isOn: Binding(
                                get: { viewModel.settings.isSoundEnabled },
                                set: { viewModel.setSoundEnabled($0) }
                            ))
                            .tint(NeonTheme.controlsTint)
                            .foregroundStyle(NeonTheme.textPrimary)
                            .accessibilityLabel("Sound")

                            Divider()
                                .overlay(NeonTheme.chipStroke.opacity(0.8))

                            Toggle("Haptics", isOn: Binding(
                                get: { viewModel.settings.isHapticsEnabled },
                                set: { viewModel.setHapticsEnabled($0) }
                            ))
                            .tint(NeonTheme.controlsTint)
                            .foregroundStyle(NeonTheme.textPrimary)
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
                                .foregroundStyle(NeonTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(red: 0.95, green: 0.87, blue: 0.78))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(red: 0.50, green: 0.34, blue: 0.24).opacity(0.35), lineWidth: 0.8)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Reset high score")
                        }

#if DEBUG
                        settingsCard(title: "Diagnostics") {
                            Toggle("Show Debug Overlay", isOn: $viewModel.diagnosticsEnabled)
                                .tint(NeonTheme.controlsTint)
                                .foregroundStyle(NeonTheme.textPrimary)
                                .accessibilityLabel("Show debug overlay")
                        }
#endif
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
                        .foregroundStyle(NeonTheme.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(NeonTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(NeonTheme.chipFill)
                        )
                        .overlay(
                            Capsule()
                                .stroke(NeonTheme.chipStroke, lineWidth: 0.8)
                        )
                        .accessibilityLabel("Done")
                }
            }
        }
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(NeonTheme.textSecondary)

            content()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(NeonTheme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(NeonTheme.cardStroke, lineWidth: 0.9)
        )
    }
}
