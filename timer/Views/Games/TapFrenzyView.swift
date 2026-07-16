import SwiftUI

struct TapFrenzyView: View {
    @EnvironmentObject private var store: GameSessionStore
    @EnvironmentObject private var settings: GameSettingsStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = TapFrenzyVM()
    @State private var options = TapFrenzyPreset.classic.options
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
                    playField
                    controls
                }
                .frame(maxWidth: 430)
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

            if viewModel.showResults {
                ResultView(
                    mode: .tapFrenzy,
                    score: viewModel.score,
                    bestScore: store.bestScore(for: .tapFrenzy, variantID: options.variantID),
                    variantLabel: options.variantLabel,
                    onPlayAgain: { viewModel.start(options: options) }
                )
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(viewModel.showResults ? .hidden : .visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showCustomization) {
            customizationSheet
        }
        .onAppear {
            loadDefaultsIfNeeded()
            LocationService.shared.refreshLocation()
            if !viewModel.showResults {
                viewModel.reset(clearResults: true)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                viewModel.stop()
            }
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            GameArtProgressBar(value: viewModel.roundDuration - viewModel.timeRemaining, total: viewModel.roundDuration)

            HStack(spacing: 10) {
                ScoreBadge(title: "Time", value: String(format: "%.1fs", viewModel.timeRemaining), symbol: "clock.fill", tint: PlayHubTheme.orange)
                ScoreBadge(title: "Score", value: "\(viewModel.score)", symbol: "trophy.fill", tint: PlayHubTheme.gold)
                ScoreBadge(title: "Best", value: "\(store.bestScore(for: .tapFrenzy, variantID: options.variantID))", symbol: "crown.fill", tint: PlayHubTheme.mint)
            }
        }
    }

    private var gameBar: some View {
        ArcadeGameBar(
            variantLabel: options.variantLabel,
            statusLabel: viewModel.isRunning ? "Round in progress" : "Ready to play",
            canConfigure: !viewModel.isRunning
        ) {
            showCustomization = true
        }
    }

    private var playField: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(PlayHubTheme.woodLight.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(PlayHubTheme.lime.opacity(0.58), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.32), radius: 12, x: 0, y: 7)

                if !viewModel.isRunning && !viewModel.showResults {
                    VStack(spacing: 10) {
                        GameModeArtworkIcon(mode: .tapFrenzy, size: 76, iconSize: 44)
                        Text("Tap as fast as you can.")
                            .font(PlayHubGameFont.display(22))
                            .foregroundStyle(PlayHubTheme.lime)
                            .gameTextShadow()
                        Text(options.trapsEnabled ? "Combos, bonuses, moving targets, and traps are active." : "Focus mode keeps traps away so you can chase clean combos.")
                            .font(PlayHubGameFont.label(14))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(PlayHubTheme.cream.opacity(0.90))
                            .gameTextShadow()
                            .padding(.horizontal, 24)
                    }
                }

                if viewModel.isRunning {
                    Button {
                        viewModel.handleTap()
                    } label: {
                        VStack(spacing: 8) {
                            TapTargetGlyph(mood: viewModel.targetMood)
                            Text(viewModel.targetMood.buttonTitle)
                                .font(PlayHubGameFont.display(15))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(PlayHubTheme.wood)
                        .frame(width: viewModel.targetSize, height: viewModel.targetSize)
                        .background {
                            if usesEnhancedControls {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [viewModel.targetMood.color, viewModel.targetMood.color.opacity(0.68)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            } else {
                                Circle()
                                    .fill(viewModel.targetMood.color)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(PlayHubTheme.cream.opacity(0.72), lineWidth: 4)
                        )
                        .shadow(
                            color: usesEnhancedControls ? PlayHubTheme.wood.opacity(0.92) : .clear,
                            radius: 0,
                            x: 0,
                            y: 8
                        )
                        .shadow(
                            color: viewModel.targetMood.color.opacity(0.36),
                            radius: usesEnhancedControls ? 12 : 18,
                            x: 0,
                            y: 10
                        )
                        .scaleEffect(viewModel.bonusBurstActive ? 1.08 : 1.0)
                        .animation(.snappy(duration: 0.22), value: viewModel.targetSize)
                        .animation(.snappy(duration: 0.22), value: viewModel.targetOffset)
                        .animation(.snappy(duration: 0.18), value: viewModel.targetMood)
                    }
                    .buttonStyle(TapTargetButtonStyle(usesEnhancedControls: usesEnhancedControls))
                    .offset(viewModel.targetOffset)
                    .accessibilityLabel(viewModel.targetMood.accessibilityLabel)
                }

                VStack {
                    Spacer()
                    HStack {
                        Label("Combo x\(viewModel.multiplier)", systemImage: "flame.fill")
                            .font(PlayHubGameFont.label(13))
                            .foregroundStyle(PlayHubTheme.wood)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(PlayHubTheme.sand, in: Capsule())
                        Spacer()
                        if viewModel.bonusBurstActive {
                            Label("Double Points", systemImage: "sparkles")
                                .font(PlayHubGameFont.label(13))
                                .foregroundStyle(PlayHubTheme.wood)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(PlayHubTheme.lime, in: Capsule())
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

    private var customizationSheet: some View {
        NavigationStack {
            Form {
                Section("Tap Frenzy Setup") {
                    Picker("Preset", selection: presetBinding) {
                        ForEach(TapFrenzyPreset.allCases) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)

                    Stepper("Round \(Int(options.roundDuration))s", value: roundDurationBinding, in: 5...30, step: 5)
                    Toggle("Traps", isOn: trapsBinding)
                    Toggle("Bonus Burst", isOn: bonusBurstBinding)

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Target Moves Every \(options.targetMoveInterval, specifier: "%.2f")s")
                        Slider(value: targetMoveBinding, in: 0.5...1.5, step: 0.05)
                    }
                }
            }
            .font(PlayHubGameFont.label(13))
            .tint(PlayHubTheme.lime)
            .scrollContentBackground(.hidden)
            .background(PlayHubTheme.wood)
            .navigationTitle("Tap Frenzy Setup")
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
        Button {
            if viewModel.isRunning {
                viewModel.reset(clearResults: false)
            } else {
                viewModel.start(options: options)
            }
        } label: {
            GameActionLabel(
                title: viewModel.isRunning ? "RESET" : "START",
                mode: .tapFrenzy
            )
                .font(PlayHubGameFont.display(15))
        }
        .buttonStyle(PlayHubPrimaryButtonStyle(tint: viewModel.isRunning ? PlayHubTheme.berry : PlayHubTheme.orange))
    }

    private var presetBinding: Binding<TapFrenzyPreset> {
        Binding(
            get: { options.preset },
            set: { preset in
                updateOptions { $0 = preset.options }
            }
        )
    }

    private var roundDurationBinding: Binding<Double> {
        Binding(
            get: { options.roundDuration },
            set: { value in updateOptions { $0.roundDuration = value } }
        )
    }

    private var trapsBinding: Binding<Bool> {
        Binding(
            get: { options.trapsEnabled },
            set: { value in updateOptions { $0.trapsEnabled = value } }
        )
    }

    private var bonusBurstBinding: Binding<Bool> {
        Binding(
            get: { options.bonusBurstEnabled },
            set: { value in updateOptions { $0.bonusBurstEnabled = value } }
        )
    }

    private var targetMoveBinding: Binding<Double> {
        Binding(
            get: { options.targetMoveInterval },
            set: { value in
                updateOptions {
                    $0.targetMoveInterval = value
                    $0.moodChangeInterval = max(0.55, value + 0.35)
                }
            }
        )
    }

    private func updateOptions(_ update: (inout TapFrenzyOptions) -> Void) {
        var nextOptions = options
        update(&nextOptions)
        options = nextOptions
        viewModel.applyOptions(nextOptions)
    }

    private func loadDefaultsIfNeeded() {
        guard !didLoadDefaults else { return }
        didLoadDefaults = true
        options = settings.defaultTapOptions
        viewModel.applyOptions(options)
    }
}

private struct TapTargetButtonStyle: ButtonStyle {
    let usesEnhancedControls: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: usesEnhancedControls && configuration.isPressed ? 5 : 0)
            .scaleEffect(usesEnhancedControls && configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.14), value: configuration.isPressed)
    }
}

private struct TapTargetGlyph: View {
    let mood: TapTargetMood

    var body: some View {
        Group {
            switch mood {
            case .normal:
                GameModeGlyph(mode: .tapFrenzy, size: 34)
            case .bonus:
                Text("+2")
                    .font(PlayHubGameFont.display(28).monospacedDigit())
            case .trap:
                Text("-2")
                    .font(PlayHubGameFont.display(28).monospacedDigit())
            }
        }
        .frame(width: 44, height: 40)
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack { TapFrenzyView() }
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
}
