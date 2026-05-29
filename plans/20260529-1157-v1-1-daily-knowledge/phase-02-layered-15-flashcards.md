---
phase: 2
title: "Layered 15 Flashcards (ordering, no lock)"
status: pending
priority: P1
effort: "3d"
dependencies: []
---

# Phase 2: Layered 15 Flashcards (ordering, no lock)

## Overview
Card gen → 15 card chia 3 layer Bloom (Recognize→Recall→Apply), **review theo thứ tự layer** (không time-lock). Bỏ cơ chế khoá 3 ngày (red-team C) — giá trị nằm ở Bloom progression của nội dung + thứ tự queue, SM-2 tự pace. Đây là infra v1.2 Deep Learn reuse.

> Red-team 2026-05-29: lock/countdown/unlock-push CẮT. Giữ layer tagging + ordering. Bonus: migration an toàn hơn (không cần field `unlockedAt`).

## Requirements
- Functional: card gen ra đúng 15 (5/5/5); review queue order Recognize→Recall→Apply; SM-2 pace tự nhiên; legacy deck (3-15 flat) review không gãy.
- Non-functional: SwiftData migration lightweight-safe; thin source không pad rác.

## Architecture
- Hiện tại: `FLASHCARDS_SYSTEM_PROMPT` (`backend/src/openrouter-client.ts:131`) sinh **3-15 by density**; `maxCardsPerDeck=15` (`SM2Constants.swift:9`) chỉ là CEILING; card gen MANUAL qua `CardGenerator.generate` (`Core/Services/AI/CardGenerator.swift`).
- Đổi: prompt FORCE đúng 15 (5/5/5) + server validate; thin source → fallback flat deck (không ép 15 rác).
- Thêm field card `layerIndex: Int` (default 0); Deck `isLayered: Bool` (default false). **KHÔNG thêm `unlockedAt`** (bỏ lock).
- Review order: queue sort by `layerIndex` rồi `nextReviewAt`. SM-2 due-date vẫn là cơ chế pace chính (không cần time-lock).

## Related Code Files
- Modify: `AntiNoise/Core/Models/Flashcard.swift:4-48` (thêm `layerIndex: Int = 0` — literal default, migration-safe)
- Modify: `AntiNoise/Core/Models/Deck.swift:5-30` (thêm `isLayered: Bool = false`)
- Modify: `backend/src/openrouter-client.ts:129-142` (`FLASHCARDS_SYSTEM_PROMPT` → force 15 / 5-5-5 + `layer` field; thin-source fallback)
- Modify: `AntiNoise/Core/Networking/AIClient.swift:182-185` (`FlashcardItem` thêm `layer`)
- Modify: `AntiNoise/Core/Services/AI/CardGenerator.swift:78-87` (gán `layerIndex`; set `deck.isLayered`; validate count)
- Modify: `AntiNoise/Core/Services/Learning/ReviewSessionEngine.swift:10-16` (order by layerIndex trong dueCards)
- Modify: `AntiNoise/Features/Learn/Views/DeckDetailView.swift:37-58` (group hiển thị theo layer — visual, KHÔNG locked)

## Implementation Steps
1. SwiftData migration: thêm `layerIndex: Int = 0` (Flashcard), `isLayered: Bool = false` (Deck). Literal static defaults → lightweight migration tự chạy. **Test boot store v1.0 trước khi ship** (no `SchemaMigrationPlan` tồn tại — `PersistenceContainer.swift:19-24` `fatalError` nếu fail).
2. Backend: rewrite `FLASHCARDS_SYSTEM_PROMPT` → đúng 15 card 5 Recognize (MC/identify) / 5 Recall (open Feynman) / 5 Apply (scenario), JSON `layer: 0|1|2`. Server validate đủ 15 + đủ 3 layer; thiếu → retry hoặc fallback flat (isLayered=false).
3. `FlashcardItem` decode `layer`; `CardGenerator` gán `layerIndex`, `deck.isLayered=true`; nếu source mỏng (model trả < threshold) → flat deck.
4. `dueCards`/`ReviewSessionModel.queue`: sort by `(layerIndex, nextReviewAt)` → Recognize trước. KHÔNG filter unlock (không có lock).
5. DeckDetailView: section theo layer (Recognize/Recall/Apply) cho deck `isLayered`; legacy flat render như cũ.
6. Compile + smoke 1 deck layered + 1 legacy deck.

## Success Criteria
- [ ] Capture/Study mới → 15 card, 5/5/5, review theo thứ tự layer
- [ ] Thin source → flat deck hợp lý (không 15 card rác)
- [ ] Legacy 3-15-card deck review không gãy
- [ ] SwiftData migration không crash user v1.0 (verified bằng test boot store cũ)
- [ ] Build pass

## Risk Assessment
- **[Crit→giảm] Migration**: chỉ thêm field literal-default (Int=0, Bool=false) → lightweight-safe. VẪN phải test boot store v1.0 (`fatalError` nếu fail). Đã bỏ `unlockedAt` non-optional nên rủi ro thấp hơn nhiều.
- Prompt không trả đủ 15/3-layer → server validate + retry + fallback flat.
- 15 card = nhiều AI cost hơn 3-15 hiện tại → monitor (P6/P7); thin-source fallback giảm phí.
- Bỏ lock = user có thể học hết 15 ngay (chấp nhận — red-team C; pacing dựa SM-2 due-date).