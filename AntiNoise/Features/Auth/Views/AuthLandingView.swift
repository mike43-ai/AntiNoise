import AuthenticationServices
import SwiftUI

@MainActor
struct AuthLandingView: View {
    @Environment(AuthStore.self) private var auth
    @State private var isAppleLoading = false
    @State private var error: AuthError?
    @State private var appeared = false

    let onEmailTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            brandBar
                .padding(.top, AppSpacing.sm)

            Spacer(minLength: AppSpacing.xl)

            VStack(spacing: AppSpacing.md) {
                Text("Cut the noise.\nFocus on what matters.")
                    .appFont(.display)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textPrimary)

                Text("Save anything. Anti Noise turns it into summaries and flash cards you'll actually remember.")
                    .appFont(.bodySmall)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, AppSpacing.md)
            }
            .padding(.horizontal, AppSpacing.lg)

            heroWave
                .padding(.vertical, AppSpacing.lg)

            featureChips

            Spacer(minLength: AppSpacing.xl)

            authActions
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary.ignoresSafeArea())
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .alert("Sign in failed", isPresented: errorBinding, presenting: error) { _ in
            Button("OK", role: .cancel) { error = nil }
        } message: { err in
            Text(err.localizedDescription)
        }
    }

    private var brandBar: some View {
        HStack(spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(Color.accent)
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                )
            Text("ANTI NOISE")
                .appFont(.bodySmall)
                .fontWeight(.bold)
                .tracking(3)
                .foregroundStyle(Color.textPrimary)
        }
    }

    // Warm radial glow sits behind the signal wave to give the hero some depth.
    private var heroWave: some View {
        NoiseToSignalWave(height: 124)
            .padding(.horizontal, AppSpacing.xl)
            .background(
                RadialGradient(
                    colors: [Color.accent.opacity(0.18), .clear],
                    center: .center, startRadius: 4, endRadius: 190
                )
                .blur(radius: 8)
            )
    }

    private var featureChips: some View {
        HStack(spacing: AppSpacing.sm) {
            Chip(title: "Summaries", systemImage: "sparkles")
            Chip(title: "Flash cards", systemImage: "rectangle.stack")
            Chip(title: "Daily learning", systemImage: "bolt.fill")
        }
    }

    private var authActions: some View {
        VStack(spacing: AppSpacing.md) {
            emailButton
            appleButton
            Text("By continuing you agree to our Terms & Privacy.")
                .appFont(.caption)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, AppSpacing.xs)
        }
    }

    // Primary CTA — warm gradient with a soft accent glow, the screen's visual focal point.
    private var emailButton: some View {
        Button {
            Haptics.tap(.medium)
            onEmailTap()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Continue with Email")
                    .appFont(.bodySmall)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                LinearGradient(
                    colors: [Color.accent, Color.accentStrong],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .shadow(color: Color.accent.opacity(0.35), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var appleButton: some View {
        Button {
            Haptics.tap(.medium)
            Task { await runAppleSignIn() }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if isAppleLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .medium))
                }
                Text("Continue with Apple")
                    .appFont(.bodySmall)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, AppSpacing.lg)
            .background(Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isAppleLoading)
    }

    @MainActor
    private func runAppleSignIn() async {
        isAppleLoading = true
        defer { isAppleLoading = false }
        do {
            try await auth.signInWithApple()
        } catch let err as AuthError {
            // Don't surface a "cancelled" alert — user just dismissed the sheet.
            if case .appleCancelled = err { return }
            error = err
        } catch {
            self.error = AuthError(error)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { error != nil }, set: { if !$0 { error = nil } })
    }
}

#Preview {
    AuthLandingView(onEmailTap: {})
        .environment(AuthStore())
}
