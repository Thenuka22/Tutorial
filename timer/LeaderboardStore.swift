import Foundation
import SwiftUI
import Combine

public enum ArcadeGameKind: String, CaseIterable, Codable, Identifiable {
    case tapFrenzy
    case lightItUp
    case quizRush

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .tapFrenzy: return "Tap Frenzy"
        case .lightItUp: return "Light It Up"
        case .quizRush: return "Quiz Rush"
        }
    }

    public var subtitle: String {
        switch self {
        case .tapFrenzy: return "10-second tap sprint"
        case .lightItUp: return "Reaction grid challenge"
        case .quizRush: return "Live trivia streaks"
        }
    }

    public var symbolName: String {
        switch self {
        case .tapFrenzy: return "hand.tap.fill"
        case .lightItUp: return "bolt.fill"
        case .quizRush: return "questionmark.bubble.fill"
        }
    }
}

public struct LeaderboardEntry: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var score: Int
    public var date: Date
}

public final class ArcadeLeaderboardStore: ObservableObject {
    public static let shared = ArcadeLeaderboardStore()

    @Published public private(set) var entries: [ArcadeGameKind: [LeaderboardEntry]]

    private let defaults = UserDefaults.standard
    private let playerNameKey = "player.name"

    public var playerName: String {
        get { defaults.string(forKey: playerNameKey) ?? "Player" }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = trimmed.isEmpty ? "Player" : trimmed
            defaults.set(value, forKey: playerNameKey)
            objectWillChange.send()
        }
    }

    public init() {
        var dict: [ArcadeGameKind: [LeaderboardEntry]] = [:]
        for kind in ArcadeGameKind.allCases {
            dict[kind] = Self.loadEntries(for: kind, defaults: defaults)
        }
        self.entries = dict
        if defaults.string(forKey: playerNameKey) == nil {
            defaults.set("Player", forKey: playerNameKey)
        }
    }

    public func submit(score: Int, for game: ArcadeGameKind, name: String? = nil) {
        let finalName: String = {
            if let n = name?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty { return n }
            return playerName
        }()

        var list = entries[game] ?? []
        let entry = LeaderboardEntry(id: UUID(), name: finalName, score: max(0, score), date: Date())
        list.append(entry)
        list.sort { lhs, rhs in
            if lhs.score == rhs.score { return lhs.date < rhs.date }
            return lhs.score > rhs.score
        }
        if list.count > 10 { list = Array(list.prefix(10)) }
        entries[game] = list
        save(game)
    }

    public func topEntries(for game: ArcadeGameKind) -> [LeaderboardEntry] {
        return entries[game] ?? []
    }

    public func reset(for game: ArcadeGameKind) {
        entries[game] = []
        save(game)
    }

    public func resetAll() {
        for kind in ArcadeGameKind.allCases {
            entries[kind] = []
            save(kind)
        }
    }

    private func save(_ game: ArcadeGameKind) {
        let key = defaultsKey(for: game)
        if let data = try? JSONEncoder().encode(entries[game] ?? []) {
            defaults.set(data, forKey: key)
        }
        objectWillChange.send()
    }

    private static func loadEntries(for game: ArcadeGameKind, defaults: UserDefaults) -> [LeaderboardEntry] {
        let key = defaultsKey(for: game)
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([LeaderboardEntry].self, from: data)) ?? []
    }

    private static func defaultsKey(for game: ArcadeGameKind) -> String {
        switch game {
        case .tapFrenzy: return "leaderboard.tapFrenzy"
        case .lightItUp: return "leaderboard.lightItUp"
        case .quizRush: return "leaderboard.quizRush"
        }
    }

    private func defaultsKey(for game: ArcadeGameKind) -> String { Self.defaultsKey(for: game) }
}

#if DEBUG
extension ArcadeLeaderboardStore {
    func seedPreviewDataIfNeeded(for game: ArcadeGameKind) {
        guard (entries[game] ?? []).isEmpty else { return }
        let names = ["Alex", "Sam", "Jordan", "Taylor", "Riley"]
        for i in 0..<5 {
            submit(score: Int.random(in: 10...50) + i * 5, for: game, name: names[i])
        }
    }
}
#endif
