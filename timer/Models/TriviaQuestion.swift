import Foundation

struct TriviaQuestion: Identifiable, Equatable {
    let id = UUID()
    let category: String
    let difficulty: String
    let prompt: String
    let correctAnswer: String
    let choices: [String]
}
