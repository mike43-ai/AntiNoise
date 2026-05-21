# Anti Noise — Growth Playbook (6 tuần post-launch)

Generated 2026-05-21. Source of truth cho marketing/growth execution. Update khi quyết định mới.

## Foundation decisions

| Item | Chốt |
|---|---|
| Persona | Knowledge Worker EN (devs/designers/PM) |
| Goal 90d | Downloads + signups (top-of-funnel) |
| Capacity | 5-10h/tuần, $0-50/tháng, organic only |
| Audience baseline | 0 — cold launch |
| Hook | "Turn the articles you save into knowledge you'll actually remember" |
| Path | C — Soft v1.0 + Big v1.0.1 |
| BIP X | 3-5 post/tuần, start tuần 0 |
| Landing | `antinoise.pages.dev` (Cloudflare Pages free) + Beehiiv waitlist |
| Demo | Self-record simulator + ScreenStudio/iMovie |
| PH hunter | Self-hunt, leverage BIP + email list |
| Free tier | Giữ 5 AI summaries/tháng v1.0 (review sau khi có data) |
| Anti Social co-launch | KHÔNG cùng ngày; cross-promote sau khi mỗi cái có audience |
| Market | EN-only marketing phase 1, skip VN press |

## Calendar 6 tuần

### TUẦN 0 — chờ Apple duyệt v1.0 (~10h)

- [ ] X account `@antinoise_app` + bio dùng hook (30min)
- [ ] First BIP post: "I just submitted Anti Noise v1.0 to App Review. 12 tuần build solo, here's the journey 🧵" (1h)
- [ ] Setup `antinoise.pages.dev` trên Cloudflare Pages
- [ ] Landing page: hero hook + 3 features + demo placeholder + waitlist form (4-6h)
- [ ] Beehiiv free account, embed form
- [ ] Bắt đầu Cloudflare Workers backend v1.0.1 (3-4h)

### TUẦN 1 (~10h)

- [ ] Workers backend tiếp: Firebase Admin auth + 2 endpoints `/v1/ai/summarize` + `/v1/ai/flashcards` (6h)
- [ ] BIP 3-5 posts: build log + screenshot mỗi 2 ngày
- [ ] Engage 10-20 indie/iOS account/ngày — like, reply nghiêm túc, KHÔNG follow-spam (1h/ngày)
- [ ] Apple duyệt v1.0 → respond nếu reject

### TUẦN 2 — v1.0 approved → SOFT LAUNCH (~10h)

- [ ] IndieHackers post: "I shipped my first iOS app. Anti Noise turns articles into flashcards" (2h)
- [ ] Reddit r/iOSProgramming: technical angle "How I built X with SwiftData + Firebase + OpenAI" (1h)
- [ ] Reddit r/SideProject: feedback ask (30min)
- [ ] X build-in-public thread tổng kết (1h)
- [ ] **KHÔNG** ProductHunt, **KHÔNG** HackerNews, **KHÔNG** email blast — giữ cho v1.0.1
- [ ] Tiếp Workers backend rate limit + cost monitor (4h)
- [ ] Collect feedback 5-20 early adopters

### TUẦN 3 (~8h)

- [ ] v1.0.1 client refactor: xoá BYOK UI, swap `OpenAIClient` → backend (4h)
- [ ] Test edge cases (token expired, network fail, quota hit) (2h)
- [ ] Submit v1.0.1 to ASC
- [ ] BIP teaser: "v1.0.1 coming — no more API key. Just sign in. Here's why 🧵" (1h)
- [ ] Reach out 5-10 indie creator đã engage trong BIP — soft ask launch support (1h)

### TUẦN 4 — v1.0.1 approved → PRELAUNCH PREP (~10h)

- [ ] Demo video 30-60s simulator + ScreenStudio (3-4h)
- [ ] Landing page polish: embed demo + testimonial + FAQ (2h)
- [ ] PH listing draft: tagline + description + 5 thumbnails (2h)
- [ ] HN "Show HN" post draft (1h)
- [ ] Reddit + IH posts draft cho launch day (1h)
- [ ] Email waitlist blast template Beehiiv (30min)
- [ ] Pick PH date: **Tuesday hoặc Wednesday** — avoid US holidays/big tech events
- [ ] Hỏi 5-10 early adopter ngày + giờ ủng hộ

### TUẦN 5 — BIG LAUNCH

**Day 0 (Tue/Wed PT):**
- 12:01am PT → post PH (full 24h cycle)
- 6am sáng VN (≈4pm PT D-1) → email blast waitlist
- 7am → X launch thread
- 8am → Reddit r/iOSProgramming + r/productivity + r/anki + r/learnprogramming
- 9am-10pm → respond EVERY PH comment trong 30min
- Tối → IndieHackers launch post

**Day 1:**
- HN "Show HN: Anti Noise — turn articles you save into flashcards" — submit 8am-10am PT
- Continue PH engagement
- X update "Made it to top X"

**Realistic targets D0+D1:**
- PH: top 20-30 (80-200 upvotes self-hunt với BIP runway)
- HN: front page nếu lucky, 100-500 click-through
- Tổng downloads ngày 1+2: 300-800

### TUẦN 6 — POST-LAUNCH

- [ ] BIP recap thread X: "PH launch result + what I learned"
- [ ] IH long-form: "Lessons from PH launch as solo indie"
- [ ] Start SEO blog 1 post/tuần:
  - Post 1: "AI Flashcard App: An Anki Alternative for iOS"
  - Post 2: "How to Use the Feynman Technique With AI"
  - Post 3: "Why Read-Later Apps Fail (And What to Do Instead)"
- [ ] Setup Beehiiv newsletter monthly

## Recurring habits

| Habit | Time | Why |
|---|---|---|
| X engage 20 account/ngày | 30-60min | Reciprocity cho launch day |
| BIP X 3-5 post/tuần | 2-3h/tuần | Seed audience 0 → 200-500 trong 6 tuần |
| Reddit comment 1 sub/ngày (no promo) | 15-30min | Karma + trust trước khi post launch |
| Reply 100% mention/DM | 30min | Solo advantage — pro user không làm được |

## 90d targets

| Metric | Target |
|---|---|
| Downloads | 500-1500 |
| Signups | 200-700 (~40% activation post-v1.0.1) |
| Waitlist email | 100-300 |
| X followers | 200-500 |
| Paid subs | 20-80 |

## Risks + mitigation

| Risk | Mitigation |
|---|---|
| Apple delay v1.0 review > 1 tuần | Vẫn tiếp Workers backend song song |
| v1.0.1 ASC re-review reject (privacy label) | Update `PrivacyInfo.xcprivacy` xoá 3rd-party OpenAI declaration trước submit |
| PH timing trùng US holiday | Check producthunt.com/calendar trước chốt |
| Email waitlist < 50 tuần 4 | Push BIP harder, ask trong DM, double Reddit |
| HN front page → backend cost spike | Hard rate limit Workers + alert spend > $50/ngày trước launch |

## Channels skipped (đã decide)

- ProductHunt với hunter outreach — tự hunt
- TikTok / IG Reels — wrong persona + capacity
- Paid ads — out of budget
- VN press (Genk, ICTNews) — phase 1 focus EN
- Newsletter sponsorship — out of budget
- Influencer outreach $50-200 — capacity

## Open questions (decide later)

- Bump free tier 5 → 10-15 summaries? — review sau v1.0 activation data
- Anti Social cross-promo timing — sau khi cả 2 launch + có audience riêng
- Mac Catalyst / web extension — defer; major capacity ask, post-v1.0.1
