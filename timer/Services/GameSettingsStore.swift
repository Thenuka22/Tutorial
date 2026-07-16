import Combine
import Foundation

@MainActor
final class GameSettingsStore: ObservableObject {
    static let shared = GameSettingsStore()

    @Published var soundEffectsEnabled = true {
        didSet {
            defaults.set(soundEffectsEnabled, forKey: Keys.soundEffectsEnabled)
        }
    }

    @Published var musicEnabled = false {
        didSet {
            defaults.set(musicEnabled, forKey: Keys.musicEnabled)
            AudioService.shared.sync(with: self)
        }
    }

    @Published var hapticsEnabled = true {
        didSet {
            defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled)
        }
    }

    @Published var soundVolume = 0.85 {
        didSet {
            defaults.set(soundVolume.clamped(to: 0...1), forKey: Keys.soundVolume)
        }
    }

    @Published var musicVolume = 0.35 {
        didSet {
            defaults.set(musicVolume.clamped(to: 0...1), forKey: Keys.musicVolume)
            AudioService.shared.sync(with: self)
        }
    }

    @Published var selectedBackgroundTheme: GameBackgroundTheme = .jungleDay {
        didSet {
            defaults.set(selectedBackgroundTheme.rawValue, forKey: Keys.selectedBackgroundTheme)
        }
    }

    @Published var defaultTapPreset: TapFrenzyPreset = .classic {
        didSet {
            defaults.set(defaultTapPreset.rawValue, forKey: Keys.defaultTapPreset)
        }
    }

    @Published var defaultLightPreset: LightItUpPreset = .classic {
        didSet {
            defaults.set(defaultLightPreset.rawValue, forKey: Keys.defaultLightPreset)
        }
    }

    @Published var defaultQuizDifficulty: QuizDifficulty = .any {
        didSet {
            defaults.set(defaultQuizDifficulty.rawValue, forKey: Keys.defaultQuizDifficulty)
        }
    }

    @Published var defaultQuizQuestionCount = 10 {
        didSet {
            defaults.set(defaultQuizQuestionCount, forKey: Keys.defaultQuizQuestionCount)
        }
    }

    @Published private(set) var defaultQuizCategoryID: Int?
    @Published private(set) var defaultQuizCategoryName = TriviaCategory.any.name

    static let allowedQuestionCounts = [5, 10, 15]

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        soundEffectsEnabled = defaults.object(forKey: Keys.soundEffectsEnabled) as? Bool ?? true
        musicEnabled = defaults.object(forKey: Keys.musicEnabled) as? Bool ?? false
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        soundVolume = (defaults.object(forKey: Keys.soundVolume) as? Double ?? 0.85).clamped(to: 0...1)
        musicVolume = (defaults.object(forKey: Keys.musicVolume) as? Double ?? 0.35).clamped(to: 0...1)

        if let rawValue = defaults.string(forKey: Keys.selectedBackgroundTheme),
           let theme = GameBackgroundTheme(rawValue: rawValue) {
            selectedBackgroundTheme = theme
        } else {
            selectedBackgroundTheme = .jungleDay
            defaults.set(GameBackgroundTheme.jungleDay.rawValue, forKey: Keys.selectedBackgroundTheme)
        }

        if let rawValue = defaults.string(forKey: Keys.defaultTapPreset) {
            if let preset = TapFrenzyPreset(rawValue: rawValue) {
                defaultTapPreset = preset
            } else {
                defaultTapPreset = .classic
                defaults.set(TapFrenzyPreset.classic.rawValue, forKey: Keys.defaultTapPreset)
            }
        }

        if let rawValue = defaults.string(forKey: Keys.defaultLightPreset),
           let preset = LightItUpPreset(rawValue: rawValue) {
            defaultLightPreset = preset
        }

        if let rawValue = defaults.string(forKey: Keys.defaultQuizDifficulty),
           let difficulty = QuizDifficulty(rawValue: rawValue) {
            defaultQuizDifficulty = difficulty
        }

        let storedQuestionCount = defaults.integer(forKey: Keys.defaultQuizQuestionCount)
        if Self.allowedQuestionCounts.contains(storedQuestionCount) {
            defaultQuizQuestionCount = storedQuestionCount
        }

        if defaults.object(forKey: Keys.defaultQuizCategoryID) != nil {
            defaultQuizCategoryID = defaults.integer(forKey: Keys.defaultQuizCategoryID)
        }
        defaultQuizCategoryName = defaults.string(forKey: Keys.defaultQuizCategoryName) ?? TriviaCategory.any.name
    }

    var defaultTapOptions: TapFrenzyOptions {
        defaultTapPreset.options
    }

    var defaultLightOptions: LightItUpOptions {
        defaultLightPreset.options
    }

    var defaultQuizOptions: QuizRushOptions {
        QuizRushOptions(
            questionCount: defaultQuizQuestionCount,
            difficulty: defaultQuizDifficulty,
            categoryID: defaultQuizCategoryID,
            categoryName: defaultQuizCategoryName,
            timedQuestions: false,
            secondsPerQuestion: 12,
            streakBonusEnabled: true
        )
    }

    func setDefaultQuizCategory(id: Int?, name: String) {
        defaultQuizCategoryID = id
        defaultQuizCategoryName = name
        if let id {
            defaults.set(id, forKey: Keys.defaultQuizCategoryID)
        } else {
            defaults.removeObject(forKey: Keys.defaultQuizCategoryID)
        }
        defaults.set(name, forKey: Keys.defaultQuizCategoryName)
    }

    private enum Keys {
        static let soundEffectsEnabled = "playhub.soundEffectsEnabled"
        static let musicEnabled = "playhub.musicEnabled"
        static let hapticsEnabled = "playhub.hapticsEnabled"
        static let soundVolume = "playhub.soundVolume"
        static let musicVolume = "playhub.musicVolume"
        static let selectedBackgroundTheme = "playhub.backgroundTheme"
        static let defaultTapPreset = "playhub.defaultTapPreset"
        static let defaultLightPreset = "playhub.defaultLightPreset"
        static let defaultQuizDifficulty = "playhub.defaultQuizDifficulty"
        static let defaultQuizQuestionCount = "playhub.defaultQuizQuestionCount"
        static let defaultQuizCategoryID = "playhub.defaultQuizCategoryID"
        static let defaultQuizCategoryName = "playhub.defaultQuizCategoryName"
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
