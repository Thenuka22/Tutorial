import Combine
import SwiftUI

@MainActor
final class TapFrenzyVM: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var timeRemaining: Double = 10
    @Published private(set) var score = 0
    @Published private(set) var taps = 0
    @Published private(set) var comboCount = 0
    @Published private(set) var showResults = false
    @Published private(set) var targetOffset: CGSize = .zero
    @Published private(set) var targetMood: TapTargetMood = .normal
    @Published private(set) var bonusBurstActive = false
    @Published private(set) var options: TapFrenzyOptions = TapFrenzyPreset.classic.options

    var roundDuration: Double { options.roundDuration }

    private var lastTapTime: Date?
    private var lastTick = Date()
    private var lastTargetMove = Date()
    private var lastMoodChange = Date()
    private var bonusBurstUsed = false
    private var hasRecordedCurrentRound = false

    var multiplier: Int {
        min(5, max(1, 1 + comboCount / 4))
    }

    var targetSize: CGFloat {
        let progress = max(0, min(1, timeRemaining / options.roundDuration))
        return 78 + (70 * progress)
    }

    func applyOptions(_ options: TapFrenzyOptions) {
        guard !isRunning else { return }
        self.options = options
        reset(clearResults: false)
    }

    func start(options: TapFrenzyOptions? = nil) {
        if let options {
            self.options = options
        }
        reset(clearResults: true)
        isRunning = true
        lastTick = Date()
        lastTargetMove = Date()
        lastMoodChange = Date()
        targetMood = .normal
    }

    func reset(clearResults: Bool) {
        isRunning = false
        timeRemaining = options.roundDuration
        score = 0
        taps = 0
        comboCount = 0
        lastTapTime = nil
        targetOffset = .zero
        targetMood = .normal
        bonusBurstActive = false
        bonusBurstUsed = false
        hasRecordedCurrentRound = false
        if clearResults {
            showResults = false
        }
    }

    func tick(_ now: Date) {
        guard isRunning else { return }

        let delta = now.timeIntervalSince(lastTick)
        lastTick = now
        timeRemaining -= delta

        if timeRemaining <= 0 {
            timeRemaining = 0
            finishRound()
            return
        }

        if now.timeIntervalSince(lastTargetMove) >= options.targetMoveInterval {
            lastTargetMove = now
            moveTarget()
        }

        if now.timeIntervalSince(lastMoodChange) >= options.moodChangeInterval {
            lastMoodChange = now
            targetMood = TapTargetMood.random(options: options)
        }

        if let lastTapTime, now.timeIntervalSince(lastTapTime) > 0.75 {
            comboCount = 0
        }
    }

    func handleTap() {
        guard isRunning else { return }
        let now = Date()

        if targetMood == .trap {
            score = max(0, score - 2)
            comboCount = 0
            lastTapTime = nil
            AudioService.shared.play(.mistake)
            AudioService.shared.impact(.rigid)
            return
        }

        taps += 1
        if let lastTapTime, now.timeIntervalSince(lastTapTime) <= 0.75 {
            comboCount += 1
        } else {
            comboCount = 1
        }
        self.lastTapTime = now

        let moodBonus = targetMood == .bonus ? 2 : 0
        let burstBonus = bonusBurstActive ? 2 : 1
        score += (1 + moodBonus) * multiplier * burstBonus

        if options.bonusBurstEnabled, score >= 20, !bonusBurstUsed {
            triggerBonusBurst()
        }

        AudioService.shared.play(targetMood == .bonus ? .bonus : .tap)
        AudioService.shared.impact(.light)
        targetMood = .normal
        moveTarget()
    }

    func moveTarget(in size: CGSize? = nil) {
        let width = max(0, (size?.width ?? 300) - targetSize - 48)
        let height = max(0, (size?.height ?? 330) - targetSize - 72)
        withAnimation(.snappy(duration: 0.24)) {
            targetOffset = CGSize(
                width: CGFloat.random(in: (-width / 2)...(width / 2)),
                height: CGFloat.random(in: (-height / 2)...(height / 2))
            )
        }
    }

    private func finishRound() {
        isRunning = false
        recordCompletionIfNeeded()
        AudioService.shared.play(.finish)
        AudioService.shared.notify(.success)
        showResults = true
    }

    private func recordCompletionIfNeeded() {
        guard !hasRecordedCurrentRound else { return }
        hasRecordedCurrentRound = true
        GameSessionStore.shared.addSession(
            mode: .tapFrenzy,
            score: score,
            coordinate: LocationService.shared.currentCoordinate,
            variantID: options.variantID,
            variantLabel: options.variantLabel
        )
    }

    private func triggerBonusBurst() {
        bonusBurstUsed = true
        bonusBurstActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.bonusBurstActive = false
        }
    }
}

enum TapTargetMood: CaseIterable, Equatable {
    case normal
    case bonus
    case trap

    var color: Color {
        switch self {
        case .normal: return PlayHubTheme.orange
        case .bonus: return PlayHubTheme.mint
        case .trap: return Color.gray
        }
    }

    var symbolName: String {
        switch self {
        case .normal: return "hand.tap.fill"
        case .bonus: return "plus.circle.fill"
        case .trap: return "minus.circle.fill"
        }
    }

    var buttonTitle: String {
        switch self {
        case .normal: return "Tap"
        case .bonus: return "+Bonus"
        case .trap: return "Trap"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .normal: return "Tap target"
        case .bonus: return "Bonus tap target"
        case .trap: return "Trap target, minus points"
        }
    }

    static func random(options: TapFrenzyOptions) -> TapTargetMood {
        let roll = Int.random(in: 0..<100)
        if roll < options.bonusChance { return .bonus }
        if options.trapsEnabled, roll < options.bonusChance + options.trapChance { return .trap }
        return .normal
    }
}
