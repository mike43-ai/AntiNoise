import SwiftUI

enum AppColor: String {
    case bgPrimary       = "BgPrimary"
    case bgSecondary     = "BgSecondary"
    case surface         = "Surface"
    case surfaceElevated = "SurfaceElevated"
    case textPrimary     = "TextPrimary"
    case textSecondary   = "TextSecondary"
    case textMuted       = "TextMuted"
    case textDisabled    = "TextDisabled"
    case accent          = "Accent"
    case accentMuted     = "AccentMuted"
    case accentStrong    = "AccentStrong"
    case border          = "Border"
    case danger          = "Danger"
    case warning         = "Warning"
    case success         = "Success"

    var color: Color { Color(rawValue, bundle: .main) }
}

// `appBorder` (not `.border`) avoids collision with SwiftUI's `View.border(_:)` modifier.
extension Color {
    static let bgPrimary       = AppColor.bgPrimary.color
    static let bgSecondary     = AppColor.bgSecondary.color
    static let surface         = AppColor.surface.color
    static let surfaceElevated = AppColor.surfaceElevated.color
    static let textPrimary     = AppColor.textPrimary.color
    static let textSecondary   = AppColor.textSecondary.color
    static let textMuted       = AppColor.textMuted.color
    static let textDisabled    = AppColor.textDisabled.color
    static let accent          = AppColor.accent.color
    static let accentMuted     = AppColor.accentMuted.color
    static let accentStrong    = AppColor.accentStrong.color
    static let appBorder       = AppColor.border.color
    static let danger          = AppColor.danger.color
    static let warning         = AppColor.warning.color
    static let success         = AppColor.success.color
}
