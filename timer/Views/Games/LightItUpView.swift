import SwiftUI

struct LightItUpView: View {
    @EnvironmentObject private var store: GameSessionStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = LightItUpVM()

    var body: some View {
        ZStack {
            PlayHubScreenBackground()

            VStack(spacing: 18) {
                header
                ProgressView(value: Double(viewModel.elapsed), total: 60)
                    .tint(levelTint)
                    .background(Color.white.opacity(0.70), in: Capsule())
                grid
                controls
            }
            .padding(20)

            if viewModel.didFinishRound {
                Color.black.opacity(0.34)
                    .ignoresSafeArea()

                ResultView(
                    mode: .lightItUp,
                    score: viewModel.score,
                    bestScore: store.bestScore(for: .lightItUp),
                    onPlayAgain: viewModel.start
                )
            }
        }
        .onAppear {
            LocationService.shared.refreshLocation()
            if !viewModel.isRunning && !viewModel.didFinishRound {
                viewModel.start()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active, viewModel.isRunning {
                viewModel.stop()
            }
        }
        .navigationTitle("Light It Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ScoreBadge(title: "Score", value: "\(viewModel.score)", symbol: "trophy.fill", tint: levelTint)
                ScoreBadge(title: "Level", value: viewModel.level.label, symbol: "square.grid.3x3.fill", tint: levelTint)
            }

            HStack(spacing: 10) {
                ScoreBadge(title: "Best", value: "\(store.bestScore(for: .lightItUp))", symbol: "crown.fill", tint: PlayHubTheme.gold)
                ScoreBadge(title: "Time", value: "\(viewModel.remaining)s", symbol: "clock.fill", tint: PlayHubTheme.sky)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: viewModel.columns, spacing: 12) {
            ForEach(viewModel.cards) { card in
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(card.isLit ? levelTint : Color.white.opacity(0.72))
                    .frame(height: 90)
                    .overlay {
                        if card.isLit {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 30, weight: .black))
                                .foregroundStyle(.white)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.08))
                    )
                    .shadow(color: levelTint.opacity(card.isLit ? 0.36 : 0), radius: 16, x: 0, y: 8)
                    .scaleEffect(card.isLit ? 1.03 : 1.0)
                    .onTapGesture { viewModel.tapCard(card) }
                    .animation(.easeInOut(duration: 0.15), value: card.isLit)
                    .accessibilityLabel(card.isLit ? "Lit tile" : "Dim tile")
                    .accessibilityAddTraits(.isButton)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.start) {
                Label(viewModel.isRunning ? "Restart" : "Start", systemImage: viewModel.isRunning ? "arrow.counterclockwise" : "play.fill")
            }
            .buttonStyle(PlayHubPrimaryButtonStyle(tint: levelTint))

            Button(action: viewModel.stop) {
                Label("Stop", systemImage: "stop.fill")
            }
            .buttonStyle(PlayHubSecondaryButtonStyle())
            .disabled(!viewModel.isRunning)
        }
    }

    private var levelTint: Color {
        switch viewModel.level {
        case .l1: return PlayHubTheme.sky
        case .l2: return PlayHubTheme.mint
        case .l3: return PlayHubTheme.gold
        case .l4: return PlayHubTheme.berry
        }
    }
}

#Preview("Light It Up") {
    NavigationStack { LightItUpView() }
        .environmentObject(GameSessionStore.shared)
}
