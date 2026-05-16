import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NeonTheme.backgroundGradient
                    .ignoresSafeArea()

                Circle()
                    .fill(NeonTheme.accentSecondary.opacity(0.18))
                    .frame(width: 280, height: 280)
                    .blur(radius: 24)
                    .offset(x: -120, y: -220)

                Circle()
                    .fill(NeonTheme.accentPrimary.opacity(0.15))
                    .frame(width: 240, height: 240)
                    .blur(radius: 20)
                    .offset(x: 120, y: 240)

                ScrollView {
                    VStack(spacing: 12) {
                        settingsCard(title: "Feedback") {
                            Toggle("Sound", isOn: Binding(
                                get: { viewModel.settings.isSoundEnabled },
                                set: { viewModel.setSoundEnabled($0) }
                            ))
                            .tint(NeonTheme.accentPrimary)
                            .foregroundStyle(NeonTheme.textPrimary)
                            .accessibilityLabel("Sound")

                            Divider()
                                .overlay(NeonTheme.chipStroke.opacity(0.8))

                            Toggle("Haptics", isOn: Binding(
                                get: { viewModel.settings.isHapticsEnabled },
                                set: { viewModel.setHapticsEnabled($0) }
                            ))
                            .tint(NeonTheme.accentSecondary)
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
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.99, green: 0.74, blue: 0.31),
                                                    Color(red: 0.98, green: 0.55, blue: 0.27)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.28), lineWidth: 0.9)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Reset high score")
                        }

#if DEBUG
                        settingsCard(title: "Diagnostics") {
                            Toggle("Show Debug Overlay", isOn: $viewModel.diagnosticsEnabled)
                                .tint(NeonTheme.accentSecondary)
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
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                .font(.caption.weight(.heavy))
                .tracking(0.8)
                .foregroundStyle(NeonTheme.textSecondary)

            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(NeonTheme.panelFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(NeonTheme.cardStroke, lineWidth: 1.0)
        )
    }
}
