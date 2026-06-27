import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var store: ArcadeLeaderboardStore = .shared
    @State private var selectedGame: ArcadeGameKind = .tapFrenzy
    @State private var showNameEditor = false
    @State private var tempName: String = ""
    @State private var confirmReset = false

    var body: some View {
        List {
            Section {
                Picker("Game", selection: $selectedGame) {
                    ForEach(ArcadeGameKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Top Scores") {
                let entries = store.topEntries(for: selectedGame)
                if entries.isEmpty {
                    ContentUnavailableView("No Scores Yet", systemImage: "trophy", description: Text("Play a round and submit your score."))
                } else {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            Text("#\(index + 1)")
                                .font(.headline)
                                .frame(width: 36, alignment: .leading)
                            VStack(alignment: .leading) {
                                Text(entry.name)
                                    .font(.headline)
                                Text(entry.date, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(entry.score)")
                                .font(.title3)
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Rank \(index + 1), \(entry.name), score \(entry.score)")
                    }
                }
            }
        }
        .navigationTitle("Leaderboard")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    tempName = store.playerName
                    showNameEditor = true
                } label: {
                    Label("Player Name", systemImage: "person.crop.circle")
                }

                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Label("Reset", systemImage: "trash")
                }
            }
        }
        .alert("Edit Player Name", isPresented: $showNameEditor) {
            TextField("Name", text: $tempName)
            Button("Save") { store.playerName = tempName }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This name will be used when submitting scores.")
        }
        .confirmationDialog("Reset \(selectedGame.displayName) scores?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset Scores", role: .destructive) { store.reset(for: selectedGame) }
            Button("Cancel", role: .cancel) { }
        }
        .onAppear {
            #if DEBUG
            store.seedPreviewDataIfNeeded(for: .tapFrenzy)
            store.seedPreviewDataIfNeeded(for: .lightItUp)
            #endif
        }
    }
}

#Preview {
    NavigationStack { LeaderboardView() }
}

