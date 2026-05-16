import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animateHorizontal = false
    @State private var animateVertical = false

    var body: some View {
        NavigationStack {
            ZStack {
                NeonTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        infoCard(title: "How to Play") {
                            Text("Move falling numbers and make lines that add up to the Target.")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(NeonTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        infoCard(title: "Horizontal Example") {
                            targetBadge(12, animated: animateHorizontal)
                            HStack(spacing: 10) {
                                numberChip(3)
                                numberChip(4)
                                numberChip(5)
                            }
                            .opacity(animateHorizontal ? 0.16 : 1.0)
                            .scaleEffect(animateHorizontal ? 0.94 : 1.0)
                            .animation(.easeInOut(duration: 0.6).delay(0.55), value: animateHorizontal)

                            equation("3 + 4 + 5 = 12")

                            Text("When the numbers add up to the Target, the line disappears!")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(NeonTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        infoCard(title: "Vertical Example") {
                            targetBadge(10, animated: animateVertical)
                            VStack(spacing: 8) {
                                numberChip(5)
                                numberChip(2)
                                numberChip(3)
                            }
                            .opacity(animateVertical ? 0.16 : 1.0)
                            .scaleEffect(animateVertical ? 0.94 : 1.0)
                            .animation(.easeInOut(duration: 0.6).delay(0.55), value: animateVertical)

                            equation("5 + 2 + 3 = 10")

                            Text("Vertical lines work too!")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(NeonTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        infoCard(title: "Controls") {
                            controlRow(icon: "arrow.left.and.right", text: "Swipe left or right to move")
                            controlRow(icon: "arrow.down", text: "Swipe down to drop faster")
                            controlRow(icon: "hand.tap", text: "Double tap for hard drop")
                        }

                        infoCard(title: "Special Gameplay") {
                            bullet("Cascade: Chain reactions give bonus points!")
                            bullet("Perfect Clear: Clear the whole board for a big reward!")
                            bullet("Special blocks can clear rows and columns.")
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("How To Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(NeonTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(NeonTheme.chipFill))
                        .overlay(Capsule().stroke(NeonTheme.chipStroke, lineWidth: 0.8))
                        .accessibilityLabel("Done")
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animateHorizontal.toggle()
                animateVertical.toggle()
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(NeonTheme.accentPrimary)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(NeonTheme.textPrimary)
            Spacer(minLength: 0)
        }
    }

    private func equation(_ text: String) -> some View {
        Text(text)
            .font(.title3.weight(.bold))
            .foregroundStyle(NeonTheme.textPrimary)
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
                    .fill(Color(NeonTheme.tileColor(for: value)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(Color.white.opacity(0.26), lineWidth: 0.9)
            )
            .shadow(color: Color(NeonTheme.tileColor(for: value)).opacity(0.42), radius: 6)
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
                        colors: [NeonTheme.accentPrimary, NeonTheme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: NeonTheme.glowColor.opacity(animated ? 0.52 : 0.26), radius: animated ? 14 : 6)
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
                        .fill(NeonTheme.chipFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(NeonTheme.chipStroke, lineWidth: 1)
                )
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NeonTheme.textPrimary)
            Spacer()
        }
    }

    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(NeonTheme.textSecondary)
            content()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(NeonTheme.cardFill))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonTheme.cardStroke, lineWidth: 0.9))
    }
}
