import SwiftUI

struct LightItUpView: View {
    @EnvironmentObject private var store: GameSessionStore
    @EnvironmentObject private var settings: GameSettingsStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = LightItUpVM()
    @State private var options = LightItUpPreset.classic.options
    @State private var didLoadDefaults = false
    @State private var showCustomization = false

    var body: some View {
        ZStack {
            MiniArcadeScreenBackground()

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
                ScoreBadge(title: "Best", value: "\(store.bestScore(for: .lightItUp, variantID: options.variantID))", symbol: "crown.fill", tint: MiniArcadeTheme.gold)
                ScoreBadge(title: "Time", value: "\(viewModel.remaining)s", symbol: "clock.fill", tint: MiniArcadeTheme.sky)
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
                        .fill(card.isLit ? levelTint : MiniArcadeTheme.woodLight)
                        .frame(height: 90)
                        .overlay {
                            if card.isLit {
                                GameModeGlyph(mode: .lightItUp, size: 36)
                                    .foregroundStyle(MiniArcadeTheme.wood)
                                    .frame(width: 44, height: 44, alignment: .center)
                            } else {
                                Circle()
                                    .fill(MiniArcadeTheme.wood.opacity(0.44))
                                    .frame(width: 14, height: 14)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(card.isLit ? MiniArcadeTheme.cream.opacity(0.72) : MiniArcadeTheme.lime.opacity(0.26), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(card.isLit ? 0.36 : 0.18), radius: 8, x: 0, y: 5)
                        .scaleEffect(card.isLit ? 1.03 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: card.isLit)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(card.isLit ? "Lit tile" : "Dim tile")
            }
        }
        .padding(12)
        .background(MiniArcadePanelBackground(cornerRadius: 22))
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

                    Stepper("Extra Lights \(options.extraLightsPerTick)", value: extraLightsBinding, in: 0...2)
                }
            }
            .font(MiniArcadeGameFont.label(13))
            .tint(MiniArcadeTheme.lime)
            .scrollContentBackground(.hidden)
            .background(MiniArcadeTheme.wood)
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
                GameActionLabel(
                    title: viewModel.isRunning ? "RESTART" : "START",
                    mode: .lightItUp
                )
                    .font(MiniArcadeGameFont.display(15))
            }
            .buttonStyle(MiniArcadePrimaryButtonStyle(tint: levelTint))

            Button(action: viewModel.stop) {
                Text("STOP")
                    .font(MiniArcadeGameFont.display(15))
            }
            .buttonStyle(MiniArcadeSecondaryButtonStyle())
            .disabled(!viewModel.isRunning)
        }
    }

    private var levelTint: Color {
        switch viewModel.level {
        case .l1: return MiniArcadeTheme.sky
        case .l2: return MiniArcadeTheme.mint
        case .l3: return MiniArcadeTheme.gold
        case .l4: return MiniArcadeTheme.berry
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
