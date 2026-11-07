import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateHorizontal = false
    @State private var animateVertical = false

    var body: some View {
        NavigationStack {
            ZStack {
                ArcadeTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        infoCard(title: "How to Play") {
                            Text("Move falling numbers and make lines that add up to the Target.")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(ArcadeTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        infoCard(title: "Horizontal Example") {
                            targetBadge(12, animated: animateHorizontal)
                            HStack(spacing: 10) {
                                numberChip(3)
                                numberChip(4)
                                numberChip(5)
                            }
                            .scaleEffect(animateHorizontal ? 1.03 : 1.0)
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.6).delay(0.55), value: animateHorizontal)

                            equation("3 + 4 + 5 = 12")

                            Text("When the numbers add up to the Target, the line disappears!")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ArcadeTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        infoCard(title: "Vertical Example") {
                            targetBadge(10, animated: animateVertical)
                            VStack(spacing: 8) {
                                numberChip(5)
                                numberChip(2)
                                numberChip(3)
                            }
                            .scaleEffect(animateVertical ? 1.03 : 1.0)
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.6).delay(0.55), value: animateVertical)

                            equation("5 + 2 + 3 = 10")

                            Text("Vertical lines work too!")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ArcadeTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        infoCard(title: "Game Modes") {
                            modeSummary(
                                title: "Beginner",
                                detail: "7 × 12 board • gradual difficulty • automatic chain reactions",
                                icon: "leaf.fill",
                                color: ArcadeTheme.accentPrimary
                            )
                            modeSummary(
                                title: "Expert",
                                detail: "10 × 18 board • faster falling • targets from 5 to 20",
                                icon: "bolt.fill",
                                color: ArcadeTheme.accentSecondary
                            )
                            bullet("Make straight, connected lines of at least two numbers. Diagonal and L-shaped groups do not count.")
                        }

                        infoCard(title: "Controls") {
                            controlRow(icon: "arrow.left.and.right", text: "Swipe left or right to move")
                            controlRow(icon: "arrow.down", text: "Swipe down to drop faster")
                            controlRow(icon: "hand.tap", text: "Double tap for hard drop")
                            controlRow(icon: "hand.point.up.left", text: "Tap either side to move, or the lower center to soft drop")
                        }

                        infoCard(title: "Special Gameplay") {
                            specialTileRow(symbol: "↔", title: "Row Clear", detail: "Removes the landing row.", color: ArcadeTheme.accentPrimary)
                            specialTileRow(symbol: "↕", title: "Column Clear", detail: "Removes the landing column.", color: ArcadeTheme.accentSecondary)
                            specialTileRow(symbol: "⟳", title: "Reorder", detail: "Sorts occupied numbers from the bottom.", color: ArcadeTheme.ink)
                            bullet("Beginner cascades: Chain reactions give bonus points!")
                            bullet("Perfect Clear: Clear the whole board for a big reward!")
                            bullet("Special tiles appear from level 6 in Beginner and level 3 in Expert.")
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("How To Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ArcadeTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(ArcadeTheme.chipFill))
                        .overlay(Capsule().stroke(ArcadeTheme.chipStroke, lineWidth: 0.8))
                        .accessibilityLabel("Done")
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animateHorizontal.toggle()
                animateVertical.toggle()
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(ArcadeTheme.accentPrimary)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(ArcadeTheme.textPrimary)
            Spacer(minLength: 0)
        }
    }

    private func equation(_ text: String) -> some View {
        Text(text)
            .font(.title3.weight(.bold))
            .foregroundStyle(ArcadeTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(text.replacingOccurrences(of: "+", with: " plus ").replacingOccurrences(of: "=", with: " equals "))
    }

    private func numberChip(_ value: Int) -> some View {
        Text("\(value)")
            .font(.headline.weight(.heavy))
            .foregroundStyle(Color.white)
            .frame(width: 38, height: 38)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color(ArcadeTheme.tileColor(for: value)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(Color.white.opacity(0.26), lineWidth: 0.9)
            )
            .shadow(color: Color(ArcadeTheme.tileColor(for: value)).opacity(0.42), radius: 6)
    }

    private func targetBadge(_ target: Int, animated: Bool) -> some View {
        HStack(spacing: 8) {
            Text("TARGET")
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color.white.opacity(0.95))
            Text("\(target)")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [ArcadeTheme.accentPrimary, ArcadeTheme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: ArcadeTheme.glowColor.opacity(animated ? 0.52 : 0.26), radius: animated ? 14 : 6)
        .scaleEffect(animated ? 1.04 : 1.0)
        .animation(.easeInOut(duration: 0.55), value: animated)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Target \(target)")
    }

    private func controlRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ArcadeTheme.accentPrimary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(ArcadeTheme.accentSecondary.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: ArcadeTheme.accentPrimary.opacity(0.24), radius: 4, y: 2)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ArcadeTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    private func modeSummary(title: String, detail: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ArcadeTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ArcadeTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func specialTileRow(symbol: String, title: String, detail: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(symbol)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ArcadeTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ArcadeTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(ArcadeTheme.textSecondary)
            content()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(ArcadeTheme.cardFill))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(ArcadeTheme.cardStroke, lineWidth: 0.9))
    }
}
