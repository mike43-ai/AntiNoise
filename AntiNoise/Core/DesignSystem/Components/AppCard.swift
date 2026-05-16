import SwiftUI

struct AppCard<Content: View>: View {
    enum Style { case flat, elevated, outline }

    var style: Style = .flat
    var padding: CGFloat = AppSpacing.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(borderOverlay)
            .shadow(color: shadowColor, radius: 0, x: 0, y: shadowOffsetY)
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .flat:     Color.surface
        case .elevated: Color.surface
        case .outline:  Color.bgPrimary
        }
    }

    // Always render a 1pt border — dark-mode 5%-black offset shadow is below perceptible.
    @ViewBuilder private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            .stroke(Color.appBorder, lineWidth: 1)
    }

    private var shadowColor: Color {
        style == .elevated ? Color.black.opacity(0.05) : .clear
    }

    private var shadowOffsetY: CGFloat {
        style == .elevated ? 4 : 0
    }
}

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.md) {
            AppCard {
                Text("Flat card — bordered, no shadow")
                    .appFont(.body)
            }
            AppCard(style: .elevated) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Elevated card")
                        .appFont(.h3)
                    Text("Offset shadow, no border — kinetic style.")
                        .appFont(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                }
            }
            AppCard(style: .outline) {
                Text("Outline card — same bg as parent")
                    .appFont(.body)
            }
        }
        .padding()
    }
    .background(Color.bgPrimary)
}
