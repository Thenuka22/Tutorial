import SwiftUI

struct HomeTab: View {
    @EnvironmentObject private var store: GameSessionStore
    private let games = GameMode.allCases

    var body: some View {
        ZStack {
            PlayHubScreenBackground()

            ScrollView {
                VStack(spacing: 20) {
                    topHud
                    logo
                    quickPlay
                    gameLauncher
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topHud: some View {
        HStack(spacing: 10) {
            hudPill(icon: GameArt.coinIcon, value: "\(totalScore)")
            hudPill(icon: GameArt.gemsIcon, value: "\(store.sessions.count)", background: GameArt.gemsBar)
            Spacer()
            NavigationLink {
                SettingsTab()
            } label: {
                Image(GameArt.settings)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var logo: some View {
        Image(GameArt.logo)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 360)
            .padding(.top, 6)
            .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
            .accessibilityLabel("Cats Defender Arcade logo")
    }

    private var quickPlay: some View {
        NavigationLink {
            TapFrenzyView()
        } label: {
            Label("Play Now", systemImage: "play.fill")
        }
        .buttonStyle(PlayHubPrimaryButtonStyle())
        .padding(.horizontal, 18)
    }

    private var gameLauncher: some View {
        GameArtPanel(contentInsets: EdgeInsets(top: 22, leading: 18, bottom: 24, trailing: 18)) {
            VStack(spacing: 14) {
                GameArtTitle(text: "Game Modes")

                ForEach(games) { game in
                    NavigationLink {
                        destination(for: game)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: game.symbolName)
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(PlayHubTheme.tint(for: game), in: Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.65), lineWidth: 3))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(game.displayName)
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundStyle(PlayHubTheme.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)

                                Text(game.subtitle)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(PlayHubTheme.mutedInk)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Text("\(store.bestScore(for: game))")
                                .font(.system(size: 20, weight: .black, design: .rounded).monospacedDigit())
                                .foregroundStyle(.white)
                                .gameTextShadow()
                                .frame(width: 76, height: 46)
                                .background {
                                    Image(GameArt.coinBar)
                                        .resizable(capInsets: EdgeInsets(top: 18, leading: 42, bottom: 18, trailing: 42), resizingMode: .stretch)
                                }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background {
                            Image(GameArt.buttonOrange)
                                .resizable(capInsets: EdgeInsets(top: 28, leading: 42, bottom: 28, trailing: 42), resizingMode: .stretch)
                                .opacity(0.94)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func hudPill(icon: String, value: String, background: String = GameArt.coinBar) -> some View {
        HStack(spacing: 6) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)

            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .gameTextShadow()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 132, height: 46)
        .background {
            Image(background)
                .resizable(capInsets: EdgeInsets(top: 18, leading: 42, bottom: 18, trailing: 42), resizingMode: .stretch)
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

#Preview {
    NavigationStack { HomeTab() }
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
        .environmentObject(LocationService.shared)
}
