import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Anti Noise")
                .font(.largeTitle.weight(.semibold))
            Text("Cut the Noise — Focus on What Matters")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    RootView()
}
