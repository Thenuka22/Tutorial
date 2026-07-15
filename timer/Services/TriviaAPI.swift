import Foundation

struct TriviaAPI {
    private let questionsEndpoint = URL(string: "https://opentdb.com/api.php")!
    private let categoriesEndpoint = URL(string: "https://opentdb.com/api_category.php")!

    func fetchCategories() async throws -> [TriviaCategory] {
        let (data, response) = try await URLSession.shared.data(from: categoriesEndpoint)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw TriviaAPIError.badResponse
        }

        let payload = try JSONDecoder().decode(TriviaCategoryPayload.self, from: data)
        return payload.triviaCategories.map { TriviaCategory(id: $0.id, name: $0.name.htmlDecoded) }
    }

    func fetchQuestions(options: QuizRushOptions = QuizRushOptions()) async throws -> [TriviaQuestion] {
        var components = URLComponents(url: questionsEndpoint, resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "amount", value: "\(options.questionCount)"),
            URLQueryItem(name: "type", value: "multiple")
        ]

        if let difficulty = options.difficulty.apiValue {
            queryItems.append(URLQueryItem(name: "difficulty", value: difficulty))
        }

        if let categoryID = options.categoryID {
            queryItems.append(URLQueryItem(name: "category", value: "\(categoryID)"))
        }

        components?.queryItems = queryItems
        guard let url = components?.url else { throw TriviaAPIError.badRequest }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw TriviaAPIError.badResponse
        }

        let payload = try JSONDecoder().decode(TriviaPayload.self, from: data)
        guard payload.responseCode == 0 else { throw TriviaAPIError.empty }
        let questions = payload.results.map(\.triviaQuestion)
        guard !questions.isEmpty else { throw TriviaAPIError.empty }
        return questions
    }

    static func fallbackQuestions(for options: QuizRushOptions) -> [TriviaQuestion] {
        var filteredQuestions = fallbackQuestions

        if options.difficulty != .any {
            filteredQuestions = filteredQuestions.filter { $0.difficulty == options.difficulty.rawValue }
        }

        if options.categoryName != TriviaCategory.any.name {
            let categoryNeedle = options.cleanCategoryName.lowercased()
            let categoryMatches = filteredQuestions.filter {
                $0.category.lowercased().contains(categoryNeedle)
            }
            if !categoryMatches.isEmpty {
                filteredQuestions = categoryMatches
            }
        }

        if filteredQuestions.count < options.questionCount {
            filteredQuestions = fallbackQuestions
        }

        return Array(filteredQuestions.shuffled().prefix(options.questionCount))
    }

    static let fallbackQuestions: [TriviaQuestion] = [
        TriviaQuestion(
            category: "Computing",
            difficulty: "easy",
            prompt: "Which Apple framework is used to build declarative iOS interfaces?",
            correctAnswer: "SwiftUI",
            choices: ["SwiftUI", "MapKit", "CloudKit", "SpriteKit"].shuffled()
        ),
        TriviaQuestion(
            category: "iOS",
            difficulty: "easy",
            prompt: "Which SwiftUI view creates a tab bar interface?",
            correctAnswer: "TabView",
            choices: ["TabView", "List", "Form", "ShareLink"].shuffled()
        ),
        TriviaQuestion(
            category: "iOS",
            difficulty: "easy",
            prompt: "Which framework schedules local notifications?",
            correctAnswer: "UserNotifications",
            choices: ["UserNotifications", "CoreMotion", "Charts", "Photos"].shuffled()
        ),
        TriviaQuestion(
            category: "Maps",
            difficulty: "easy",
            prompt: "Which Apple framework displays maps and markers?",
            correctAnswer: "MapKit",
            choices: ["MapKit", "HealthKit", "WidgetKit", "SceneKit"].shuffled()
        ),
        TriviaQuestion(
            category: "Stats",
            difficulty: "easy",
            prompt: "Which SwiftUI framework can draw BarMark charts?",
            correctAnswer: "Charts",
            choices: ["Charts", "Core Data", "Contacts", "AVKit"].shuffled()
        ),
        TriviaQuestion(
            category: "Computing",
            difficulty: "medium",
            prompt: "Which data format does PlayHub use to persist completed sessions in UserDefaults?",
            correctAnswer: "JSON",
            choices: ["JSON", "CSV", "YAML", "XML"].shuffled()
        ),
        TriviaQuestion(
            category: "iOS",
            difficulty: "medium",
            prompt: "Which property wrapper owns an observable object for the lifetime of a SwiftUI view?",
            correctAnswer: "StateObject",
            choices: ["StateObject", "Binding", "Environment", "Namespace"].shuffled()
        ),
        TriviaQuestion(
            category: "Maps",
            difficulty: "medium",
            prompt: "Which type represents latitude and longitude coordinates in Core Location?",
            correctAnswer: "CLLocationCoordinate2D",
            choices: ["CLLocationCoordinate2D", "MKMarker", "URLRequest", "DateComponents"].shuffled()
        ),
        TriviaQuestion(
            category: "Stats",
            difficulty: "medium",
            prompt: "Which Charts mark is used by PlayHub for vertical score bars?",
            correctAnswer: "BarMark",
            choices: ["BarMark", "PointMark", "RuleMark", "AreaMark"].shuffled()
        ),
        TriviaQuestion(
            category: "General Knowledge",
            difficulty: "easy",
            prompt: "What does a leaderboard usually rank?",
            correctAnswer: "Scores",
            choices: ["Scores", "Battery levels", "Contacts", "Calendar events"].shuffled()
        ),
        TriviaQuestion(
            category: "Computing",
            difficulty: "hard",
            prompt: "Which Swift protocol allows a type to be encoded and decoded?",
            correctAnswer: "Codable",
            choices: ["Codable", "View", "Identifiable", "ObservableObject"].shuffled()
        ),
        TriviaQuestion(
            category: "iOS",
            difficulty: "hard",
            prompt: "Which framework is commonly used to play generated audio data in an iOS app?",
            correctAnswer: "AVFoundation",
            choices: ["AVFoundation", "MapKit", "Swift Charts", "CoreLocation"].shuffled()
        ),
        TriviaQuestion(
            category: "Geography",
            difficulty: "easy",
            prompt: "Which coordinate value measures north and south position?",
            correctAnswer: "Latitude",
            choices: ["Latitude", "Longitude", "Altitude", "Heading"].shuffled()
        ),
        TriviaQuestion(
            category: "History",
            difficulty: "easy",
            prompt: "What do app version histories usually record?",
            correctAnswer: "Changes over time",
            choices: ["Changes over time", "Only colors", "Only icons", "Device brightness"].shuffled()
        ),
        TriviaQuestion(
            category: "Sports",
            difficulty: "easy",
            prompt: "In most timed games, what does a sprint mode usually emphasize?",
            correctAnswer: "Speed",
            choices: ["Speed", "Waiting", "Reading settings", "Map pins"].shuffled()
        )
    ]
}

private struct TriviaPayload: Decodable {
    let responseCode: Int
    let results: [TriviaQuestionDTO]

    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case results
    }
}

private struct TriviaCategoryPayload: Decodable {
    let triviaCategories: [TriviaCategoryDTO]

    enum CodingKeys: String, CodingKey {
        case triviaCategories = "trivia_categories"
    }
}

private struct TriviaCategoryDTO: Decodable {
    let id: Int
    let name: String
}

private struct TriviaQuestionDTO: Decodable {
    let category: String
    let difficulty: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    enum CodingKeys: String, CodingKey {
        case category
        case difficulty
        case question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }

    var triviaQuestion: TriviaQuestion {
        let decodedCorrect = correctAnswer.htmlDecoded
        let decodedIncorrect = incorrectAnswers.map(\.htmlDecoded)
        return TriviaQuestion(
            category: category.htmlDecoded,
            difficulty: difficulty,
            prompt: question.htmlDecoded,
            correctAnswer: decodedCorrect,
            choices: ([decodedCorrect] + decodedIncorrect).shuffled()
        )
    }
}

private enum TriviaAPIError: Error {
    case badRequest
    case badResponse
    case empty
}

private extension String {
    var htmlDecoded: String {
        guard let data = data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        return attributedString.string
    }
}
