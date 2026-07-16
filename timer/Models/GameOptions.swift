import Foundation

enum TapFrenzyPreset: String, CaseIterable, Codable, Hashable, Identifiable {
    case classic
    case focus

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .focus: return "Focus"
        }
    }

    var subtitle: String {
        switch self {
        case .classic: return "10-second sprint with bonuses and traps"
        case .focus: return "Longer round with traps disabled"
        }
    }

    var options: TapFrenzyOptions {
        switch self {
        case .classic:
            return TapFrenzyOptions(preset: self)
        case .focus:
            return TapFrenzyOptions(
                preset: self,
                roundDuration: 20,
                trapsEnabled: false,
                bonusBurstEnabled: true,
                targetMoveInterval: 1.35,
                moodChangeInterval: 1.7,
                bonusChance: 14,
                trapChance: 0
            )
        }
    }
}

struct TapFrenzyOptions: Codable, Equatable {
    var preset: TapFrenzyPreset = .classic
    var roundDuration: Double = 10
    var trapsEnabled = true
    var bonusBurstEnabled = true
    var targetMoveInterval: TimeInterval = 1.0
    var moodChangeInterval: TimeInterval = 1.35
    var bonusChance = 18
    var trapChance = 18

    var variantID: String {
        let duration = Int(roundDuration)
        let move = Int((targetMoveInterval * 10).rounded())
        return "tap:\(preset.rawValue):\(duration):\(trapsEnabled):\(bonusBurstEnabled):\(move)"
    }

    var variantLabel: String {
        isPresetDefault ? preset.displayName : "\(preset.displayName) Custom"
    }

    private var isPresetDefault: Bool {
        let defaultOptions = preset.options
        return roundDuration == defaultOptions.roundDuration &&
            trapsEnabled == defaultOptions.trapsEnabled &&
            bonusBurstEnabled == defaultOptions.bonusBurstEnabled &&
            targetMoveInterval == defaultOptions.targetMoveInterval
    }
}

enum LightItUpPreset: String, CaseIterable, Codable, Hashable, Identifiable {
    case classic
    case sprint
    case expert

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .sprint: return "Sprint"
        case .expert: return "Expert"
        }
    }

    var subtitle: String {
        switch self {
        case .classic: return "60-second level progression"
        case .sprint: return "Shorter round with quicker lights"
        case .expert: return "Harder penalties and denser lights"
        }
    }

    var options: LightItUpOptions {
        switch self {
        case .classic:
            return LightItUpOptions(preset: self)
        case .sprint:
            return LightItUpOptions(
                preset: self,
                roundDuration: 30,
                startingLevel: .l2,
                wrongTapPenalty: 1,
                missedLightPenalty: 1,
                extraLightsPerTick: 1,
                spawnSpeedMultiplier: 0.85
            )
        case .expert:
            return LightItUpOptions(
                preset: self,
                roundDuration: 45,
                startingLevel: .l3,
                wrongTapPenalty: 2,
                missedLightPenalty: 2,
                extraLightsPerTick: 1,
                spawnSpeedMultiplier: 0.72
            )
        }
    }
}

struct LightItUpOptions: Codable, Equatable {
    var preset: LightItUpPreset = .classic
    var roundDuration = 60
    var startingLevel: GameLevel = .l1
    var wrongTapPenalty = 1
    var missedLightPenalty = 1
    var extraLightsPerTick = 0
    var spawnSpeedMultiplier: Double = 1.0

    var variantID: String {
        "light:\(preset.rawValue):\(roundDuration):\(startingLevel.rawValue):\(wrongTapPenalty):\(missedLightPenalty):\(extraLightsPerTick)"
    }

    var variantLabel: String {
        isPresetDefault ? preset.displayName : "\(preset.displayName) Custom"
    }

    private var isPresetDefault: Bool {
        let defaultOptions = preset.options
        return roundDuration == defaultOptions.roundDuration &&
            startingLevel == defaultOptions.startingLevel &&
            wrongTapPenalty == defaultOptions.wrongTapPenalty &&
            missedLightPenalty == defaultOptions.missedLightPenalty &&
            extraLightsPerTick == defaultOptions.extraLightsPerTick
    }
}

enum QuizDifficulty: String, CaseIterable, Codable, Hashable, Identifiable {
    case any
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .any: return "Any"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var apiValue: String? {
        self == .any ? nil : rawValue
    }
}

struct TriviaCategory: Identifiable, Codable, Equatable {
    let id: Int
    let name: String

    static let anyID = 0

    static var any: TriviaCategory {
        TriviaCategory(id: anyID, name: "Any Category")
    }
}

struct QuizRushOptions: Codable, Equatable {
    var questionCount = 10
    var difficulty: QuizDifficulty = .any
    var categoryID: Int?
    var categoryName = TriviaCategory.any.name
    var timedQuestions = false
    var secondsPerQuestion = 12
    var streakBonusEnabled = true

    var variantID: String {
        let categoryPart = categoryID.map(String.init) ?? "any"
        return "quiz:\(questionCount):\(difficulty.rawValue):\(categoryPart):\(timedQuestions):\(secondsPerQuestion):\(streakBonusEnabled)"
    }

    var variantLabel: String {
        var parts = [difficulty.displayName]
        if categoryName != TriviaCategory.any.name {
            parts.append(cleanCategoryName)
        }
        parts.append("\(questionCount)Q")
        if timedQuestions {
            parts.append("\(secondsPerQuestion)s")
        }
        return parts.joined(separator: " / ")
    }

    var cleanCategoryName: String {
        categoryName
            .replacingOccurrences(of: "Entertainment: ", with: "")
            .replacingOccurrences(of: "Science: ", with: "")
    }

    func withoutCategory() -> QuizRushOptions {
        var copy = self
        copy.categoryID = nil
        copy.categoryName = TriviaCategory.any.name
        return copy
    }
}
