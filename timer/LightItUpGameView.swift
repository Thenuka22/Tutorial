import SwiftUI
import Combine
import UIKit

struct LightItUpEnhancedView: View {
    @State private var isRunning = false
    @State private var timeRemaining: Double = 60
    @State private var score: Int = 0
    @State private var level: Int = 1

    private let gridSize: Int = 4

    @State private var litIndices: Set<Int> = []
    @State private var bombIndices: Set<Int> = []
    @State private var freezeIndices: Set<Int> = []
    @State private var tapDisabledUntil: Date? = nil

    @State private var spawnInterval: TimeInterval = 1.2
    @State private var litLifetime: TimeInterval = 1.4

    @State private var enableBombs = true
    @State private var enableFreezes = true

    @State private var lastTick: Date = Date()
    @State private var lastSpawn: Date = Date()
    @State private var showResults = false

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: 1 - timeRemaining / 60)
                    .tint(.green)
                HStack {
                    Label("Time", systemImage: "clock"); Spacer(); Text("\(timeRemaining, specifier: "%.1f")s")
                }
                .font(.caption)
                HStack {
                    Label("Score", systemImage: "trophy.fill"); Spacer(); Text("\(score)").monospacedDigit()
                }
                .font(.headline)
                Text("Level \(level)").font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: gridSize)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<(gridSize*gridSize), id: \.self) { index in
                    Button {
                        tileTapped(index)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(tileColor(for: index))
                                .frame(height: 72)
                            tileOverlay(for: index)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!isRunning || isFrozen)
                    .accessibilityLabel(accessibilityLabel(for: index))
                }
            }
            .padding(.horizontal)

            HStack {
                Toggle("Bombs", isOn: $enableBombs)
                Toggle("Freezes", isOn: $enableFreezes)
            }
            .disabled(isRunning)
            .padding(.horizontal)

            Button(action: startOrReset) {
                Text(isRunning ? "Reset" : "Start")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .navigationTitle("Light It Up")
        .onAppear { reset() }
        .onReceive(Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect()) { now in
            guard isRunning else { return }
            let delta = now.timeIntervalSince(lastTick)
            lastTick = now
            timeRemaining -= delta
            if timeRemaining <= 0 { timeRemaining = 0; stop() }

            if now.timeIntervalSince(lastSpawn) >= spawnInterval {
                lastSpawn = now
                spawnTiles()
            }

            updateDifficulty()
        }
        .sheet(isPresented: $showResults) { resultsSheet }
    }

    private var isFrozen: Bool {
        if let until = tapDisabledUntil { return Date() < until }
        return false
    }

    private func tileColor(for index: Int) -> Color {
        if bombIndices.contains(index) { return .red }
        if freezeIndices.contains(index) { return .purple }
        if litIndices.contains(index) { return .yellow }
        return .gray.opacity(0.3)
    }

    @ViewBuilder private func tileOverlay(for index: Int) -> some View {
        if bombIndices.contains(index) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.white)
        } else if freezeIndices.contains(index) {
            Image(systemName: "snowflake").foregroundStyle(.white)
        } else if litIndices.contains(index) {
            Image(systemName: "bolt.fill").foregroundStyle(.white)
        } else {
            EmptyView()
        }
    }

    private func accessibilityLabel(for index: Int) -> String {
        if bombIndices.contains(index) { return "Bomb tile, minus points" }
        if freezeIndices.contains(index) { return "Freeze tile" }
        if litIndices.contains(index) { return "Lit tile" }
        return "Tile"
    }

    private func startOrReset() { isRunning ? reset() : start() }

    private func start() {
        reset()
        isRunning = true
        lastTick = Date()
        lastSpawn = Date()
    }

    private func stop() {
        isRunning = false
        showResults = true
    }

    private func reset() {
        isRunning = false
        timeRemaining = 60
        score = 0
        level = 1
        litIndices.removeAll()
        bombIndices.removeAll()
        freezeIndices.removeAll()
        tapDisabledUntil = nil
        spawnInterval = 1.2
        litLifetime = 1.4
    }

    private func updateDifficulty() {
        // Increase difficulty at 45, 30, 15 seconds remaining
        let thresholds: [Double] = [45, 30, 15]
        let elapsedLevels = thresholds.filter { timeRemaining <= $0 }.count
        let newLevel = 1 + elapsedLevels
        if newLevel != level {
            level = newLevel
            // Decrease timings by ~18%
            spawnInterval = max(0.5, spawnInterval * 0.82)
            litLifetime = max(0.6, litLifetime * 0.82)
        }
    }

    private func spawnTiles() {
        // choose 1-3 new tiles to light
        let total = gridSize * gridSize
        let available = Array(0..<total).filter { !litIndices.contains($0) && !bombIndices.contains($0) && !freezeIndices.contains($0) }
        guard !available.isEmpty else { return }
        let count = min(Int.random(in: 1...3), available.count)
        let chosen = available.shuffled().prefix(count)
        for idx in chosen {
            litIndices.insert(idx)
            let appearTime = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + litLifetime) {
                // auto-dim if still lit
                if litIndices.contains(idx) {
                    litIndices.remove(idx)
                }
            }
            // Spawn bombs and freezes occasionally
            if enableBombs && Int.random(in: 0..<100) < 15 { // 15%
                bombIndices.insert(idx)
                // bomb clears after a bit
                DispatchQueue.main.asyncAfter(deadline: .now() + max(0.8, litLifetime)) {
                    bombIndices.remove(idx)
                }
            } else if enableFreezes && Int.random(in: 0..<100) < 8 { // 8%
                freezeIndices.insert(idx)
                DispatchQueue.main.asyncAfter(deadline: .now() + max(0.8, litLifetime)) {
                    freezeIndices.remove(idx)
                }
            }
            _ = appearTime // keep variable used for potential timing bonus
        }
    }

    private func tileTapped(_ index: Int) {
        guard isRunning, !isFrozen else { return }
        if bombIndices.contains(index) {
            score = max(0, score - 3)
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            bombIndices.remove(index)
            return
        }
        if freezeIndices.contains(index) {
            score = max(0, score - 1)
            tapDisabledUntil = Date().addingTimeInterval(0.8)
            freezeIndices.remove(index)
            return
        }
        if litIndices.contains(index) {
            // Give +1, and +1 bonus if just spawned recently (<0.5s). We don't track per-tile time; emulate via quick reaction window: grant bonus if many lit tiles exist -> more chaos, limit bonus.
            score += 1
            // small extra bonus if multiple lit at once to reward quickness
            if litIndices.count >= 2 { score += 1 }
            litIndices.remove(index)
        }
    }

    private var resultsSheet: some View {
        VStack(spacing: 16) {
            Text("Great round!").font(.largeTitle)
            Text("Score: \(score)").font(.title).monospacedDigit()
            HStack(spacing: 12) {
                Button("Play Again") { start() }
                Button("Submit to Leaderboard") {
                    ArcadeLeaderboardStore.shared.submit(score: score, for: ArcadeGameKind.lightItUp)
                    showResults = false
                }
            }
            .buttonStyle(.borderedProminent)
            Button("Close", role: .cancel) { showResults = false }
        }
        .padding()
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack { LightItUpEnhancedView() }
}

