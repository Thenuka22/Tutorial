import Combine
import CoreLocation
import Foundation

@MainActor
final class GameSessionStore: ObservableObject {
    static let shared = GameSessionStore()

    @Published private(set) var sessions: [GameSession]

    private let defaults: UserDefaults
    private let sessionsKey = "playhub.gameSessions"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.sessions = Self.loadSessions(defaults: defaults, key: sessionsKey)
    }

    func addSession(
        mode: GameMode,
        score: Int,
        coordinate: CLLocationCoordinate2D?,
        variantID: String? = nil,
        variantLabel: String? = nil
    ) {
        let session = GameSession(
            mode: mode,
            score: score,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude,
            variantID: variantID,
            variantLabel: variantLabel
        )
        sessions.insert(session, at: 0)
        save()
    }

    func resetAll() {
        sessions = []
        defaults.removeObject(forKey: sessionsKey)
    }

    func sessions(for mode: GameMode) -> [GameSession] {
        sessions.filter { $0.mode == mode }
    }

    func sessions(for mode: GameMode, variantID: String) -> [GameSession] {
        sessions.filter { $0.mode == mode && $0.variantID == variantID }
    }

    func bestScore(for mode: GameMode) -> Int {
        sessions(for: mode).map(\.score).max() ?? 0
    }

    func bestScore(for mode: GameMode, variantID: String) -> Int {
        sessions(for: mode, variantID: variantID).map(\.score).max() ?? 0
    }

    func totalScore(for mode: GameMode) -> Int {
        sessions(for: mode).reduce(0) { $0 + $1.score }
    }

    func count(for mode: GameMode) -> Int {
        sessions(for: mode).count
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        defaults.set(data, forKey: sessionsKey)
    }

    private static func loadSessions(defaults: UserDefaults, key: String) -> [GameSession] {
        guard let data = defaults.data(forKey: key),
              let sessions = try? JSONDecoder().decode([GameSession].self, from: data) else {
            return []
        }
        return sessions.sorted { $0.timestamp > $1.timestamp }
    }
}
