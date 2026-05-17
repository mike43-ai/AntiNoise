import SwiftUI

@MainActor
struct PrivacyConsentRow: View {
    @Environment(PrivacyConsentStore.self) private var consent

    var body: some View {
        @Bindable var bound = consent
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Toggle(isOn: $bound.isAnalyticsEnabled) {
                    rowLabel(
                        title: "Share product analytics",
                        subtitle: "Anonymous usage helps us see which features matter. No third-party trackers."
                    )
                }
                .tint(Color.accent)
                Divider().background(Color.appBorder)
                Toggle(isOn: $bound.isCrashlyticsEnabled) {
                    rowLabel(
                        title: "Share crash reports",
                        subtitle: "Lets us know when something breaks so we can fix it."
                    )
                }
                .tint(Color.accent)
            }
        }
    }

    private func rowLabel(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).appFont(.body)
            Text(subtitle).appFont(.caption).foregroundStyle(Color.textMuted)
        }
    }
}
