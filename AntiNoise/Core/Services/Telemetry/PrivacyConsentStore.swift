import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation
import Observation

// Opt-out analytics + crash reporting. Defaults to ON because Apple permits
// it when disclosed in the privacy nutrition label and our event list is
// product-only (no third-party trackers, no advertising IDs). User can flip
// the toggle in Profile → Privacy.
@Observable
@MainActor
final class PrivacyConsentStore {
    private static let analyticsKey = "privacy.analyticsEnabled"
    private static let crashlyticsKey = "privacy.crashlyticsEnabled"

    var isAnalyticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAnalyticsEnabled, forKey: Self.analyticsKey)
            Analytics.setAnalyticsCollectionEnabled(isAnalyticsEnabled)
        }
    }

    var isCrashlyticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCrashlyticsEnabled, forKey: Self.crashlyticsKey)
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(isCrashlyticsEnabled)
        }
    }

    init() {
        let defaults = UserDefaults.standard
        // Treat absent keys as opted-in (matches Apple's opt-out model and
        // the LOCKED plan decision).
        self.isAnalyticsEnabled = defaults.object(forKey: Self.analyticsKey) as? Bool ?? true
        self.isCrashlyticsEnabled = defaults.object(forKey: Self.crashlyticsKey) as? Bool ?? true
    }

    func apply() {
        Analytics.setAnalyticsCollectionEnabled(isAnalyticsEnabled)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(isCrashlyticsEnabled)
    }
}
