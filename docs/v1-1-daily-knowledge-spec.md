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

### Onboarding (3 signals for AI rank)

Multi-step flow, mỗi screen 1 tap, ~15s total extra. Topic packs vẫn là Screen 1.

| # | Question | Type | Options | Signal for rank |
|---|---|---|---|---|
| 1 | Topic packs (existing) | Multi-select 1-3 | 5 packs above | Primary subreddit filter |
| 2 | **What's your role?** | Single-select, required | Engineer / PM / Designer / Founder / Student / Other | Role-relevance filter (vd Engineer + AI/ML → implementation posts; PM + AI/ML → strategy posts) |
| 3 | **How experienced are you?** | Single-select, required | Just starting (0-2y) / Building up (2-5y) / Senior (5+y) | Depth filter — Senior lọc bỏ "intro to X" |
| 4 | **What do you want from daily articles?** | Single-select, required | Learn new skills / Stay current / Get inspiration / Make better decisions | Content-type boost (tutorials vs news vs case studies vs frameworks) |

Profile screen exposes all 3 signals để edit anytime.

### AI rank

- Gemini 2.0 Flash (free tier 1500/day covers first ~500 users)
- Save vào Firestore `daily_inbox/{uid}/{date}` collection
- Prompt structure:

```
User: role={role}, level={level}, goal={goal}
Topics: [{topic_packs}]
Articles: [30 candidates with title + subreddit + snippet]

Score 1-10 each on:
- Topic match (selected packs)
- Role relevance ({role} would benefit)
- Depth match ({level} appropriate)
- Goal alignment ({goal} format)

Return top 3 with reason.
```

### Trigger entry points

Backend cần **2 entry points** để fetch + rank:

| Trigger | When | Scope | Why |
|---|---|---|---|
| **Cron 6AM UTC** | Mỗi ngày | All active users (batch) | Daily refresh trước user wake up |
| **On-demand** `POST /daily/refresh` | Onboarding xong; nút "Refresh" trong Home | Single uid | First-run momentum — không bắt user chờ tới 7AM hôm sau |

Same core logic (fetch 30 → Gemini rank → save inbox). Khác là scope (1 vs all) và trigger source.

### First-run UX (after onboarding Q4)

1. System push permission prompt
2. **Loading screen** ~3-5s: "⚡ Picking your first 3 articles..." với progress hint ("Scanning 30 posts from r/programming, r/startups...")
3. Home tab opens với 3 articles ready

### UX (rest of flow)

- **Push notification** 7AM user local: "3 articles ready for [Topic]"
- **Home tab redesign**: "Today's 3" card grid
  - Title + source (subreddit name) + reading time estimate
  - Skip button + "Capture this" button
- **FOMO mechanic**: skipped articles vanish 23:59 local
- Tap "Capture this" → existing capture flow + AI summary + 15 layered cards

### Fallback handling (on-demand path)

- **Reddit API timeout** (>5s) → fallback: top-of-week cached pool + retry trong background
- **Gemini rate limit / timeout** → fallback: top-3 by Reddit upvote score (unranked) + retry
- **Loading > 8s** → show skeleton cards + "Almost there..." copy
- **Complete failure** → "Couldn't fetch right now. Tap to retry." button trong Home tab

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
| Articles (Reddit OAuth, cron + on-demand endpoint, rank, 3-step onboarding + first-run loading + profile edit, Home inbox UI, push, fallback handling) | 7-8 |
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
- 3-step onboarding tăng drop-off ~10-20% — mỗi screen 1 tap để giảm; A/B test vs minimal onboarding sau v1.1 ship

---

## Cross-references

- [Product roadmap](product-roadmap.md)
- [v1.0.1 server proxy spec](v1-0-1-server-proxy-spec.md) — foundation phải ship trước
- [Growth playbook](growth-playbook.md)
