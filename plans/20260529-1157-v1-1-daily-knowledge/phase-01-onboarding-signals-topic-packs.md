---
phase: 1
title: Onboarding Signals & Topic Packs
status: completed
priority: P1
effort: 2d
dependencies: []
---

# Phase 1: Onboarding Signals & Topic Packs

## Overview
Thêm Topic Packs (concept mới) + 3 rank signal (role/level/goal) vào onboarding, persist local + Firestore `users/{uid}` để backend rank đọc được (cron batch). Profile cho edit lại.

## Requirements
- Functional: onboarding thêm **topic packs (multi-select 1-3, REQUIRED)**; role/level/goal **OPTIONAL** — đẩy sang Profile/post-onboarding "improve your feed" (red-team D: giảm 10-20% drop-off launch). Profile edit cả 4 anytime. Signals ghi Firestore (best-effort).
- Non-functional: onboarding launch chỉ +1 screen (topic packs); KISS — reuse pattern picker hiện có. KHÔNG dep Phase 0 (build trên UI hiện tại — redesign tách v1.1.1).

## Architecture
- **Topic packs ≠ ClassificationScope** (Personal/Work/Business). Tạo enum `TopicPack` riêng (5 pack: AI/ML, Engineering, Product/Design, Startup, Productivity) với subreddit mapping (dùng ở Phase 3).
- Onboarding answers → `OnboardingStore` (UserDefaults per-uid) + mirror Firestore `users/{uid}` (merge:true) cho backend.
- Backend cron cần signals → **phải** ở Firestore (UserDefaults không đủ). Mở rộng pattern write của `AccountDeletionService` (đã chạm `users/{uid}`).

## Related Code Files
- Create: `AntiNoise/Core/Models/TopicPack.swift` (enum + subreddit map + display), `UserSignals.swift` (role/level/goal enums)
- Create: `AntiNoise/Features/Profile/Views/ProfileSignalsEditView.swift`
- Create: `AntiNoise/Core/Services/Account/UserProfileSyncService.swift` (write signals → Firestore `users/{uid}`)
- Modify: `AntiNoise/Features/Onboarding/OnboardingFlowView.swift:8` (Step enum: thêm `.topicPacks`, `.role`, `.experience`, `.goal`)
- Modify: `AntiNoise/Core/Services/Onboarding/OnboardingStore.swift:21-38` (getters/setters: topicPacks, role, level, goal)
- Modify: `AntiNoise/Features/Profile/ProfileRootView.swift:131` (section "Profile signals" + sheet)

## Implementation Steps
1. Tạo `TopicPack` enum (5 case) + static `subreddits: [String]` map + emoji/title. Tạo `UserRole`/`ExperienceLevel`/`UserGoal` enums (theo spec options).
2. Extend `OnboardingStore`: keys `onboarding.topicPacks/role/level/goal.{uid}`; CSV cho topicPacks.
3. Insert 4 step vào `OnboardingFlowView.Step` (topic packs là Screen 1, trước profile). Reuse picker UI pattern (OnboardingFlowView:52-56). Continue enable khi đủ field.
4. `UserProfileSyncService.syncSignals(uid:)` → Firestore `users/{uid}` merge `{topicPacks, role, level, goal}`. Gọi sau onboarding persist (OnboardingFlowView:118) + sau profile edit.
5. `ProfileSignalsEditView`: pickers cho 4 field, save → OnboardingStore + UserProfileSyncService.
6. Compile check (xcodebuild simulator).

## Success Criteria
- [ ] Onboarding mới chạy: topic packs (1-3) + role/level/goal required, mỗi screen 1 tap
- [ ] Signals đọc được ở Firestore `users/{uid}` sau onboarding
- [ ] Profile edit cập nhật cả local + Firestore
- [ ] Build pass, không syntax error

## Risk Assessment
- Drop-off tăng do thêm screen → mỗi screen 1 tap, required tối thiểu. A/B sau ship.
- Firestore write fail (offline) → queue/retry, đừng block onboarding completion (best-effort sync, local là source of truth).

## Red Team Corrections (2026-05-29)
- **[Med] Existing v1.0 users không có signals**: user đã onboard (`OnboardingStore.isCompleted` true) → `RootView.swift:20` bỏ qua onboarding → không bao giờ pick topic packs/signals → `users/{uid}` thiếu signals → P3 rank trả generic. FIX: thêm `signalsVersion` check ĐỘC LẬP với `isCompleted` → prompt "set your topics" cho user cũ; P3 cần fallback khi `users/{uid}` thiếu signals. Đây là feature headline → đừng để user cũ mất.
- Onboarding hiện 2 step (`OnboardingFlowView.swift:8` = profile, notifications) → thành 6; re-verify anchor persist (không phải :118). `GrowthScope` = typealias của `ClassificationScope` (xác nhận topic packs là enum riêng).
