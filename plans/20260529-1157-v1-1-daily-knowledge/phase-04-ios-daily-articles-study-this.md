---
phase: 4
title: iOS Daily Skills & Study This
status: completed
priority: P1
effort: 3-4d
dependencies:
  - 1
  - 2
  - 3
---

# Phase 4: iOS Daily Skills & Study This

# Overview
iOS đọc `daily_inbox` từ Firestore, hiện "Today's 3 skills" ở Home (title + keyword + why-now), push, first-run loading. "Study this" → action sheet Feynman/Flashcards: feed **explainer text** vào capture pipeline (text path) → summary + 15 layered cards (P2). "Learn more" mở suggestedSearch trong browser.

> Đổi nguồn 2026-05-29: item = skill/concept (curated taxonomy + AI explainer), KHÔNG phải Reddit article. → Study-this dùng **text path** (explainer), không URL fetch → SSRF risk gần như hết.

## Requirements
- Functional: hiển thị 3 skill item; Skip + Study this (Feynman/Flashcards, cả 2 → 15 layered cards qua text path); "Learn more" → suggestedSearch (browser); first-run fetch ngay sau onboarding; "all caught up" khi hết.
- Non-functional: offline-graceful (3 state missing/empty/error riêng); reuse capture pipeline (DRY); KHÔNG fetch URL ngoài trong app.

## Architecture
- iOS **chưa có** Firestore read layer → `DailyInboxService` (đọc `daily_inbox/{uid}/{date}`, cache SwiftData; gọi backend `/v1/daily/refresh`).
- Item model `DailySkillItem`: id, title, keyword, whyNow, coreConcept, suggestedSearch, packRaw, date, skipped.
- "Study this" = `CaptureFlowModel` **text path** (`save()` với rawText = "{title}\n\n{whyNow}\n\n{coreConcept}") → `summarizer.process()` → **await `CardGenerator.generate()`** (card gen MANUAL, phải gọi tường minh — red-team) → DeckDetail/SummaryDetail. Feynman mở summary; Flashcards mở deck.
- Push reuse `NotificationScheduler` (category `dailySkills`).

## Related Code Files
- Create: `AntiNoise/Core/Models/DailySkillItem.swift`
- Create: `AntiNoise/Core/Services/Daily/DailyInboxService.swift` (Firestore read + POST /v1/daily/refresh)
- Create: `AntiNoise/Features/Home/Views/DailySkillsSection.swift` (3-item grid + Study/Skip/Learn-more)
- Create: `AntiNoise/Features/Home/Views/StudyThisActionSheet.swift` (Feynman | Flashcards)
- Create: `AntiNoise/Features/Onboarding/FirstRunLoadingView.swift`
- Modify: `AntiNoise/Features/Home/HomeRootView.swift:43-50` (insert section sau TodaySnapshotCard:44)
- Modify: `AntiNoise/Features/Home/HomeViewModel.swift:28-33` (`todaySkills`, refresh, skip)
- Modify: `AntiNoise/Core/Services/Notifications/NotificationScheduler.swift` (category `dailySkills`, 7AM)
- Modify: `AntiNoise/Features/Capture/ViewModels/CaptureFlowModel.swift` (entry "study from skill": preset rawText, route opening view, await card gen)

## Implementation Steps
1. `DailySkillItem` model + `DailyInboxService`: read Firestore `daily_inbox/{uid}/{today}`; `refresh()` → POST `/v1/daily/refresh` (AIClient pattern, Firebase token); cache SwiftData. **3 state riêng**: missing-doc → trigger refresh; empty/all-caught-up → "you're caught up today"; error → retry.
2. `DailySkillsSection`: LazyVGrid 3 item (title + keyword tag + whyNow); Skip + Study this + Learn more. Skeleton/empty/retry states.
3. Insert section vào HomeRootView (sau line 44). HomeViewModel.refresh load skills; skip → set skipped + persist.
4. `StudyThisActionSheet`: 2 nút → `CaptureFlowModel` text path (rawText = title+whyNow+coreConcept) → summarize → **await CardGenerator.generate()** (layered) → Feynman mở SummaryDetail / Flashcards mở DeckDetail. **Dedupe**: nếu skill item đã có deck/capture → mở cái cũ, không tạo trùng.
5. `FirstRunLoadingView`: sau onboarding (P1), gọi `DailyInboxService.refresh()`, copy "⚡ Picking your first 3 skills…", rồi vào Home.
6. "Learn more" → `suggestedSearch` mở `https://www.google.com/search?q=…` qua `openURL` (browser, KHÔNG fetch trong app).
7. Push: category `dailySkills`, 7AM "3 new skills for [Topic]".
8. Compile + device smoke (Firestore read, study→cards, dedupe).

## Success Criteria
- [ ] Home hiện 3 skill từ Firestore; Study this → Feynman/Flashcards đều tạo 15 layered cards (text path)
- [ ] First-run thấy 3 skill ngay sau onboarding
- [ ] "All caught up" khi hết unseen; skip ẩn item
- [ ] Double-tap Study this không tạo deck trùng (dedupe)
- [ ] Offline/empty/error states phân biệt rõ, không crash; build pass device

## Risk Assessment
- Firestore read mới = bề mặt mới → rules owner-only (P3); test chỉ đọc inbox của mình.
- "Study this" tốn AI quota (P6 gate) → consume sau gen thành công; dedupe tránh double-charge.
- SSRF gần như hết (không fetch URL ngoài) — chỉ "Learn more" mở browser (an toàn). Vẫn validate suggestedSearch là https search URL.
- Card gen MANUAL → phải await `CardGenerator.generate()` tường minh (red-team catch).
