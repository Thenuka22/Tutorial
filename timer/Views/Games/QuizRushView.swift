import SwiftUI

struct QuizRushView: View {
    @EnvironmentObject private var store: GameSessionStore
    @StateObject private var viewModel = QuizRushVM()

    var body: some View {
        ZStack {
            PlayHubScreenBackground()

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
        .task {
            LocationService.shared.refreshLocation()
            await viewModel.loadIfNeeded()
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ScoreBadge(title: "Score", value: "\(viewModel.score)", symbol: "trophy.fill", tint: PlayHubTheme.berry)
                ScoreBadge(title: "Streak", value: "\(viewModel.streak)", symbol: "flame.fill", tint: PlayHubTheme.orange)
            }

            HStack(spacing: 10) {
                ScoreBadge(title: "Best", value: "\(store.bestScore(for: .quizRush))", symbol: "crown.fill", tint: PlayHubTheme.gold)
                ScoreBadge(title: "Progress", value: viewModel.progressLabel, symbol: "list.number", tint: PlayHubTheme.sky)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(PlayHubTheme.berry)
            Text("Loading trivia")
                .font(.headline)
                .foregroundStyle(PlayHubTheme.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
        .background(Color.white.opacity(0.80), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 54, weight: .black))
                .foregroundStyle(PlayHubTheme.berry)

            Text("Trivia did not load")
                .font(.title2.bold())
                .foregroundStyle(PlayHubTheme.ink)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(PlayHubTheme.mutedInk)
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.load() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(PlayHubPrimaryButtonStyle(tint: PlayHubTheme.berry))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var quizContent: some View {
        VStack(spacing: 16) {
            if viewModel.usingFallbackQuestions {
                Label("Offline question set", systemImage: "wifi.slash")
                    .font(.caption.bold())
                    .foregroundStyle(PlayHubTheme.mutedInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.86), in: Capsule())
            }

            if let question = viewModel.currentQuestion {
                ProgressView(value: Double(viewModel.currentIndex + 1), total: Double(max(viewModel.questions.count, 1)))
                    .tint(PlayHubTheme.berry)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(question.category)
                            .font(.caption.bold())
                            .foregroundStyle(PlayHubTheme.berry)
                            .lineLimit(1)
                        Spacer()
                        Text(question.difficulty.capitalized)
                            .font(.caption.bold())
                            .foregroundStyle(PlayHubTheme.mutedInk)
                    }

                    Text(question.prompt)
                        .font(.title3.bold())
                        .foregroundStyle(PlayHubTheme.ink)
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
        ResultView(
            mode: .quizRush,
            score: viewModel.score,
            bestScore: store.bestScore(for: .quizRush),
            onPlayAgain: {
                Task { await viewModel.load() }
            }
        )
    }

    private func answerBackground(for choice: String, question: TriviaQuestion) -> Color {
        guard let selected = viewModel.selectedAnswer else { return Color.white.opacity(0.92) }
        if choice == question.correctAnswer { return PlayHubTheme.mint }
        if choice == selected { return PlayHubTheme.berry }
        return Color.white.opacity(0.70)
    }

    private func answerForeground(for choice: String, question: TriviaQuestion) -> Color {
        guard viewModel.selectedAnswer != nil else { return PlayHubTheme.ink }
        if choice == question.correctAnswer || choice == viewModel.selectedAnswer { return .white }
        return PlayHubTheme.mutedInk
    }

    private func answerSymbol(for choice: String, question: TriviaQuestion) -> String {
        guard let selected = viewModel.selectedAnswer else { return "circle" }
        if choice == question.correctAnswer { return "checkmark.circle.fill" }
        if choice == selected { return "xmark.circle.fill" }
        return "circle"
    }
}

#Preview {
    NavigationStack { QuizRushView() }
        .environmentObject(GameSessionStore.shared)
}
