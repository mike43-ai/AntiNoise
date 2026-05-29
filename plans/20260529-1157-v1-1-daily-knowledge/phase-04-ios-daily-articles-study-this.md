---
phase: 4
title: "iOS Daily Articles & Study This"
status: pending
priority: P1
effort: "4d"
dependencies: [1, 2, 3]
---

# Phase 4: iOS Daily Articles & Study This

## Overview
iOS đọc `daily_inbox` từ Firestore, hiện "Today's 3" grid ở Home, push 7AM, FOMO vanish, first-run loading. "Study this" → action sheet Feynman/Flashcards, cả 2 chạy full capture pipeline (summary + 15 layered cards), khác màn mở.

## Requirements
- Functional: hiển thị 3 article (title/source/reading-time), Skip + Study this; "Study this" tạo Capture từ URL → summarize → layered cards (Phase 2); push daily; skipped vanish 23:59 local; first-run fetch ngay sau onboarding.
- Non-functional: offline-graceful; loading skeleton; reuse capture pipeline (DRY).

## Architecture
- iOS **chưa có** Firestore read layer → tạo `DailyInboxService` (đọc `daily_inbox/{uid}/{date}`, cache local SwiftData/`Article` model).
- "Study this" = reuse `CaptureFlowModel` URL path (`CaptureFlowModel.save()` :76) → `summarizer.process()` → `CardGenerator.generate()` (layered). Feynman vs Flashcards chỉ khác view mở đầu (SummaryDetail vs DeckDetail) — cùng pipeline (decision: luôn tạo card).
- Push reuse `NotificationScheduler` (category `dailyArticles`).

## Related Code Files
- Create: `AntiNoise/Core/Models/Article.swift` (id, title, sourceURL, subreddit, readingMin, reason, date, skipped)
- Create: `AntiNoise/Core/Services/Daily/DailyInboxService.swift` (Firestore read + on-demand refresh call backend)
- Create: `AntiNoise/Features/Home/Views/DailyArticlesSection.swift` (3-col grid + Study/Skip)
- Create: `AntiNoise/Features/Home/Views/StudyThisActionSheet.swift` (Feynman | Flashcards)
- Create: `AntiNoise/Features/Onboarding/FirstRunLoadingView.swift`
- Modify: `AntiNoise/Features/Home/HomeRootView.swift:43-50` (insert section sau TodaySnapshotCard:44)
- Modify: `AntiNoise/Features/Home/HomeViewModel.swift:28-33` (`todayArticles`, refresh, skip)
- Modify: `AntiNoise/Core/Services/Notifications/NotificationScheduler.swift` (category `dailyArticles`, schedule 7AM)
- Modify: `AntiNoise/Features/Capture/ViewModels/CaptureFlowModel.swift` (entry "study from article": preset URL, route opening view)

## Implementation Steps
1. `Article` model + `DailyInboxService`: read Firestore `daily_inbox/{uid}/{today}`; `refresh()` → POST `/daily/refresh` (AIClient pattern, Firebase token). Cache vào SwiftData.
2. `DailyArticlesSection`: LazyVGrid 3 col, mỗi card title+subreddit+reading-time; Skip + Study this. Empty/skeleton/retry states (fallback từ spec).
3. Insert section vào HomeRootView content (sau line 44). HomeViewModel.refresh load articles; skip → set skipped + persist.
4. FOMO: filter article có `date==today && !skipped`; skipped/expired vanish (so local 23:59).
5. `StudyThisActionSheet`: 2 nút. Cả 2 → `CaptureFlowModel` tạo Capture(url) → summarize → CardGenerator (layered). Feynman mở SummaryDetail; Flashcards mở DeckDetail sau gen.
6. `FirstRunLoadingView`: sau onboarding Q (Phase 1), gọi `DailyInboxService.refresh()`, copy "⚡ Picking your first 3 articles…", rồi vào Home.
7. Push: NotificationScheduler category `dailyArticles`, daily 7AM local "3 articles ready for [Topic]".
8. Compile + device smoke (Firestore read, study→cards).

## Success Criteria
- [ ] Home hiện 3 article từ Firestore; tap Study this → Feynman/Flashcards đúng màn, đều tạo 15 layered cards
- [ ] First-run: sau onboarding thấy 3 article không cần chờ hôm sau
- [ ] Push 7AM bắn; skipped vanish 23:59
- [ ] Offline/empty/error states không crash (skeleton + retry)
- [ ] Build pass device

## Risk Assessment
- Firestore read mới = bề mặt mới → test auth/permission rules; chỉ owner đọc inbox của mình.
- "Study this" tốn AI quota (Phase 6 gate) → consume sau khi gen thành công.
- User overwhelm (3 article + homework) → Skip dễ, không ép.

## Red Team Corrections (2026-05-29)
- **[Crit] "Study this → cards" SAI**: card gen hiện là MANUAL (`SummaryDetailView` CTA → `SummaryDetailModel`); `CaptureFlowModel.save()` (`:76-105`) chỉ `summarizer.process()`, KHÔNG gọi CardGenerator. FIX: nhánh Flashcards phải chain capture → summarize → **await `CardGenerator.generate()`** → mở DeckDetail; nhánh Feynman dừng ở summary. Re-sequence `.lesson` consume (P6) quanh call-site mới này.
- **[High] SSRF**: article URL từ Reddit (attacker-influenced) → `ReadabilityExtractor.fetchAndExtract` (`:29-35`) fetch không validate scheme/host (`CaptureNormalizer.swift:45`), follow redirect. FIX: enforce `scheme=="https"`, reject private/loopback/link-local + file/data, validate mỗi redirect; tốt hơn: fetch+extract phía Worker. Coi body fetch là untrusted vào AI prompt.
- **[High] Firestore states + double-insert**: missing-doc là CASE THƯỜNG (user mới/cron skip/offline). FIX: 3 state riêng (missing → trigger on-demand refresh; empty-after-skip → "done today"; error → retry). Định nghĩa schema doc `{articles:[], generatedAt}` để phân biệt missing vs empty. "Study this" double-tap → `CardGenerator.generate` luôn insert Deck mới (`CardGenerator.swift:71-90`, no dedupe) → FIX: guard existing deck/capture theo URL HOẶC disable nút khi in-flight.
