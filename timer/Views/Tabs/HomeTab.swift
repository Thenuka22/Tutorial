import SwiftUI

struct HomeTab: View {
    private let games = GameMode.allCases

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hero
                gameGrid
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(PlayHubScreenBackground())
        .navigationTitle("Home")
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            PlayHubHeroCollage()
                .frame(height: 210)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text("PlayHub")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(PlayHubTheme.ink)
                    .minimumScaleFactor(0.75)

                Text("Three quick-play SwiftUI challenges with sessions, stats, maps, reminders, and score sharing.")
                    .font(.body)
                    .foregroundStyle(PlayHubTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            NavigationLink {
                TapFrenzyView()
            } label: {
                Label("Start Tap Frenzy", systemImage: "play.fill")
            }
            .buttonStyle(PlayHubPrimaryButtonStyle())
        }
    }

    private var gameGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Games")
                .font(.title2.bold())
                .foregroundStyle(PlayHubTheme.ink)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(games) { game in
                    NavigationLink {
                        destination(for: game)
                    } label: {
                        GameCard(game: game)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for game: GameMode) -> some View {
        switch game {
        case .tapFrenzy:
            TapFrenzyView()
        case .lightItUp:
            LightItUpView()
        case .quizRush:
            QuizRushView()
        }
    }
}

private struct PlayHubHeroCollage: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(spacing: 12) {
                collageTile(symbol: "hand.tap.fill", title: "Tap", tint: PlayHubTheme.orange, height: 92)
                collageTile(symbol: "bolt.fill", title: "Light", tint: PlayHubTheme.sky, height: 82)
            }

            VStack(spacing: 12) {
                collageTile(symbol: "chart.bar.fill", title: "Stats", tint: PlayHubTheme.gold, height: 126)
                collageTile(symbol: "map.fill", title: "Map", tint: PlayHubTheme.berry, height: 58)
            }
        }
    }

    private func collageTile(symbol: String, title: String, tint: Color, height: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.68)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: symbol)
                .font(.system(size: height * 0.38, weight: .black))
                .foregroundStyle(.white.opacity(0.92))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(title)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .shadow(color: tint.opacity(0.24), radius: 12, x: 0, y: 8)
    }
}

private struct GameCard: View {
    let game: GameMode

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: game.symbolName)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Color.white.opacity(0.20), in: Circle())

            Spacer(minLength: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text(game.displayName)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)

                Text(game.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 178, alignment: .leading)
        .padding(14)
        .background(PlayHubTheme.gradient(for: game), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "chevron.right.circle.fill")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.86))
                .padding(12)
        }
        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 8)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { HomeTab() }
}
