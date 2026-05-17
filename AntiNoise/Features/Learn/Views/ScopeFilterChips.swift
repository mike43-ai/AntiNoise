import SwiftUI

struct ScopeFilterChips: View {
    @Binding var selection: ClassificationScope?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                chip(title: "All", isSelected: selection == nil) { selection = nil }
                ForEach(ClassificationScope.allCases, id: \.self) { scope in
                    chip(title: shortTitle(scope), isSelected: selection == scope) {
                        selection = (selection == scope) ? nil : scope
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
        }
    }

    private func chip(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(title)
                .appFont(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(isSelected ? .white : Color.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(isSelected ? Color.textPrimary : Color.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.textPrimary : Color.appBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func shortTitle(_ scope: ClassificationScope) -> String {
        switch scope {
        case .personal: return "Personal"
        case .work:     return "Work"
        case .business: return "Business"
        }
    }
}

private struct ScopeFilterChipsPreview: View {
    @State private var sel: ClassificationScope? = nil

    var body: some View {
        ScopeFilterChips(selection: $sel)
            .padding(.vertical)
            .background(Color.bgPrimary)
    }
}

#Preview {
    ScopeFilterChipsPreview()
}
