import SwiftUI

struct ResultView: View {
    let mode: GameMode
    let score: Int
    let bestScore: Int
    var variantLabel: String?
    let onPlayAgain: () -> Void

    private var displayTitle: String {
        guard let variantLabel, !variantLabel.isEmpty else { return mode.displayName }
        return "\(mode.displayName) - \(variantLabel)"
    }

    private var shareText: String {
        "I just scored \(score) on \(displayTitle) - beat that"
    }

    var body: some View {
        ZStack {
            Image(GameArt.winPopup)
                .resizable(capInsets: EdgeInsets(top: 170, leading: 210, bottom: 180, trailing: 210), resizingMode: .stretch)

            VStack(spacing: 12) {
                Spacer(minLength: 54)

                Text(displayTitle)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .gameTextShadow()
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.62)
                    .padding(.horizontal, 56)

                HStack(spacing: 10) {
                    Image(GameArt.starGold)
                        .resizable()
                        .scaledToFit()
                    Image(GameArt.starGold)
                        .resizable()
                        .scaledToFit()
                    Image(bestScore > score ? GameArt.starBlue : GameArt.starGold)
                        .resizable()
                        .scaledToFit()
                }
                .frame(height: 40)

                Text("Score \(score)")
                    .font(.system(size: 32, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .gameTextShadow()
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(PlayHubTheme.orange, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("Best \(bestScore)")
                    .font(.system(size: 17, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(PlayHubTheme.ink)

                HStack(spacing: 12) {
                    ShareLink(item: shareText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PlayHubSecondaryButtonStyle())

                    Button(action: onPlayAgain) {
                        Label("Play Again", systemImage: "play.fill")
                    }
                    .buttonStyle(PlayHubPrimaryButtonStyle(tint: PlayHubTheme.tint(for: mode)))
                }
                .padding(.horizontal, 42)

                Spacer(minLength: 22)
            }
        }
        .frame(maxWidth: 620)
        .frame(minHeight: 390)
        .padding(24)
        .accessibilityElement(children: .combine)
    }
}
