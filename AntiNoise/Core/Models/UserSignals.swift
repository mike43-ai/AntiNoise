import Foundation

// Optional ranking signals for the daily-article ranker. Not required at
// onboarding (kept lean to avoid activation drop-off) — the user can set them
// later in Profile → "Improve your feed". Mirrored to Firestore users/{uid} so
// the backend ranker can read them; absence is handled with a generic fallback.

enum UserRole: String, CaseIterable, Codable, Sendable, Identifiable {
    case engineer, pm, designer, founder, student, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .engineer: return "Engineer"
        case .pm:       return "Product Manager"
        case .designer: return "Designer"
        case .founder:  return "Founder"
        case .student:  return "Student"
        case .other:    return "Other"
        }
    }
}

enum ExperienceLevel: String, CaseIterable, Codable, Sendable, Identifiable {
    case starting, building, senior
    var id: String { rawValue }
    var title: String {
        switch self {
        case .starting: return "Just starting (0–2y)"
        case .building: return "Building up (2–5y)"
        case .senior:   return "Senior (5+y)"
        }
    }
}

enum UserGoal: String, CaseIterable, Codable, Sendable, Identifiable {
    case learnSkills, stayCurrent, inspiration, decisions
    var id: String { rawValue }
    var title: String {
        switch self {
        case .learnSkills: return "Learn new skills"
        case .stayCurrent: return "Stay current"
        case .inspiration: return "Get inspiration"
        case .decisions:   return "Make better decisions"
        }
    }
}
