import SwiftUI

struct LightItUpView: View {
    @EnvironmentObject private var store: GameSessionStore
    @EnvironmentObject private var settings: GameSettingsStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = LightItUpVM()
    @State private var options = LightItUpPreset.classic.options
    @State private var didLoadDefaults = false
    @State private var showCustomization = false

    private var usesEnhancedControls: Bool {
        settings.selectedBackgroundTheme.usesEnhancedControls
    }

    var body: some View {
        ZStack {
            PlayHubScreenBackground()

            ScrollView {
                VStack(spacing: 14) {
                    gameBar
                    header
                    GameArtProgressBar(value: Double(viewModel.elapsed), total: Double(viewModel.roundDuration))
                    grid
                    controls
                }
                .frame(maxWidth: 430)
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

            if viewModel.didFinishRound {
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(viewModel.didFinishRound ? .hidden : .visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showCustomization) {
            customizationSheet
        }
    }

    private var gameBar: some View {
        ArcadeGameBar(
            variantLabel: options.variantLabel,
            statusLabel: viewModel.isRunning ? "Level \(viewModel.level.label) in progress" : "Ready to play",
            canConfigure: !viewModel.isRunning
        ) {
            showCustomization = true
        }
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

    private var grid: some View {
        LazyVGrid(columns: viewModel.columns, spacing: 12) {
            ForEach(viewModel.cards) { card in
                Button {
                    viewModel.tapCard(card)
                } label: {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            usesEnhancedControls
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [
                                            card.isLit ? levelTint : PlayHubTheme.woodLight,
                                            (card.isLit ? levelTint : PlayHubTheme.woodLight).opacity(0.66)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                : AnyShapeStyle(card.isLit ? levelTint : PlayHubTheme.woodLight)
                        )
                        .frame(height: 90)
                        .overlay {
                            if card.isLit {
                                Image(systemName: "bolt.fill")
                                    .symbolRenderingMode(.monochrome)
                                    .font(.system(size: 34, weight: .black))
                                    .foregroundStyle(PlayHubTheme.wood)
                                    .frame(width: 44, height: 44, alignment: .center)
                            } else {
                                Circle()
                                    .fill(PlayHubTheme.wood.opacity(0.44))
                                    .frame(width: 14, height: 14)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(card.isLit ? PlayHubTheme.cream.opacity(0.72) : PlayHubTheme.lime.opacity(0.26), lineWidth: 2)
                        )
                        .shadow(
                            color: usesEnhancedControls ? PlayHubTheme.wood.opacity(0.92) : .clear,
                            radius: 0,
                            x: 0,
                            y: 6
                        )
                        .shadow(color: Color.black.opacity(card.isLit ? 0.36 : 0.18), radius: 8, x: 0, y: 5)
                        .scaleEffect(card.isLit ? 1.03 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: card.isLit)
                }
                .buttonStyle(LightTileButtonStyle(usesEnhancedControls: usesEnhancedControls))
                .accessibilityLabel(card.isLit ? "Lit tile" : "Dim tile")
            }
        }
        .padding(12)
        .background(PlayHubPanelBackground(cornerRadius: 22))
    }

    private var customizationSheet: some View {
        NavigationStack {
            Form {
                Section("Light It Up Setup") {
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

                    Stepper("Wrong Tap Penalty \(options.wrongTapPenalty)", value: wrongPenaltyBinding, in: 0...5)
                    Stepper("Missed Light Penalty \(options.missedLightPenalty)", value: missedPenaltyBinding, in: 0...5)
                    Stepper("Extra Lights \(options.extraLightsPerTick)", value: extraLightsBinding, in: 0...2)
                }
            }
            .font(PlayHubGameFont.label(13))
            .tint(PlayHubTheme.lime)
            .scrollContentBackground(.hidden)
            .background(PlayHubTheme.wood)
            .navigationTitle("Light It Up Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showCustomization = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.start(options: options)
            } label: {
                Label(viewModel.isRunning ? "Restart" : "Start", systemImage: viewModel.isRunning ? "arrow.counterclockwise" : "play.fill")
                    .font(PlayHubGameFont.display(15))
            }
            .buttonStyle(PlayHubPrimaryButtonStyle(tint: levelTint))

            Button(action: viewModel.stop) {
                Label("Stop", systemImage: "stop.fill")
                    .font(PlayHubGameFont.display(15))
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

private struct LightTileButtonStyle: ButtonStyle {
    let usesEnhancedControls: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: usesEnhancedControls && configuration.isPressed ? 4 : 0)
            .scaleEffect(usesEnhancedControls && configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview("Light It Up") {
    NavigationStack { LightItUpView() }
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
}
