import SwiftUI

struct ResultView: View {
    let mode: GameMode
    let score: Int
    let bestScore: Int
    let onPlayAgain: () -> Void

    private var shareText: String {
        "I just scored \(score) on \(mode.displayName) - beat that"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: mode.symbolName)
                .font(.system(size: 58, weight: .black))
                .foregroundStyle(PlayHubTheme.tint(for: mode))

            Text("Result")
                .font(.largeTitle.bold())
                .foregroundStyle(PlayHubTheme.ink)

            Text("\(score)")
                .font(.system(size: 68, weight: .black, design: .rounded))
                .foregroundStyle(PlayHubTheme.tint(for: mode))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("Best \(bestScore)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(PlayHubTheme.mutedInk)

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
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 20, x: 0, y: 12)
        .padding(24)
        .accessibilityElement(children: .combine)
    }
}
