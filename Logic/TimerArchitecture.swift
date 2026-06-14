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

    private var backgroundLayer: some View {
        LinearGradient(colors: [Color(red: 0.06, green: 0.07, blue: 0.12), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()
            VStack(spacing: 20) {
                header
                ProgressView(value: Double(vm.elapsed), total: 60)
                    .tint(.white)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08), in: Capsule())
                grid
                controls
            }
            .padding()

            if vm.didFinishRound {
                overlay
            }
        }
        .onAppear { vm.start() }
        .onChange(of: scenePhase) { newPhase in
            if newPhase != .active, vm.isRunning {
                vm.stop()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            Text("Score: \(vm.score)")
            Spacer()
            Text("Level \(vm.level.label)")
            Spacer()
            Text("High: \(vm.highScore)")
            Spacer()
            Text("Time: \(vm.remaining)s")
        }
        .font(.headline)
        .monospacedDigit()
        .foregroundStyle(.white.opacity(0.9))
    }

    private var grid: some View {
        LazyVGrid(columns: vm.columns, spacing: 12) {
            ForEach(vm.cards) { card in
                RoundedRectangle(cornerRadius: 14)
                    .fill(card.isLit ? Color.white : Color.white.opacity(0.08))
                    .frame(height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.15))
                    )
                    .shadow(color: Color.white.opacity(card.isLit ? 0.7 : 0.0), radius: 18, x: 0, y: 0)
                    .shadow(color: Color.white.opacity(card.isLit ? 0.35 : 0.0), radius: 36, x: 0, y: 0)
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
            Button(action: { vm.start() }) { Text(vm.isRunning ? "Restart" : "Start") }
                .buttonStyle(.borderedProminent)
            Button(action: { vm.stop() }) { Text("Stop") }
                .buttonStyle(.bordered)
        }
        .tint(.cyan)
    }

    private var overlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                Text("Time's Up!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Final Score: \(vm.score)")
                    .font(.title2)
                    .foregroundStyle(.white)
                Text("High Score: \(vm.highScore)")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                Button(action: { vm.start() }) {
                    Text("Play Again")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
            .padding()
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.15))
            )
            .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 10)
            .padding(24)
        }
    }
}

#Preview("Light It Up – Game") {
    LightItUpGameView()
}

