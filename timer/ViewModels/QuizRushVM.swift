import Combine
import Foundation
internal import UIKit

@MainActor
final class QuizRushVM: ObservableObject {
    @Published private(set) var phase: QuizRushPhase = .idle
    @Published private(set) var questions: [TriviaQuestion] = []
    @Published private(set) var categories: [TriviaCategory] = [.any]
    @Published private(set) var currentIndex = 0
    @Published private(set) var score = 0
    @Published private(set) var streak = 0
    @Published private(set) var selectedAnswer: String?
    @Published private(set) var usingFallbackQuestions = false
    @Published private(set) var activeOptions = QuizRushOptions()
    @Published private(set) var scoreVariantID = QuizRushOptions().variantID
    @Published private(set) var scoreVariantLabel = QuizRushOptions().variantLabel
    @Published private(set) var sourceNote: String?
    @Published private(set) var timeRemaining = 0

    private let triviaAPI = TriviaAPI()
    private var hasRecordedCurrentRound = false
    private var questionTimerCancellable: AnyCancellable?

    var currentQuestion: TriviaQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var progressLabel: String {
        guard !questions.isEmpty else { return "0/0" }
        return "\(min(currentIndex + 1, questions.count))/\(questions.count)"
    }

    var activeFilterLabel: String {
        scoreVariantLabel
    }

    func loadCategories() async {
        guard categories.count == 1 else { return }
        if let fetchedCategories = try? await triviaAPI.fetchCategories() {
            categories = [.any] + fetchedCategories
        }
    }

    func loadIfNeeded(options: QuizRushOptions) async {
        guard phase == .idle else { return }
        await load(options: options)
    }

    func load(options: QuizRushOptions) async {
        resetRoundState(options: options)

        do {
            let loadedQuestions = try await triviaAPI.fetchQuestions(options: options)
            finishLoading(questions: loadedQuestions, options: options, fallback: false, note: nil)
        } catch {
            await loadRelaxedOrFallback(from: options)
        }
    }

    func choose(_ answer: String) {
        guard selectedAnswer == nil, let question = currentQuestion else { return }
        questionTimerCancellable?.cancel()

        selectedAnswer = answer
        if answer == question.correctAnswer {
            streak += 1
            let streakBonus = activeOptions.streakBonusEnabled ? min(streak - 1, 4) * 2 : 0
            score += 10 + streakBonus
            AudioService.shared.play(.success)
            AudioService.shared.impact(.light)
        } else {
            streak = 0
            AudioService.shared.play(.mistake)
            AudioService.shared.impact(.rigid)
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            advance()
        }
    }

    private func resetRoundState(options: QuizRushOptions) {
        questionTimerCancellable?.cancel()
        phase = .loading
        activeOptions = options
        scoreVariantID = options.variantID
        scoreVariantLabel = options.variantLabel
        sourceNote = nil
        selectedAnswer = nil
        currentIndex = 0
        score = 0
        streak = 0
        timeRemaining = options.timedQuestions ? options.secondsPerQuestion : 0
        hasRecordedCurrentRound = false
    }

    private func loadRelaxedOrFallback(from options: QuizRushOptions) async {
        if options.categoryID != nil {
            let relaxedOptions = options.withoutCategory()
            do {
                let loadedQuestions = try await triviaAPI.fetchQuestions(options: relaxedOptions)
                finishLoading(
                    questions: loadedQuestions,
                    options: relaxedOptions,
                    fallback: false,
                    note: "Category unavailable - using Any Category"
                )
                return
            } catch { }
        }

        let fallbackQuestions = TriviaAPI.fallbackQuestions(for: options)
        if fallbackQuestions.isEmpty {
            questionTimerCancellable?.cancel()
            phase = .failed("Trivia did not load.")
            return
        }

        finishLoading(
            questions: fallbackQuestions,
            options: options,
            fallback: true,
            note: "Offline question set"
        )
        scoreVariantID = "fallback:\(options.variantID)"
        scoreVariantLabel = "\(options.variantLabel) / Offline"
    }

    private func finishLoading(
        questions: [TriviaQuestion],
        options: QuizRushOptions,
        fallback: Bool,
        note: String?
    ) {
        self.questions = questions
        activeOptions = options
        scoreVariantID = options.variantID
        scoreVariantLabel = options.variantLabel
        usingFallbackQuestions = fallback
        sourceNote = note
        selectedAnswer = nil
        currentIndex = 0
        phase = .loaded
        beginQuestionTimerIfNeeded()
    }

    private func beginQuestionTimerIfNeeded() {
        questionTimerCancellable?.cancel()
        guard activeOptions.timedQuestions, phase == .loaded else {
            timeRemaining = 0
            return
        }

        timeRemaining = activeOptions.secondsPerQuestion
        questionTimerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.phase == .loaded, self.selectedAnswer == nil else { return }
                self.timeRemaining -= 1
                if self.timeRemaining <= 0 {
                    self.handleTimeout()
                }
            }
    }

    private func handleTimeout() {
        guard selectedAnswer == nil, currentQuestion != nil else { return }
        questionTimerCancellable?.cancel()
        selectedAnswer = "__timeout__"
        streak = 0
        AudioService.shared.play(.mistake)
        AudioService.shared.impact(.rigid)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            advance()
        }
    }

    private func advance() {
        questionTimerCancellable?.cancel()
        if currentIndex >= questions.count - 1 {
            phase = .finished
            selectedAnswer = nil
            timeRemaining = 0
            recordCompletionIfNeeded()
            AudioService.shared.play(.finish)
            AudioService.shared.notify(.success)
        } else {
            currentIndex += 1
            selectedAnswer = nil
            phase = .loaded
            beginQuestionTimerIfNeeded()
        }
    }

    private func recordCompletionIfNeeded() {
        guard !hasRecordedCurrentRound else { return }
        hasRecordedCurrentRound = true
        GameSessionStore.shared.addSession(
            mode: .quizRush,
            score: score,
            coordinate: LocationService.shared.currentCoordinate,
            variantID: scoreVariantID,
            variantLabel: scoreVariantLabel
        )
    }

    deinit {
        questionTimerCancellable?.cancel()
    }
}

enum QuizRushPhase: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
    case finished
}
