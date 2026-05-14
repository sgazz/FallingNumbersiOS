import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Feedback") {
                    Toggle("Sound", isOn: Binding(
                        get: { viewModel.settings.isSoundEnabled },
                        set: { viewModel.setSoundEnabled($0) }
                    ))
                    Toggle("Haptics", isOn: Binding(
                        get: { viewModel.settings.isHapticsEnabled },
                        set: { viewModel.setHapticsEnabled($0) }
                    ))
                }

                Section("Data") {
                    Button("Reset High Score", role: .destructive) {
                        viewModel.resetHighScore()
                    }
                }

#if DEBUG
                Section("Diagnostics") {
                    Toggle("Show Debug Overlay", isOn: $viewModel.diagnosticsEnabled)
                }
#endif
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
