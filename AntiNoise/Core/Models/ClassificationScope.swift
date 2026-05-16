import Foundation

// Three growth scopes locked at plan-time (decision #?, in `plan.md`):
// personal / work / business. Used in two places:
//
// 1. Onboarding (Phase 03): user selects which scopes matter — fuels the
//    daily priority engine in Phase 07.
// 2. AI summary (Phase 06): GPT-4o tags every capture with its best-fit
//    scope so the priority engine knows what to surface.
//
// Same enum, same raw values, same cases — keeping them aligned simplifies
// the priority engine's set-intersection logic.
enum ClassificationScope: String, CaseIterable, Codable, Sendable {
    case personal
    case work
    case business

    var title: String {
        switch self {
        case .personal: return "Personal development"
        case .work:     return "Work performance"
        case .business: return "Business growth"
        }
    }

    var subtitle: String {
        switch self {
        case .personal: return "Health, learning, relationships."
        case .work:     return "Career skills and craft."
        case .business: return "Founder ideas, products, sales."
        }
    }

    var systemImage: String {
        switch self {
        case .personal: return "leaf"
        case .work:     return "briefcase"
        case .business: return "chart.line.uptrend.xyaxis"
        }
    }
}

// Phase 03 still references `GrowthScope`. Keep both names working.
typealias GrowthScope = ClassificationScope
