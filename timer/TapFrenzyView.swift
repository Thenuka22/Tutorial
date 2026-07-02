import SwiftUI
import Combine
import UIKit

struct TapFrenzyView: View {
    @State private var isRunning = false
    @State private var timeRemaining: Double = 10
    @State private var score: Int = 0
    @State private var taps: Int = 0
    @State private var comboCount: Int = 0
    @State private var lastTapTime: Date? = nil
    @State private var showResults = false
    @State private var targetOffset: CGSize = .zero
    @State private var targetMood: TargetMood = .normal
    @State private var bonusBurstActive = false
    @State private var bonusBurstUsed = false
    @State private var lastTick: Date = Date()
    @State private var lastTargetMove: Date = Date()
    @State private var lastMoodChange: Date = Date()
    @AppStorage("tapFrenzyHighScore") private var highScore = 0

    private let roundDuration: Double = 10
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ArcadeScreenBackground()

            VStack(spacing: 18) {
                scoreHeader
                playField
                controls
            }
            .padding(20)

            if showResults {
                resultOverlay
            }
        }
        .navigationTitle("Tap Frenzy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { reset(clearResults: true) }
        .onReceive(timer) { now in
            guard isRunning else { return }
            let delta = now.timeIntervalSince(lastTick)
            lastTick = now
            timeRemaining -= delta
            if timeRemaining <= 0 {
                timeRemaining = 0
                stop()
            }

            if now.timeIntervalSince(lastTargetMove) >= 1.0 {
                lastTargetMove = now
                moveTarget()
            }

            if now.timeIntervalSince(lastMoodChange) >= 1.35 {
                lastMoodChange = now
                targetMood = TargetMood.random()
            }

            if let last = lastTapTime, now.timeIntervalSince(last) > 0.75 {
                comboCount = 0
            }
        }
    }

    private var scoreHeader: some View {
        VStack(spacing: 12) {
            ProgressView(value: roundDuration - timeRemaining, total: roundDuration)
                .tint(ArcadeTheme.orange)
                .background(Color.white.opacity(0.7), in: Capsule())

            HStack(spacing: 10) {
                metric("Time", value: String(format: "%.1fs", timeRemaining), symbol: "clock.fill")
                metric("Score", value: "\(score)", symbol: "trophy.fill")
                metric("Best", value: "\(highScore)", symbol: "crown.fill")
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

    private var playField: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )

                if !isRunning && !showResults {
                    VStack(spacing: 10) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 54, weight: .black))
                            .foregroundStyle(ArcadeTheme.orange)
                        Text("Tap as fast as you can.")
                            .font(.title3.bold())
                            .foregroundStyle(ArcadeTheme.ink)
                        Text("Combos, bonus bursts, moving target, and color traps are active.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(ArcadeTheme.mutedInk)
                            .padding(.horizontal, 24)
                    }
                }

                if isRunning {
                    Button {
                        handleTap()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: targetMood.symbolName)
                                .font(.system(size: 34, weight: .black))
                            Text(targetMood.buttonTitle)
                                .font(.headline.bold())
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(.white)
                        .frame(width: targetSize, height: targetSize)
                        .background(targetMood.color, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.65), lineWidth: 4)
                        )
                        .shadow(color: targetMood.color.opacity(0.36), radius: 18, x: 0, y: 10)
                        .scaleEffect(bonusBurstActive ? 1.08 : 1.0)
                        .animation(.snappy(duration: 0.22), value: targetSize)
                        .animation(.snappy(duration: 0.22), value: targetOffset)
                        .animation(.snappy(duration: 0.18), value: targetMood)
                    }
                    .buttonStyle(.plain)
                    .offset(targetOffset)
                    .accessibilityLabel(targetMood.accessibilityLabel)
                }

                VStack {
                    Spacer()
                    HStack {
                        Label("Combo x\(multiplier)", systemImage: "flame.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(ArcadeTheme.berry)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.92), in: Capsule())
                        Spacer()
                        if bonusBurstActive {
                            Label("Double Points", systemImage: "sparkles")
                                .font(.subheadline.bold())
                                .foregroundStyle(ArcadeTheme.mint)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.92), in: Capsule())
                        }
                    }
                    .padding(14)
                }
            }
            .onChange(of: isRunning) { _, running in
                if running {
                    targetOffset = .zero
                    moveTarget(in: proxy.size)
                }
            }
        }
        .frame(minHeight: 330)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                if isRunning {
                    reset(clearResults: false)
                } else {
                    start()
                }
            } label: {
                Label(isRunning ? "Reset" : "Start", systemImage: isRunning ? "arrow.counterclockwise" : "play.fill")
            }
            .buttonStyle(ArcadePrimaryButtonStyle(tint: isRunning ? ArcadeTheme.berry : ArcadeTheme.orange))

            Button {
                ArcadeLeaderboardStore.shared.submit(score: score, for: .tapFrenzy)
            } label: {
                Label("Save", systemImage: "square.and.arrow.down.fill")
            }
            .buttonStyle(ArcadeSecondaryButtonStyle())
            .disabled(score == 0 || isRunning)
        }
    }

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 58, weight: .black))
                    .foregroundStyle(ArcadeTheme.gold)
                    .offset(y: -10)

                Text("Time's Up!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(ArcadeTheme.ink)

                VStack(spacing: 6) {
                    Text("\(score)")
                        .font(.system(size: 68, weight: .black, design: .rounded))
                        .foregroundStyle(ArcadeTheme.orange)
                    Text("Final Score")
                        .font(.headline)
                        .foregroundStyle(ArcadeTheme.mutedInk)
                }

                Text("Taps \(taps)  |  Best \(highScore)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(ArcadeTheme.mutedInk)

                HStack(spacing: 12) {
                    Button {
                        ArcadeLeaderboardStore.shared.submit(score: score, for: .tapFrenzy)
                        showResults = false
                    } label: {
                        Label("Save", systemImage: "trophy.fill")
                    }
                    .buttonStyle(ArcadeSecondaryButtonStyle())

                    Button {
                        start()
                    } label: {
                        Label("Play Again", systemImage: "play.fill")
                    }
                    .buttonStyle(ArcadePrimaryButtonStyle())
                }
            }
            .padding(22)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 22, x: 0, y: 14)
            .padding(24)
        }
    }

    private var multiplier: Int {
        min(5, max(1, 1 + comboCount / 4))
    }

    private var targetSize: CGFloat {
        let progress = max(0, min(1, timeRemaining / roundDuration))
        return 78 + (70 * progress)
    }

    private func start() {
        reset(clearResults: true)
        isRunning = true
        lastTick = Date()
        lastTargetMove = Date()
        lastMoodChange = Date()
        targetMood = .normal
    }

    private func stop() {
        isRunning = false
        highScore = max(highScore, score)
        showResults = true
    }

    private func reset(clearResults: Bool) {
        isRunning = false
        timeRemaining = roundDuration
        score = 0
        taps = 0
        comboCount = 0
        lastTapTime = nil
        targetOffset = .zero
        targetMood = .normal
        bonusBurstActive = false
        bonusBurstUsed = false
        if clearResults {
            showResults = false
        }
    }

    private func handleTap() {
        guard isRunning else { return }
        let now = Date()

        if targetMood == .trap {
            score = max(0, score - 2)
            comboCount = 0
            lastTapTime = nil
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }

        taps += 1
        if let last = lastTapTime, now.timeIntervalSince(last) <= 0.75 {
            comboCount += 1
        } else {
            comboCount = 1
        }
        lastTapTime = now

        let moodBonus = targetMood == .bonus ? 2 : 0
        let burstBonus = bonusBurstActive ? 2 : 1
        score += (1 + moodBonus) * multiplier * burstBonus

        if score >= 20, !bonusBurstUsed {
            triggerBonusBurst()
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        targetMood = .normal
        moveTarget()
    }

    private func moveTarget(in size: CGSize? = nil) {
        let width = max(0, (size?.width ?? 300) - targetSize - 48)
        let height = max(0, (size?.height ?? 330) - targetSize - 72)
        withAnimation(.snappy(duration: 0.24)) {
            targetOffset = CGSize(
                width: CGFloat.random(in: (-width / 2)...(width / 2)),
                height: CGFloat.random(in: (-height / 2)...(height / 2))
            )
        }
    }

    private func triggerBonusBurst() {
        bonusBurstUsed = true
        bonusBurstActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            bonusBurstActive = false
        }
    }
}

private enum TargetMood: CaseIterable, Equatable {
    case normal
    case bonus
    case trap

    var color: Color {
        switch self {
        case .normal: return ArcadeTheme.orange
        case .bonus: return ArcadeTheme.mint
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

    static func random() -> TargetMood {
        let roll = Int.random(in: 0..<100)
        if roll < 18 { return .bonus }
        if roll < 36 { return .trap }
        return .normal
    }
}

#Preview {
    NavigationStack { TapFrenzyView() }
}
