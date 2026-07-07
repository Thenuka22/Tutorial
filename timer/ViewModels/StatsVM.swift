import Combine
import Foundation

@MainActor
final class StatsVM: ObservableObject {
    @Published private(set) var sessions: [GameSession] = []

    private var cancellables = Set<AnyCancellable>()

    init(store: GameSessionStore = .shared) {
        sessions = store.sessions
        store.$sessions
            .sink { [weak self] sessions in
                self?.sessions = sessions
            }
            .store(in: &cancellables)
    }

    var totalGames: Int { sessions.count }

    var totalScore: Int {
        sessions.reduce(0) { $0 + $1.score }
    }

    var averageScore: Int {
        guard !sessions.isEmpty else { return 0 }
        return totalScore / sessions.count
    }

    var recentSessions: [GameSession] {
        Array(sessions.prefix(8))
    }

    var locatedSessions: [GameSession] {
        sessions.filter { $0.coordinate != nil }
    }

    var modeStats: [ModeStat] {
        GameMode.allCases.map { mode in
            let modeSessions = sessions.filter { $0.mode == mode }
            return ModeStat(
                mode: mode,
                games: modeSessions.count,
                bestScore: modeSessions.map(\.score).max() ?? 0,
                totalScore: modeSessions.reduce(0) { $0 + $1.score }
            )
        }
    }

    func bestScore(for mode: GameMode) -> Int {
        sessions.filter { $0.mode == mode }.map(\.score).max() ?? 0
    }
}

struct ModeStat: Identifiable {
    let mode: GameMode
    let games: Int
    let bestScore: Int
    let totalScore: Int

    var id: GameMode { mode }
}
