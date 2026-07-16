import SwiftUI

struct ResultView: View {
    @Environment(\.dismiss) private var dismiss

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
        score > 0 && score >= bestScore
    }

    private var resultTitle: String {
        if isBestScore { return "NEW BEST" }
        if starCount == 2 { return "GREAT RUN" }
        return "ROUND COMPLETE"
    }

    private var starCount: Int {
        guard score > 0 else { return 1 }
        guard bestScore > 0 else { return 3 }
        if score >= bestScore { return 3 }
        if Double(score) >= Double(bestScore) * 0.70 { return 2 }
        return 1
    }

    var body: some View {
        GeometryReader { proxy in
            let boardWidth = min(max(proxy.size.width - 32, 280), 370)
            let boardHeight = boardWidth / 0.62

            ZStack {
                PlayHubScreenBackground()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                resultBoard
                    .frame(width: boardWidth, height: boardHeight)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.58)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }

    private var resultBoard: some View {
        ZStack {
            AdventureArtSlice(imageName: GameArt.adventurePanel)

            VStack(spacing: 12) {
                Text(resultTitle)
                    .font(PlayHubGameFont.display(24))
                    .foregroundStyle(PlayHubTheme.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .padding(.horizontal, 14)
                    .background(
                        AdventureArtSlice(
                            imageName: GameArt.adventureButton,
                            capInsets: EdgeInsets(top: 7, leading: 13, bottom: 7, trailing: 13)
                        )
                    )

                Text(displayTitle.uppercased())
                    .font(PlayHubGameFont.label(12))
                    .foregroundStyle(PlayHubTheme.woodLight)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                HStack(alignment: .center, spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < starCount ? "star.fill" : "star")
                            .symbolRenderingMode(.monochrome)
                            .font(.system(size: index == 1 ? 54 : 40, weight: .black))
                            .foregroundStyle(index < starCount ? PlayHubTheme.gold : PlayHubTheme.sand.opacity(0.56))
                            .shadow(color: PlayHubTheme.orange, radius: 0, x: 2, y: 3)
                            .frame(width: index == 1 ? 62 : 48, height: 64)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(starCount) out of 3 stars")

                VStack(spacing: 5) {
                    Text("SCORE")
                        .font(PlayHubGameFont.display(13))
                        .foregroundStyle(PlayHubTheme.woodLight)

                    Text("\(score)")
                        .font(PlayHubGameFont.display(34).monospacedDigit())
                        .foregroundStyle(PlayHubTheme.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.60)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(PlayHubTheme.woodLight, lineWidth: 5)
                        }

                    Text("BEST \(bestScore)")
                        .font(PlayHubGameFont.label(11).monospacedDigit())
                        .foregroundStyle(PlayHubTheme.woodLight)
                }

                actionButtons
            }
            .padding(26)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 9) {
            HStack(spacing: 10) {
                Button(action: onPlayAgain) {
                    Label("REPLAY", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(AdventureButtonStyle())

                Button {
                    dismiss()
                } label: {
                    Label("HOME", systemImage: "house.fill")
                }
                .buttonStyle(AdventureButtonStyle())
            }

            ShareLink(item: shareText) {
                Label("SHARE SCORE", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(AdventureButtonStyle())
        }
    }
}
