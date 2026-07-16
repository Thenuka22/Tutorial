import Foundation

enum GameBackgroundTheme: String, CaseIterable, Codable, Hashable, Identifiable {
    case jungleDay
    case sunsetRuins
    case moonlitForest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .jungleDay: return "Jungle Day"
        case .sunsetRuins: return "Sunset Ruins"
        case .moonlitForest: return "Moonlit Forest"
        }
    }

    var assetName: String {
        switch self {
        case .jungleDay: return GameArt.quizBackground
        case .sunsetRuins: return GameArt.sunsetRuinsBackground
        case .moonlitForest: return GameArt.moonlitForestBackground
        }
    }

    var backgroundOverlayOpacity: Double {
        switch self {
        case .jungleDay: return 0.18
        case .sunsetRuins: return 0.16
        case .moonlitForest: return 0.22
        }
    }
}
