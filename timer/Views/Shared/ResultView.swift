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

    private var isBestScore: Bool {
        score >= bestScore
    }

    var body: some View {
        VStack(spacing: 18) {
            PlayHubSymbolIcon(
                systemName: mode.symbolName,
                tint: PlayHubTheme.tint(for: mode),
                size: 72,
                symbolSize: 30
            )

            VStack(spacing: 6) {
                Text(isBestScore ? "New Best" : "Round Complete")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(PlayHubTheme.ink)

                Text(displayTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PlayHubTheme.mutedInk)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index == 2 && !isBestScore ? "star" : "star.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(index == 2 && !isBestScore ? PlayHubTheme.mutedInk : PlayHubTheme.gold)
                        .frame(width: 32, height: 32, alignment: .center)
                }
            }
            .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold).monospacedDigit())
                    .foregroundStyle(PlayHubTheme.tint(for: mode))
                Text("Best \(bestScore)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(PlayHubTheme.mutedInk)
            }

            actionButtons
        }
        .padding(24)
        .frame(maxWidth: 560)
        .background(PlayHubPanelBackground(cornerRadius: 28))
        .padding(24)
    }

    private var actionButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                shareButton
                playAgainButton
            }

            VStack(spacing: 12) {
                playAgainButton
                shareButton
            }
        }
    }

    private var shareButton: some View {
        ShareLink(item: shareText) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(PlayHubSecondaryButtonStyle())
    }

    private var playAgainButton: some View {
        Button(action: onPlayAgain) {
            Label("Play Again", systemImage: "play.fill")
        }
        .buttonStyle(PlayHubPrimaryButtonStyle(tint: PlayHubTheme.tint(for: mode)))
    }
}
