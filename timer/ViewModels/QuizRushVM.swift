import Combine
import Foundation

@MainActor
final class QuizRushVM: ObservableObject {
    @Published private(set) var phase: QuizRushPhase = .idle
    @Published private(set) var questions: [TriviaQuestion] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var score = 0
    @Published private(set) var streak = 0
    @Published private(set) var selectedAnswer: String?
    @Published private(set) var usingFallbackQuestions = false

    private let triviaAPI = TriviaAPI()
    private var hasRecordedCurrentRound = false

    var currentQuestion: TriviaQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var progressLabel: String {
        guard !questions.isEmpty else { return "0/10" }
        return "\(min(currentIndex + 1, questions.count))/\(questions.count)"
    }

    func loadIfNeeded() async {
        guard phase == .idle else { return }
        await load()
    }

    func load() async {
        phase = .loading
        selectedAnswer = nil
        currentIndex = 0
        score = 0
        streak = 0
        hasRecordedCurrentRound = false

        do {
            questions = try await triviaAPI.fetchQuestions()
            usingFallbackQuestions = false
            phase = .loaded
        } catch {
            questions = Self.fallbackQuestions()
            usingFallbackQuestions = true
            phase = questions.isEmpty ? .failed("Trivia did not load.") : .loaded
        }
    }

    func choose(_ answer: String) {
        guard selectedAnswer == nil, let question = currentQuestion else { return }

        selectedAnswer = answer
        if answer == question.correctAnswer {
            streak += 1
            score += 10 + min(streak - 1, 4) * 2
        } else {
            streak = 0
            score = max(0, score - 2)
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            advance()
        }
    }

    private func advance() {
        if currentIndex >= questions.count - 1 {
            phase = .finished
            selectedAnswer = nil
            recordCompletionIfNeeded()
        } else {
            currentIndex += 1
            selectedAnswer = nil
            phase = .loaded
        }
    }

    private func recordCompletionIfNeeded() {
        guard !hasRecordedCurrentRound else { return }
        hasRecordedCurrentRound = true
        GameSessionStore.shared.addSession(
            mode: .quizRush,
            score: score,
            coordinate: LocationService.shared.currentCoordinate
        )
    }

    private static func fallbackQuestions() -> [TriviaQuestion] {
        TriviaAPI.fallbackQuestions.shuffled()
    }
}

enum QuizRushPhase: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
    case finished
}
