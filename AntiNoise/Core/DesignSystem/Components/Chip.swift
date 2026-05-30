import SwiftUI

struct Chip: View {
    enum Variant { case neutral, accent, success, danger }

    let title: String
    var systemImage: String? = nil
    var variant: Variant = .neutral
    var isSelected: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        let label = HStack(spacing: AppSpacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(title)
                .appFont(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(background)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(borderColor, lineWidth: 1)
        )

        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }

    private var foreground: Color {
        switch variant {
        case .neutral: return isSelected ? .white : .textPrimary
        // `accentStrong` is a darkened orange that clears AA 4.5:1 on white for the
        // 12pt uppercase label — the brand `accent` only reaches ~3.3:1 at this size.
        case .accent:  return isSelected ? .white : .accentStrong
        case .success: return isSelected ? .white : .success
        case .danger:  return isSelected ? .white : .danger
        }
    }

    private var background: Color {
        switch variant {
        case .neutral: return isSelected ? .textPrimary : .surface
        case .accent:  return isSelected ? .accentStrong : .surface
        case .success: return isSelected ? .success : .surface
        case .danger:  return isSelected ? .danger : .surface
        }
    }

    private var borderColor: Color {
        switch variant {
        case .neutral: return isSelected ? .textPrimary : .appBorder
        case .accent:  return .accentStrong
        case .success: return .success
        case .danger:  return .danger
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: AppSpacing.md) {
        HStack {
            Chip(title: "Personal")
            Chip(title: "Work", isSelected: true)
            Chip(title: "Business", systemImage: "briefcase")
        }
        HStack {
            Chip(title: "AI", variant: .accent)
            Chip(title: "AI", variant: .accent, isSelected: true)
            Chip(title: "Done", variant: .success, isSelected: true)
            Chip(title: "Failed", variant: .danger)
        }
    }
    .padding()
    .background(Color.bgPrimary)
}
