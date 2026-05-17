import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation

// Single entry point for product analytics + non-fatal logging. Honors
// PrivacyConsentStore — `track` is a no-op when analytics consent is off,
// `record(error:)` is a no-op when crashlytics consent is off. Idempotent
// to bootstrap before Firebase is configured: calls are still typesafe but
// don't reach the SDK.
enum Telemetry {
    private static var consentProvider: () -> (analytics: Bool, crashlytics: Bool) = { (true, true) }

    @MainActor
    static func attach(_ store: PrivacyConsentStore) {
        consentProvider = { (store.isAnalyticsEnabled, store.isCrashlyticsEnabled) }
    }

    static func track(_ event: TelemetryEvent) {
        guard consentProvider().analytics else { return }
        Analytics.logEvent(event.name, parameters: event.params)
    }

    static func setUserID(_ uid: String?) {
        guard consentProvider().analytics else { return }
        Analytics.setUserID(uid)
        if let uid {
            Crashlytics.crashlytics().setUserID(uid)
        }
    }

    static func record(error: Error, context: [String: Any] = [:]) {
        guard consentProvider().crashlytics else { return }
        Crashlytics.crashlytics().record(error: error, userInfo: context)
    }
}
