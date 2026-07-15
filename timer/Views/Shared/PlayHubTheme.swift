import SwiftUI

enum GameArt {
    static let quizBackground = "QuizBackground"
    static let quizBoard = "QuizBoard"
    static let musicOn = "GameButtonMusic"
    static let musicOff = "GameButtonMusicOff"
    static let soundOn = "GameButtonSound"
    static let soundOff = "GameButtonSoundOff"
    static let vibraOn = "GameButtonVibra"
    static let vibraOff = "GameButtonVibraOff"
    static let settings = "GameSettingsButton"
}

enum PlayHubGameFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

enum PlayHubTheme {
    static let paper = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let ink = Color.primary
    static let mutedInk = Color.secondary
    static let orange = Color(red: 1.00, green: 0.46, blue: 0.16)
    static let sky = Color(red: 0.18, green: 0.54, blue: 0.95)
    static let mint = Color(red: 0.08, green: 0.68, blue: 0.48)
    static let berry = Color(red: 0.88, green: 0.20, blue: 0.42)
    static let gold = Color(red: 1.00, green: 0.68, blue: 0.08)
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
            PlayHubTheme.paper

            LinearGradient(
                colors: [
                    PlayHubTheme.sky.opacity(0.10),
                    Color.clear,
                    PlayHubTheme.orange.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

struct PlayHubPanelBackground: View {
    var cornerRadius: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}

struct PlayHubSymbolIcon: View {
    let systemName: String
    let tint: Color
    var size: CGFloat = 52
    var symbolSize: CGFloat = 22

    var body: some View {
        Image(systemName: systemName)
            .symbolRenderingMode(.hierarchical)
            .font(.system(size: symbolSize, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size, alignment: .center)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: size * 0.30, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct PlayHubPrimaryButtonStyle: ButtonStyle {
    var tint: Color = PlayHubTheme.orange

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 18)
            .background(
                tint.opacity(configuration.isPressed ? 0.78 : 1),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: tint.opacity(configuration.isPressed ? 0.08 : 0.22), radius: 10, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct PlayHubSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(PlayHubTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 18)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
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
            .background(PlayHubPanelBackground())
    }
}

struct GameArtTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title3.weight(.bold))
            .foregroundStyle(PlayHubTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
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
        ProgressView(value: fraction)
            .progressViewStyle(.linear)
            .tint(PlayHubTheme.sky)
            .scaleEffect(x: 1, y: 1.8, anchor: .center)
            .padding(.vertical, 8)
            .accessibilityLabel("Progress")
            .accessibilityValue("\(Int(fraction * 100)) percent")
    }
}

extension View {
    func gameTextShadow() -> some View {
        shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
    }
}
