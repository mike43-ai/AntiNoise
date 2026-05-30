# Anti Noise — Product Roadmap

> Locked 2026-05-23 brainstorm. Updated 2026-05-29: v1.2 = Deep Learn (replaces Focus).

## Roadmap summary

| Version | Theme | Effort | Status |
|---|---|---|---|
| v1.0 | MVP | — | **LIVE on App Store 2026-05-28** |
| v1.0.1 | Server proxy + Gemini Flash migration | 3-5 ngày | **Shipped 2026-05-29** (OpenRouter swap) |
| v1.1 | Daily Knowledge (skills feed + layered cards) | ~2 tuần | **Code complete + tested 2026-05-30** (P1–P7; 40 tests green; backend deployed) — pending ASC submit. See [v1.1 spec](v1-1-daily-knowledge-spec.md) |
| v1.2 | **Deep Learn** (multi-day course từ flashcard, replaces Focus) | ~2-3 tuần | **Code-complete + shipping 2026-05-30** (merged main, backend deployed) — see [v1.2 spec](v1-2-deep-learn-spec.md) |
| v1.3 | **Ascent** (gamified 60-day climb fueled by learning; new tab) | ~2 tuần | Scoped 2026-05-30 — see [v1.3 spec](v1-3-ascent-spec.md). Ships after v1.2 (needs data to tune economy) |
| v1.4 | Widgets + Chrome Ext + Android port | TBD | Candidates only |

## v1.2 — Deep Learn (replaces Focus)

> Scoped 2026-05-29 brainstorm. **Depends on v1.1** (card mechanic + Gemini + cron) → ships sau v1.1. v1.2 headliner.

### Why
Focus (Pomodoro timer) lạc đề + buggy (build 16) → gỡ. Deep Learn kéo dài value ladder: capture → summarize → flashcard → **mastery course**. Gộp luôn retention hook (bài học mỗi ngày = daily reason-to-open).

### Mechanic
Học xong deck/topic → opt-in **course 7 ngày** (14-day defer). Mỗi "ngày" = micro-lesson 3-5':
- Concept explainer (Feynman — reuse summarize prompt)
- 3-5 card mới (reuse Flashcard + SRS)
- 1 apply/reflection (reuse layered "Apply" từ v1.1)
- Resurface card ngày trước (SRS spaced over course window)

### Locked decisions (2026-05-29)
1. **Replace Focus entirely** — gỡ Pomodoro timer, tab Focus → Learn. Không check telemetry trước (user OK gỡ thẳng).
2. **Content source = hybrid (a)+(b)**: seed từ captures của user + Gemini lấp gap; captures thưa → Gemini tự sinh full. Web/Reddit source defer.
3. **Pro-gate full** — Deep Learn là Pro feature (không free trial course).
4. **Lazy generation** — sinh Day 1 lúc opt-in, ngày còn lại qua cron/on-open (tiết kiệm token + cho phép adaptive).
5. **MVP cut**: chỉ 7-day, 1 active path/lúc. Defer: 14-day, adaptive difficulty, web source, share path.

### Data model
- Mới: `LearningPath` (topic, durationDays, startDate, currentDay, status) + `LearningDay` (index, lessonText, cardIDs, completed).
- Reuse: Flashcard, SRS, summarize prompt, **notification code của FocusSessionEngine** (lịch reminder). Retire `FocusSession` + timer.

### ⚠️ Removal impact (Focus → Deep Learn)
- **Streak ownership phải chuyển**: streak hiện đếm "consecutive days với completed Focus session" (support.md:66). Bỏ Focus → streak phải buộc vào **completed daily lesson / review** (Deep Learn hoặc card review). KHÔNG để streak chết.
- **Docs cần update khi ship**: `legal/privacy-policy.md` (telemetry "focus session started", export "focus sessions"), `legal/support.md` (FAQ "Focus mode" + streak definition), `x-content-6-weeks.md` (marketing tweet bán "Focus timer + streak" — line 64/359/580 cần đổi message).
- **Telemetry event** `focus_session_started` → thay bằng `learn_day_completed` / `learn_path_started`.

## v1.3 candidates (defer)

- **iOS Widgets**: Daily 3 articles widget, streak/due cards widget, quick capture widget
- **Chrome Extension**: Capture URL from browser → push to iOS app, reading-time text selection capture. Cần backend endpoint mới.
- **Google Play Store (Android)**: Major scope. Options:
  - React Native rewrite (shared codebase future)
  - Flutter rewrite
  - Kotlin/Compose parallel app (2 codebase maintain)
  - Effort: 4-8 tuần
  - Backend (v1.0.1 server proxy) ready, không cần rebuild

## Locked architecture decisions (2026-05-23)

1. **§2 unlocked**: Original plan locked "GPT-4o vision only" — unlocked 2026-05-23, switching all AI to **Gemini 2.0 Flash** starting v1.0.1.
2. **AI vendor consolidation**: Single provider Gemini cho rank + summary + flashcard. Lý do: cheaper, VI tốt hơn (Google data), free tier overlap, native multimodal.
3. **Content source**: ~~Reddit API only~~ → **đổi 2026-05-29: curated skill taxonomy + AI explainer** (curriculum "skills thời AI", KHÔNG news; bỏ Reddit/OAuth hoàn toàn — bundle trong Worker). Lý do: định vị Daily Knowledge = skills nên học, tự kiểm soát chất lượng, gỡ blocker creds.
4. **Card mechanic**: Layered 15 cards (Recognize → Recall → Apply) replacing 5-card lessons. Per Bloom's taxonomy.
5. **Server-shared API key**: Kill BYOK entirely. All AI calls qua server proxy với operator's Gemini key.

## Cost projection 1000 active users/month

- Reddit API: $0
- Gemini Flash rank + summary + flashcard: ~$25/mo total
- Cloudflare Workers + Firestore: $0 (free tier)
- **Total infra**: ~$25/mo
- Revenue $9.99 × 5% conv = $500/mo → **95% gross margin**

## Launch strategy

Per [growth-playbook.md](growth-playbook.md) Path C, updated 2026-05-23:

- **v1.0**: Soft launch only. KHÔNG burn PH/HN.
- **v1.0.1**: Quiet foundation update. Kill BYOK + Gemini migration.
- **v1.1**: **Big launch moment**. ProductHunt + HackerNews + Reddit. Hook = Daily Knowledge feature drop.

## Cross-references

- [v1.0.1 server proxy spec](v1-0-1-server-proxy-spec.md)
- [v1.1 daily knowledge spec](v1-1-daily-knowledge-spec.md)
- [v1.2 deep learn spec](v1-2-deep-learn-spec.md)
- [Growth playbook](growth-playbook.md)
