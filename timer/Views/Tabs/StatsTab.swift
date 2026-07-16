import Charts
import SwiftUI

struct StatsTab: View {
    @StateObject private var viewModel = StatsVM()

    var body: some View {
        ZStack {
            scoreBackground

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    scoreboardHeader
                    summaryGrid
                    chartSection
                    modeBreakdown
                    variantLeaderboards
                    recentGames
                }
                .frame(maxWidth: 430)
                .padding(.horizontal, 18)
                .padding(.top, 150)
                .padding(.bottom, 108)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }

    private var scoreBackground: some View {
        Image(GameArt.scoreBackground)
            .resizable()
            .aspectRatio(9.0 / 16.0, contentMode: .fill)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }

    private var scoreboardHeader: some View {
        HStack(spacing: 13) {
            PlayHubSymbolIcon(
                systemName: "trophy.fill",
                tint: PlayHubTheme.gold,
                size: 54,
                symbolSize: 24
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("SCOREBOARD")
                    .font(PlayHubGameFont.display(24))
                    .foregroundStyle(.white)
                Text("YOUR GAME ARCADE RECORDS")
                    .font(PlayHubGameFont.label(10))
                    .foregroundStyle(PlayHubTheme.cream)
            }

            Spacer()
        }
        .padding(16)
        .background(PixelArtSlice(imageName: GameArt.pixelPanelBrown, capInset: 11))
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            PixelStatCard(title: "Games", value: "\(viewModel.totalGames)", symbol: "gamecontroller.fill", tint: PlayHubTheme.orange)
            PixelStatCard(title: "Total", value: "\(viewModel.totalScore)", symbol: "sum", tint: PlayHubTheme.sky)
            PixelStatCard(title: "Average", value: "\(viewModel.averageScore)", symbol: "divide.circle.fill", tint: PlayHubTheme.mint)
            PixelStatCard(title: "Mapped", value: "\(viewModel.locatedSessions.count)", symbol: "mappin.circle.fill", tint: PlayHubTheme.berry)
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("BEST SCORES", symbol: "chart.bar.fill")

            if viewModel.totalGames == 0 {
                emptyState(symbol: "chart.bar", title: "No stats yet", message: "Complete any game to build your chart.")
            } else {
                Chart(viewModel.modeStats) { stat in
                    BarMark(
                        x: .value("Game", stat.mode.shortName),
                        y: .value("Best Score", stat.bestScore)
                    )
                    .foregroundStyle(PlayHubTheme.tint(for: stat.mode))
                    .annotation(position: .top) {
                        Text("\(stat.bestScore)")
                            .font(PlayHubGameFont.label(10))
                            .foregroundStyle(PlayHubTheme.wood)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(PlayHubTheme.wood.opacity(0.16))
                        AxisValueLabel().foregroundStyle(PlayHubTheme.wood)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(PlayHubTheme.wood.opacity(0.16))
                        AxisValueLabel().foregroundStyle(PlayHubTheme.wood)
                    }
                }
                .frame(height: 220)
                .padding(16)
                .background(panelBackground)
            }
        }
    }

    private var modeBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("BY GAME", symbol: "gamecontroller.fill")

            ForEach(viewModel.modeStats) { stat in
                scoreRow(
                    mode: stat.mode,
                    title: stat.mode.displayName,
                    detail: "\(stat.games) games  |  total \(stat.totalScore)",
                    score: stat.bestScore
                )
            }
        }
    }

    private var variantLeaderboards: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("VARIANT LEADERS", symbol: "list.star")

            if viewModel.variantStats.isEmpty {
                emptyState(symbol: "list.star", title: "No variants yet", message: "Complete a customized game to start a variant leaderboard.")
            } else {
                ForEach(viewModel.variantStats) { stat in
                    scoreRow(
                        mode: stat.mode,
                        title: stat.mode.displayName,
                        detail: "\(stat.variantLabel)  |  \(stat.games) games",
                        score: stat.bestScore
                    )
                }
            }
        }
    }

    private var recentGames: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("RECENT GAMES", symbol: "clock.fill")

            if viewModel.recentSessions.isEmpty {
                emptyState(symbol: "clock", title: "No recent games", message: "Your completed sessions will appear here.")
            } else {
                ForEach(viewModel.recentSessions) { session in
                    HStack(spacing: 12) {
                        PlayHubSymbolIcon(
                            systemName: session.mode.symbolName,
                            tint: PlayHubTheme.tint(for: session.mode),
                            size: 42,
                            symbolSize: 18
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.mode.displayName)
                                .font(PlayHubGameFont.display(14))
                                .foregroundStyle(PlayHubTheme.wood)
                            Text(session.displayVariantLabel)
                                .font(PlayHubGameFont.label(10))
                                .foregroundStyle(PlayHubTheme.woodLight.opacity(0.78))
                                .lineLimit(2)
                            Text(session.timestamp, style: .relative)
                                .font(PlayHubGameFont.label(9))
                                .foregroundStyle(PlayHubTheme.woodLight.opacity(0.68))
                        }

                        Spacer()

                        scorePlate(session.score)
                    }
                    .padding(13)
                    .background(panelBackground)
                }
            }
        }
    }

    private func sectionTitle(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(PlayHubGameFont.display(15))
            .foregroundStyle(PlayHubTheme.wood)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, 14)
            .background(PixelArtSlice(imageName: GameArt.pixelButtonYellow))
            .accessibilityAddTraits(.isHeader)
    }

    private func scoreRow(mode: GameMode, title: String, detail: String, score: Int) -> some View {
        HStack(spacing: 12) {
            PlayHubSymbolIcon(
                systemName: mode.symbolName,
                tint: PlayHubTheme.tint(for: mode),
                size: 42,
                symbolSize: 18
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(PlayHubGameFont.display(14))
                    .foregroundStyle(PlayHubTheme.wood)
                Text(detail)
                    .font(PlayHubGameFont.label(10))
                    .foregroundStyle(PlayHubTheme.woodLight.opacity(0.78))
                    .lineLimit(2)
            }

            Spacer()
            scorePlate(score)
        }
        .padding(13)
        .background(panelBackground)
    }

    private func scorePlate(_ score: Int) -> some View {
        Text("\(score)")
            .font(PlayHubGameFont.display(16).monospacedDigit())
            .foregroundStyle(PlayHubTheme.orange)
            .lineLimit(1)
            .minimumScaleFactor(0.64)
            .frame(minWidth: 52, minHeight: 38)
            .padding(.horizontal, 5)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(PlayHubTheme.woodLight, lineWidth: 3)
            }
    }

    private func emptyState(symbol: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(PlayHubTheme.orange)
            Text(title.uppercased())
                .font(PlayHubGameFont.display(15))
                .foregroundStyle(PlayHubTheme.wood)
            Text(message)
                .font(PlayHubGameFont.label(11))
                .multilineTextAlignment(.center)
                .foregroundStyle(PlayHubTheme.woodLight.opacity(0.78))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(panelBackground)
    }

    private var panelBackground: some View {
        PixelArtSlice(imageName: GameArt.pixelPanelTan, capInset: 11)
    }
}

private struct PixelStatCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            PlayHubSymbolIcon(
                systemName: symbol,
                tint: tint,
                size: 40,
                symbolSize: 17
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(PlayHubGameFont.label(9))
                    .foregroundStyle(PlayHubTheme.woodLight.opacity(0.76))
                    .lineLimit(1)

                Text(value)
                    .font(PlayHubGameFont.display(19).monospacedDigit())
                    .foregroundStyle(PlayHubTheme.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }

            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 76)
        .background(PixelArtSlice(imageName: GameArt.pixelPanelTan, capInset: 11))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { StatsTab() }
}
