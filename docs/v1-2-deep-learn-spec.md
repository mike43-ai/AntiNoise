# Anti Noise v1.2 — Deep Learn (replaces Focus)

> **Theme**: Multi-day mastery course nối tiếp flashcard. Pro headliner + retention hook.
> **Effort**: ~2-3 tuần (xem [Effort](#effort-estimate)).
> **Status**: Scoped 2026-05-29 brainstorm. **Depends on v1.1** (layered-card mechanic + Gemini + cron) → ships sau v1.1.
> **Synced**: memory [[anti-noise-v1-2-deep-learn]].

## Why

Focus (Pomodoro timer) lạc đề so với "capture → learn what matters" + buggy (build 16) → gỡ. Deep Learn kéo dài value ladder:

```
capture → summarize (Feynman) → flashcard (SRS) → MASTERY COURSE (Deep Learn)
```

Học xong 1 deck/topic, user thường rơi vào khoảng trống "rồi sao nữa". Deep Learn lấp bằng course nhiều ngày app tự "cook" — vừa đào sâu, vừa tạo lý do mở app mỗi ngày (retention). Đây cũng là Pro-conversion moment thứ 2 sau v1.1.

---

## Phần A — Gỡ Focus

### Xóa
- Tab **Focus** → thay bằng Deep Learn sống trong **Learn tab** (đã tồn tại `Features/Learn/`).
- Delete: `Features/Focus/*`, `Core/Services/Focus/FocusSessionEngine.swift`, `Core/Models/FocusSession.swift`.
- `App/MainTabView.swift` + `AppRouter` (`AppTab` enum): bỏ `.focus`.
- Không check telemetry trước (user OK gỡ thẳng — decision 2026-05-29).

### Giữ lại (reuse)
- Notification scheduling logic trong `FocusSessionEngine` (wall-clock + `UNUserNotificationCenter`) → tách ra `Core/Services/Notifications/` cho daily lesson reminder.

### ⚠️ Streak phải chuyển owner
Streak hiện đếm "consecutive days với completed Focus session" (`Core/Services/Stats/StatsAggregator.swift`, support.md:66). Gỡ Focus = streak chết nếu không chuyển.

**LOCKED 2026-05-29:** streak = **ngày có ≥1 completed card review** (bất kỳ: review thường, layered card, Deep Learn lesson).
- Lý do: card review **free-available**; nếu buộc streak vào Deep Learn (Pro-gated) → free user mất streak.
- Rộng + robust hơn Focus-session cũ, không gãy khi gỡ Focus.
- `StatsAggregator` đổi: đếm distinct days có review event thay vì completed FocusSession.

---

## Phần B — Deep Learn

### B1. Trigger / entry

| Entry | Khi |
|---|---|
| **Sau khi "Mastered" 1 deck** | Result screen (chỗ `FocusResultView` cũ): "Học sâu chủ đề này 7 ngày?" |
| **Learn tab** | Section "Deep Learn paths" — start path mới từ deck bất kỳ, xem path đang active |

Ràng buộc MVP: **1 active path / lúc** (tránh overwhelm + cost). Muốn start path mới khi đang có active → phải finish/abandon path cũ.

### B2. Cấu trúc course (7 ngày — MVP)

Course = 7 `LearningDay`. Mỗi ngày = micro-lesson 3-5 phút:

| Phần | Nội dung | Reuse |
|---|---|---|
| Concept | Giải thích 1 sub-topic kiểu Feynman | `SummarizerService` |
| Card mới | 3-5 layered card (Recognize→Recall→Apply) | `Flashcard` + v1.1 layered prompt |
| Apply | 1 reflection / scenario prompt | layered "Apply" (v1.1) |
| Resurface | Card ngày trước tới hạn | `SpacedRepetitionScheduler` (SM-2) |

- **Lock/countdown/unlock + daily push**: reuse y nguyên cơ chế layered-card v1.1 ("Day 2 unlocks in 14h"). Đây là lý do depends v1.1.
- Day cuối = "review day": chỉ resurface, no new card → đóng course bằng badge "Mastered [topic] in 7 days 🏆".

### B3. Content generation (hybrid)

Nguồn content — decision 2026-05-29 = **hybrid (a)+(b)**:
- **(a) Seed từ captures user** về topic đó (nếu có) → course bám notes "của họ".
- **(b) Gemini lấp gap / tự sinh full** khi captures thưa.
- Web/Reddit source: **defer** (v1.1 đã có Reddit infra → nâng cấp sau).

**Generation = outline + lazy (LOCKED 2026-05-29).** KHÔNG sinh hết 7 ngày lúc opt-in.
- Opt-in → sinh **Day 1 ngay** (sync, loading screen).
- Day 2-7 → sinh qua **cron / on-open** (giống v1.1 daily cron) trước khi unlock.
- Lý do: tiết kiệm token khi user drop giữa chừng + cho phép **adaptive** (defer) điều chỉnh theo card fail.

**Outline-first prompt** (1 lần lúc opt-in, rẻ): Gemini sinh **7-day outline** (mỗi ngày 1 sub-topic + objective) từ topic + snippet captures. Lưu vào path. Mỗi ngày sau chỉ "expand outline day N → concept + cards" → coherent, không lặp.

```
[Outline prompt]
Topic: {deck title}
User notes (snippets): {captures về topic, có thì đưa}
User: role={role}, level={level}   // reuse onboarding signals v1.1
Tạo lộ trình học 7 ngày, mỗi ngày 1 sub-topic build lên ngày trước.
Day 7 = review/synthesis. Return 7× {day, subtopic, objective}.

[Per-day expand prompt]
Course topic: {topic}. Today: day {n} — {subtopic} ({objective}).
Đã học: {prev day subtopics}.
Tạo: (1) concept explainer Feynman ≤150 từ, (2) 3-5 layered card (Recognize/Recall/Apply), (3) 1 apply prompt.
```

### B4. Adaptive difficulty (DEFER — không MVP)
Ngày sau điều chỉnh độ khó theo SM-2 grade ngày trước (fail nhiều → thêm Recognize card; mastered → nhảy Apply). Ghi nhận, làm sau data.

---

## Data model

Model mới (`Core/Models/`):

```swift
@Model LearningPath {
  @Attribute(.unique) var id: UUID
  var deckID: UUID            // deck gốc trigger path
  var topic: String
  var durationDays: Int       // 7 (MVP)
  var startedAt: Date
  var currentDay: Int         // 1..7
  var status: String          // active | completed | abandoned
  var outlineJSON: String?    // 7-day outline cached
}

@Model LearningDay {
  @Attribute(.unique) var id: UUID
  var pathID: UUID
  var dayIndex: Int           // 1..7
  var conceptText: String?    // nil = chưa gen (lazy)
  var applyPrompt: String?
  var cardIDs: [UUID]         // → Flashcard sinh cho ngày này
  var unlocksAt: Date         // lock countdown
  var completedAt: Date?
}
```

- **Reuse**: `Flashcard` (SM-2 fields sẵn), `Deck`, `Summary`, `SpacedRepetitionScheduler`, `ReviewSessionEngine`, `SummarizerService`.
- **Retire**: `FocusSession` + `FocusSessionEngine`.
- Cards Deep Learn: tạo `Flashcard` bình thường với `deckID` = deck của path → tự động vào SRS queue chung. `LearningDay.cardIDs` link để hiển thị theo ngày.
- Firestore mirror: `learning_paths/{uid}/{pathId}` (cross-device sync như capture hiện tại).

---

## UX flow (trong Learn tab)

1. **Entry** — Mastered deck → CTA "Học sâu 7 ngày"; hoặc Learn tab → "Deep Learn" section.
2. **Opt-in** — Pro check (xem [Pro-gating](#pro-gating)). Loading ~3-5s: "⚡ Đang thiết kế lộ trình 7 ngày…" (outline + Day 1 gen).
3. **Path screen** — progress "Day 3/7", list 7 ngày: completed ✓ / today (mở) / locked 🔒 + countdown.
4. **Daily lesson** — concept → card mới (layered) → apply → resurface. Dùng lại `FlashcardReviewView`.
5. **Unlock** — push 7AM local "Day {n} of {topic} unlocked" (reuse v1.1 push).
6. **Complete** — Day 7 xong → badge "Mastered in 7 days 🏆" + share card (reuse weekly-recap render nếu có; nếu chưa → simple).

---

## Pro-gating

- **Deep Learn = Pro-only, full** (decision 2026-05-29). Không free trial course.
- Free user thấy entry CTA → tap → paywall (reuse `Features/Paywall/` + `Core/Services/Subscription/`).
- Card review thường + layered card (v1.1) vẫn theo quota free cũ — Deep Learn là tầng trên.

| Tier | Deep Learn |
|---|---|
| Free | Xem CTA, tap → paywall |
| Pro | Unlimited paths (1 active/lúc) |

---

## Backend (Cloudflare Worker — reuse proxy v1.0.1)

| Endpoint | Việc |
|---|---|
| `POST /learn/path` | Tạo path: gen outline + Day 1 (sync). Return path + day 1. |
| `POST /learn/day` `{pathId, dayIndex}` | Lazy gen 1 ngày (on-open trước unlock). |
| Cron (optional) | Pre-gen ngày kế cho active paths trước 7AM (giảm latency khi mở). |

- Tất cả qua OpenRouter (Gemini Flash) — model swap qua `wrangler.toml` (xem [[anti-noise-backend-openrouter-swap]]).

---

## Telemetry

`Core/Services/Telemetry/TelemetryEvent.swift`:
- **Bỏ**: `focus_session_started`, `focus_session_completed`.
- **Thêm**: `learn_path_started`, `learn_day_completed`, `learn_path_completed`, `learn_path_abandoned`.
- Streak event đổi nguồn theo Phần A.

---

## Removal checklist (cần làm khi ship)

- [ ] `legal/privacy-policy.md` — bỏ "focus session started" event + "focus sessions" trong export; thêm learning_paths.
- [ ] `legal/support.md` — bỏ FAQ "Focus mode"; viết lại streak definition; FAQ Deep Learn mới.
- [ ] `x-content-6-weeks.md` — sửa tweet bán "Focus timer + streak" (line ~64/359/580) → Deep Learn message.
- [ ] Data export JSON: thêm learning paths.
- [ ] App Store "what's new": Focus removed → Deep Learn (frame as upgrade).

---

## Cost projection (thêm vào ~$25/mo hiện tại)

- 1 path = 1 outline call + 7 expand call = ~8 Gemini Flash call.
- Pro-gated → chỉ Pro user gen. Giả định 50 Pro × 2 path/tháng = 800 call/mo → vẫn trong free tier / vài $.
- Lazy gen tránh phí token cho path user drop sớm.
- **Tác động margin: không đáng kể.**

---

## Effort estimate

| Work | Days |
|---|---|
| Gỡ Focus (delete files, tab enum, tách notification logic, streak migration sang StatsAggregator) | 1-2 |
| Data model + Firestore sync (`LearningPath`, `LearningDay`) | 1 |
| Backend endpoints (outline + lazy day gen, prompts) | 2-3 |
| Learn tab UI (path screen, day list, lock/countdown reuse v1.1, lesson flow, complete badge) | 3-4 |
| Pro-gate + paywall wiring | 1 |
| Telemetry + docs removal checklist | 1 |
| Polish + ASC review | ~3 |
| **Total** | **~2-3 tuần dev + review** |

---

## Risks

- **Content "padding"** — course 7 ngày AI dễ loãng. Mitigation: outline-first (coherent build-up), concept ≤150 từ, Day 7 = synthesis, ground vào captures.
- **Completion rate thấp** (khoá học online ~10% finish). Mitigation: bài ngắn 3-5', push reminder, "catch up" linh hoạt (miss không phạt, chỉ dịch unlock), 1 active path tránh ngợp.
- **Cold start** — captures thưa → (b) Gemini tự sinh, nhưng generic hơn. Chấp nhận theo decision.
- **Gỡ Focus = user backlash** nếu ai đó dùng. Đã chấp nhận (buggy/lạc đề). Frame App Store như upgrade.
- **Streak gãy** nếu quên migration — checklist Phần A bắt buộc.
- **Depends v1.1** — không start trước khi v1.1 ship (layered-card infra là nền).

---

## Decisions locked (2026-05-29)
- Streak = ≥1 completed card review/ngày (decouple khỏi Pro Deep Learn).
- Generation = outline 7 ngày (1 lần, rẻ) + lazy gen content từng ngày.

## Open questions
1. 14-day option — defer hẳn hay làm cùng MVP như toggle 7/14?
2. Abandon path → cards đã sinh giữ trong SRS hay xóa? (đề xuất: giữ — đã học rồi)
3. Share card lúc complete — làm ngay hay defer chờ weekly-recap render component?
