import SwiftUI

struct HomeTab: View {
    @EnvironmentObject private var store: GameSessionStore
    private let games = GameMode.allCases

    var body: some View {
        ZStack {
            PlayHubScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    overview
                    quickPlay
                    gameLauncher
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 108)
            }
            .scrollIndicators(.hidden)
        }
        .navigationDestination(for: GameMode.self) { game in
            destination(for: game)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("GAME ARCADE")
                    .font(PlayHubGameFont.display(31))
                    .foregroundStyle(PlayHubTheme.lime)
                    .gameTextShadow()

                Text("Pick a challenge. Beat your best.")
                    .font(PlayHubGameFont.label(13))
                    .foregroundStyle(PlayHubTheme.mutedInk)
            }

            Spacer(minLength: 8)

            NavigationLink {
                SettingsTab()
            } label: {
                Image(GameArt.settings)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54, alignment: .center)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(16)
        .background(PlayHubPanelBackground(cornerRadius: 24))
    }

    private var overview: some View {
        HStack(spacing: 12) {
            ScoreBadge(
                title: "Total Score",
                value: "\(totalScore)",
                symbol: "trophy.fill",
                tint: PlayHubTheme.gold
            )
            ScoreBadge(
                title: "Games Played",
                value: "\(store.sessions.count)",
                symbol: "gamecontroller.fill",
                tint: PlayHubTheme.sky
            )
        }
    }

    private var quickPlay: some View {
        NavigationLink(value: GameMode.tapFrenzy) {
            HStack {
                Label("START TAP FRENZY", systemImage: "play.fill")
                Spacer()
                Text("QUICK PLAY")
                    .font(PlayHubGameFont.label(10))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(PlayHubTheme.wood.opacity(0.16), in: Capsule())
            }
        }
        .buttonStyle(PlayHubPrimaryButtonStyle())
    }

    private var gameLauncher: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("CHOOSE A GAME", systemImage: "gamecontroller.fill")
                .font(PlayHubGameFont.display(19))
                .foregroundStyle(PlayHubTheme.lime)
                .gameTextShadow()

            LazyVStack(spacing: 12) {
                ForEach(games) { game in
                    NavigationLink(value: game) {
                        GameRow(game: game, bestScore: store.bestScore(for: game))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var totalScore: Int {
        store.sessions.reduce(0) { $0 + $1.score }
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

private struct GameRow: View {
    let game: GameMode
    let bestScore: Int

    var body: some View {
        HStack(spacing: 14) {
            GameModeArtworkIcon(mode: game)

            VStack(alignment: .leading, spacing: 4) {
                Text(game.displayName)
                    .font(PlayHubGameFont.display(17))
                    .foregroundStyle(PlayHubTheme.ink)
                    .lineLimit(1)

                Text(game.subtitle)
                    .font(PlayHubGameFont.label(12))
                    .foregroundStyle(PlayHubTheme.mutedInk)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            VStack(alignment: .center, spacing: 1) {
                Text("BEST")
                    .font(PlayHubGameFont.label(9))
                    .foregroundStyle(PlayHubTheme.wood.opacity(0.72))
                Text("\(bestScore)")
                    .font(PlayHubGameFont.display(18).monospacedDigit())
                    .foregroundStyle(PlayHubTheme.wood)
            }
            .frame(width: 48, height: 48)
            .background(PlayHubTheme.sand, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.black))
                .foregroundStyle(PlayHubTheme.lime)
                .frame(width: 18, height: 24, alignment: .center)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(PlayHubPanelBackground(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens \(game.displayName)")
    }
}

#Preview {
    NavigationStack { HomeTab() }
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
        .environmentObject(LocationService.shared)
}
