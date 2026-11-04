import SwiftUI

struct MainMenuView: View {
    @ObservedObject var viewModel: GameScreenViewModel
    var onPlay: (GameMode) -> Void
    @State private var selectedMode: GameMode = .beginner
    @State private var isHowToPresented = false
    @State private var isSettingsPresented = false
    @State private var isCreditsPresented = false

    var body: some View {
        ZStack {
            ArcadeTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 26) {
                    HStack {
                        Text("THE ADDITION ARCADE")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(ArcadeTheme.accentPrimary)
                        Spacer()
                        Button { isSettingsPresented = true } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 46, height: 46)
                                .background(ArcadeTheme.cardFill, in: Circle())
                                .overlay(Circle().stroke(ArcadeTheme.cardStroke, lineWidth: 1))
                        }
                        .accessibilityLabel("Settings")
                    }

                    VStack(spacing: 18) {
                        HStack(spacing: 10) {
                            menuTile(4, rotation: -10)
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(ArcadeTheme.textSecondary)
                            menuTile(6, rotation: 8)
                            Image(systemName: "equal")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(ArcadeTheme.textSecondary)
                            menuTile(10, rotation: -5)
                        }
                        .padding(.vertical, 12)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Four plus six equals ten")

                        Text("Fall, Number…\nFall!")
                            .font(.system(size: 43, weight: .heavy, design: .rounded))
                            .tracking(-1.8)
                            .lineSpacing(-2)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Small numbers. Big possibilities.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(ArcadeTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("FIND YOUR RHYTHM")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1.8)
                            .foregroundStyle(ArcadeTheme.textSecondary)
                        HStack(spacing: 10) {
                            modeCard(.beginner, symbol: "leaf", subtitle: "Room to learn")
                            modeCard(.expert, symbol: "bolt", subtitle: "Think on your feet")
                        }
                        Button { onPlay(selectedMode) } label: {
                            HStack {
                                Spacer()
                                Text("Let's play")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .padding(20)
                            .foregroundStyle(.white)
                            .background(ArcadeTheme.buttonFill, in: RoundedRectangle(cornerRadius: 19))
                        }
                        .accessibilityLabel("Play")
                        Button { isHowToPresented = true } label: {
                            Label("How to play", systemImage: "questionmark.circle")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: 46)
                        }
                        .accessibilityLabel("How to play")
                    }

                    Button { isCreditsPresented = true } label: {
                        HStack(spacing: 8) {
                            Image("MenuAppIcon")
                                .resizable().frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text("MADE FOR CURIOUS MINDS")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .tracking(1.3)
                        }
                        .foregroundStyle(ArcadeTheme.textSecondary)
                        .frame(minHeight: 44)
                    }
                    .accessibilityLabel("Credits")
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 18)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(ArcadeTheme.textPrimary)
        .buttonStyle(.plain)
        .sheet(isPresented: $isHowToPresented) { HowToPlayView() }
        .sheet(isPresented: $isSettingsPresented) { SettingsView(viewModel: viewModel) }
        .sheet(isPresented: $isCreditsPresented) {
            NavigationStack {
                VStack(spacing: 20) {
                    Image("SGLogo")
                        .resizable().renderingMode(.template).scaledToFit()
                        .frame(width: 150, height: 60)
                    Text("Made by Stanko G.").font(.title3.bold())
                    Text(String(Calendar.current.component(.year, from: Date())))
                        .foregroundStyle(ArcadeTheme.textSecondary)
                }
                .foregroundStyle(ArcadeTheme.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ArcadeTheme.backgroundGradient)
                .navigationTitle("About")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isCreditsPresented = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onAppear { selectedMode = viewModel.state.gameMode }
    }

    private func menuTile(_ number: Int, rotation: Double) -> some View {
        Text("\(number)")
            .font(.system(size: 35, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 65, height: 72)
            .background(Color(ArcadeTheme.tileColor(for: number == 10 ? 3 : number)),
                        in: RoundedRectangle(cornerRadius: 18))
            .rotationEffect(.degrees(rotation))
            .shadow(color: ArcadeTheme.ink.opacity(0.14), radius: 0, x: 0, y: 5)
    }

    private func modeCard(_ mode: GameMode, symbol: String, subtitle: String) -> some View {
        let selected = selectedMode == mode
        return Button { selectedMode = mode } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: symbol)
                    Spacer()
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                }
                .foregroundStyle(selected ? ArcadeTheme.accentPrimary : ArcadeTheme.textSecondary)
                Text(mode.title).font(.system(size: 18, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(ArcadeTheme.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? ArcadeTheme.accentPrimary.opacity(0.08) : ArcadeTheme.cardFill,
                        in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(selected ? ArcadeTheme.accentPrimary : ArcadeTheme.cardStroke, lineWidth: selected ? 1.5 : 1))
        }
        .accessibilityLabel(mode.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
