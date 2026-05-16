import SwiftUI

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var fullWidth: Bool = true
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .scaledAppFont(.bodySmall)
            .fontWeight(.semibold)
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 44)
            .padding(.horizontal, AppSpacing.lg)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(AppMotion.standard, value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        SecondaryButton(title: "Skip for now") {}
        SecondaryButton(title: "Continue with Email", systemImage: "envelope") {}
        SecondaryButton(title: "Compact", fullWidth: false) {}
    }
    .padding()
    .background(Color.bgPrimary)
}
