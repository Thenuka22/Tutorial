import SwiftUI
import Combine
import UIKit

struct TapFrenzyEnhancedView: View {
    @State private var isRunning = false
    @State private var timeRemaining: Double = 10
    @State private var score: Int = 0
    @State private var taps: Int = 0
    @State private var combo: Int = 0
    @State private var lastTapTime: Date? = nil
    @State private var showResults = false

    // Obstacles
    @State private var spawnObstacles = true
    @State private var obstaclePenalty = 2
    @State private var activeButtons: [Int] = Array(0..<12)
    @State private var decoyIndices: Set<Int> = []
    @State private var decoySpawnInterval: TimeInterval = 1.4

    // Timers
    @State private var lastTick: Date = Date()
    @State private var lastDecoySpawn: Date = Date()

    var body: some View {
        VStack(spacing: 16) {
            VStack {
                ProgressView(value: 1 - timeRemaining / 10)
                    .tint(.green)
                HStack {
                    Label("Time", systemImage: "clock"); Spacer(); Text("\(timeRemaining, specifier: "%.1f")s")
                }
                .font(.caption)
                HStack {
                    Label("Score", systemImage: "trophy.fill"); Spacer(); Text("\(score)").monospacedDigit()
                }
                .font(.headline)
            }
            .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                ForEach(activeButtons, id: \.self) { index in
                    Button {
                        handleTap(on: index)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(decoyIndices.contains(index) ? Color.red.opacity(0.8) : Color.blue)
                                .frame(height: 80)
                            VStack(spacing: 6) {
                                Image(systemName: decoyIndices.contains(index) ? "xmark.octagon.fill" : "hand.tap")
                                    .foregroundStyle(.white)
                                if decoyIndices.contains(index) {
                                    Text("-\(obstaclePenalty)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!isRunning)
                    .accessibilityLabel(decoyIndices.contains(index) ? "Decoy, minus \(obstaclePenalty) points" : "Tap")
                }
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                HStack {
                    Toggle("Obstacles", isOn: $spawnObstacles)
                    Stepper("Penalty: \(obstaclePenalty)", value: $obstaclePenalty, in: 1...5)
                }
                .disabled(isRunning == true)
                .font(.caption)

                Button(action: startOrReset) {
                    Text(isRunning ? "Reset" : "Start")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Tap Frenzy")
        .onAppear { reset() }
        .onReceive(Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect()) { now in
            guard isRunning else { return }
            let delta = now.timeIntervalSince(lastTick)
            lastTick = now
            timeRemaining -= delta
            if timeRemaining <= 0 {
                timeRemaining = 0
                stop()
            }
            // Spawn/clear decoys
            if spawnObstacles {
                if now.timeIntervalSince(lastDecoySpawn) >= decoySpawnInterval {
                    lastDecoySpawn = now
                    spawnDecoys()
                    // Clear decoys shortly after
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { decoyIndices.removeAll() }
                }
            } else {
                decoyIndices.removeAll()
            }
            // Combo decay if idle
            if let last = lastTapTime, now.timeIntervalSince(last) > 0.75 {
                combo = 0
            }
        }
        .sheet(isPresented: $showResults) {
            resultsSheet
        }
    }

    private var resultsSheet: some View {
        VStack(spacing: 16) {
            Text("Time's up!").font(.largeTitle)
            Text("Score: \(score)").font(.title).monospacedDigit()
            Text("Taps: \(taps)").foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("Play Again") { start() }
                Button("Submit to Leaderboard") {
                    ArcadeLeaderboardStore.shared.submit(score: score, for: ArcadeGameKind.tapFrenzy)
                    showResults = false
                }
            }
            .buttonStyle(.borderedProminent)
            Button("Close", role: .cancel) { showResults = false }
        }
        .padding()
        .presentationDetents([.medium])
    }

    private func startOrReset() { isRunning ? reset() : start() }

    private func start() {
        reset()
        isRunning = true
        lastTick = Date()
        lastDecoySpawn = Date()
    }

    private func stop() {
        isRunning = false
        showResults = true
    }

    private func reset() {
        isRunning = false
        timeRemaining = 10
        score = 0
        taps = 0
        combo = 0
        lastTapTime = nil
        decoyIndices.removeAll()
    }

    private func handleTap(on index: Int) {
        guard isRunning else { return }
        let now = Date()
        if decoyIndices.contains(index) {
            // Penalty for decoy
            score = max(0, score - obstaclePenalty)
            combo = 0
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }
        // Real tap
        taps += 1
        if let last = lastTapTime, now.timeIntervalSince(last) <= 0.75 {
            combo += 1
        } else {
            combo = 0
        }
        lastTapTime = now
        let bonus = combo / 5 // +1 every 5 consecutive quick taps
        score += 1 + bonus
    }

    private func spawnDecoys() {
        decoyIndices.removeAll()
        // choose up to 2 decoys
        let count = Int.random(in: 1...2)
        let choices = activeButtons.shuffled().prefix(count)
        decoyIndices = Set(choices)
    }
}

#Preview {
    NavigationStack { TapFrenzyEnhancedView() }
}
