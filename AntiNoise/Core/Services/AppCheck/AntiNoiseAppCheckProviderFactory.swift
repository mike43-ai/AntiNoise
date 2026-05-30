import FirebaseAppCheck
import FirebaseCore
import Foundation

/// Supplies the App Check attestation provider used to prove requests originate
/// from a genuine, unmodified build of the app.
///
/// - Release: App Attest — hardware-backed, available on every device the app
///   ships to (deployment target is iOS 17, well above App Attest's iOS 14 floor).
/// - DEBUG: the debug provider, so simulators and dev devices work once their
///   printed debug token is registered in Firebase Console → App Check.
///
/// Must be installed via `AppCheck.setAppCheckProviderFactory(_:)` BEFORE
/// `FirebaseApp.configure()`.
final class AntiNoiseAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        return AppCheckDebugProvider(app: app)
        #else
        return AppAttestProvider(app: app)
        #endif
    }
}
