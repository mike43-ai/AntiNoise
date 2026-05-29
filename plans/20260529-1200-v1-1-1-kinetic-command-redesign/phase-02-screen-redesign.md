---
phase: 2
title: "Screen Redesign (all screens)"
status: pending
priority: P2
effort: "4d"
dependencies: [1]
---

# Phase 2: Screen Redesign (all screens)

## Overview
Redesign toàn bộ màn theo 3 mockup Kinetic Command, dùng component Phase 1. **XP/SkillRadar shell CẮT** (red-team B) — Profile chỉ data thật. Vì v1.1 ship trên design cũ, phase này redesign tất cả: Learn/flashcard, Capture, Profile, Home, dock.

## Requirements
- Functional: Learn/flashcard, Capture, Profile, Home khớp mockup; Profile dùng DATA THẬT (streak, completed, weekly chart) — KHÔNG XP/radar.
- Non-functional: pixel-gần mockup; reuse component Phase 1; visual-only (không đổi logic/feature).

## Architecture
- Mockup nguồn: `flashcard_learning_view/`, `refined_quick_capture_flow/`, `professional_profile_progress/`. Mỗi folder có `code.html` (layout) + `screen.png`.
- "Define Intent" mockup (Learn Skill/Improve Work/Develop Myself) ≈ `ClassificationScope` → relabel/icon, KHÔNG đổi model.
- Profile dataviz: completed-lessons ring + weekly chart từ `StatsAggregator` (data có thật). **KHÔNG SkillRadar, KHÔNG XP badge** (cut B — chỉ thêm khi có spec gamification).

## Related Code Files
- Modify: `AntiNoise/Features/Learn/Views/FlashcardReviewView.swift`, `FlashcardFaceView.swift`, `DeckDetailView.swift` → flashcard card mockup (tap-to-flip, progress, "AI Deeper Dive" = nối deep-dive gen sẵn, NO XP badge)
- Modify: `AntiNoise/Features/Capture/Views/*` → paste-link card + upload-media dropzone + define-intent rows + "Process & Save" dark button
- Modify: `AntiNoise/Features/Profile/ProfileRootView.swift` + `Views/StatsGrid.swift` → pro badge, growth tracks (real %), CompletedLessonsRing, WeeklySummaryChart. NO radar/XP.
- Modify: `AntiNoise/Features/Home/HomeRootView.swift` + `Views/TodaySnapshotCard.swift` → card system; phối article grid (v1.1) nếu đã ship
- Create: `AntiNoise/Features/Profile/Views/WeeklySummaryChart.swift`, `CompletedLessonsRing.swift` (data thật)

## Implementation Steps
1. Flashcard view (`flashcard_learning_view/code.html`): card trắng + shadow, tap-to-flip, progress bar, "AI Deeper Dive" (nối CardGenerator deep-dive sẵn), share/flag. Bỏ "+50 XP" badge (cut B). "Contextual Connections" = defer (related chưa có).
2. Capture (`refined_quick_capture_flow/code.html`): "1. Capture Content" (paste link + clipboard + upload dropzone), "2. Define Intent" (3 row scope, selected=orange), "Process & Save" dark button. Map intent → ClassificationScope.
3. Profile (`professional_profile_progress/code.html`): header pro badge + name + Edit; Growth tracks (real %); CompletedLessonsRing (completed count); WeeklySummaryChart (review/ngày StatsAggregator); AI Recommendation card (nếu có data) hoặc bỏ. **KHÔNG Skill radar, KHÔNG XP.**
4. Home: card system; phối article grid + snapshot.
5. Compile + device visual QA đối chiếu screen.png (lưu ý: bỏ các phần XP/radar so với mockup).

## Success Criteria
- [ ] Learn/Capture/Profile/Home khớp mockup (layout, màu, font, card, dock) — trừ XP/radar đã cắt
- [ ] Profile chỉ hiển thị data thật; không có placeholder giả "coming soon"
- [ ] Define Intent map đúng ClassificationScope, không đổi model
- [ ] Build pass; không regression chức năng
- [ ] Visual QA 3 screen.png đạt (đã trừ XP/radar)

## Risk Assessment
- code.html là web (Tailwind) → dịch SwiftUI, không copy 1-1; bám token Phase 1.
- Mockup có XP/radar nhưng ta cắt → đảm bảo layout vẫn cân khi bỏ (đừng để chỗ trống xấu).
- Tab naming mockup (Focus/Learn/Plan/Profile) chưa chốt (đụng v1.2) → giữ tab hiện tại, chỉ đổi style dock.
