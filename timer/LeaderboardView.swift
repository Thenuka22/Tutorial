import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var store: ArcadeLeaderboardStore = .shared
    @State private var selectedGame: ArcadeGameKind = .tapFrenzy
    @State private var showNameEditor = false
    @State private var tempName: String = ""
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            ArcadeScreenBackground()

            ScrollView {
                VStack(spacing: 20) {
                    gamePicker
                    podium
                    scoreList
                }
                .padding(20)
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    tempName = store.playerName
                    showNameEditor = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .accessibilityLabel("Player Name")
                }

                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Image(systemName: "trash")
                        .accessibilityLabel("Reset Scores")
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
            for game in ArcadeGameKind.allCases {
                store.seedPreviewDataIfNeeded(for: game)
            }
            #endif
        }
    }

    private var entries: [LeaderboardEntry] {
        store.topEntries(for: selectedGame)
    }

    private var gamePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedGame.displayName)
                        .font(.title.bold())
                        .foregroundStyle(ArcadeTheme.ink)
                    Text(selectedGame.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ArcadeTheme.mutedInk)
                }

                Spacer()

                Image(systemName: selectedGame.symbolName)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(ArcadeTheme.gradient(for: selectedGame), in: Circle())
            }

            Picker("Game", selection: $selectedGame) {
                ForEach(ArcadeGameKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    private var podium: some View {
        VStack(spacing: 16) {
            if entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(ArcadeTheme.gold)
                    Text("No Scores Yet")
                        .font(.title3.bold())
                        .foregroundStyle(ArcadeTheme.ink)
                    Text("Play a round and save your score.")
                        .font(.subheadline)
                        .foregroundStyle(ArcadeTheme.mutedInk)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
            } else {
                HStack(alignment: .bottom, spacing: 10) {
                    podiumColumn(rank: 2, entry: entry(at: 1), color: ArcadeTheme.sky, height: 116)
                    podiumColumn(rank: 1, entry: entry(at: 0), color: ArcadeTheme.orange, height: 148)
                    podiumColumn(rank: 3, entry: entry(at: 2), color: ArcadeTheme.gold, height: 96)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func podiumColumn(rank: Int, entry: LeaderboardEntry?, color: Color, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            avatar(for: entry, rank: rank, color: color)

            VStack(spacing: 2) {
                Text(entry?.name ?? "-")
                    .font(.subheadline.bold())
                    .foregroundStyle(ArcadeTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(entry.map { "\($0.score)" } ?? "0")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(ArcadeTheme.mutedInk)
            }

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color)
                    .frame(height: height)
                Text("#\(rank)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func avatar(for entry: LeaderboardEntry?, rank: Int, color: Color) -> some View {
        Text(initials(for: entry?.name, fallback: "\(rank)"))
            .font(.headline.bold())
            .foregroundStyle(.white)
            .frame(width: rank == 1 ? 64 : 54, height: rank == 1 ? 64 : 54)
            .background(color, in: Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 4)
            )
            .shadow(color: color.opacity(0.28), radius: 12, x: 0, y: 8)
    }

    private var scoreList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Scores")
                .font(.title3.bold())
                .foregroundStyle(ArcadeTheme.ink)

            if entries.isEmpty {
                EmptyView()
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack(spacing: 12) {
                            Text("#\(index + 1)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(ArcadeTheme.mutedInk)
                                .frame(width: 44, alignment: .leading)

                            avatar(for: entry, rank: index + 1, color: rowColor(for: index))
                                .scaleEffect(0.72)
                                .frame(width: 46, height: 46)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.name)
                                    .font(.headline)
                                    .foregroundStyle(ArcadeTheme.ink)
                                    .lineLimit(1)
                                Text(entry.date, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(ArcadeTheme.mutedInk)
                            }

                            Spacer()

                            Text("\(entry.score)")
                                .font(.title3.bold().monospacedDigit())
                                .foregroundStyle(ArcadeTheme.ink)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Rank \(index + 1), \(entry.name), score \(entry.score)")
                    }
                }
            }
        }
    }

    private func entry(at index: Int) -> LeaderboardEntry? {
        guard entries.indices.contains(index) else { return nil }
        return entries[index]
    }

    private func initials(for name: String?, fallback: String) -> String {
        guard let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallback
        }
        return name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }

    private func rowColor(for index: Int) -> Color {
        switch index % 4 {
        case 0: return ArcadeTheme.orange
        case 1: return ArcadeTheme.sky
        case 2: return ArcadeTheme.gold
        default: return ArcadeTheme.mint
        }
    }
}

#Preview {
    NavigationStack { LeaderboardView() }
}

