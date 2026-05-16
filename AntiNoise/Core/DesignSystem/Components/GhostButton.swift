import SwiftUI

struct GhostButton: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = .accent
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .scaledAppFont(.bodySmall)
            .fontWeight(.semibold)
            .foregroundStyle(tint)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.7 : 1.0)
            .animation(AppMotion.quick, value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        GhostButton(title: "Forgot password?") {}
        GhostButton(title: "See all", systemImage: "chevron.right") {}
        GhostButton(title: "Delete account", tint: .danger) {}
    }
    .padding()
    .background(Color.bgPrimary)
}
