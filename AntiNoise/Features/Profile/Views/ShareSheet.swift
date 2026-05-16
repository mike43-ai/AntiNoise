import SwiftUI
import UIKit

// UIActivityViewController bridge for SwiftUI. Used by export + delete flows
// to hand the JSON file to whatever destination the user picks.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context: Context) {}
}

// `.sheet(item:)` needs Identifiable; wrap the items array. Shared by Profile
// export + DeleteAccount flow.
struct ShareItemsBox: Identifiable {
    let id = UUID()
    let items: [Any]
}
