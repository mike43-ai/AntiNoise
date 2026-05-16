import UIKit
import Social
import UniformTypeIdentifiers

// Phase-01 stub. Real payload extraction (URL/text/image) lands in Phase 05.
// Do NOT submit to App Store until Phase 06 — Apple rejects non-functional extensions.
final class ShareViewController: SLComposeServiceViewController {
    override func isContentValid() -> Bool { true }

    override func didSelectPost() {
        let appGroupID = "group.com.antinoise.shared"
        if let defaults = UserDefaults(suiteName: appGroupID) {
            defaults.set(Date(), forKey: "lastSharePayloadAt")
        }
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! { [] }
}
