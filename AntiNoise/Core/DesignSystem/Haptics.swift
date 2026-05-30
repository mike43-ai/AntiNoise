import UIKit

/// Imperative haptic helpers for use inside tap/gesture closures.
/// Respects the system Haptics setting automatically (UIKit no-ops when disabled).
enum Haptics {
    /// Light tap — buttons, chip selection, card flip.
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// Success / warning / error — graded answers, completion moments, failures.
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    /// Discrete value change — swipe crossing a commit threshold.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
