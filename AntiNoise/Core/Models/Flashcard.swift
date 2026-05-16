import Foundation
import SwiftData

@Model
final class Flashcard {
    @Attribute(.unique) var id: UUID
    var deckID: UUID
    var question: String
    var answer: String
    var hint: String?
    var difficulty: Int
    var createdAt: Date

    // SM-2 fields
    var easeFactor: Double
    var intervalDays: Int
    var repetitions: Int
    var nextReviewAt: Date
    var lastGrade: Int?

    init(
        id: UUID = UUID(),
        deckID: UUID,
        question: String,
        answer: String,
        hint: String? = nil,
        difficulty: Int = 3,
        createdAt: Date = Date(),
        easeFactor: Double = SM2Constants.defaultEaseFactor,
        intervalDays: Int = 0,
        repetitions: Int = 0,
        nextReviewAt: Date = Date(),
        lastGrade: Int? = nil
    ) {
        self.id = id
        self.deckID = deckID
        self.question = question
        self.answer = answer
        self.hint = hint
        self.difficulty = difficulty
        self.createdAt = createdAt
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.repetitions = repetitions
        self.nextReviewAt = nextReviewAt
        self.lastGrade = lastGrade
    }
}
