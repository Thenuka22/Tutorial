import SwiftUI

struct QuizRushView: View {
    @EnvironmentObject private var store: GameSessionStore
    @EnvironmentObject private var settings: GameSettingsStore
    @StateObject private var viewModel = QuizRushVM()
    @State private var options = QuizRushOptions()
    @State private var didLoadDefaults = false

    var body: some View {
        ZStack {
            PlayHubScreenBackground()

            ScrollView {
                VStack(spacing: 18) {
                    customizePanel
                    header

                    switch viewModel.phase {
                    case .idle:
                        startView
                    case .loading:
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
        }
        .navigationTitle("Quiz Rush")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadDefaultsIfNeeded()
            LocationService.shared.refreshLocation()
            await viewModel.loadCategories()
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ScoreBadge(title: "Score", value: "\(viewModel.score)", symbol: "trophy.fill", tint: PlayHubTheme.berry)
                ScoreBadge(title: "Streak", value: "\(viewModel.streak)", symbol: "flame.fill", tint: PlayHubTheme.orange)
            }

            HStack(spacing: 10) {
                ScoreBadge(title: "Best", value: "\(store.bestScore(for: .quizRush, variantID: currentVariantID))", symbol: "crown.fill", tint: PlayHubTheme.gold)
                ScoreBadge(title: "Progress", value: viewModel.progressLabel, symbol: "list.number", tint: PlayHubTheme.sky)
            }

            if options.timedQuestions || viewModel.timeRemaining > 0 {
                ScoreBadge(title: "Timer", value: viewModel.timeRemaining > 0 ? "\(viewModel.timeRemaining)s" : "\(options.secondsPerQuestion)s", symbol: "timer", tint: PlayHubTheme.mint)
            }
        }
    }

    private var customizePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Customize", systemImage: "slider.horizontal.3")
                    .font(.headline.bold())
                    .foregroundStyle(PlayHubTheme.ink)
                Spacer()
                Text(currentVariantLabel)
                    .font(.caption.bold())
                    .foregroundStyle(PlayHubTheme.mutedInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }

            Picker("Questions", selection: questionCountBinding) {
                ForEach(GameSettingsStore.allowedQuestionCounts, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }
            .pickerStyle(.segmented)

            Picker("Difficulty", selection: difficultyBinding) {
                ForEach(QuizDifficulty.allCases) { difficulty in
                    Text(difficulty.displayName).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)

            Picker("Category", selection: categoryBinding) {
                ForEach(availableCategories) { category in
                    Text(category.name).tag(category.id)
                }
            }
            .pickerStyle(.menu)

            Toggle("Timed Questions", isOn: timedQuestionsBinding)
                .tint(PlayHubTheme.mint)

            if options.timedQuestions {
                Stepper("Time \(options.secondsPerQuestion)s", value: secondsPerQuestionBinding, in: 5...30, step: 5)
            }

            Toggle("Streak Bonus", isOn: streakBonusBinding)
                .tint(PlayHubTheme.orange)
        }
        .font(.subheadline)
        .padding(14)
        .background(PlayHubPanelBackground())
        .disabled(isRoundActive)
        .opacity(isRoundActive ? 0.68 : 1)
    }

    private var startView: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.bubble.fill")
                .font(.system(size: 54, weight: .black))
                .foregroundStyle(PlayHubTheme.berry)

            Text("Ready for \(options.variantLabel)")
                .font(.title2.bold())
                .foregroundStyle(PlayHubTheme.ink)
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.load(options: options) }
            } label: {
                Label("Start Quiz", systemImage: "play.fill")
            }
            .buttonStyle(PlayHubPrimaryButtonStyle(tint: PlayHubTheme.berry))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(PlayHubPanelBackground())
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
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(PlayHubPanelBackground())
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
                Task { await viewModel.load(options: options) }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(PlayHubPrimaryButtonStyle(tint: PlayHubTheme.berry))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(PlayHubPanelBackground())
    }

    private var quizContent: some View {
        VStack(spacing: 16) {
            if let sourceNote = viewModel.sourceNote {
                Label(sourceNote, systemImage: viewModel.usingFallbackQuestions ? "wifi.slash" : "line.3.horizontal.decrease.circle")
                    .font(.caption.bold())
                    .foregroundStyle(PlayHubTheme.mutedInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.86), in: Capsule())
            }

            Label(viewModel.activeFilterLabel, systemImage: "tag.fill")
                .font(.caption.bold())
                .foregroundStyle(PlayHubTheme.berry)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.86), in: Capsule())

            if let question = viewModel.currentQuestion {
                GameArtProgressBar(value: Double(viewModel.currentIndex + 1), total: Double(max(viewModel.questions.count, 1)))

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
                .background(PlayHubPanelBackground())

                VStack(spacing: 10) {
                    ForEach(question.choices, id: \.self) { choice in
                        Button {
                            viewModel.choose(choice)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: answerSymbol(for: choice, question: question))
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.title3.weight(.semibold))
                                    .frame(width: 28, height: 28, alignment: .center)
                                Text(choice)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(
                                answerTint(for: choice, question: question),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                            .opacity(answerOpacity(for: choice, question: question))
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
            bestScore: store.bestScore(for: .quizRush, variantID: viewModel.scoreVariantID),
            variantLabel: viewModel.scoreVariantLabel,
            onPlayAgain: {
                Task { await viewModel.load(options: options) }
            }
        )
    }

    private var availableCategories: [TriviaCategory] {
        var categories = viewModel.categories
        if let selectedID = options.categoryID,
           !categories.contains(where: { $0.id == selectedID }) {
            categories.append(TriviaCategory(id: selectedID, name: options.categoryName))
        }
        return categories
    }

    private var isRoundActive: Bool {
        viewModel.phase == .loading || viewModel.phase == .loaded
    }

    private var currentVariantID: String {
        switch viewModel.phase {
        case .loaded, .finished:
            return viewModel.scoreVariantID
        default:
            return options.variantID
        }
    }

    private var currentVariantLabel: String {
        switch viewModel.phase {
        case .loaded, .finished:
            return viewModel.scoreVariantLabel
        default:
            return options.variantLabel
        }
    }

    private var questionCountBinding: Binding<Int> {
        Binding(
            get: { options.questionCount },
            set: { value in options.questionCount = value }
        )
    }

    private var difficultyBinding: Binding<QuizDifficulty> {
        Binding(
            get: { options.difficulty },
            set: { value in options.difficulty = value }
        )
    }

    private var categoryBinding: Binding<Int> {
        Binding(
            get: { options.categoryID ?? TriviaCategory.anyID },
            set: { selectedID in
                if selectedID == TriviaCategory.anyID {
                    options.categoryID = nil
                    options.categoryName = TriviaCategory.any.name
                    return
                }

                guard let category = availableCategories.first(where: { $0.id == selectedID }) else { return }
                options.categoryID = category.id
                options.categoryName = category.name
            }
        )
    }

    private var timedQuestionsBinding: Binding<Bool> {
        Binding(
            get: { options.timedQuestions },
            set: { value in options.timedQuestions = value }
        )
    }

    private var secondsPerQuestionBinding: Binding<Int> {
        Binding(
            get: { options.secondsPerQuestion },
            set: { value in options.secondsPerQuestion = value }
        )
    }

    private var streakBonusBinding: Binding<Bool> {
        Binding(
            get: { options.streakBonusEnabled },
            set: { value in options.streakBonusEnabled = value }
        )
    }

    private func loadDefaultsIfNeeded() {
        guard !didLoadDefaults else { return }
        didLoadDefaults = true
        options = settings.defaultQuizOptions
    }

    private func answerTint(for choice: String, question: TriviaQuestion) -> Color {
        guard let selected = viewModel.selectedAnswer else { return PlayHubTheme.berry }
        if choice == question.correctAnswer { return PlayHubTheme.mint }
        if choice == selected { return PlayHubTheme.berry }
        return PlayHubTheme.sky
    }

    private func answerOpacity(for choice: String, question: TriviaQuestion) -> Double {
        guard let selected = viewModel.selectedAnswer else { return 1 }
        return choice == question.correctAnswer || choice == selected ? 1 : 0.45
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
        .environmentObject(GameSettingsStore.shared)
}
