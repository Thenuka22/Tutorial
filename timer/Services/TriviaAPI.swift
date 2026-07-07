import Foundation

struct TriviaAPI {
    private let endpoint = URL(string: "https://opentdb.com/api.php?amount=10&type=multiple")!

    func fetchQuestions() async throws -> [TriviaQuestion] {
        let (data, response) = try await URLSession.shared.data(from: endpoint)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw TriviaAPIError.badResponse
        }

        let payload = try JSONDecoder().decode(TriviaPayload.self, from: data)
        let questions = payload.results.map(\.triviaQuestion)
        guard !questions.isEmpty else { throw TriviaAPIError.empty }
        return questions
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
        )
    ]
}

private struct TriviaPayload: Decodable {
    let results: [TriviaQuestionDTO]
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
