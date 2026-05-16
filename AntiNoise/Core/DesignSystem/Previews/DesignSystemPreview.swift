import SwiftUI

// Internal-only gallery to visually QA every component in both light + dark.
// Keep wrapped in DEBUG so it doesn't ship in release builds.
#if DEBUG
struct DesignSystemPreview: View {
    @State private var sampleEmail = "you@email.com"
    @State private var samplePass = ""
    @State private var selectedTab: AppTab = .home

    var body: some View {
        NavigationStack {
            TabView {
                ColorsSection()
                    .tabItem { Label("Color", systemImage: "paintpalette") }
                TypographySection()
                    .tabItem { Label("Type", systemImage: "textformat") }
                buttonsSection
                    .tabItem { Label("Buttons", systemImage: "rectangle.and.hand.point.up.left") }
                inputsSection
                    .tabItem { Label("Inputs", systemImage: "character.cursor.ibeam") }
                surfacesSection
                    .tabItem { Label("Surfaces", systemImage: "square.stack.3d.up") }
                stateSection
                    .tabItem { Label("State", systemImage: "ellipsis.circle") }
            }
            .navigationTitle("Design System")
        }
    }

    private var buttonsSection: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                PrimaryButton(title: "Primary") {}
                PrimaryButton(title: "Loading", isLoading: true) {}
                SecondaryButton(title: "Secondary") {}
                SecondaryButton(title: "Secondary with icon", systemImage: "envelope") {}
                HStack {
                    GhostButton(title: "Ghost") {}
                    GhostButton(title: "Danger ghost", tint: .danger) {}
                }
                Divider().padding(.vertical, AppSpacing.sm)
                HStack {
                    Chip(title: "Personal")
                    Chip(title: "Work", isSelected: true)
                    Chip(title: "AI", variant: .accent, isSelected: true)
                }
            }
            .padding()
        }
        .background(Color.bgPrimary)
    }

    private var inputsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            AppTextField(label: "Email", text: $sampleEmail, systemImage: "envelope", keyboard: .emailAddress, autocapitalization: .never)
            AppTextField(label: "Password", text: $samplePass, placeholder: "••••••••", systemImage: "lock", isSecure: true)
            AppTextField(label: "With error", text: .constant("huy"), errorMessage: "Must be at least 4 characters")
            Spacer()
        }
        .padding()
        .background(Color.bgPrimary)
    }

    private var surfacesSection: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Flat Card").appFont(.h3)
                        Text("Default surface, 1pt border.").appFont(.bodySmall).foregroundStyle(Color.textMuted)
                    }
                }
                AppCard(style: .elevated) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Elevated Card").appFont(.h3)
                        Text("Offset shadow, no border.").appFont(.bodySmall).foregroundStyle(Color.textMuted)
                    }
                }
                AppCard(style: .outline) {
                    Text("Outline Card").appFont(.body)
                }
            }
            .padding()
        }
        .background(Color.bgPrimary)
    }

    private var stateSection: some View {
        VStack(spacing: AppSpacing.xl) {
            AppLoadingIndicator()
            AppEmptyState(
                systemImage: "tray",
                title: "Nothing here yet",
                message: "Capture something to fill this space.",
                actionTitle: "Capture",
                action: {}
            )
            BottomTabBar(selection: $selectedTab)
        }
        .padding(.top, AppSpacing.xl)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.bgPrimary)
    }
}

private struct ColorsSection: View {
    private let swatches: [(String, Color)] = [
        ("Bg Primary", .bgPrimary),
        ("Bg Secondary", .bgSecondary),
        ("Surface", .surface),
        ("Surface Elevated", .surfaceElevated),
        ("Text Primary", .textPrimary),
        ("Text Secondary", .textSecondary),
        ("Text Muted", .textMuted),
        ("Accent", .accent),
        ("Accent Muted", .accentMuted),
        ("Border", .appBorder),
        ("Danger", .danger),
        ("Success", .success),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.sm) {
                ForEach(swatches, id: \.0) { name, color in
                    HStack(spacing: AppSpacing.md) {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(color)
                            .frame(width: 56, height: 40)
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.sm).stroke(Color.appBorder, lineWidth: 1))
                        Text(name).appFont(.body)
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .background(Color.bgPrimary)
    }
}

private struct TypographySection: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Display").scaledAppFont(.display)
                Text("Heading 1").scaledAppFont(.h1)
                Text("Heading 2").scaledAppFont(.h2)
                Text("Heading 3").scaledAppFont(.h3)
                Text("Body — the lazy quick brown fox jumps over the dog.").scaledAppFont(.body)
                Text("Body small — secondary explanatory text.").scaledAppFont(.bodySmall).foregroundStyle(Color.textMuted)
                Text("Caption label").scaledAppFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)
                Text("Mono 14").scaledAppFont(.mono)
            }
            .foregroundStyle(Color.textPrimary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.bgPrimary)
    }
}

#Preview("Light") {
    DesignSystemPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DesignSystemPreview()
        .preferredColorScheme(.dark)
}
#endif
