import SwiftUI

struct QuizRushView: View {
    @EnvironmentObject private var store: GameSessionStore
    @EnvironmentObject private var settings: GameSettingsStore
    @StateObject private var viewModel = QuizRushVM()
    @State private var options = QuizRushOptions()
    @State private var didLoadDefaults = false
    @State private var showCustomization = false

    var body: some View {
        ZStack {
            quizBackground

            ScrollView {
                VStack(spacing: 12) {
                    gameBar
                    board
                }
                .frame(maxWidth: 430)
                .padding(.horizontal, 12)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showCustomization) {
            customizationSheet
        }
        .task {
            loadDefaultsIfNeeded()
            LocationService.shared.refreshLocation()
            await viewModel.loadCategories()
        }
    }

    private var quizBackground: some View {
        Image(GameArt.quizBackground)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .overlay(Color.black.opacity(0.08).ignoresSafeArea())
            .accessibilityHidden(true)
    }

    private var gameBar: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(currentVariantLabel)
                    .font(PlayHubGameFont.label(13))
                    .lineLimit(1)
                Text(gameStatusLabel)
                    .font(PlayHubGameFont.label(11))
                    .foregroundStyle(QuizPalette.lime.opacity(0.82))
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if !isRoundActive {
                Button {
                    showCustomization = true
                } label: {
                    Label("Setup", systemImage: "slider.horizontal.3")
                        .font(PlayHubGameFont.label(12))
                        .padding(.horizontal, 11)
                        .frame(height: 34)
                        .background(QuizPalette.lime, in: Capsule())
                        .foregroundStyle(QuizPalette.ink)
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(QuizPalette.wood.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(QuizPalette.lime.opacity(0.38), lineWidth: 1)
        }
    }

    private var board: some View {
        QuizBoardContainer {
            switch viewModel.phase {
            case .idle:
                startContent
            case .loading:
                loadingContent
            case .failed(let message):
                failureContent(message)
            case .loaded:
                questionContent
            case .finished:
                finishedContent
            }
        }
    }

    private var startContent: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            Text("READY?")
                .font(PlayHubGameFont.display(32))
                .foregroundStyle(QuizPalette.lime)
                .gameTextShadow()

            Text(options.variantLabel)
                .font(PlayHubGameFont.label(16))
                .foregroundStyle(QuizPalette.lime.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.75)

            Button {
                Task { await viewModel.load(options: options) }
            } label: {
                Label("START QUIZ", systemImage: "play.fill")
                    .font(PlayHubGameFont.display(16))
            }
            .buttonStyle(JungleQuizButtonStyle(background: QuizPalette.lime))

            Spacer(minLength: 0)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(QuizPalette.lime)
            Text("LOADING TRIVIA")
                .font(PlayHubGameFont.display(18))
                .foregroundStyle(QuizPalette.lime)
            Spacer()
        }
    }

    private func failureContent(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(QuizPalette.lime)
            Text("TRIVIA DID NOT LOAD")
                .font(PlayHubGameFont.display(18))
                .foregroundStyle(QuizPalette.lime)
                .multilineTextAlignment(.center)
            Text(message)
                .font(PlayHubGameFont.label(13))
                .foregroundStyle(QuizPalette.lime.opacity(0.86))
                .multilineTextAlignment(.center)
                .lineLimit(3)
            Button {
                Task { await viewModel.load(options: options) }
            } label: {
                Label("TRY AGAIN", systemImage: "arrow.clockwise")
                    .font(PlayHubGameFont.display(14))
            }
            .buttonStyle(JungleQuizButtonStyle(background: QuizPalette.lime))
            Spacer()
        }
    }

    @ViewBuilder
    private var questionContent: some View {
        if let question = viewModel.currentQuestion {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("SCORE \(viewModel.score)")
                    Text("STREAK \(viewModel.streak)")
                    Spacer(minLength: 0)
                    Text(viewModel.progressLabel)
                    if options.timedQuestions || viewModel.timeRemaining > 0 {
                        Text("\(viewModel.timeRemaining)S")
                    }
                }
                .font(PlayHubGameFont.label(11))
                .foregroundStyle(QuizPalette.lime.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

                ProgressView(
                    value: Double(viewModel.currentIndex + 1),
                    total: Double(max(viewModel.questions.count, 1))
                )
                .tint(QuizPalette.lime)

                Text(question.prompt)
                    .font(PlayHubGameFont.display(20))
                    .foregroundStyle(QuizPalette.lime)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.68)
                    .frame(maxWidth: .infinity, minHeight: 64)

                VStack(spacing: 8) {
                    ForEach(question.choices.indices, id: \.self) { index in
                        let choice = question.choices[index]
                        Button {
                            viewModel.choose(choice)
                        } label: {
                            HStack(spacing: 10) {
                                Text(answerLetter(for: index))
                                    .frame(width: 24, alignment: .leading)
                                Text(choice.uppercased())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(PlayHubGameFont.label(13))
                            .lineLimit(2)
                            .minimumScaleFactor(0.70)
                        }
                        .buttonStyle(
                            JungleQuizButtonStyle(
                                background: answerColor(for: choice, question: question)
                            )
                        )
                        .opacity(answerOpacity(for: choice, question: question))
                        .disabled(viewModel.selectedAnswer != nil)
                        .accessibilityLabel("\(answerLetter(for: index)) \(choice)")
                    }
                }

                if let sourceNote = viewModel.sourceNote {
                    Text(sourceNote.uppercased())
                        .font(PlayHubGameFont.label(10))
                        .foregroundStyle(QuizPalette.lime.opacity(0.72))
                        .lineLimit(1)
                }
            }
            .animation(.snappy(duration: 0.20), value: viewModel.selectedAnswer)
        }
    }

    private var finishedContent: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)

            Text("ROUND COMPLETE")
                .font(PlayHubGameFont.display(22))
                .foregroundStyle(QuizPalette.lime)
                .multilineTextAlignment(.center)

            Text("\(viewModel.score)")
                .font(PlayHubGameFont.display(48))
                .foregroundStyle(QuizPalette.lime)
                .monospacedDigit()

            Text("BEST \(store.bestScore(for: .quizRush, variantID: viewModel.scoreVariantID))")
                .font(PlayHubGameFont.label(14))
                .foregroundStyle(QuizPalette.lime.opacity(0.86))

            Button {
                Task { await viewModel.load(options: options) }
            } label: {
                Label("PLAY AGAIN", systemImage: "play.fill")
                    .font(PlayHubGameFont.display(14))
            }
            .buttonStyle(JungleQuizButtonStyle(background: QuizPalette.lime))

            ShareLink(item: shareText) {
                Label("SHARE SCORE", systemImage: "square.and.arrow.up")
                    .font(PlayHubGameFont.display(13))
            }
            .buttonStyle(JungleQuizButtonStyle(background: QuizPalette.sand))

            Spacer(minLength: 0)
        }
    }

    private var customizationSheet: some View {
        NavigationStack {
            Form {
                Section("Quiz Setup") {
                    Picker("Questions", selection: questionCountBinding) {
                        ForEach(GameSettingsStore.allowedQuestionCounts, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }

                    Picker("Difficulty", selection: difficultyBinding) {
                        ForEach(QuizDifficulty.allCases) { difficulty in
                            Text(difficulty.displayName).tag(difficulty)
                        }
                    }

                    Picker("Category", selection: categoryBinding) {
                        ForEach(availableCategories) { category in
                            Text(category.name).tag(category.id)
                        }
                    }

                    Toggle("Timed Questions", isOn: timedQuestionsBinding)

                    if options.timedQuestions {
                        Stepper("Time \(options.secondsPerQuestion)s", value: secondsPerQuestionBinding, in: 5...30, step: 5)
                    }

                    Toggle("Streak Bonus", isOn: streakBonusBinding)
                }
            }
            .navigationTitle("Quiz Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showCustomization = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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

    private var currentVariantLabel: String {
        switch viewModel.phase {
        case .loaded, .finished:
            return viewModel.scoreVariantLabel
        default:
            return options.variantLabel
        }
    }

    private var gameStatusLabel: String {
        switch viewModel.phase {
        case .idle: return "READY TO PLAY"
        case .loading: return "LOADING"
        case .loaded: return "QUESTION \(viewModel.progressLabel)"
        case .failed: return "OFFLINE"
        case .finished: return "SCORE \(viewModel.score)"
        }
    }

    private var shareText: String {
        "I scored \(viewModel.score) in Quiz Rush - \(viewModel.scoreVariantLabel)"
    }

    private var questionCountBinding: Binding<Int> {
        Binding(
            get: { options.questionCount },
            set: { options.questionCount = $0 }
        )
    }

    private var difficultyBinding: Binding<QuizDifficulty> {
        Binding(
            get: { options.difficulty },
            set: { options.difficulty = $0 }
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
            set: { options.timedQuestions = $0 }
        )
    }

    private var secondsPerQuestionBinding: Binding<Int> {
        Binding(
            get: { options.secondsPerQuestion },
            set: { options.secondsPerQuestion = $0 }
        )
    }

    private var streakBonusBinding: Binding<Bool> {
        Binding(
            get: { options.streakBonusEnabled },
            set: { options.streakBonusEnabled = $0 }
        )
    }

    private func loadDefaultsIfNeeded() {
        guard !didLoadDefaults else { return }
        didLoadDefaults = true
        options = settings.defaultQuizOptions
    }

    private func answerLetter(for index: Int) -> String {
        let letters = ["A.", "B.", "C.", "D."]
        return letters.indices.contains(index) ? letters[index] : ""
    }

    private func answerColor(for choice: String, question: TriviaQuestion) -> Color {
        guard let selected = viewModel.selectedAnswer else { return QuizPalette.lime }
        if choice == question.correctAnswer { return QuizPalette.correct }
        if choice == selected { return QuizPalette.wrong }
        return QuizPalette.sand
    }

    private func answerOpacity(for choice: String, question: TriviaQuestion) -> Double {
        guard let selected = viewModel.selectedAnswer else { return 1 }
        return choice == question.correctAnswer || choice == selected ? 1 : 0.48
    }
}

private struct QuizBoardContainer<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Color.clear
            .aspectRatio(9.0 / 16.0, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    ZStack {
                        Image(GameArt.quizBoard)
                            .resizable()
                            .aspectRatio(9.0 / 16.0, contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityHidden(true)

                        content
                            .frame(
                                width: proxy.size.width * 0.68,
                                height: proxy.size.height * 0.58,
                                alignment: .top
                            )
                            .position(
                                x: proxy.size.width * 0.50,
                                y: proxy.size.height * 0.58
                            )
                    }
                }
            }
    }
}

private struct JungleQuizButtonStyle: ButtonStyle {
    let background: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(QuizPalette.ink)
            .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                background.opacity(configuration.isPressed ? 0.78 : 1),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(QuizPalette.ink.opacity(0.24), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }
}

private enum QuizPalette {
    static let lime = Color(red: 0.82, green: 0.93, blue: 0.39)
    static let sand = Color(red: 0.92, green: 0.82, blue: 0.49)
    static let ink = Color(red: 0.28, green: 0.12, blue: 0.03)
    static let wood = Color(red: 0.26, green: 0.12, blue: 0.04)
    static let correct = Color(red: 0.48, green: 0.82, blue: 0.28)
    static let wrong = Color(red: 0.94, green: 0.47, blue: 0.20)
}

#Preview {
    NavigationStack { QuizRushView() }
        .environmentObject(GameSessionStore.shared)
        .environmentObject(GameSettingsStore.shared)
}
