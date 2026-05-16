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

#Preview {
    @Previewable @State var text = ""
    CaptureUrlInputView(text: $text)
        .padding()
        .background(Color.bgPrimary)
}
