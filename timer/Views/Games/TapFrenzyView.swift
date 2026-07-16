import Combine
import SwiftUI

struct TapFrenzyView: View {
    @EnvironmentObject private var store: GameSessionStore
    @EnvironmentObject private var settings: GameSettingsStore
    @StateObject private var viewModel = TapFrenzyVM()
    @State private var options = TapFrenzyPreset.classic.options
    @State private var didLoadDefaults = false

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            PlayHubScreenBackground()

            VStack(spacing: 18) {
                header
                customizePanel
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
                    bestScore: store.bestScore(for: .tapFrenzy, variantID: options.variantID),
                    variantLabel: options.variantLabel,
                    onPlayAgain: { viewModel.start(options: options) }
                )
            }
        }
        .navigationTitle("Tap Frenzy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            loadDefaultsIfNeeded()
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
            GameArtProgressBar(value: viewModel.roundDuration - viewModel.timeRemaining, total: viewModel.roundDuration)

            HStack(spacing: 10) {
                ScoreBadge(title: "Time", value: String(format: "%.1fs", viewModel.timeRemaining), symbol: "clock.fill", tint: PlayHubTheme.orange)
                ScoreBadge(title: "Score", value: "\(viewModel.score)", symbol: "trophy.fill", tint: PlayHubTheme.gold)
                ScoreBadge(title: "Best", value: "\(store.bestScore(for: .tapFrenzy, variantID: options.variantID))", symbol: "crown.fill", tint: PlayHubTheme.mint)
            }
        }
    }

    private var customizePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Customize", systemImage: "slider.horizontal.3")
                    .font(PlayHubGameFont.display(16))
                    .foregroundStyle(PlayHubTheme.ink)
                Spacer()
                Text(options.variantLabel)
                    .font(PlayHubGameFont.label(11))
                    .foregroundStyle(PlayHubTheme.mutedInk)
            }

            Picker("Preset", selection: presetBinding) {
                ForEach(TapFrenzyPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            Stepper("Round \(Int(options.roundDuration))s", value: roundDurationBinding, in: 5...30, step: 5)

            Toggle("Traps", isOn: trapsBinding)
                .tint(PlayHubTheme.berry)

            Toggle("Bonus Burst", isOn: bonusBurstBinding)
                .tint(PlayHubTheme.mint)

            VStack(alignment: .leading, spacing: 6) {
                Text("Target Moves Every \(options.targetMoveInterval, specifier: "%.2f")s")
                    .font(PlayHubGameFont.label(13))
                    .foregroundStyle(PlayHubTheme.ink)
                Slider(value: targetMoveBinding, in: 0.5...1.5, step: 0.05)
                    .tint(PlayHubTheme.orange)
            }
        }
        .font(PlayHubGameFont.label(13))
        .padding(14)
        .background(PlayHubPanelBackground())
        .disabled(viewModel.isRunning)
        .opacity(viewModel.isRunning ? 0.68 : 1)
    }

    private var playField: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 0.11, green: 0.17, blue: 0.19).opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 2)
                    )

                if !viewModel.isRunning && !viewModel.showResults {
                    VStack(spacing: 10) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 54, weight: .black))
                            .foregroundStyle(PlayHubTheme.orange)
                        Text("Tap as fast as you can.")
                            .font(PlayHubGameFont.display(22))
                            .foregroundStyle(.white)
                            .gameTextShadow()
                        Text(options.trapsEnabled ? "Combos, bonuses, moving targets, and traps are active." : "Focus mode keeps traps away so you can chase clean combos.")
                            .font(PlayHubGameFont.label(14))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.92))
                            .gameTextShadow()
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
                                .font(PlayHubGameFont.display(15))
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
                            .font(PlayHubGameFont.label(13))
                            .foregroundStyle(PlayHubTheme.berry)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(PlayHubTheme.cream.opacity(0.94), in: Capsule())
                        Spacer()
                        if viewModel.bonusBurstActive {
                            Label("Double Points", systemImage: "sparkles")
                                .font(PlayHubGameFont.label(13))
                                .foregroundStyle(PlayHubTheme.mint)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(PlayHubTheme.cream.opacity(0.94), in: Capsule())
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
                viewModel.start(options: options)
            }
        } label: {
            Label(viewModel.isRunning ? "Reset" : "Start", systemImage: viewModel.isRunning ? "arrow.counterclockwise" : "play.fill")
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

#Preview {
    NavigationStack { TapFrenzyView() }
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
}
