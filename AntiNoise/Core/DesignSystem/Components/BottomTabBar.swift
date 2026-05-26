import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case home, learn, capture, focus, profile

    var title: String {
        switch self {
        case .home:    return "Home"
        case .learn:   return "Learn"
        case .capture: return "Capture"
        case .focus:   return "Focus"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home:    return "house"
        case .learn:   return "book"
        case .capture: return "plus.circle.fill"
        case .focus:   return "timer"
        case .profile: return "person.crop.circle"
        }
    }

    var isCenterAction: Bool { self == .capture }
}

struct BottomTabBar: View {
    @Binding var selection: AppTab

    // Height of the bar's tappable content, excluding the home-indicator safe
    // area (scroll views already inset for that). Scrollable tab roots add this
    // as bottom content margin so their last rows stay reachable above the bar —
    // a `safeAreaInset` on MainTabView does not cross into each tab's own
    // NavigationStack, so the inset must be applied inside the scroll content.
    static let contentHeight: CGFloat = 44 + AppSpacing.xs * 2

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                BottomTabButton(
                    tab: tab,
                    isSelected: selection == tab,
                    action: { selection = tab }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Color.surface
                .overlay(Color.appBorder.frame(height: 1), alignment: .top)
                // Extend the bar fill through the bottom safe area (home indicator
                // strip) so scroll content never shows through beneath the buttons.
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct BottomTabButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: tab.isCenterAction ? 28 : 22, weight: tab.isCenterAction ? .semibold : .regular))
                    .foregroundStyle(tab.isCenterAction ? Color.accent : (isSelected ? Color.textPrimary : Color.textMuted))
                if !tab.isCenterAction {
                    Text(tab.title)
                        .appFont(.caption)
                        .foregroundStyle(isSelected ? Color.textPrimary : Color.textMuted)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }
}

private struct BottomTabBarPreview: View {
    @State private var sel: AppTab = .home

    var body: some View {
        VStack {
            Spacer()
            BottomTabBar(selection: $sel)
        }
        .background(Color.bgPrimary)
    }
}

#Preview {
    BottomTabBarPreview()
}
