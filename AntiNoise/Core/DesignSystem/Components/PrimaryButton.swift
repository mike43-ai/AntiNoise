import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var fullWidth: Bool = true
    let action: () -> Void

    @State private var isPressed = false

    private var isInactive: Bool { isLoading || isDisabled }

    var body: some View {
        Button(action: { Haptics.tap(.medium); action() }) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    if let systemImage {
                        Image(systemName: systemImage)
                    }
                    Text(title)
                }
            }
            .appFont(.bodySmall)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 44)
            .padding(.horizontal, AppSpacing.lg)
            .background(isDisabled ? Color.textDisabled : Color.accent)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isLoading ? 0.85 : 1.0)
            .animation(AppMotion.quick, value: isPressed)
        }
        .disabled(isInactive)
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            guard !isInactive else { return }
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        PrimaryButton(title: "Continue") {}
        PrimaryButton(title: "Sign in with Apple", systemImage: "apple.logo") {}
        PrimaryButton(title: "Loading", isLoading: true) {}
        PrimaryButton(title: "Disabled", isDisabled: true) {}
        PrimaryButton(title: "Compact", fullWidth: false) {}
    }
    .padding()
    .background(Color.bgPrimary)
}
