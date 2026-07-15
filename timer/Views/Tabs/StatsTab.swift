import Charts
import SwiftUI

struct StatsTab: View {
    @StateObject private var viewModel = StatsVM()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryGrid
                chartSection
                modeBreakdown
                variantLeaderboards
                recentGames
            }
            .padding(20)
        }
        .background(PlayHubScreenBackground())
        .navigationTitle("Stats")
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ScoreBadge(title: "Games", value: "\(viewModel.totalGames)", symbol: "number.circle.fill", tint: PlayHubTheme.orange)
            ScoreBadge(title: "Total", value: "\(viewModel.totalScore)", symbol: "sum", tint: PlayHubTheme.sky)
            ScoreBadge(title: "Average", value: "\(viewModel.averageScore)", symbol: "divide.circle.fill", tint: PlayHubTheme.mint)
            ScoreBadge(title: "Mapped", value: "\(viewModel.locatedSessions.count)", symbol: "mappin.circle.fill", tint: PlayHubTheme.berry)
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Scores")
                .font(.title3.bold())
                .foregroundStyle(PlayHubTheme.ink)

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
                            .font(.caption.bold())
                            .foregroundStyle(PlayHubTheme.ink)
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
            Text("By Game")
                .font(.title3.bold())
                .foregroundStyle(PlayHubTheme.ink)

            ForEach(viewModel.modeStats) { stat in
                HStack(spacing: 12) {
                    PlayHubSymbolIcon(
                        systemName: stat.mode.symbolName,
                        tint: PlayHubTheme.tint(for: stat.mode),
                        size: 42,
                        symbolSize: 18
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(stat.mode.displayName)
                            .font(.headline)
                            .foregroundStyle(PlayHubTheme.ink)
                        Text("\(stat.games) games  |  total \(stat.totalScore)")
                            .font(.caption)
                            .foregroundStyle(PlayHubTheme.mutedInk)
                    }

                    Spacer()

                    Text("\(stat.bestScore)")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(PlayHubTheme.ink)
                }
                .padding(14)
                .background(panelBackground)
            }
        }
    }

    private var variantLeaderboards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Variant Leaderboards")
                .font(.title3.bold())
                .foregroundStyle(PlayHubTheme.ink)

            if viewModel.variantStats.isEmpty {
                emptyState(symbol: "list.star", title: "No variants yet", message: "Complete a customized game to start a variant leaderboard.")
            } else {
                ForEach(viewModel.variantStats) { stat in
                    HStack(spacing: 12) {
                        PlayHubSymbolIcon(
                            systemName: stat.mode.symbolName,
                            tint: PlayHubTheme.tint(for: stat.mode),
                            size: 42,
                            symbolSize: 18
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(stat.mode.displayName)
                                .font(.headline)
                                .foregroundStyle(PlayHubTheme.ink)
                            Text("\(stat.variantLabel)  |  \(stat.games) games")
                                .font(.caption)
                                .foregroundStyle(PlayHubTheme.mutedInk)
                                .lineLimit(2)
                        }

                        Spacer()

                        Text("\(stat.bestScore)")
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(PlayHubTheme.ink)
                    }
                    .padding(14)
                    .background(panelBackground)
                }
            }
        }
    }

    private var recentGames: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.title3.bold())
                .foregroundStyle(PlayHubTheme.ink)

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
                                .font(.headline)
                                .foregroundStyle(PlayHubTheme.ink)
                            Text(session.displayVariantLabel)
                                .font(.caption)
                                .foregroundStyle(PlayHubTheme.mutedInk)
                                .lineLimit(2)
                            Text(session.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundStyle(PlayHubTheme.mutedInk)
                        }

                        Spacer()

                        Text("\(session.score)")
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(PlayHubTheme.ink)
                    }
                    .padding(12)
                    .background(panelBackground)
                }
            }
        }
    }

    private func emptyState(symbol: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(PlayHubTheme.orange)
            Text(title)
                .font(.headline)
                .foregroundStyle(PlayHubTheme.ink)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(PlayHubTheme.mutedInk)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(panelBackground)
    }

    private var panelBackground: some View {
        PlayHubPanelBackground()
    }
}

#Preview {
    NavigationStack { StatsTab() }
}
