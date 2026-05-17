import SwiftUI

struct AppTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var systemImage: String? = nil
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .appFont(.caption)
                .textCase(.uppercase)
                .foregroundStyle(Color.textMuted)

            HStack(spacing: AppSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(Color.textMuted)
                }

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .appFont(.body)
                .foregroundStyle(Color.textPrimary)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(isSecure)
                .focused($isFocused)
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 48)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .animation(AppMotion.quick, value: isFocused)

            if let errorMessage {
                Text(errorMessage)
                    .appFont(.caption)
                    .foregroundStyle(Color.danger)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return .danger }
        return isFocused ? .accent : .appBorder
    }
}

private struct AppTextFieldPreview: View {
    @State private var email = ""
    @State private var pass = ""
    @State private var withError = "huy"

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            AppTextField(label: "Email", text: $email, placeholder: "you@email.com", systemImage: "envelope", keyboard: .emailAddress, autocapitalization: .never)
            AppTextField(label: "Password", text: $pass, placeholder: "••••••••", systemImage: "lock", isSecure: true)
            AppTextField(label: "Display Name", text: $withError, errorMessage: "Must be at least 4 characters")
        }
        .padding()
        .background(Color.bgPrimary)
    }
}

#Preview {
    AppTextFieldPreview()
}
