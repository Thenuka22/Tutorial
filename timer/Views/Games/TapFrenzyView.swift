import SwiftUI

struct TapFrenzyView: View {
    @EnvironmentObject private var store: GameSessionStore
    @StateObject private var viewModel = TapFrenzyVM()

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            PlayHubScreenBackground()

            VStack(spacing: 18) {
                header
                playField
                controls
            }
            .padding(20)

            if viewModel.showResults {
                Color.black.opacity(0.34)
                    .ignoresSafeArea()

                ResultView(
                    mode: .tapFrenzy,
                    score: viewModel.score,
                    bestScore: store.bestScore(for: .tapFrenzy),
                    onPlayAgain: viewModel.start
                )
            }
        }
        .navigationTitle("Tap Frenzy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            LocationService.shared.refreshLocation()
            if !viewModel.showResults {
                viewModel.reset(clearResults: true)
            }
        }
        .onReceive(timer) { now in
            viewModel.tick(now)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ProgressView(value: viewModel.roundDuration - viewModel.timeRemaining, total: viewModel.roundDuration)
                .tint(PlayHubTheme.orange)
                .background(Color.white.opacity(0.7), in: Capsule())

            HStack(spacing: 10) {
                ScoreBadge(title: "Time", value: String(format: "%.1fs", viewModel.timeRemaining), symbol: "clock.fill", tint: PlayHubTheme.orange)
                ScoreBadge(title: "Score", value: "\(viewModel.score)", symbol: "trophy.fill", tint: PlayHubTheme.gold)
                ScoreBadge(title: "Best", value: "\(store.bestScore(for: .tapFrenzy))", symbol: "crown.fill", tint: PlayHubTheme.mint)
            }
        }
    }

    private var playField: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )

                if !viewModel.isRunning && !viewModel.showResults {
                    VStack(spacing: 10) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 54, weight: .black))
                            .foregroundStyle(PlayHubTheme.orange)
                        Text("Tap as fast as you can.")
                            .font(.title3.bold())
                            .foregroundStyle(PlayHubTheme.ink)
                        Text("Combos, bonus bursts, moving targets, and traps are active.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(PlayHubTheme.mutedInk)
                            .padding(.horizontal, 24)
                    }
                }

                if viewModel.isRunning {
                    Button {
                        viewModel.handleTap()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: viewModel.targetMood.symbolName)
                                .font(.system(size: 34, weight: .black))
                            Text(viewModel.targetMood.buttonTitle)
                                .font(.headline.bold())
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(.white)
                        .frame(width: viewModel.targetSize, height: viewModel.targetSize)
                        .background(viewModel.targetMood.color, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.65), lineWidth: 4)
                        )
                        .shadow(color: viewModel.targetMood.color.opacity(0.36), radius: 18, x: 0, y: 10)
                        .scaleEffect(viewModel.bonusBurstActive ? 1.08 : 1.0)
                        .animation(.snappy(duration: 0.22), value: viewModel.targetSize)
                        .animation(.snappy(duration: 0.22), value: viewModel.targetOffset)
                        .animation(.snappy(duration: 0.18), value: viewModel.targetMood)
                    }
                    .buttonStyle(.plain)
                    .offset(viewModel.targetOffset)
                    .accessibilityLabel(viewModel.targetMood.accessibilityLabel)
                }

                VStack {
                    Spacer()
                    HStack {
                        Label("Combo x\(viewModel.multiplier)", systemImage: "flame.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(PlayHubTheme.berry)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.92), in: Capsule())
                        Spacer()
                        if viewModel.bonusBurstActive {
                            Label("Double Points", systemImage: "sparkles")
                                .font(.subheadline.bold())
                                .foregroundStyle(PlayHubTheme.mint)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.92), in: Capsule())
                        }
                    }
                    .padding(14)
                }
            }
            .onChange(of: viewModel.isRunning) { _, running in
                if running {
                    viewModel.moveTarget(in: proxy.size)
                }
            }
        }
        .frame(minHeight: 330)
    }

    private var controls: some View {
        Button {
            if viewModel.isRunning {
                viewModel.reset(clearResults: false)
            } else {
                viewModel.start()
            }
        } label: {
            Label(viewModel.isRunning ? "Reset" : "Start", systemImage: viewModel.isRunning ? "arrow.counterclockwise" : "play.fill")
        }
        .buttonStyle(PlayHubPrimaryButtonStyle(tint: viewModel.isRunning ? PlayHubTheme.berry : PlayHubTheme.orange))
    }
}

#Preview {
    NavigationStack { TapFrenzyView() }
        .environmentObject(GameSessionStore.shared)
}
