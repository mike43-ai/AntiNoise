import SwiftUI

struct CaptureUrlInputView: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppTextField(
                label: "Paste a link",
                text: $text,
                placeholder: "https://...",
                systemImage: "link",
                keyboard: .URL,
                autocapitalization: .never
            )
            Text("Tip: share from Safari, X, Reddit — anywhere with a URL.")
                .appFont(.caption)
                .foregroundStyle(Color.textMuted)
        }
    }
}

private struct CaptureUrlInputViewPreview: View {
    @State private var text = ""

    var body: some View {
        CaptureUrlInputView(text: $text)
            .padding()
            .background(Color.bgPrimary)
    }
}

#Preview {
    CaptureUrlInputViewPreview()
}
