---
phase: 5
title: Seed Content
status: completed
priority: P2
effort: 1d
dependencies:
  - 2
---

# Phase 5: Seed Content

## Overview
Bundle **1-2 layered-card lesson** evergreen (Productivity + 1 pack phổ biến) static JSON. First launch: nếu user's pack có lesson → show; không có → fallback Productivity. Fix empty Learn tab → bounce.

> Red-team G 2026-05-29: giảm từ 5 lesson (75 card hand-QA) → 1-2 lesson + fallback. Đủ fix cold-start, ít content QA. Mở rộng pack sau theo data thực.

## Requirements
- Functional: 5 evergreen lesson (mỗi cái 1 layered deck 15 card 3-layer); load first launch; chọn 3 theo onboarding topic packs; `isSample` flag; KHÔNG tính quota (Phase 6).
- Non-functional: zero AI cost, zero network; reuse layered structure (Phase 2); tái dùng cho Deep Learn demo (v1.2).

## Architecture
- Static `SeedDecks.json` (5 deck, mỗi deck 15 card đã viết sẵn + layerIndex). Bundle Resources.
- `SeedDeckRepository`: first launch (Deck.count==0 hoặc flag chưa-seed) → đọc onboarding topic packs → map 3 pack → insert 3 deck tương ứng (fallback Productivity nếu rỗng).
- Deck thêm `isSample: Bool` (đã có `isLayered` từ Phase 2) → exclude quota + có thể badge "Sample".

## Related Code Files
- Create: `AntiNoise/Resources/SeedDecks.json` (5 layered decks evergreen)
- Create: `AntiNoise/Core/Services/Learning/SeedDeckRepository.swift` (decode + select-by-pack + insert)
- Modify: `AntiNoise/Core/Models/Deck.swift` (thêm `isSample`)
- Modify: `AntiNoise/Core/Persistence/PersistenceContainer.swift` hoặc app first-launch hook (gọi seed sau onboarding)
- Modify: `AntiNoise/Features/Learn/Views/DeckListView.swift:4-63` (badge "Sample" optional)

## Implementation Steps
1. Soạn 5 lesson evergreen (Productivity, AI/ML, Engineering, Product/Design, Startup) — mỗi cái 15 card 3-layer (Recognize/Recall/Apply). Có thể gen 1 lần bằng Gemini rồi freeze vào JSON (one-time, không runtime).
2. `Deck.isSample` field (default false).
3. `SeedDeckRepository.seedIfNeeded(uid:)`: idempotent (UserDefaults flag `seeded.{uid}`); đọc OnboardingStore topicPacks → chọn 3 deck khớp (fallback Productivity); insert Deck+Flashcard với `isSample=true`, `isLayered=true`, unlockedAt theo layer.
4. Gọi seed sau onboarding hoàn tất (sau Phase 1 persist) hoặc first Learn tab open nếu deck rỗng.
5. DeckListView optional badge "Sample".
6. Compile + verify 3 deck xuất hiện cho user mới.

## Success Criteria
- [ ] User mới (sau onboarding) thấy 3 sample deck khớp topic packs, fallback Productivity
- [ ] Sample card review được ngay (Day 1 mở), layered đúng
- [ ] `isSample` exclude khỏi quota (verify ở Phase 6)
- [ ] Không seed lại lần mở sau (idempotent)
- [ ] Build pass

## Risk Assessment
- Soạn 5 lesson tốn công content (one-time) → gen Gemini rồi review tay, freeze JSON.
- Seed timing race với onboarding → chạy sau persist; idempotent flag chống double-seed.
- Sample lẫn capture thật → `isSample` + badge phân biệt rõ.
