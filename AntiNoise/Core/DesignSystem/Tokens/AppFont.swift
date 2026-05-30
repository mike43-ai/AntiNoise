import SwiftUI

// Type scale mirrors Tailwind mockup spec.
// Display/headings/body render in Space Grotesk (4 static faces registered under the
// shared family name, so `.fontWeight(...)` resolves to the matching face). The `.mono`
// token stays on the system monospaced face — Space Grotesk has no monospaced cut.
// `.fontWeight(...)` calls after `.appFont(.x)` override the token weight — by design.
enum AppFont {
    case display
    case h1
    case h2
    case h3
    case body
    case bodySmall
    case caption
    case mono

    var size: CGFloat {
        switch self {
        case .display:   return 48
        case .h1:        return 32
        case .h2:        return 24
        case .h3:        return 20
        case .body:      return 16
        case .bodySmall: return 14
        case .caption:   return 12
        case .mono:      return 14
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display:   return .bold
        case .h1, .h2, .h3: return .semibold
        case .body, .bodySmall: return .regular
        case .caption:   return .medium
        case .mono:      return .regular
        }
    }

    var design: Font.Design {
        self == .mono ? .monospaced : .default
    }

    // Additive line spacing on top of system leading. Small, additive — not multiplier.
    var lineSpacing: CGFloat {
        switch self {
        case .display, .h1: return 2
        case .h2, .h3:      return 1
        case .body, .bodySmall: return 2
        case .caption:      return 0
        case .mono:         return 1
        }
    }

    var tracking: CGFloat {
        switch self {
        case .display:   return -0.5
        case .h1:        return -0.25
        case .caption:   return 1.0
        default:         return 0
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .display:   return .largeTitle
        case .h1:        return .title
        case .h2:        return .title2
        case .h3:        return .title3
        case .body:      return .body
        case .bodySmall: return .callout
        case .caption:   return .caption
        case .mono:      return .body
        }
    }
}

// Dynamic Type-aware modifier. All app text should use this — `appFont` is an alias.
struct ScaledAppFont: ViewModifier {
    static let brandFamily = "Space Grotesk"

    let style: AppFont
    @ScaledMetric private var scaledSize: CGFloat

    init(_ style: AppFont) {
        self.style = style
        _scaledSize = ScaledMetric(wrappedValue: style.size, relativeTo: style.textStyle)
    }

    func body(content: Content) -> some View {
        content
            .font(resolvedFont)
            .fontWeight(style.weight)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
    }

    // Size is pre-scaled via ScaledMetric, so the fixed-size `.custom` keeps Dynamic Type
    // behaviour without double-scaling. Falls back to the system face if the family is absent.
    private var resolvedFont: Font {
        if style.design == .monospaced {
            return .system(size: scaledSize, weight: style.weight, design: .monospaced)
        }
        return .custom(Self.brandFamily, size: scaledSize)
    }
}

extension View {
    func appFont(_ style: AppFont) -> some View {
        modifier(ScaledAppFont(style))
    }

    // Kept for parity with earlier API surface; identical to `appFont`.
    func scaledAppFont(_ style: AppFont) -> some View {
        modifier(ScaledAppFont(style))
    }
}
