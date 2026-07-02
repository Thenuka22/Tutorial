import SwiftUI
import Combine
import Foundation

struct QuizRushView: View {
    @StateObject private var viewModel = QuizRushViewModel()
    @AppStorage("quizRushHighScore") private var highScore = 0

    var body: some View {
        ZStack {
            ArcadeScreenBackground()

            VStack(spacing: 18) {
                header

                switch viewModel.phase {
                case .idle, .loading:
                    loadingView
                case .failed(let message):
                    failureView(message)
                case .loaded:
                    quizContent
                case .finished:
                    resultView
                }
            }
            .padding(20)
        }
        .navigationTitle("Quiz Rush")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadIfNeeded() }
        .onChange(of: viewModel.phase) { _, phase in
            if phase == .finished {
                highScore = max(highScore, viewModel.score)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                metric("Score", value: "\(viewModel.score)", symbol: "trophy.fill")
                metric("Streak", value: "\(viewModel.streak)", symbol: "flame.fill")
            }

            HStack(spacing: 10) {
                metric("Best", value: "\(highScore)", symbol: "crown.fill")
                metric("Progress", value: viewModel.progressLabel, symbol: "list.number")
            }
        }
    }

    private func metric(_ title: String, value: String, symbol: String) -> some View {
        VStack(spacing: 5) {
            Label(title, systemImage: symbol)
                .font(.caption2.bold())
                .foregroundStyle(ArcadeTheme.mutedInk)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(ArcadeTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(ArcadeTheme.berry)
            Text("Loading trivia")
                .font(.headline)
                .foregroundStyle(ArcadeTheme.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
        .background(Color.white.opacity(0.80), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 54, weight: .black))
                .foregroundStyle(ArcadeTheme.berry)

            Text("Trivia did not load")
                .font(.title2.bold())
                .foregroundStyle(ArcadeTheme.ink)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(ArcadeTheme.mutedInk)
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.load() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(ArcadePrimaryButtonStyle(tint: ArcadeTheme.berry))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var quizContent: some View {
        VStack(spacing: 16) {
            if let question = viewModel.currentQuestion {
                ProgressView(value: Double(viewModel.currentIndex + 1), total: Double(max(viewModel.questions.count, 1)))
                    .tint(ArcadeTheme.berry)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(question.category)
                            .font(.caption.bold())
                            .foregroundStyle(ArcadeTheme.berry)
                            .lineLimit(1)
                        Spacer()
                        Text(question.difficulty.capitalized)
                            .font(.caption.bold())
                            .foregroundStyle(ArcadeTheme.mutedInk)
                    }

                    Text(question.prompt)
                        .font(.title3.bold())
                        .foregroundStyle(ArcadeTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(spacing: 10) {
                    ForEach(question.choices, id: \.self) { choice in
                        Button {
                            viewModel.choose(choice)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: answerSymbol(for: choice, question: question))
                                    .frame(width: 24)
                                Text(choice)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .foregroundStyle(answerForeground(for: choice, question: question))
                            .padding(14)
                            .background(answerBackground(for: choice, question: question), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.selectedAnswer != nil)
                    }
                }
            }
        }
        .animation(.snappy(duration: 0.22), value: viewModel.selectedAnswer)
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 58, weight: .black))
                .foregroundStyle(ArcadeTheme.mint)

            Text("Quiz Complete")
                .font(.largeTitle.bold())
                .foregroundStyle(ArcadeTheme.ink)

            Text("\(viewModel.score)")
                .font(.system(size: 68, weight: .black, design: .rounded))
                .foregroundStyle(ArcadeTheme.berry)

            Text("Best \(highScore)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(ArcadeTheme.mutedInk)

            HStack(spacing: 12) {
                Button {
                    ArcadeLeaderboardStore.shared.submit(score: viewModel.score, for: .quizRush)
                } label: {
                    Label("Save", systemImage: "trophy.fill")
                }
                .buttonStyle(ArcadeSecondaryButtonStyle())

                Button {
                    Task { await viewModel.load() }
                } label: {
                    Label("Play Again", systemImage: "play.fill")
                }
                .buttonStyle(ArcadePrimaryButtonStyle(tint: ArcadeTheme.berry))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 10)
    }

    private func answerBackground(for choice: String, question: QuizQuestion) -> Color {
        guard let selected = viewModel.selectedAnswer else { return Color.white.opacity(0.92) }
        if choice == question.correctAnswer { return ArcadeTheme.mint }
        if choice == selected { return ArcadeTheme.berry }
        return Color.white.opacity(0.70)
    }

    private func answerForeground(for choice: String, question: QuizQuestion) -> Color {
        guard viewModel.selectedAnswer != nil else { return ArcadeTheme.ink }
        if choice == question.correctAnswer || choice == viewModel.selectedAnswer { return .white }
        return ArcadeTheme.mutedInk
    }

    private func answerSymbol(for choice: String, question: QuizQuestion) -> String {
        guard let selected = viewModel.selectedAnswer else { return "circle" }
        if choice == question.correctAnswer { return "checkmark.circle.fill" }
        if choice == selected { return "xmark.circle.fill" }
        return "circle"
    }
}

@MainActor
final class QuizRushViewModel: ObservableObject {
    @Published private(set) var phase: QuizPhase = .idle
    @Published private(set) var questions: [QuizQuestion] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var score = 0
    @Published private(set) var streak = 0
    @Published private(set) var selectedAnswer: String?

    private let endpoint = URL(string: "https://opentdb.com/api.php?amount=10&type=multiple")!

    var currentQuestion: QuizQuestion? {
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

        do {
            let (data, response) = try await URLSession.shared.data(from: endpoint)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                throw QuizRushError.badResponse
            }

            let payload = try JSONDecoder().decode(TriviaPayload.self, from: data)
            let loadedQuestions = payload.results.map { $0.quizQuestion }

            guard !loadedQuestions.isEmpty else {
                throw QuizRushError.empty
            }

            questions = loadedQuestions
            phase = .loaded
        } catch {
            questions = []
            phase = .failed("Check your connection and try again.")
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
        } else {
            currentIndex += 1
            selectedAnswer = nil
            phase = .loaded
        }
    }
}

enum QuizPhase: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
    case finished
}

struct QuizQuestion: Identifiable, Equatable {
    let id = UUID()
    let category: String
    let difficulty: String
    let prompt: String
    let correctAnswer: String
    let choices: [String]
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

    var quizQuestion: QuizQuestion {
        let decodedCorrect = correctAnswer.htmlDecoded
        let decodedIncorrect = incorrectAnswers.map(\.htmlDecoded)
        return QuizQuestion(
            category: category.htmlDecoded,
            difficulty: difficulty,
            prompt: question.htmlDecoded,
            correctAnswer: decodedCorrect,
            choices: ([decodedCorrect] + decodedIncorrect).shuffled()
        )
    }
}

private enum QuizRushError: Error {
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

#Preview {
    NavigationStack { QuizRushView() }
}
