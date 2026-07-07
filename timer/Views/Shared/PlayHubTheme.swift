import SwiftUI

enum PlayHubTheme {
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let ink = Color(red: 0.10, green: 0.10, blue: 0.13)
    static let mutedInk = Color(red: 0.42, green: 0.42, blue: 0.48)
    static let orange = Color(red: 1.00, green: 0.46, blue: 0.16)
    static let sky = Color(red: 0.18, green: 0.54, blue: 0.95)
    static let mint = Color(red: 0.08, green: 0.68, blue: 0.48)
    static let berry = Color(red: 0.88, green: 0.20, blue: 0.42)
    static let gold = Color(red: 1.00, green: 0.74, blue: 0.18)

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
        LinearGradient(
            colors: [
                PlayHubTheme.paper,
                Color(red: 0.92, green: 0.95, blue: 0.99),
                Color(red: 0.99, green: 0.95, blue: 0.88)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct PlayHubPrimaryButtonStyle: ButtonStyle {
    var tint: Color = PlayHubTheme.orange

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(tint.opacity(configuration.isPressed ? 0.78 : 1), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct PlayHubSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(PlayHubTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(configuration.isPressed ? 0.72 : 0.96), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}
