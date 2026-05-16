# Phase 04 — Tab Navigation Shell (5 Tabs)

## Context Links
- Parent: [plan.md](./plan.md)
- Deps: phase-02 (BottomTabBar), phase-03 (auth gate)
- Mockups: all `Product UI/*/screen.png` show bottom tab bar variants; canonical: `simplified_learn_hub_anti_noise`, `focus_session_setup_anti_noise`, `professional_profile_progress`

## Overview
- Date: 2026-05-16
- Description: Build `MainTabView` with 5 tabs (Home, Learn, Capture, Focus, Profile). Each tab is a placeholder screen filled in later phases. Capture tab is a center "+" action that opens a modal sheet, not a normal tab.
- Priority: P0
- Implementation status: completed (2026-05-16)
- Review status: approved with fixes
- Effort: 1d

## Key Insights
- Capture as center FAB-style tab (modal sheet on tap) is common in productivity apps; differentiates from pull-to-add. Mockups support this layout (refined_quick_capture_flow opens modally).
- SwiftUI `TabView` w/ `.tabItem` is fine, but custom `BottomTabBar` (from phase-02) gives full styling control.
- Each tab owns its own `NavigationStack` for independent back stacks.

## Requirements
**Functional**
- 5 tabs visible only when signed in.
- Tap Home/Learn/Focus/Profile → switches tab.
- Tap Capture (center) → presents `CaptureFlowView` as `.sheet`.
- Deep-link entry points reserved (URL scheme) — wired but stubbed.

**Non-functional**
- Tab switch < 100ms (no async load on switch).
- Capture sheet dismissible via swipe-down.

## Architecture
```
Features/
├── Home/HomeRootView.swift             (placeholder)
├── Learn/LearnRootView.swift           (placeholder)
├── Capture/CaptureFlowView.swift       (placeholder)
├── Focus/FocusRootView.swift           (placeholder)
└── Profile/ProfileRootView.swift       (placeholder)
App/MainTabView.swift                   (custom tab bar + sheet)
App/AppRouter.swift                     (@Observable for cross-tab nav)
```

## Related Code Files (to create)
- `AntiNoise/App/MainTabView.swift`
- `AntiNoise/App/AppRouter.swift`
- `AntiNoise/Features/Home/HomeRootView.swift`
- `AntiNoise/Features/Learn/LearnRootView.swift`
- `AntiNoise/Features/Capture/CaptureFlowView.swift`
- `AntiNoise/Features/Focus/FocusRootView.swift`
- `AntiNoise/Features/Profile/ProfileRootView.swift`

## Implementation Steps
1. Define `enum AppTab: CaseIterable { home, learn, capture, focus, profile }`.
2. `AppRouter` holds `selectedTab: AppTab`, `isCaptureSheetPresented: Bool`.
3. `MainTabView` renders 5-icon bottom bar (using `BottomTabBar` from phase-02).
4. Tapping `capture` → toggles `isCaptureSheetPresented = true`, does NOT change `selectedTab`.
5. Each tab wraps content in its own `NavigationStack`.
6. Placeholder views: title + `AppEmptyState("Coming soon")`.
7. `RootView`: if `authStore.state == .signedIn` → `MainTabView`, else → `AuthLandingView`.
8. QA on iPhone SE (smallest) and iPhone 15 Pro Max (largest).

## Todo
- [x] AppTab enum (already in Phase 02 BottomTabBar)
- [x] AppRouter observable (@Observable @MainActor; selectedTab + isCaptureSheetPresented)
- [x] MainTabView with `.safeAreaInset(edge: .bottom)` (per R1) hosting BottomTabBar
- [x] Capture sheet presentation wired (.presentationDetents([.medium, .large]) per R2)
- [x] 5 placeholder root views (Home/Learn/Focus/Profile own NavigationStack; Capture is a modal)
- [x] RootView gated by auth (signed-in + onboarding-complete → MainTabView)
- [~] Layout verified on SE + Pro Max — deferred (no simulator runtime)

## Notes (implementation)
- `selectTab(.capture)` opens the sheet without mutating `selectedTab`, so the bar never momentarily highlights Capture.
- AppRouter is `@State` in MainTabView → fresh instance on each sign-in (intentional).
- Sign-out error swallowed in Profile placeholder; full handling in Phase 10.
- Code review applied 2 WARN fixes: switched from ZStack + magic `padding(.bottom, 60)` to `.safeAreaInset(edge: .bottom)`; removed unused `@Environment(AuthStore.self)` from MainTabView.

## Success Criteria
- All 4 non-capture tabs switch within frame budget.
- Capture button presents sheet; swipe-down dismisses.
- No layout glitches across device sizes.

## Risk Assessment
- **R1**: Custom tab bar overlaps with home indicator. → Use `.safeAreaInset(edge: .bottom)`.
- **R2**: Sheet over tab bar feels jarring. → Use `.presentationDetents([.medium, .large])` for Capture.

## Security Considerations
- N/A.

## Next Steps
- Phases 05–10 each fill one tab.
