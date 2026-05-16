import SwiftData
import SwiftUI

struct FocusSetupView: View {
    let onStart: (_ duration: Int, _ kind: FocusTargetKind, _ id: UUID?, _ label: String?) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var model: FocusSetupModel?

    var body: some View {
        Group {
            if let model {
                content(model: model)
            } else {
                AppLoadingIndicator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .task {
            if model == nil {
                model = FocusSetupModel(modelContext: modelContext)
            }
            model?.loadDecks()
        }
    }

    @ViewBuilder
    private func content(model: FocusSetupModel) -> some View {
        @Bindable var bound = model

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Focus")
                        .appFont(.h1)
                    Text("Pick a duration. Optionally tie this session to a flash-card deck.")
                        .appFont(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                }

                durationSection(bound: bound)
                deckSection(bound: bound)

                Spacer(minLength: AppSpacing.xl)

                PrimaryButton(title: "Start session") {
                    onStart(
                        bound.resolvedDurationSeconds,
                        bound.resolvedTargetKind,
                        bound.resolvedTargetID,
                        bound.resolvedTargetLabel
                    )
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxxl)
        }
    }

    private func durationSection(bound: FocusSetupModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Duration").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)

            HStack(spacing: AppSpacing.sm) {
                ForEach(FocusSetupModel.defaultDurationsMinutes, id: \.self) { mins in
                    durationChip(mins: mins, isSelected: !bound.useCustom && bound.durationMinutes == mins) {
                        bound.useCustom = false
                        bound.durationMinutes = mins
                    }
                }
                durationChip(mins: nil, isSelected: bound.useCustom) {
                    bound.useCustom = true
                }
            }

            if bound.useCustom {
                Stepper(
                    value: $bound.customMinutes,
                    in: 1...180,
                    step: 5
                ) {
                    Text("\(bound.customMinutes) min").appFont(.body)
                }
                .padding(AppSpacing.md)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
        }
    }

    private func durationChip(mins: Int?, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(mins.map { "\($0) min" } ?? "Custom")
                .appFont(.bodySmall)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? .white : Color.textPrimary)
                .padding(.horizontal, AppSpacing.lg)
                .frame(minHeight: 44)
                .background(isSelected ? Color.textPrimary : Color.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.textPrimary : Color.appBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func deckSection(bound: FocusSetupModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Optional: link a deck").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)

            if bound.decks.isEmpty {
                AppCard(style: .outline) {
                    Text("No decks yet — create one from a summary's Deep dive.")
                        .appFont(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                }
            } else {
                VStack(spacing: AppSpacing.xs) {
                    deckRow(title: "No deck", isSelected: bound.pickedDeckID == nil) {
                        bound.pickedDeckID = nil
                        bound.pickedDeckTitle = nil
                    }
                    ForEach(bound.decks) { deck in
                        deckRow(title: deck.title, isSelected: bound.pickedDeckID == deck.id) {
                            bound.pickedDeckID = deck.id
                            bound.pickedDeckTitle = deck.title
                        }
                    }
                }
            }
        }
    }

    private func deckRow(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack {
                Text(title).appFont(.body).foregroundStyle(Color.textPrimary).lineLimit(1)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accent : Color.textMuted)
            }
            .padding(AppSpacing.md)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(isSelected ? Color.accent : Color.appBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
