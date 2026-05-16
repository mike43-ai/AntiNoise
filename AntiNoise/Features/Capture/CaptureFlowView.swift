import SwiftUI

// Modal capture flow — entry point for adding new content to the system.
// Phase 05 implements URL/text/image intake + AI summary handoff.
struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                AppEmptyState(
                    systemImage: "plus.circle",
                    title: "Capture",
                    message: "Paste a link, drop a screenshot, or write a thought.\nPhase 05 wires the real intake."
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .tint(Color.textPrimary)
                }
            }
        }
    }
}

#Preview {
    CaptureFlowView()
}
