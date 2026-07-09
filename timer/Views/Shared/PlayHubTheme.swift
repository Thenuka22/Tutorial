import SwiftUI

enum GameArt {
    static let landing = "GameLanding"
    static let logo = "GameLogo"
    static let winPopup = "GameWinPopup"
    static let panelBlank = "GamePanelBlank"
    static let titleRibbon = "GameTitleRibbon"
    static let buttonOrange = "GameButtonOrange"
    static let buttonOrangePressed = "GameButtonOrangePressed"
    static let buttonGreen = "GameButtonGreen"
    static let buttonGreenPressed = "GameButtonGreenPressed"
    static let musicOn = "GameButtonMusic"
    static let musicOff = "GameButtonMusicOff"
    static let soundOn = "GameButtonSound"
    static let soundOff = "GameButtonSoundOff"
    static let vibraOn = "GameButtonVibra"
    static let vibraOff = "GameButtonVibraOff"
    static let settings = "GameSettingsButton"
    static let coinBar = "GameCoinBar"
    static let coinIcon = "GameCoinIcon"
    static let gemsBar = "GameGemsBar"
    static let gemsIcon = "GameGemsIcon"
    static let progressTrack = "GameProgressTrack"
    static let starGold = "GameStarGold"
    static let starBlue = "GameStarBlue"
    static let medal = "GameMedal"
}

enum PlayHubTheme {
    static let paper = Color(red: 0.18, green: 0.23, blue: 0.27)
    static let ink = Color(red: 0.22, green: 0.11, blue: 0.09)
    static let mutedInk = Color(red: 0.50, green: 0.31, blue: 0.20)
    static let orange = Color(red: 1.00, green: 0.55, blue: 0.11)
    static let sky = Color(red: 0.23, green: 0.72, blue: 0.89)
    static let mint = Color(red: 0.55, green: 0.80, blue: 0.18)
    static let berry = Color(red: 0.84, green: 0.28, blue: 0.28)
    static let gold = Color(red: 1.00, green: 0.78, blue: 0.12)
    static let cream = Color(red: 1.00, green: 0.89, blue: 0.60)

    static func tint(for mode: GameMode) -> Color {
        switch mode {
        case .tapFrenzy: return orange
        case .lightItUp: return sky
        case .quizRush: return berry
        }
    }

    static func gradient(for mode: GameMode) -> LinearGradient {
        switch mode {
        case .tapFrenzy:
            return LinearGradient(colors: [orange, gold], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .lightItUp:
            return LinearGradient(colors: [sky, mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .quizRush:
            return LinearGradient(colors: [berry, Color(red: 0.38, green: 0.31, blue: 0.86)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct PlayHubScreenBackground: View {
    var body: some View {
        ZStack {
            Image(GameArt.landing)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.34),
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.40)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct PlayHubPrimaryButtonStyle: ButtonStyle {
    var tint: Color = PlayHubTheme.orange

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: Color(red: 0.25, green: 0.10, blue: 0.06), radius: 0, x: 0, y: 2)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .padding(.horizontal, 22)
            .background {
                Image(configuration.isPressed ? GameArt.buttonOrangePressed : GameArt.buttonOrange)
                    .resizable(capInsets: EdgeInsets(top: 28, leading: 42, bottom: 28, trailing: 42), resizingMode: .stretch)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct PlayHubSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: Color(red: 0.20, green: 0.28, blue: 0.05), radius: 0, x: 0, y: 2)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .padding(.horizontal, 22)
            .background {
                Image(configuration.isPressed ? GameArt.buttonGreenPressed : GameArt.buttonGreen)
                    .resizable(capInsets: EdgeInsets(top: 28, leading: 42, bottom: 28, trailing: 42), resizingMode: .stretch)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct GameArtPanel<Content: View>: View {
    var contentInsets = EdgeInsets(top: 28, leading: 28, bottom: 28, trailing: 28)
    private let content: Content

    init(
        contentInsets: EdgeInsets = EdgeInsets(top: 28, leading: 28, bottom: 28, trailing: 28),
        @ViewBuilder content: () -> Content
    ) {
        self.contentInsets = contentInsets
        self.content = content()
    }

    var body: some View {
        content
            .padding(contentInsets)
            .background {
                Image(GameArt.panelBlank)
                    .resizable(capInsets: EdgeInsets(top: 120, leading: 130, bottom: 130, trailing: 130), resizingMode: .stretch)
            }
            .shadow(color: Color.black.opacity(0.24), radius: 18, x: 0, y: 10)
    }
}

struct GameArtTitle: View {
    let text: String

    var body: some View {
        ZStack {
            Image(GameArt.titleRibbon)
                .resizable(capInsets: EdgeInsets(top: 36, leading: 100, bottom: 36, trailing: 100), resizingMode: .stretch)

            Text(text.uppercased())
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: PlayHubTheme.ink, radius: 0, x: 0, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .padding(.horizontal, 34)
        }
        .frame(height: 58)
        .accessibilityElement(children: .combine)
    }
}

struct GameArtProgressBar: View {
    let value: Double
    let total: Double

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Image(GameArt.progressTrack)
                    .resizable(capInsets: EdgeInsets(top: 42, leading: 130, bottom: 42, trailing: 130), resizingMode: .stretch)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [PlayHubTheme.sky, Color(red: 0.40, green: 0.90, blue: 1.00)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .frame(width: max(42, proxy.size.width * fraction), alignment: .leading)
            }
        }
        .frame(height: 34)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(fraction * 100)) percent")
    }
}

extension View {
    func gameTextShadow() -> some View {
        shadow(color: Color(red: 0.20, green: 0.08, blue: 0.05), radius: 0, x: 0, y: 2)
    }
}
