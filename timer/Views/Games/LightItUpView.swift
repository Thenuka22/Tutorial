import SwiftUI

struct LightItUpView: View {
    @EnvironmentObject private var store: GameSessionStore
    @EnvironmentObject private var settings: GameSettingsStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = LightItUpVM()
    @State private var options = LightItUpPreset.classic.options
    @State private var didLoadDefaults = false

    var body: some View {
        ZStack {
            PlayHubScreenBackground()

            VStack(spacing: 18) {
                header
                customizePanel
                GameArtProgressBar(value: Double(viewModel.elapsed), total: Double(viewModel.roundDuration))
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
                    bestScore: store.bestScore(for: .lightItUp, variantID: options.variantID),
                    variantLabel: options.variantLabel,
                    onPlayAgain: { viewModel.start(options: options) }
                )
            }
        }
        .onAppear {
            loadDefaultsIfNeeded()
            LocationService.shared.refreshLocation()
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
                ScoreBadge(title: "Best", value: "\(store.bestScore(for: .lightItUp, variantID: options.variantID))", symbol: "crown.fill", tint: PlayHubTheme.gold)
                ScoreBadge(title: "Time", value: "\(viewModel.remaining)s", symbol: "clock.fill", tint: PlayHubTheme.sky)
            }
        }
    }

    private var customizePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Customize", systemImage: "slider.horizontal.3")
                    .font(.headline.bold())
                    .foregroundStyle(PlayHubTheme.ink)
                Spacer()
                Text(options.variantLabel)
                    .font(.caption.bold())
                    .foregroundStyle(PlayHubTheme.mutedInk)
            }

            Picker("Preset", selection: presetBinding) {
                ForEach(LightItUpPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            Stepper("Round \(options.roundDuration)s", value: roundDurationBinding, in: 15...90, step: 15)

            Picker("Starting Level", selection: startingLevelBinding) {
                ForEach(GameLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.menu)

            Stepper("Wrong Tap Penalty \(options.wrongTapPenalty)", value: wrongPenaltyBinding, in: 0...5)

            Stepper("Missed Light Penalty \(options.missedLightPenalty)", value: missedPenaltyBinding, in: 0...5)

            Stepper("Extra Lights \(options.extraLightsPerTick)", value: extraLightsBinding, in: 0...2)
        }
        .font(.subheadline)
        .padding(14)
        .background(PlayHubPanelBackground())
        .disabled(viewModel.isRunning)
        .opacity(viewModel.isRunning ? 0.68 : 1)
    }

    private var grid: some View {
        LazyVGrid(columns: viewModel.columns, spacing: 12) {
            ForEach(viewModel.cards) { card in
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(card.isLit ? levelTint : Color(red: 0.12, green: 0.18, blue: 0.20).opacity(0.80))
                    .frame(height: 90)
                    .overlay {
                        if card.isLit {
                            Image(GameArt.medal)
                                .resizable()
                                .scaledToFit()
                                .padding(18)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(card.isLit ? 0.65 : 0.18), lineWidth: 2)
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
            Button {
                viewModel.start(options: options)
            } label: {
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

    private var presetBinding: Binding<LightItUpPreset> {
        Binding(
            get: { options.preset },
            set: { preset in updateOptions { $0 = preset.options } }
        )
    }

    private var roundDurationBinding: Binding<Int> {
        Binding(
            get: { options.roundDuration },
            set: { value in updateOptions { $0.roundDuration = value } }
        )
    }

    private var startingLevelBinding: Binding<GameLevel> {
        Binding(
            get: { options.startingLevel },
            set: { value in updateOptions { $0.startingLevel = value } }
        )
    }

    private var wrongPenaltyBinding: Binding<Int> {
        Binding(
            get: { options.wrongTapPenalty },
            set: { value in updateOptions { $0.wrongTapPenalty = value } }
        )
    }

    private var missedPenaltyBinding: Binding<Int> {
        Binding(
            get: { options.missedLightPenalty },
            set: { value in updateOptions { $0.missedLightPenalty = value } }
        )
    }

    private var extraLightsBinding: Binding<Int> {
        Binding(
            get: { options.extraLightsPerTick },
            set: { value in updateOptions { $0.extraLightsPerTick = value } }
        )
    }

    private func updateOptions(_ update: (inout LightItUpOptions) -> Void) {
        var nextOptions = options
        update(&nextOptions)
        options = nextOptions
        viewModel.applyOptions(nextOptions)
    }

    private func loadDefaultsIfNeeded() {
        guard !didLoadDefaults else { return }
        didLoadDefaults = true
        options = settings.defaultLightOptions
        viewModel.applyOptions(options)
    }
}

#Preview("Light It Up") {
    NavigationStack { LightItUpView() }
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
}
