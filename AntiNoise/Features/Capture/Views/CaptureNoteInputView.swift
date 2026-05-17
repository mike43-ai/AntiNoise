import SwiftUI

struct CaptureNoteInputView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Quick note")
                .appFont(.caption)
                .textCase(.uppercase)
                .foregroundStyle(Color.textMuted)

            TextEditor(text: $text)
                .appFont(.body)
                .foregroundStyle(Color.textPrimary)
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .padding(AppSpacing.sm)
                .frame(minHeight: 160)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(isFocused ? Color.accent : Color.appBorder, lineWidth: isFocused ? 2 : 1)
                )
                .animation(AppMotion.quick, value: isFocused)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Capture an idea, a quote, a thought to chew on later…")
                            .appFont(.body)
                            .foregroundStyle(Color.textMuted)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.md)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}

private struct CaptureNoteInputViewPreview: View {
    @State private var text = ""

    var body: some View {
        CaptureNoteInputView(text: $text)
            .padding()
            .background(Color.bgPrimary)
    }
}

#Preview {
    CaptureNoteInputViewPreview()
}
