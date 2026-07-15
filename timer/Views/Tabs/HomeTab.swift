import SwiftUI

struct HomeTab: View {
    @EnvironmentObject private var store: GameSessionStore
    private let games = GameMode.allCases

    var body: some View {
        ZStack {
            PlayHubScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    overview
                    quickPlay
                    gameLauncher
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
        }
        .navigationDestination(for: GameMode.self) { game in
            destination(for: game)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PlayHub")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(PlayHubTheme.ink)

                Text("Pick a challenge and beat your best.")
                    .font(.subheadline)
                    .foregroundStyle(PlayHubTheme.mutedInk)
            }

            Spacer(minLength: 8)

            NavigationLink {
                SettingsTab()
            } label: {
                Image(GameArt.settings)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52, alignment: .center)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
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
            Label("Start Tap Frenzy", systemImage: "play.fill")
        }
        .buttonStyle(PlayHubPrimaryButtonStyle())
    }

    private var gameLauncher: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Games")
                .font(.title2.weight(.bold))
                .foregroundStyle(PlayHubTheme.ink)

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
            PlayHubSymbolIcon(
                systemName: game.symbolName,
                tint: PlayHubTheme.tint(for: game),
                size: 54,
                symbolSize: 24
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(game.displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PlayHubTheme.ink)
                    .lineLimit(1)

                Text(game.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(PlayHubTheme.mutedInk)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("BEST")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(PlayHubTheme.mutedInk)
                Text("\(bestScore)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(PlayHubTheme.ink)
            }
            .frame(minWidth: 44, alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 18, height: 24, alignment: .center)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
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
