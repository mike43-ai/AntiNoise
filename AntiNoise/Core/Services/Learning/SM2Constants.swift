import Foundation

// Locked at plan time. See phase-08 spec.
enum SM2Constants {
    static let defaultEaseFactor:  Double = 2.5
    static let minEaseFactor:      Double = 1.3
    static let firstIntervalDays:  Int = 1
    static let secondIntervalDays: Int = 6
    static let maxCardsPerDeck:    Int = 15
    static let minCardsPerDeck:    Int = 3
}
