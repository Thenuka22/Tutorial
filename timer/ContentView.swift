import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Modes") {
                    NavigationLink {
                        TapFrenzyEnhancedView()
                    } label: {
                        Label("Tap Frenzy", systemImage: "hand.tap")
                    }

                    NavigationLink {
                        LightItUpEnhancedView()
                    } label: {
                        Label("Light It Up", systemImage: "bolt.fill")
                    }
                    
                    NavigationLink {
                        LeaderboardView()
                    } label: {
                        Label("Leaderboard", systemImage: "trophy")
                    }
                }

                Section("About") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Light It Up")
                            .font(.headline)
                        Text("A grid-based reaction game. Tap lit cards before they dim. Difficulty increases every 15 seconds.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tap Frenzy")
                            .font(.headline)
                        Text("Tap as fast as you can before the timer runs out.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Leaderboard")
                            .font(.headline)
                        Text("Track top scores for each game. Edit your player name and reset when needed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Arcade")
        }
    }
}

#Preview {
    ContentView()
}
