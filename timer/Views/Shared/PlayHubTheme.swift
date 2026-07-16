import SwiftUI

enum GameArt {
    static let quizBackground = "QuizBackground"
    static let sunsetRuinsBackground = "BackgroundSunsetRuins"
    static let moonlitForestBackground = "BackgroundMoonlitForest"
    static let quizBoard = "QuizBoard"
    static let adventurePanel = "AdventurePanel"
    static let adventureButton = "AdventureButton"
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
    static let wood = Color(red: 0.25, green: 0.11, blue: 0.03)
    static let woodLight = Color(red: 0.43, green: 0.22, blue: 0.06)
    static let paper = wood
    static let surface = woodLight
    static let cream = Color(red: 1.00, green: 0.92, blue: 0.65)
    static let sand = Color(red: 0.92, green: 0.82, blue: 0.49)
    static let lime = Color(red: 0.82, green: 0.93, blue: 0.39)
    static let leaf = Color(red: 0.34, green: 0.67, blue: 0.08)
    static let ink = cream
    static let mutedInk = cream.opacity(0.76)
    static let orange = Color(red: 1.00, green: 0.38, blue: 0.08)
    static let sky = Color(red: 0.30, green: 0.78, blue: 0.84)
    static let mint = Color(red: 0.48, green: 0.82, blue: 0.28)
    static let berry = Color(red: 0.94, green: 0.35, blue: 0.22)
    static let gold = Color(red: 1.00, green: 0.72, blue: 0.14)

    static func tint(for mode: GameMode) -> Color {
        switch mode {
        case .tapFrenzy: return orange
        case .lightItUp: return sky
        case .quizRush: return lime
        }
    }
}

struct PlayHubScreenBackground: View {
    @EnvironmentObject private var settings: GameSettingsStore

    var body: some View {
        Image(settings.selectedBackgroundTheme.assetName)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .overlay(
                Color.black
                    .opacity(settings.selectedBackgroundTheme.backgroundOverlayOpacity)
                    .ignoresSafeArea()
            )
            .accessibilityHidden(true)
    }
}

struct PlayHubPanelBackground: View {
    var cornerRadius: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(PlayHubTheme.wood.opacity(0.95))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(PlayHubTheme.lime.opacity(0.42), lineWidth: 1.5)
            }
            .shadow(color: Color.black.opacity(0.32), radius: 12, x: 0, y: 7)
    }
}

struct PlayHubSymbolIcon: View {
    let systemName: String
    let tint: Color
    var size: CGFloat = 52
    var symbolSize: CGFloat = 22

    var body: some View {
        Image(systemName: systemName)
            .symbolRenderingMode(.monochrome)
            .font(.system(size: symbolSize, weight: .black))
            .foregroundStyle(PlayHubTheme.wood)
            .frame(width: size, height: size, alignment: .center)
            .background(tint, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .strokeBorder(PlayHubTheme.cream.opacity(0.48), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

struct GameModeArtworkIcon: View {
    let mode: GameMode
    var size: CGFloat = 54
    var iconSize: CGFloat = 31

    var body: some View {
        GameModeGlyph(mode: mode, size: iconSize)
            .foregroundStyle(PlayHubTheme.wood)
            .frame(width: size, height: size)
            .background(
                PlayHubTheme.tint(for: mode),
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .strokeBorder(PlayHubTheme.cream.opacity(0.52), lineWidth: 1.5)
            }
            .accessibilityHidden(true)
    }
}

struct PlayHubPrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject private var settings: GameSettingsStore

    var tint: Color = PlayHubTheme.orange

    private var usesEnhancedControls: Bool {
        settings.selectedBackgroundTheme.usesEnhancedControls
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PlayHubGameFont.display(15))
            .foregroundStyle(PlayHubTheme.wood)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 18)
            .background {
                if usesEnhancedControls {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint, tint.opacity(0.76)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(configuration.isPressed ? 0.90 : 1)
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(configuration.isPressed ? 0.78 : 1))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        usesEnhancedControls ? PlayHubTheme.cream.opacity(0.58) : PlayHubTheme.wood.opacity(0.28),
                        lineWidth: usesEnhancedControls ? 2 : 1
                    )
            }
            .shadow(
                color: usesEnhancedControls ? PlayHubTheme.wood.opacity(0.92) : .clear,
                radius: 0,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.08 : 0.28), radius: 8, x: 0, y: 5)
            .offset(y: usesEnhancedControls && configuration.isPressed ? 4 : 0)
            .scaleEffect(configuration.isPressed ? (usesEnhancedControls ? 0.99 : 0.98) : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct GameModeGlyph: View {
    let mode: GameMode
    var size: CGFloat = 24

    var body: some View {
        Group {
            switch mode {
            case .tapFrenzy:
                ZStack {
                    Circle()
                        .stroke(lineWidth: max(2, size * 0.10))
                        .frame(width: size * 0.92, height: size * 0.92)
                    Circle()
                        .stroke(lineWidth: max(2, size * 0.09))
                        .frame(width: size * 0.54, height: size * 0.54)
                    Circle()
                        .frame(width: size * 0.20, height: size * 0.20)
                }
            case .lightItUp:
                ZStack {
                    ForEach(0..<8, id: \.self) { index in
                        Capsule()
                            .frame(width: size * 0.12, height: size * 0.28)
                            .offset(y: -size * 0.34)
                            .rotationEffect(.degrees(Double(index) * 45))
                    }
                    Circle()
                        .frame(width: size * 0.44, height: size * 0.44)
                }
            case .quizRush:
                VStack(spacing: size * 0.10) {
                    HStack(spacing: size * 0.10) {
                        quizTile(isHighlighted: true)
                        quizTile(isHighlighted: false)
                    }
                    HStack(spacing: size * 0.10) {
                        quizTile(isHighlighted: false)
                        quizTile(isHighlighted: false)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func quizTile(isHighlighted: Bool) -> some View {
        RoundedRectangle(cornerRadius: size * 0.10, style: .continuous)
            .frame(width: size * 0.36, height: size * 0.30)
            .opacity(isHighlighted ? 1 : 0.48)
    }
}

struct GameActionLabel: View {
    let title: String
    let mode: GameMode
    var iconSize: CGFloat = 21

    var body: some View {
        HStack(spacing: 8) {
            GameModeGlyph(mode: mode, size: iconSize)
            Text(title)
        }
    }
}

struct GameSetupLabel: View {
    var title = "SETUP"

    var body: some View {
        HStack(spacing: 6) {
            Image(GameArt.settings)
                .resizable()
                .scaledToFit()
                .frame(width: 21, height: 21)
                .accessibilityHidden(true)
            Text(title)
        }
    }
}

struct PlayHubSecondaryButtonStyle: ButtonStyle {
    @EnvironmentObject private var settings: GameSettingsStore

    private var usesEnhancedControls: Bool {
        settings.selectedBackgroundTheme.usesEnhancedControls
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PlayHubGameFont.display(15))
            .foregroundStyle(PlayHubTheme.wood)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 18)
            .background {
                if usesEnhancedControls {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [PlayHubTheme.cream, PlayHubTheme.sand],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(configuration.isPressed ? 0.90 : 1)
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(PlayHubTheme.sand.opacity(configuration.isPressed ? 0.78 : 1))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        usesEnhancedControls ? PlayHubTheme.cream.opacity(0.58) : PlayHubTheme.wood.opacity(0.28),
                        lineWidth: usesEnhancedControls ? 2 : 1
                    )
            }
            .shadow(
                color: usesEnhancedControls ? PlayHubTheme.wood.opacity(0.92) : .clear,
                radius: 0,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
            .shadow(
                color: usesEnhancedControls ? Color.black.opacity(configuration.isPressed ? 0.08 : 0.26) : .clear,
                radius: 8,
                x: 0,
                y: configuration.isPressed ? 2 : 7
            )
            .offset(y: usesEnhancedControls && configuration.isPressed ? 4 : 0)
            .scaleEffect(configuration.isPressed ? (usesEnhancedControls ? 0.99 : 0.98) : 1)
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
            .font(PlayHubGameFont.display(20))
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
            .tint(PlayHubTheme.lime)
            .scaleEffect(x: 1, y: 1.8, anchor: .center)
            .padding(.vertical, 8)
            .accessibilityLabel("Progress")
            .accessibilityValue("\(Int(fraction * 100)) percent")
    }
}

struct ArcadeGameBar: View {
    let variantLabel: String
    let statusLabel: String
    var canConfigure = true
    let onSetup: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(variantLabel.uppercased())
                    .font(PlayHubGameFont.label(13))
                    .lineLimit(1)
                Text(statusLabel.uppercased())
                    .font(PlayHubGameFont.label(10))
                    .foregroundStyle(PlayHubTheme.lime.opacity(0.82))
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if canConfigure {
                Button(action: onSetup) {
                    GameSetupLabel()
                        .font(PlayHubGameFont.label(11))
                        .foregroundStyle(PlayHubTheme.wood)
                        .padding(.horizontal, 11)
                        .frame(height: 34)
                        .background(PlayHubTheme.lime, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(PlayHubTheme.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(PlayHubPanelBackground(cornerRadius: 16))
    }
}

struct AdventureArtSlice: View {
    let imageName: String
    var capInsets = EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)

    var body: some View {
        Image(imageName)
            .resizable(capInsets: capInsets, resizingMode: .stretch)
            .accessibilityHidden(true)
    }
}

struct AdventureButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PlayHubGameFont.display(14))
            .foregroundStyle(PlayHubTheme.cream)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 12)
            .background(
                AdventureArtSlice(
                    imageName: GameArt.adventureButton,
                    capInsets: EdgeInsets(top: 7, leading: 13, bottom: 7, trailing: 13)
                )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.80 : 1)
            .animation(.snappy(duration: 0.14), value: configuration.isPressed)
    }
}

extension View {
    func gameTextShadow() -> some View {
        shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
    }
}
