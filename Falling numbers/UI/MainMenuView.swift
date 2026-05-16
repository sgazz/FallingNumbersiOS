import SwiftUI

struct MainMenuView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    var onPlay: (GameMode) -> Void
    @State private var isHowToPresented = false
    @State private var isSettingsPresented = false
    @State private var drift = false
    @State private var selectedMode: GameMode = .beginner

    var body: some View {
        ZStack {
            NeonTheme.backgroundGradient
                .ignoresSafeArea()

            floatingBackgroundTiles

            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(NeonTheme.textPrimary)
                            .frame(width: 42, height: 42)
                            .background(NeonTheme.chipFill)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(NeonTheme.chipStroke, lineWidth: 1))
                    }
                    .accessibilityLabel("Settings")
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 18)

                Image("MenuAppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: NeonTheme.glowColor.opacity(0.28), radius: 18, y: 8)
                    .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Text("Fall, Number… Fall!")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(NeonTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .shadow(color: NeonTheme.accentSecondary.opacity(0.35), radius: 8)
                    Text("Learn addition by making number lines.")
                        .font(.subheadline)
                        .foregroundStyle(NeonTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 20)

                VStack(spacing: 10) {
                    modePicker

                    menuButton(title: "PLAY", primary: true) {
                        onPlay(selectedMode)
                    }
                    .accessibilityLabel("Play")

                    menuButton(title: "HOW TO PLAY", primary: false) {
                        isHowToPresented = true
                    }
                    .accessibilityLabel("How to play")
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(NeonTheme.panelFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(NeonTheme.cardStroke, lineWidth: 1)
                )
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.vertical, 18)
        }
        .sheet(isPresented: $isHowToPresented) {
            HowToPlayView()
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(viewModel: viewModel)
        }
        .onAppear {
            selectedMode = viewModel.state.gameMode
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(GameMode.allCases, id: \.self) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    VStack(spacing: 2) {
                        Text(mode.title)
                            .font(.subheadline.weight(.bold))
                        Text(mode == .expert ? "Full random targets and numbers from the start." : "Current friendly ramp and pacing.")
                            .font(.caption2.weight(.medium))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(selectedMode == mode ? Color.white : NeonTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedMode == mode ? AnyShapeStyle(NeonTheme.buttonFill) : AnyShapeStyle(NeonTheme.chipFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedMode == mode ? Color.white.opacity(0.26) : NeonTheme.chipStroke, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.title)
            }
        }
    }

    private func menuButton(title: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(primary ? Color.white : NeonTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(primary ? AnyShapeStyle(NeonTheme.buttonFill) : AnyShapeStyle(NeonTheme.chipFill))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(primary ? Color.white.opacity(0.26) : NeonTheme.chipStroke, lineWidth: 1.0)
                )
        }
        .buttonStyle(.plain)
    }

    private var floatingBackgroundTiles: some View {
        ZStack {
            floatingTile("3", color: Color(NeonTheme.tileColor(for: 3)), x: -130, y: -220, rotation: -11)
            floatingTile("6", color: Color(NeonTheme.tileColor(for: 6)), x: 100, y: -180, rotation: 8)
            floatingTile("8", color: Color(NeonTheme.tileColor(for: 8)), x: -120, y: 120, rotation: -7)
            floatingTile("4", color: Color(NeonTheme.tileColor(for: 4)), x: 115, y: 170, rotation: 10)
        }
        .opacity(0.34)
        .allowsHitTesting(false)
    }

    private func floatingTile(_ value: String, color: Color, x: CGFloat, y: CGFloat, rotation: Double) -> some View {
        Text(value)
            .font(.system(size: 28, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 66, height: 66)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.45), radius: 10)
            .rotationEffect(.degrees(rotation + (drift ? 2.5 : -2.5)))
            .offset(x: x + (drift ? 6 : -6), y: y + (drift ? -10 : 10))
    }
}

#if DEBUG
struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainMenuView(viewModel: GameScreenViewModel(), onPlay: { _ in })
                .previewDisplayName("Menu - iPhone SE")
                .previewDevice("iPhone SE (3rd generation)")

            MainMenuView(viewModel: GameScreenViewModel(), onPlay: { _ in })
                .previewDisplayName("Menu - iPhone 16")
                .previewDevice("iPhone 16")

            MainMenuView(viewModel: GameScreenViewModel(), onPlay: { _ in })
                .previewDisplayName("Menu - iPhone 16 Pro Max")
                .previewDevice("iPhone 16 Pro Max")
        }
    }
}
#endif
