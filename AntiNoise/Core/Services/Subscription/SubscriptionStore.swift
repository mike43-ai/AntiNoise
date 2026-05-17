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
        self.isPro = active

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
    }
}
