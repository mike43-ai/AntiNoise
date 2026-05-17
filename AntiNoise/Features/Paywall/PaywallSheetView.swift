import RevenueCat
import RevenueCatUI
import SwiftUI

// Thin wrapper around RevenueCatUI's prebuilt PaywallView. Skips designing
// a custom paywall for the MVP. Dismissal is owned by the parent sheet.
@MainActor
struct PaywallSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionStore.self) private var subscription
    let offering: Offering?

    var body: some View {
        Group {
            if let offering {
                PaywallView(offering: offering)
            } else {
                // Fall through to the default offering when no specific one is passed.
                PaywallView()
            }
        }
        .onPurchaseCompleted { _ in
            Task { await subscription.refreshCustomerInfo() }
            dismiss()
        }
        .onRestoreCompleted { _ in
            Task { await subscription.refreshCustomerInfo() }
        }
    }
}
