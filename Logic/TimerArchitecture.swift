import SwiftUI
import Combine

// MARK: - Game Level Definition
enum GameLevel: Int, CaseIterable, Equatable {
    case l1, l2, l3, l4

    // Total number of cards on the grid for this level
    var gridCount: Int {
        switch self {
        case .l1: return 3      // 1 row of 3
        case .l2: return 4      // 2x2
        case .l3: return 6      // 2x3
        case .l4: return 9      // 3x3
        }
    }

    // Number of columns for LazyVGrid
    var columnsCount: Int {
        switch self {
        case .l1: return 3
        case .l2: return 2
        case .l3: return 3
        case .l4: return 3
        }
    }

    // How long a card stays lit
    var timeWindow: TimeInterval {
        switch self {
        case .l1: return 1.5
        case .l2: return 1.2
        case .l3: return 1.0
        case .l4: return 0.8
        }
    }

    // How many cards light up per spawn tick
    var lightsPerTick: Int {
        switch self {
        case .l1, .l2, .l3: return 1
        case .l4: return 2
        }
    }

    // Human-readable short label for the UI
    var label: String {
        switch self {
        case .l1: return "L1"
        case .l2: return "L2"
        case .l3: return "L3"
        case .l4: return "L4"
        }
    }

    // How frequently we spawn new lights; aligned with the time window to avoid overlap
    var spawnInterval: TimeInterval { timeWindow }

    // Determine the level based on elapsed time in the 60s round
    static func level(forElapsed seconds: Int) -> GameLevel {
        switch seconds {
        case 0..<15: return .l1
        case 15..<30: return .l2
        case 30..<45: return .l3
        default: return .l4
        }
    }
}

// MARK: - Card Model

struct LightCard: Identifiable, Equatable {
    let id: Int           // stable index id within the grid
    var isLit: Bool = false
    // Token identifies a specific light-up event to prevent race conditions
    var litToken: UInt64? = nil
}

// MARK: - View Model

@MainActor
final class LightItUpViewModel: ObservableObject {
    // Published game state
    @Published private(set) var cards: [LightCard] = []
    @Published private(set) var level: GameLevel = .l1
    @Published private(set) var elapsed: Int = 0
    @Published private(set) var remaining: Int = 60
    @Published private(set) var score: Int = 0
    @Published private(set) var highScore: Int = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var didFinishRound: Bool = false

    // Grid columns for LazyVGrid usage in a SwiftUI View
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: level.columnsCount)
    }

    // Combine timers
    private var spawnCancellable: AnyCancellable?
    private var roundCancellable: AnyCancellable?

    // Token generator to disambiguate overlapping timers
    private var tokenGenerator: UInt64 = 0

    // Constants
    private let roundDuration: Int = 60
    private let penaltyOnMiss: Int = 1
    private let penaltyOnWrongTap: Int = 1
    private let highScoreKey = "LightItUpHighScore"

    init() {
        // Load persisted high score
        highScore = UserDefaults.standard.integer(forKey: highScoreKey)
        configureGrid(for: level)
    }

    // MARK: - Public API

    func start() {
        guard !isRunning else { return }
        isRunning = true
        didFinishRound = false

        // Reset round state
        elapsed = 0
        remaining = roundDuration
        score = 0
        level = .l1
        tokenGenerator = 0

        configureGrid(for: level)
        restartRoundTimer()
        restartSpawnTimer()
    }

    private func endRound(finished: Bool) {
        isRunning = false

        // Cancel timers
        spawnCancellable?.cancel(); spawnCancellable = nil
        roundCancellable?.cancel(); roundCancellable = nil

        // Turn off all cards
        for i in cards.indices {
            cards[i].isLit = false
            cards[i].litToken = nil
        }

        // Update high score if needed
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: highScoreKey)
        }

        // Mark completion state
        didFinishRound = finished
    }

    func stop() {
        guard isRunning else { return }
        endRound(finished: false)
    }

    func tapCard(_ card: LightCard) {
        guard isRunning else { return }
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }

        if cards[index].isLit {
            // Correct tap
            cards[index].isLit = false
            cards[index].litToken = nil
            score += 1
        } else {
            // Wrong tap
            score = max(0, score - penaltyOnWrongTap)
        }
    }

    // MARK: - Private helpers

    private func configureGrid(for level: GameLevel) {
        let count = level.gridCount
        if cards.count == count {
            // Reuse grid; ensure all cards are unlit
            for i in cards.indices {
                cards[i].isLit = false
                cards[i].litToken = nil
            }
            return
        }
        cards = (0..<count).map { LightCard(id: $0) }
    }

    private func restartRoundTimer() {
        roundCancellable?.cancel()
        roundCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.isRunning else { return }

                self.elapsed += 1
                self.remaining = max(0, self.roundDuration - self.elapsed)
                self.updateLevelIfNeeded()

                if self.elapsed >= self.roundDuration {
                    self.endRound(finished: true)
                }
            }
    }

    private func updateLevelIfNeeded() {
        let newLevel = GameLevel.level(forElapsed: elapsed)
        if newLevel != level {
            level = newLevel
            configureGrid(for: newLevel)
            restartSpawnTimer()
        }
    }

    private func restartSpawnTimer() {
        spawnCancellable?.cancel()
        let interval = level.spawnInterval
        spawnCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.spawnLights()
            }
    }

    private func spawnLights() {
        guard isRunning else { return }

        let lights = level.lightsPerTick
        var availableIndices = cards.indices.filter { !cards[$0].isLit }

        // If not enough unlit cards are available, allow selecting from all
        if availableIndices.count < lights {
            availableIndices = Array(cards.indices)
        }

        var chosen: [Int] = []
        for _ in 0..<lights {
            guard !availableIndices.isEmpty else { break }
            let idx = availableIndices.randomElement()!
            chosen.append(idx)
            if let removeIdx = availableIndices.firstIndex(of: idx) {
                availableIndices.remove(at: removeIdx)
            }
        }

        for idx in chosen {
            lightCard(at: idx, window: level.timeWindow)
        }
    }

    private func nextLitToken() -> UInt64 {
        tokenGenerator &+= 1
        if tokenGenerator == 0 { tokenGenerator = 1 }
        return tokenGenerator
    }

    private func lightCard(at index: Int, window: TimeInterval) {
        guard cards.indices.contains(index) else { return }
        if cards[index].isLit { return } // already lit; skip

        let token = nextLitToken()
        cards[index].isLit = true
        cards[index].litToken = token

        // Auto-extinguish after window
        DispatchQueue.main.asyncAfter(deadline: .now() + window) { [weak self] in
            guard let self = self else { return }
            self.extinguishCardIfStillLit(at: index, token: token)
        }
    }

    private func extinguishCardIfStillLit(at index: Int, token: UInt64) {
        guard isRunning else { return }
        guard cards.indices.contains(index) else { return }

        if cards[index].isLit, cards[index].litToken == token {
            // Missed card
            cards[index].isLit = false
            cards[index].litToken = nil
            score = max(0, score - penaltyOnMiss)
        }
    }

    deinit {
        spawnCancellable?.cancel()
        roundCancellable?.cancel()
    }
}

// MARK: - Game View

struct LightItUpGameView: View {
    @StateObject private var vm = LightItUpViewModel()
    @Environment(\.scenePhase) private var scenePhase

    private var backgroundLayer: some View { ArcadeScreenBackground() }

    var body: some View {
        ZStack {
            backgroundLayer
            VStack(spacing: 18) {
                header
                ProgressView(value: Double(vm.elapsed), total: 60)
                    .tint(levelTint)
                    .background(Color.white.opacity(0.70), in: Capsule())
                grid
                controls
            }
            .padding(20)

            if vm.didFinishRound {
                overlay
            }
        }
        .onAppear { vm.start() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active, vm.isRunning {
                vm.stop()
            }
        }
        .navigationTitle("Light It Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                metric("Score", value: "\(vm.score)", symbol: "trophy.fill")
                metric("Level", value: vm.level.label, symbol: "square.grid.3x3.fill")
            }

            HStack(spacing: 10) {
                metric("Best", value: "\(vm.highScore)", symbol: "crown.fill")
                metric("Time", value: "\(vm.remaining)s", symbol: "clock.fill")
            }
        }
    }

    private func metric(_ title: String, value: String, symbol: String) -> some View {
        VStack(spacing: 5) {
            Label(title, systemImage: symbol)
                .font(.caption2.bold())
                .foregroundStyle(ArcadeTheme.mutedInk)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(ArcadeTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var grid: some View {
        LazyVGrid(columns: vm.columns, spacing: 12) {
            ForEach(vm.cards) { card in
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
                    .onTapGesture { vm.tapCard(card) }
                    .animation(.easeInOut(duration: 0.15), value: card.isLit)
                    .accessibilityLabel(card.isLit ? "Lit tile" : "Dim tile")
                    .accessibilityAddTraits(.isButton)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(action: { vm.start() }) {
                Label(vm.isRunning ? "Restart" : "Start", systemImage: vm.isRunning ? "arrow.counterclockwise" : "play.fill")
            }
            .buttonStyle(ArcadePrimaryButtonStyle(tint: levelTint))

            Button(action: { vm.stop() }) {
                Label("Stop", systemImage: "stop.fill")
            }
            .buttonStyle(ArcadeSecondaryButtonStyle())
            .disabled(!vm.isRunning)
        }
    }

    private var overlay: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                Text("Time's Up!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(ArcadeTheme.ink)
                Text("Final Score: \(vm.score)")
                    .font(.title2)
                    .foregroundStyle(ArcadeTheme.ink)
                Text("High Score: \(vm.highScore)")
                    .font(.title3)
                    .foregroundStyle(ArcadeTheme.mutedInk)

                HStack(spacing: 12) {
                    Button {
                        ArcadeLeaderboardStore.shared.submit(score: vm.score, for: .lightItUp)
                        vm.start()
                    } label: {
                        Label("Save", systemImage: "trophy.fill")
                    }
                    .buttonStyle(ArcadeSecondaryButtonStyle())

                    Button(action: { vm.start() }) {
                        Label("Play Again", systemImage: "play.fill")
                    }
                    .buttonStyle(ArcadePrimaryButtonStyle(tint: levelTint))
                }
            }
            .padding(22)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 22, x: 0, y: 14)
            .padding(24)
        }
    }

    private var levelTint: Color {
        switch vm.level {
        case .l1: return ArcadeTheme.sky
        case .l2: return ArcadeTheme.mint
        case .l3: return ArcadeTheme.gold
        case .l4: return ArcadeTheme.berry
        }
    }
}

#Preview("Light It Up Game") {
    LightItUpGameView()
}

