import SwiftUI

struct StatsTab: View {
    @StateObject private var viewModel = StatsVM()

    private let xpPerLevel = 100

    var body: some View {
        ZStack {
            MiniArcadeScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    adventureHeader
                    playerProgress
                    achievements
                    gameQuests
                    latestRuns
                }
                .frame(maxWidth: 430)
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 108)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: GameMode.self) { mode in
            destination(for: mode)
        }
    }

    private var adventureHeader: some View {
        HStack(spacing: 14) {
            MiniArcadeSymbolIcon(
                systemName: "map.fill",
                tint: MiniArcadeTheme.lime,
                size: 54,
                symbolSize: 23
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("ADVENTURE LOG")
                    .font(MiniArcadeGameFont.display(24))
                    .foregroundStyle(MiniArcadeTheme.lime)
                Text("PLAY. LEVEL UP. CONQUER.")
                    .font(MiniArcadeGameFont.label(10))
                    .foregroundStyle(MiniArcadeTheme.cream)
            }

            Spacer()
        }
        .padding(16)
        .background(MiniArcadePanelBackground(cornerRadius: 22))
    }

    private var playerProgress: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(MiniArcadeTheme.gold)
                    Circle()
                        .strokeBorder(MiniArcadeTheme.woodLight, lineWidth: 4)
                    Text("\(playerLevel)")
                        .font(MiniArcadeGameFont.display(27).monospacedDigit())
                        .foregroundStyle(MiniArcadeTheme.wood)
                }
                .frame(width: 68, height: 68)

                VStack(alignment: .leading, spacing: 3) {
                    Text("LEVEL \(playerLevel)")
                        .font(MiniArcadeGameFont.label(11))
                        .foregroundStyle(MiniArcadeTheme.woodLight.opacity(0.76))
                    Text(rankName.uppercased())
                        .font(MiniArcadeGameFont.display(20))
                        .foregroundStyle(MiniArcadeTheme.wood)
                    Text("\(viewModel.totalGames) quests completed")
                        .font(MiniArcadeGameFont.label(10))
                        .foregroundStyle(MiniArcadeTheme.woodLight.opacity(0.74))
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("NEXT LEVEL")
                    Spacer()
                    Text("\(currentLevelXP) / \(xpPerLevel) XP")
                }
                .font(MiniArcadeGameFont.label(10))
                .foregroundStyle(MiniArcadeTheme.woodLight)

                ProgressView(value: Double(currentLevelXP), total: Double(xpPerLevel))
                    .tint(MiniArcadeTheme.leaf)
                    .scaleEffect(x: 1, y: 2.2, anchor: .center)
            }
        }
        .padding(18)
        .background(adventurePanel)
        .accessibilityElement(children: .combine)
    }

    private var achievements: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("ACHIEVEMENTS")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AchievementBadge(
                    title: "First Quest",
                    detail: "Finish one game",
                    symbol: "flag.checkered",
                    unlocked: viewModel.totalGames >= 1
                )
                AchievementBadge(
                    title: "Triple Hero",
                    detail: "Play every game",
                    symbol: "crown.fill",
                    unlocked: viewModel.modeStats.allSatisfy { $0.games > 0 }
                )
                AchievementBadge(
                    title: "Score Hunter",
                    detail: "Earn 100 points",
                    symbol: "star.fill",
                    unlocked: viewModel.totalScore >= 100
                )
                AchievementBadge(
                    title: "Trail Finder",
                    detail: "Save a map pin",
                    symbol: "mappin.and.ellipse",
                    unlocked: !viewModel.locatedSessions.isEmpty
                )
            }
        }
    }

    private var gameQuests: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("GAME QUESTS")

            ForEach(viewModel.modeStats) { stat in
                NavigationLink(value: stat.mode) {
                    HStack(spacing: 14) {
                        GameModeArtworkIcon(mode: stat.mode, size: 58, iconSize: 34)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(stat.mode.displayName.uppercased())
                                .font(MiniArcadeGameFont.display(16))
                                .foregroundStyle(MiniArcadeTheme.wood)
                            Text("\(stat.games) RUNS")
                                .font(MiniArcadeGameFont.label(10))
                                .foregroundStyle(MiniArcadeTheme.woodLight.opacity(0.72))
                        }

                        Spacer()

                        VStack(spacing: 1) {
                            Text("BEST")
                                .font(MiniArcadeGameFont.label(9))
                            Text("\(stat.bestScore)")
                                .font(MiniArcadeGameFont.display(19).monospacedDigit())
                        }
                        .foregroundStyle(MiniArcadeTheme.wood)
                        .frame(minWidth: 58, minHeight: 48)
                        .padding(.horizontal, 4)
                        .background(MiniArcadeTheme.gold, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Image(systemName: "play.fill")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(MiniArcadeTheme.wood)
                    }
                    .padding(15)
                    .background(adventurePanel)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var latestRuns: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("LATEST RUNS")

            if viewModel.recentSessions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(MiniArcadeTheme.orange)
                    Text("YOUR FIRST QUEST AWAITS")
                        .font(MiniArcadeGameFont.display(14))
                        .foregroundStyle(MiniArcadeTheme.wood)
                    Text("Complete any game to begin your adventure log.")
                        .font(MiniArcadeGameFont.label(10))
                        .foregroundStyle(MiniArcadeTheme.woodLight.opacity(0.74))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(adventurePanel)
            } else {
                ForEach(Array(viewModel.recentSessions.prefix(3))) { session in
                    HStack(spacing: 12) {
                        GameModeArtworkIcon(mode: session.mode, size: 42, iconSize: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.mode.displayName)
                                .font(MiniArcadeGameFont.display(13))
                                .foregroundStyle(MiniArcadeTheme.wood)
                            Text(session.displayVariantLabel.uppercased())
                                .font(MiniArcadeGameFont.label(9))
                                .foregroundStyle(MiniArcadeTheme.woodLight.opacity(0.70))
                                .lineLimit(1)
                        }

                        Spacer()

                        Text("+\(session.score) XP")
                            .font(MiniArcadeGameFont.display(13).monospacedDigit())
                            .foregroundStyle(MiniArcadeTheme.orange)
                    }
                    .padding(13)
                    .background(adventurePanel)
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(MiniArcadeGameFont.display(18))
            .foregroundStyle(MiniArcadeTheme.lime)
            .gameTextShadow()
            .accessibilityAddTraits(.isHeader)
    }

    private var adventurePanel: some View {
        AdventureArtSlice(imageName: GameArt.adventurePanel)
    }

    private var playerLevel: Int {
        min(max(viewModel.totalScore / xpPerLevel + 1, 1), 99)
    }

    private var currentLevelXP: Int {
        viewModel.totalScore % xpPerLevel
    }

    private var rankName: String {
        switch playerLevel {
        case 1...2: return "New Explorer"
        case 3...5: return "Trailblazer"
        case 6...10: return "Arcade Hero"
        default: return "Jungle Legend"
        }
    }

    @ViewBuilder
    private func destination(for mode: GameMode) -> some View {
        switch mode {
        case .tapFrenzy:
            TapFrenzyView()
        case .lightItUp:
            LightItUpView()
        case .quizRush:
            QuizRushView()
        }
    }
}

private struct AchievementBadge: View {
    let title: String
    let detail: String
    let symbol: String
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(unlocked ? MiniArcadeTheme.wood : MiniArcadeTheme.woodLight.opacity(0.42))
                    .frame(width: 48, height: 48)
                    .background(
                        unlocked ? MiniArcadeTheme.gold : MiniArcadeTheme.sand.opacity(0.56),
                        in: Circle()
                    )

                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(MiniArcadeTheme.woodLight, in: Circle())
                }
            }

            Text(title.uppercased())
                .font(MiniArcadeGameFont.display(11))
                .foregroundStyle(MiniArcadeTheme.wood)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(detail)
                .font(MiniArcadeGameFont.label(9))
                .foregroundStyle(MiniArcadeTheme.woodLight.opacity(0.70))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 122)
        .padding(12)
        .background(AdventureArtSlice(imageName: GameArt.adventurePanel))
        .opacity(unlocked ? 1 : 0.72)
        .accessibilityElement(children: .combine)
        .accessibilityValue(unlocked ? "Unlocked" : "Locked")
    }
}

#Preview {
    NavigationStack { StatsTab() }
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
        .environmentObject(LocationService.shared)
}
