import FirebaseAuth
import Foundation
import Observation
import RevenueCat

@Observable
@MainActor
final class SubscriptionStore {
    enum TrialState: Equatable {
        case notStarted
        case active(endsAt: Date)
        case expired
        case converted
    }

    static let proEntitlementID = "pro"

    private(set) var isPro: Bool = false
    private(set) var trialState: TrialState = .notStarted
    private(set) var currentOffering: Offering?

    /// Public-readable RevenueCat API key. SET BEFORE SHIPPING:
    /// drop the real value into Bundle Info.plist key `RCAppPublicKey` so
    /// the binary stays clean. We fall back to an empty string in dev.
    private static var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "RCAppPublicKey") as? String) ?? ""
    }

    func bootstrap() {
        guard !Self.apiKey.isEmpty else {
            #if DEBUG
            print("[AntiNoise] RCAppPublicKey missing — RevenueCat disabled. Add it to Info.plist before shipping.")
            #endif
            return
        }
        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: Self.apiKey)
        observeCustomerInfo()
        Task { await refreshOffering() }
    }

    func signedIn(uid: String) async {
        guard Purchases.isConfigured else { return }
        do {
            let result = try await Purchases.shared.logIn(uid)
            apply(customerInfo: result.customerInfo)
        } catch {
            #if DEBUG
            print("[AntiNoise] RC logIn failed: \(error)")
            #endif
        }
    }

    func signedOut() async {
        guard Purchases.isConfigured else { return }
        do {
            let info = try await Purchases.shared.logOut()
            apply(customerInfo: info)
        } catch {
            // Anonymous already — RC throws if not aliased. Ignore.
        }
    }

    func refreshCustomerInfo() async {
        guard Purchases.isConfigured else { return }
        if let info = try? await Purchases.shared.customerInfo() {
            apply(customerInfo: info)
        }
    }

    func restorePurchases() async {
        guard Purchases.isConfigured else { return }
        if let info = try? await Purchases.shared.restorePurchases() {
            apply(customerInfo: info)
        }
    }

    private func refreshOffering() async {
        guard Purchases.isConfigured else { return }
        if let offerings = try? await Purchases.shared.offerings() {
            currentOffering = offerings.current
        }
    }

    private func observeCustomerInfo() {
        Task {
            for await info in Purchases.shared.customerInfoStream {
                await MainActor.run { self.apply(customerInfo: info) }
            }
        }
    }

    private func apply(customerInfo info: CustomerInfo) {
        let entitlement = info.entitlements[Self.proEntitlementID]
        let active = entitlement?.isActive == true
        let priorIsPro = self.isPro
        self.isPro = active

        // Pro state flipped — the RC webhook should have written a new `tier`
        // custom claim on the Firebase user by now. Force-refresh the ID token
        // so the next backend call carries the server-signed tier instead of
        // the legacy client-attached header.
        if active != priorIsPro {
            Task.detached(priority: .utility) {
                _ = try? await Auth.auth().currentUser?.getIDTokenResult(forcingRefresh: true)
            }
        }

        if let entitlement, active {
            switch entitlement.periodType {
            case .trial:
                if let endsAt = entitlement.expirationDate {
                    trialState = .active(endsAt: endsAt)
                } else {
                    trialState = .notStarted
                }
            case .intro, .normal, .prepaid:
                trialState = .converted
            @unknown default:
                trialState = .converted
            }
        } else if let entitlement, !active {
            trialState = entitlement.periodType == .trial ? .expired : .notStarted
        } else {
            trialState = .notStarted
        }

        emitTransitions(productID: entitlement?.productIdentifier, uid: Purchases.shared.appUserID)
    }

    // Telemetry edge-detection backed by UserDefaults so cold launches after
    // a previous emission don't inflate `trial_started` / `subscription_started`.
    // Keyed by RC's appUserId (post-alias = Firebase UID; pre-alias = anonymous RC ID).
    private func emitTransitions(productID: String?, uid: String) {
        let proKey = "subscription.lastEmittedIsPro.\(uid)"
        let trialKey = "subscription.lastEmittedTrialState.\(uid)"
        let defaults = UserDefaults.standard
        let lastPro = defaults.object(forKey: proKey) as? Bool
        let lastTrialRaw = defaults.string(forKey: trialKey)

        if isPro, lastPro != true, let productID {
            Telemetry.track(.subscriptionStarted(productID: productID))
        }
        let trialRaw = Self.trialStateRawValue(trialState)
        if case .active = trialState, lastTrialRaw != trialRaw, lastTrialRaw != "active" {
            Telemetry.track(.trialStarted)
        }
        if trialState == .expired, lastTrialRaw != "expired" {
            Telemetry.track(.trialExpired)
        }

        defaults.set(isPro, forKey: proKey)
        defaults.set(trialRaw, forKey: trialKey)
    }

    private static func trialStateRawValue(_ state: TrialState) -> String {
        switch state {
        case .notStarted: return "notStarted"
        case .active:     return "active"
        case .expired:    return "expired"
        case .converted:  return "converted"
        }
    }
}
