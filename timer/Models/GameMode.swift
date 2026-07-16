import Foundation

enum GameMode: String, CaseIterable, Codable, Hashable, Identifiable {
    case tapFrenzy
    case lightItUp
    case quizRush

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tapFrenzy: return "Tap Frenzy"
        case .lightItUp: return "Light It Up"
        case .quizRush: return "Quiz Rush"
        }
    }

    var shortName: String {
        switch self {
        case .tapFrenzy: return "Tap"
        case .lightItUp: return "Light"
        case .quizRush: return "Quiz"
        }
    }

    var subtitle: String {
        switch self {
        case .tapFrenzy: return "10-second tap sprint"
        case .lightItUp: return "Reaction grid challenge"
        case .quizRush: return "Free trivia streaks"
        }
    }

    var symbolName: String {
        switch self {
        case .tapFrenzy: return "hand.tap.fill"
        case .lightItUp: return "bolt.fill"
        case .quizRush: return "questionmark.bubble.fill"
        }
    }

}
