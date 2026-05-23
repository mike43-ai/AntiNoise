# Anti Noise v1.1 — Daily Knowledge

> **Theme**: Discovery + spaced layered learning. Big launch moment.
> **Effort**: ~2 tuần (5-7 ngày articles + 3-5 ngày cards + 2 ngày polish + ASC review).
> **Status**: Scoped 2026-05-23 brainstorm. Ships ~4-6 tuần sau v1.0.1.

## Why

v1.0 capture-on-demand không có daily resurface hook → retention gap. v1.1 thêm 2 mechanic:
- (a) App-initiated daily content discovery
- (b) 3-day study journey thay vì 3-minute event

Mục tiêu: lý do open mỗi ngày.

---

## Feature 1: Daily 3 articles

### Content source

**Reddit API only** (free, OAuth). Skip Twitter ($100+/mo), skip HN/Dev.to.

Backend cron 6AM UTC: fetch top of day từ subs theo topic pack mapping.

### Topic packs (5 default)

| Pack | Subreddits |
|---|---|
| 🧠 AI/ML | r/MachineLearning, r/LocalLLaMA, r/learnmachinelearning |
| 🛠 Engineering | r/programming, r/webdev |
| 🎨 Product/Design | r/UXDesign, r/ProductManagement |
| 🚀 Startup | r/startups, r/SaaS, r/Entrepreneur |
| ⏱ Productivity | r/productivity, r/getdisciplined |

### AI rank

- Gemini 2.0 Flash (free tier 1500/day covers first ~500 users)
- Prompt: chấm 30 articles → top 3 theo "match user topic interest" + "knowledge worker relevance"
- Save vào Firestore `daily_inbox/{uid}/{date}` collection

### UX

- **Onboarding screen mới**: multi-select 1-3 topic packs
- **Push notification** 7AM user local: "3 articles ready for [Topic]"
- **Home tab redesign**: "Today's 3" card grid
  - Title + source (subreddit name) + reading time estimate
  - Skip button + "Capture this" button
- **FOMO mechanic**: skipped articles vanish 23:59 local
- **Profile → "My Topics"**: edit anytime
- Tap "Capture this" → existing capture flow + AI summary + 15 layered cards

---

## Feature 2: Layered 15 flashcards

### Mechanic

AI generates 15 cards per capture (thay vì 5), theo Bloom's taxonomy:

| Day | Layer | Format | Count |
|---|---|---|---|
| Day 1 | Recognize | Multiple-choice / identify concept | 5 cards |
| Day 2 | Recall | Open-ended Feynman / explain own words | 5 cards |
| Day 3 | Apply | Scenario-based / use in context | 5 cards |

### UX

- Learn tab card shows:
  - "Day X/3" progress
  - 5 cards remaining
- **Locked state** với countdown: "Day 2 unlocks in 14h 23m"
- **Mastered state**: golden badge "Mastered in 3 days ⭐"
- Push notification "Day 2 of [topic] unlocked" mỗi sáng

### Migration

- Existing captures (5 cards) → marked legacy, vẫn SM-2 review
- New captures từ v1.1 → 15 cards layered
- KHÔNG retro-generate cards cho captures cũ (tiết kiệm AI cost)

---

## Quota structure v1.1

| Tier | Daily articles | Captures | Layered card lessons |
|---|---|---|---|
| Free | 1/day | 3/day (giữ) | 3 lessons/month |
| Pro | 3/day | unlimited | unlimited |

Pro pricing giữ $9.99/mo (review sau data v1.1).

---

## Effort estimate

| Work | Days |
|---|---|
| Articles (Reddit OAuth, cron, rank, onboarding, Home inbox UI, push) | 5-7 |
| Layered cards (AI prompt, Learn tab UI, lock countdown, migration) | 3-5 |
| Polish + paywall update | 2 |
| ASC re-review | ~3 |
| **Total** | **~2 tuần dev + 3 ngày review** |

---

## Risks

- Reddit API rate limit nếu user tăng nhanh → cần caching layer per subreddit per hour
- Topic pack curation maintenance: subs có thể chết/private/move
- 15 cards = 3x AI cost vs 5 → monitor margin tight
- User overwhelm: 3 articles + 3-day journey = lots of "homework", có thể churn ngược

---

## Cross-references

- [Product roadmap](product-roadmap.md)
- [v1.0.1 server proxy spec](v1-0-1-server-proxy-spec.md) — foundation phải ship trước
- [Growth playbook](growth-playbook.md)
