import Foundation

/// Daily Knowledge topic packs the user picks during onboarding. Distinct from
/// `ClassificationScope` (personal/work/business) — these drive daily-article
/// curation. The subreddit mapping lives backend-side (the Worker owns the
/// Reddit fetch), so this enum stays display-only on iOS.
enum TopicPack: String, CaseIterable, Codable, Sendable, Identifiable {
    case aiml
    case engineering
    case productDesign
    case startup
    case productivity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aiml:          return "AI / ML"
        case .engineering:   return "Engineering"
        case .productDesign: return "Product / Design"
        case .startup:       return "Startup"
        case .productivity:  return "Productivity"
        }
    }

    var emoji: String {
        switch self {
        case .aiml:          return "🧠"
        case .engineering:   return "🛠"
        case .productDesign: return "🎨"
        case .startup:       return "🚀"
        case .productivity:  return "⏱"
        }
    }

    var subtitle: String {
        switch self {
        case .aiml:          return "Machine learning, LLMs, research."
        case .engineering:   return "Programming, web, systems."
        case .productDesign: return "UX, product management."
        case .startup:       return "Founders, SaaS, growth."
        case .productivity:  return "Focus, habits, getting things done."
        }
    }

    /// Max packs a user may select (keeps the rank prompt focused + cheap).
    static let maxSelectable = 3
}
