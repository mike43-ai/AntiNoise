import Social
import UIKit
import UniformTypeIdentifiers

// Drops the extension UI almost entirely — we just persist the payload and
// dismiss. Apple-style "saving…" toast is implicit because the extension
// closes within ~1s and the user is back in the source app.
final class ShareViewController: SLComposeServiceViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.isEditable = false
        textView.text = "Saving to Anti Noise…"
        placeholder = "Anti Noise"
        Task { @MainActor in await persistAndExit() }
    }

    // We want the post action invisible — the user sees zero UI between tap
    // and dismiss. But SLComposeServiceViewController requires us to allow
    // post for the bar button to be tappable; we hide it via empty config items.
    override func isContentValid() -> Bool { false }
    override func configurationItems() -> [Any]! { [] }
    override func didSelectPost() { /* unused — auto-persist path */ }

    @MainActor
    private func persistAndExit() async {
        let payloads = await ShareItemExtractor.extractAll(from: extensionContext)
        for payload in payloads {
            do {
                try SharedQueueStore.enqueue(payload)
            } catch {
                NSLog("[AntiNoiseShareExtension] enqueue failed: %@", "\(error)")
            }
        }
        SharedQueueStore.postUpdateNotification()
        // Brief visual ack before dismiss so the user knows it worked.
        try? await Task.sleep(for: .milliseconds(300))
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
