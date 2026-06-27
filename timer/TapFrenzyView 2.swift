import SwiftUI
import Combine
import UIKit

struct TapFrenzyLegacyView: View {
    @State private var isRunning = false
    @State private var timeRemaining: Double = 10
    @State private var score: Int = 0
    @State private var taps: Int = 0
    @State private var combo: Int = 0
    @State private var lastTapTime: Date? = nil
    @State private var showResults = false
    @State private var spawnObstacles = true
    @State private var obstaclePenalty = 2
    @State private var gridItems = [GridItem(.adaptive(minimum: 80), spacing: 12)]
    @State private var activeButtons: [Int] = Array(0..<12)
    @State private var decoyIndices: Set<Int> = []
    @State private var decoySpawnInterval: TimeInterval = 1.5
    
    // Timer publisher for 1/60 second ticks
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Tap Frenzy")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                
                ProgressView(value: timeRemaining, total: 10)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 8)
                    .accessibilityLabel("Time remaining")
                    .accessibilityValue("\(Int(timeRemaining)) seconds")
                
                Text("Time: \(String(format: "%.2f", timeRemaining))")
                    .font(.headline.monospacedDigit())
                    .accessibilityHidden(true)
                
                HStack(spacing: 20) {
                    Text("Score: \(score)")
                        .font(.title2).bold()
                        .accessibilityLabel("Score")
                        .accessibilityValue("\(score)")
                    Text("Combo: \(combo)")
                        .font(.title3)
                        .accessibilityLabel("Combo count")
                        .accessibilityValue("\(combo)")
                }
            }
            
            LazyVGrid(columns: gridItems, spacing: 12) {
                ForEach(activeButtons, id: \.self) { index in
                    Button {
                        buttonTapped(index: index)
                    } label: {
                        Circle()
                            .fill(decoyIndices.contains(index) ? Color.red : Color.blue)
                            .frame(height: 80)
                            .overlay(
                                Text(decoyIndices.contains(index) ? "X" : "")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.white)
                            )
                    }
                    .disabled(!isRunning)
                    .accessibilityLabel(decoyIndices.contains(index) ? "Fake button" : "Real button")
                    .accessibilityHint(isRunning ? "Tap me" : "Disabled")
                }
            }
            .padding(.horizontal)
            
            Toggle("Spawn Obstacles (Fake Buttons)", isOn: $spawnObstacles)
                .padding(.horizontal)
                .disabled(isRunning)
                .accessibilityLabel("Spawn obstacles toggle")
            
            HStack(spacing: 20) {
                Text("Penalty: -\(obstaclePenalty)")
                    .accessibilityLabel("Obstacle penalty")
                    .accessibilityValue("\(obstaclePenalty) points")
                
                Stepper("Penalty", value: $obstaclePenalty, in: 1...10)
                    .labelsHidden()
                    .disabled(isRunning)
                    .accessibilityLabel("Adjust obstacle penalty")
            }
            .padding(.horizontal)
            
            Button(isRunning ? "Reset" : "Start") {
                if isRunning {
                    resetGame()
                } else {
                    startGame()
                }
            }
            .font(.title2.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(isRunning ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .accessibilityHint(isRunning ? "Reset the game" : "Start the game")
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1/60
                if timeRemaining <= 0 {
                    timeRemaining = 0
                    isRunning = false
                    decoyIndices.removeAll()
                    showResults = true
                }
            }
        }
        .onChange(of: isRunning) { running in
            if running {
                decoySpawnerStart()
            } else {
                decoyIndices.removeAll()
                decoySpawnerCancel()
            }
        }
        .sheet(isPresented: $showResults) {
            ResultsView(score: score, onSubmit: {
                ArcadeLeaderboardStore.shared.submit(score: score, for: .tapFrenzy)
            })
        }
    }
    
    // MARK: - Button tap logic
    
    private func buttonTapped(index: Int) {
        guard isRunning else { return }
        let now = Date()
        if decoyIndices.contains(index) {
            // Decoy tapped: penalty and combo reset
            score = max(0, score - obstaclePenalty)
            combo = 0
            lastTapTime = nil
            taps = max(0, taps-1)
            // Haptic feedback for error
            Haptics.feedback(.error)
        } else {
            // Real button tapped
            taps += 1
            if let last = lastTapTime, now.timeIntervalSince(last) > 0.75 {
                combo = 0
            }
            combo += 1
            lastTapTime = now
            
            let pointsEarned = 1 + combo / 5
            score += pointsEarned
            Haptics.feedback(.success)
        }
    }
    
    // MARK: - Game control
    
    private func startGame() {
        score = 0
        taps = 0
        combo = 0
        lastTapTime = nil
        timeRemaining = 10
        isRunning = true
    }
    
    private func resetGame() {
        isRunning = false
        timeRemaining = 10
        score = 0
        taps = 0
        combo = 0
        lastTapTime = nil
        decoyIndices.removeAll()
    }
    
    // MARK: - Decoy spawner
    
    @State private var decoyTimer: Timer? = nil
    
    private func decoySpawnerStart() {
        guard spawnObstacles else { return }
        decoyTimer?.invalidate()
        decoyTimer = Timer.scheduledTimer(withTimeInterval: decoySpawnInterval, repeats: true) { _ in
            guard isRunning else {
                decoyIndices.removeAll()
                decoyTimer?.invalidate()
                decoyTimer = nil
                return
            }
            spawnDecoys()
        }
        decoyTimer?.fire()
    }
    
    private func decoySpawnerCancel() {
        decoyTimer?.invalidate()
        decoyTimer = nil
        decoyIndices.removeAll()
    }
    
    private func spawnDecoys() {
        let count = 2
        var newDecoys = Set<Int>()
        var attempts = 0
        while newDecoys.count < count && attempts < 50 {
            attempts += 1
            let candidate = Int.random(in: 0..<activeButtons.count)
            if !newDecoys.contains(candidate) {
                newDecoys.insert(candidate)
            }
        }
        
        decoyIndices = newDecoys
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            decoyIndices.removeAll()
        }
    }
}

private struct ResultsView: View {
    let score: Int
    let onSubmit: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Time's Up!")
                    .font(.largeTitle)
                    .bold()
                
                Text("Your final score is:")
                    .font(.title2)
                Text("\(score)")
                    .font(.system(size: 72, weight: .heavy, design: .monospaced))
                    .foregroundColor(.blue)
                
                Button("Submit to Leaderboard") {
                    onSubmit()
                    dismiss()
                }
                .font(.title3.bold())
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                
                Button("Close") {
                    dismiss()
                }
                .font(.title3)
                .padding()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

private struct Haptics {
    static func feedback(_ type: FeedbackType) {
        switch type {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    enum FeedbackType {
        case success, error
    }
}

