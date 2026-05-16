# Phase 02 — Design System Tokens

## Context Links
- Parent: [plan.md](./plan.md)
- Deps: phase-01
- Mockups: ALL `Product UI/*/screen.png` + `code.html` (extract palette, type scale, spacing from Tailwind classes)
- Key references: `anti_noise_minimal_wordmark/code.html`, `anti_noise_landing_page_updated_hero/code.html`

## Overview
- Date: 2026-05-16
- Description: Build SwiftUI design tokens (color, type, spacing, motion) + base components (Button, Card, TextField, TabBar, EmptyState) mirroring Tailwind mockups.
- Priority: P0 (blocks all UI phases)
- Implementation status: pending
- Review status: pending
- Effort: 2d

## Key Insights
- "Anti-noise" aesthetic = high whitespace, single accent, minimal chrome. Resist gradient/shadow temptation.
- Tailwind classes in `code.html` files are authoritative palette source — extract exact hex values.
- SwiftUI `@ScaledMetric` for font sizes ensures Dynamic Type support out-of-box.

## Requirements
**Functional**
- Token enums for color, typography, spacing, radius, animation.
- Base components: PrimaryButton, SecondaryButton, GhostButton, Card, InputField, Chip, EmptyState, LoadingIndicator, BottomTabBar.
- Light + dark mode both supported (auto via `Color(.systemBackground)` semantics + custom assets).

**Non-functional**
- All text supports Dynamic Type.
- Min tap target 44pt.
- Animation defaults: 0.25s ease-in-out.

## Architecture
```
Core/DesignSystem/
├── Tokens/
│   ├── AppColor.swift            (enum + Color extension)
│   ├── AppFont.swift             (enum + Font extension, @ScaledMetric helpers)
│   ├── AppSpacing.swift          (CGFloat constants)
│   ├── AppRadius.swift
│   └── AppMotion.swift
├── Components/
│   ├── PrimaryButton.swift
│   ├── SecondaryButton.swift
│   ├── GhostButton.swift
│   ├── AppCard.swift
│   ├── AppTextField.swift
│   ├── Chip.swift
│   ├── AppEmptyState.swift
│   ├── AppLoadingIndicator.swift
│   └── BottomTabBar.swift
└── Previews/
    └── DesignSystemPreview.swift (gallery for visual QA)
```

## Related Code Files (to create)
- `AntiNoise/Core/DesignSystem/Tokens/AppColor.swift`
- `AntiNoise/Core/DesignSystem/Tokens/AppFont.swift`
- `AntiNoise/Core/DesignSystem/Tokens/AppSpacing.swift`
- `AntiNoise/Core/DesignSystem/Tokens/AppRadius.swift`
- `AntiNoise/Core/DesignSystem/Tokens/AppMotion.swift`
- `AntiNoise/Core/DesignSystem/Components/PrimaryButton.swift`
- `AntiNoise/Core/DesignSystem/Components/SecondaryButton.swift`
- `AntiNoise/Core/DesignSystem/Components/GhostButton.swift`
- `AntiNoise/Core/DesignSystem/Components/AppCard.swift`
- `AntiNoise/Core/DesignSystem/Components/AppTextField.swift`
- `AntiNoise/Core/DesignSystem/Components/Chip.swift`
- `AntiNoise/Core/DesignSystem/Components/AppEmptyState.swift`
- `AntiNoise/Core/DesignSystem/Components/AppLoadingIndicator.swift`
- `AntiNoise/Core/DesignSystem/Components/BottomTabBar.swift`
- `AntiNoise/Core/DesignSystem/Previews/DesignSystemPreview.swift`
- Color assets in `AntiNoise/Resources/Assets.xcassets/Colors/`

## Implementation Steps
1. Open each mockup `code.html` → list unique Tailwind color classes (e.g., `bg-stone-950`, `text-amber-400`).
2. Map to color assets (light + dark variants).
3. Define `AppColor` enum with cases: `bgPrimary, bgSecondary, surface, textPrimary, textSecondary, textMuted, accent, accentMuted, border, danger, success`.
4. Define `AppFont` scale: `display, h1, h2, h3, body, bodySmall, caption, mono` mapped to `.system(size:, weight:, design:)` with `@ScaledMetric`.
5. Define `AppSpacing`: `xxs=2, xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48`.
6. Define `AppRadius`: `sm=6, md=10, lg=16, pill=999`.
7. Define `AppMotion`: `quick=.easeOut(0.15)`, `standard=.easeInOut(0.25)`, `slow=.easeInOut(0.4)`.
8. Build each component with `#Preview` block.
9. Build `DesignSystemPreview.swift` gallery (TabView of all components).
10. Visual QA against mockup PNGs side-by-side.

## Todo
- [ ] Color tokens + asset catalog
- [ ] Type scale with Dynamic Type
- [ ] Spacing + radius + motion constants
- [ ] PrimaryButton
- [ ] SecondaryButton
- [ ] GhostButton
- [ ] AppCard
- [ ] AppTextField
- [ ] Chip
- [ ] AppEmptyState
- [ ] AppLoadingIndicator
- [ ] BottomTabBar
- [ ] Gallery preview compiles
- [ ] Visual QA vs mockups

## Success Criteria
- Gallery preview renders every component in light + dark.
- Tapping a `PrimaryButton` triggers a 0.25s scale animation.
- Dynamic Type up to AX3 does not break layout.

## Risk Assessment
- **R1**: Tailwind color palette drift across mockups. → Pick canonical palette from landing page + wordmark; doc deltas in `DesignSystemPreview.swift` comments.
- **R2**: Over-engineering tokens. → Start with the 11 colors / 8 fonts / 8 spacings above; expand only when a screen demands it.

## Security Considerations
- N/A (presentation layer only).

## Next Steps
- Phase 04 (tab navigation shell) consumes BottomTabBar.
- Phase 03 (auth) consumes PrimaryButton + AppTextField.
