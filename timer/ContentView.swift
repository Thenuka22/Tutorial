import SwiftUI

struct ContentView: View {
    private let games = ArcadeGameKind.allCases

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    hero
                    gameGrid
                    leaderboardCallout
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .background(ArcadeScreenBackground())
            .navigationTitle("Game Arcade")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        LeaderboardView()
                    } label: {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(ArcadeTheme.orange)
                            .accessibilityLabel("Leaderboard")
                    }
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            ArcadeHeroCollage()
                .frame(height: 210)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Game Arcade")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(ArcadeTheme.ink)
                    .minimumScaleFactor(0.75)

                Text("Three quick-play SwiftUI challenges with live scores, high scores, and a shared leaderboard.")
                    .font(.body)
                    .foregroundStyle(ArcadeTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                NavigationLink {
                    TapFrenzyView()
                } label: {
                    Label("Get Started", systemImage: "play.fill")
                }
                .buttonStyle(ArcadePrimaryButtonStyle())

                NavigationLink {
                    LeaderboardView()
                } label: {
                    Label("Scores", systemImage: "trophy.fill")
                }
                .buttonStyle(ArcadeSecondaryButtonStyle())
            }
        }
    }

    private var gameGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mini Games")
                .font(.title2.bold())
                .foregroundStyle(ArcadeTheme.ink)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(games) { game in
                    NavigationLink {
                        destination(for: game)
                    } label: {
                        ArcadeGameCard(game: game)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var leaderboardCallout: some View {
        NavigationLink {
            LeaderboardView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundStyle(ArcadeTheme.gold)
                    .frame(width: 46, height: 46)
                    .background(ArcadeTheme.ink, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Leaderboard")
                        .font(.headline)
                        .foregroundStyle(ArcadeTheme.ink)
                    Text("Save your best runs and compare every mode.")
                        .font(.subheadline)
                        .foregroundStyle(ArcadeTheme.mutedInk)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(ArcadeTheme.mutedInk)
            }
            .padding(16)
            .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func destination(for game: ArcadeGameKind) -> some View {
        switch game {
        case .tapFrenzy:
            TapFrenzyView()
        case .lightItUp:
            LightItUpGameView()
        case .quizRush:
            QuizRushView()
        }
    }
}

private struct ArcadeHeroCollage: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(spacing: 12) {
                collageTile(symbol: "hand.tap.fill", title: "Tap", tint: ArcadeTheme.orange, height: 92)
                collageTile(symbol: "bolt.fill", title: "Light", tint: ArcadeTheme.sky, height: 82)
            }

            VStack(spacing: 12) {
                collageTile(symbol: "trophy.fill", title: "Win", tint: ArcadeTheme.gold, height: 126)
                collageTile(symbol: "questionmark.bubble.fill", title: "Quiz", tint: ArcadeTheme.berry, height: 58)
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

private struct ArcadeGameCard: View {
    let game: ArcadeGameKind

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
        .background(ArcadeTheme.gradient(for: game), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
    ContentView()
}
