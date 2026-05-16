import SwiftUI

struct AppLoadingIndicator: View {
    var size: CGFloat = 32
    var lineWidth: CGFloat = 3
    var tint: Color = .accent

    @State private var isSpinning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                    isSpinning = true
                }
            }
            .accessibilityLabel("Loading")
            .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    HStack(spacing: AppSpacing.xl) {
        AppLoadingIndicator(size: 24)
        AppLoadingIndicator(size: 32)
        AppLoadingIndicator(size: 48, tint: .textPrimary)
    }
    .padding()
    .background(Color.bgPrimary)
}
