import SwiftUI

struct GameControlsView: View {
    @ObservedObject var viewModel: GameScreenViewModel

    var body: some View {
        HStack(spacing: 12) {
            controlButton(symbol: "chevron.left", label: "Left", accessibilityLabel: "Move left") {
                viewModel.moveLeft()
            }
            controlButton(symbol: "arrow.down", label: "Down", accessibilityLabel: "Soft drop") {
                viewModel.softDrop()
            }
            controlButton(symbol: "arrow.down.to.line", label: "Drop", accessibilityLabel: "Hard drop") {
                viewModel.hardDrop()
            }
            controlButton(symbol: "chevron.right", label: "Right", accessibilityLabel: "Move right") {
                viewModel.moveRight()
            }
        }
        .frame(height: 48)
    }

    private func controlButton(symbol: String, label: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .black))
                Text(label)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(ArcadeTheme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ArcadeTheme.chipFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ArcadeTheme.chipStroke, lineWidth: 0.9)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
        }
        .buttonStyle(ControlPadButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}
private struct ControlPadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: Color(red: 0.40, green: 0.29, blue: 0.21).opacity(configuration.isPressed ? 0.22 : 0.0),
                radius: configuration.isPressed ? 6 : 0
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
struct GameGestureControls: View {
    @ObservedObject var viewModel: GameScreenViewModel

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.moveLeft() }
                        .accessibilityHidden(true)

                    Color.clear
                        .accessibilityHidden(true)

                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.moveRight() }
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: width * 0.42, height: height * 0.34)
                    .position(x: width * 0.5, y: height * 0.82)
                    .onTapGesture { viewModel.softDrop() }
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                TapGesture(count: 2).onEnded {
                    viewModel.hardDrop()
                }
            )
            .gesture(
                DragGesture(minimumDistance: GameScreenViewModel.swipeActivationThreshold)
                    .onEnded { value in
                        viewModel.handleDrag(translation: value.translation)
                    }
            )
        }
    }
}

