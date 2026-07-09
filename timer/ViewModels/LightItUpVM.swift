import Combine
import SwiftUI

enum GameLevel: Int, CaseIterable, Codable, Equatable, Hashable, Identifiable {
    case l1, l2, l3, l4

    var id: Int { rawValue }

    var gridCount: Int {
        switch self {
        case .l1: return 3
        case .l2: return 4
        case .l3: return 6
        case .l4: return 9
        }
    }

    var columnsCount: Int {
        switch self {
        case .l1: return 3
        case .l2: return 2
        case .l3: return 3
        case .l4: return 3
        }
    }

    var timeWindow: TimeInterval {
        switch self {
        case .l1: return 1.5
        case .l2: return 1.2
        case .l3: return 1.0
        case .l4: return 0.8
        }
    }

    var lightsPerTick: Int {
        switch self {
        case .l1, .l2, .l3: return 1
        case .l4: return 2
        }
    }

    var label: String {
        switch self {
        case .l1: return "L1"
        case .l2: return "L2"
        case .l3: return "L3"
        case .l4: return "L4"
        }
    }

    var displayName: String {
        switch self {
        case .l1: return "Level 1"
        case .l2: return "Level 2"
        case .l3: return "Level 3"
        case .l4: return "Level 4"
        }
    }

    var spawnInterval: TimeInterval { timeWindow }

    static func level(forElapsed seconds: Int, startingLevel: GameLevel, roundDuration: Int) -> GameLevel {
        let levels = Array(allCases.dropFirst(startingLevel.rawValue))
        guard !levels.isEmpty else { return startingLevel }
        let progress = Double(seconds) / Double(max(roundDuration, 1))
        let offset = min(levels.count - 1, Int(progress * Double(levels.count)))
        return levels[offset]
    }
}

struct LightCard: Identifiable, Equatable {
    let id: Int
    var isLit = false
    var litToken: UInt64?
}

@MainActor
final class LightItUpVM: ObservableObject {
    @Published private(set) var cards: [LightCard] = []
    @Published private(set) var level: GameLevel = .l1
    @Published private(set) var elapsed = 0
    @Published private(set) var remaining = 60
    @Published private(set) var score = 0
    @Published private(set) var isRunning = false
    @Published private(set) var didFinishRound = false
    @Published private(set) var options: LightItUpOptions = LightItUpPreset.classic.options

    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: level.columnsCount)
    }

    private var spawnCancellable: AnyCancellable?
    private var roundCancellable: AnyCancellable?
    private var tokenGenerator: UInt64 = 0
    private var hasRecordedCurrentRound = false

    var roundDuration: Int { options.roundDuration }

    init() {
        configureGrid(for: level)
    }

    func applyOptions(_ options: LightItUpOptions) {
        guard !isRunning else { return }
        self.options = options
        level = options.startingLevel
        elapsed = 0
        remaining = options.roundDuration
        score = 0
        didFinishRound = false
        configureGrid(for: level)
    }

    func start(options: LightItUpOptions? = nil) {
        if let options {
            self.options = options
        }
        isRunning = true
        didFinishRound = false
        hasRecordedCurrentRound = false
        elapsed = 0
        remaining = self.options.roundDuration
        score = 0
        level = self.options.startingLevel
        tokenGenerator = 0

        configureGrid(for: level)
        restartRoundTimer()
        restartSpawnTimer()
    }

    func stop() {
        guard isRunning else { return }
        endRound(finished: false)
    }

    func tapCard(_ card: LightCard) {
        guard isRunning else { return }
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }

        if cards[index].isLit {
            cards[index].isLit = false
            cards[index].litToken = nil
            score += 1
            AudioService.shared.play(.success)
            AudioService.shared.impact(.light)
        } else {
            score = max(0, score - options.wrongTapPenalty)
            AudioService.shared.play(.mistake)
            AudioService.shared.impact(.rigid)
        }
    }

    private func endRound(finished: Bool) {
        isRunning = false
        spawnCancellable?.cancel()
        spawnCancellable = nil
        roundCancellable?.cancel()
        roundCancellable = nil

        for index in cards.indices {
            cards[index].isLit = false
            cards[index].litToken = nil
        }

        if finished {
            recordCompletionIfNeeded()
            AudioService.shared.play(.finish)
            AudioService.shared.notify(.success)
        }
        didFinishRound = finished
    }

    private func recordCompletionIfNeeded() {
        guard !hasRecordedCurrentRound else { return }
        hasRecordedCurrentRound = true
        GameSessionStore.shared.addSession(
            mode: .lightItUp,
            score: score,
            coordinate: LocationService.shared.currentCoordinate,
            variantID: options.variantID,
            variantLabel: options.variantLabel
        )
    }

    private func configureGrid(for level: GameLevel) {
        let count = level.gridCount
        if cards.count == count {
            for index in cards.indices {
                cards[index].isLit = false
                cards[index].litToken = nil
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
                guard let self, self.isRunning else { return }
                self.elapsed += 1
                self.remaining = max(0, self.options.roundDuration - self.elapsed)
                self.updateLevelIfNeeded()

                if self.elapsed >= self.options.roundDuration {
                    self.endRound(finished: true)
                }
            }
    }

    private func updateLevelIfNeeded() {
        let newLevel = GameLevel.level(
            forElapsed: elapsed,
            startingLevel: options.startingLevel,
            roundDuration: options.roundDuration
        )
        if newLevel != level {
            level = newLevel
            configureGrid(for: newLevel)
            restartSpawnTimer()
            AudioService.shared.play(.levelUp)
        }
    }

    private func restartSpawnTimer() {
        spawnCancellable?.cancel()
        spawnCancellable = Timer.publish(every: level.spawnInterval * options.spawnSpeedMultiplier, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.spawnLights()
            }
    }

    private func spawnLights() {
        guard isRunning else { return }
        let lights = level.lightsPerTick + options.extraLightsPerTick
        var availableIndices = cards.indices.filter { !cards[$0].isLit }

        if availableIndices.count < lights {
            availableIndices = Array(cards.indices)
        }

        var chosen: [Int] = []
        for _ in 0..<lights {
            guard let index = availableIndices.randomElement() else { break }
            chosen.append(index)
            if let removeIndex = availableIndices.firstIndex(of: index) {
                availableIndices.remove(at: removeIndex)
            }
        }

        for index in chosen {
            lightCard(at: index, window: level.timeWindow)
        }
    }

    private func lightCard(at index: Int, window: TimeInterval) {
        guard cards.indices.contains(index), !cards[index].isLit else { return }

        let token = nextLitToken()
        cards[index].isLit = true
        cards[index].litToken = token

        DispatchQueue.main.asyncAfter(deadline: .now() + window) { [weak self] in
            self?.extinguishCardIfStillLit(at: index, token: token)
        }
    }

    private func nextLitToken() -> UInt64 {
        tokenGenerator &+= 1
        if tokenGenerator == 0 { tokenGenerator = 1 }
        return tokenGenerator
    }

    private func extinguishCardIfStillLit(at index: Int, token: UInt64) {
        guard isRunning, cards.indices.contains(index) else { return }
        if cards[index].isLit, cards[index].litToken == token {
            cards[index].isLit = false
            cards[index].litToken = nil
            score = max(0, score - options.missedLightPenalty)
            AudioService.shared.play(.mistake)
        }
    }

    deinit {
        spawnCancellable?.cancel()
        roundCancellable?.cancel()
    }
}
