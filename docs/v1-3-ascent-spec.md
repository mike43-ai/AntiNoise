# Anti Noise v1.3 — Ascent (gamified climb, replaces the Focus tab slot)

> **Theme**: A 60-day mountain expedition fueled by genuine learning. Retention via a medium-term visual goal + collectible seasons.
> **Status**: Scoped 2026-05-30 brainstorm. Ships AFTER v1.2 (Deep Learn) is live + has data. Net-new tab → app returns to 5 tabs.
> **Synced**: memory [[anti-noise-v1-3-ascent]].

## Why
Focus (Pomodoro) was removed in v1.2 (off-theme + buggy); Deep Learn took the "what next after flashcards" role inside the Learn tab, leaving the old tab slot empty (4 tabs). Ascent fills it with a feature that **drives the core flywheel**: every act of real learning earns elevation toward a summit. Gives a goal longer than a streak, shorter than "forever" — a repeatable 60-day season.

**Positioning guardrail:** the app is *Anti Noise* — it fights the save-and-never-read graveyard. So the gamification must reward **studying**, never **hoarding** or **grinding**. Reward the behavior the app exists to create.

## Core mechanic — Elevation (earned ONLY from learning)

Points are reframed as **elevation (meters climbed)**. Earn rules (user decision 2026-05-30: learning-only):

| Action | Elevation (starter — TUNABLE) | Notes |
|---|---|---|
| Review a **due** card (graded) | +10m / card | Effort-based: any honest grade counts; failing still earns (you showed up). Re-reviewing non-due cards earns 0. |
| Complete a review **session** | +20m bonus | Rewards finishing, not abandoning mid-way. |
| Complete a **Deep Learn** day | +150m | The headline daily action. |
| Capture → summarize → **first review** of it | +30m | Rewards closing the loop, NOT capturing alone. |
| Streak multiplier | ×1.0 / 1.1 / 1.25 / 1.5 (1 / 3 / 7 / 14+ day streak) | Streak (review-based, existing) feeds the climb. |

**Never earns elevation:** adding a topic, opening/flipping cards outside a due session, re-reviewing completed cards, raw capture without studying.

**Daily soft cap:** ~400m/day (post-multiplier) so a power-user can't trivialize the 60-day arc; keeps the season meaningful.

## The mountain — a 60-day expedition

- **Cumulative model:** your marker sits at total elevation earned this season. Camps at fixed fractions of the summit:
  - Base Camp (0) → Camp I (25%) → Camp II (50%) → Camp III (75%) → **Summit (100%)**.
- **Summit target (starter, TUNABLE):** ~**9,000m** over 60 days (~150m/day average). Set so **moderate consistency summits** (≈ study most days), and a sporadic user still reaches Camp II–III by day 60 (satisfying, not punishing). Target ≈ 60–70% of a max-effort ceiling, NOT the ceiling — avoids "unreachable → quit".
- **Elastic, not a gate:** the daily-pace line is advisory. Missing days just slows the climb; nothing locks. No streak-style reset of progress.
- **Camp milestones unlock a small reward** (a badge, a fact/quote card, a new biome preview, a topic suggestion) → the reason to open the tab daily = makes it a destination, not a static bar.
- **Day 60 → Summit ceremony:** permanent badge ("Summited [Peak Name]"), then a **new expedition** auto-starts on a new biome (alpine → glacier → volcano → desert mesa → canyon…). Seasons remove the day-61 cliff.

## What makes it worthy of a TAB (vs a Home hero)
User chose a dedicated tab. Justify it with destination value beyond a progress bar:
- **Today's climb** card: elevation gained today, distance to next camp, pace vs summit.
- **Trophy room:** the collection of summited peaks/biomes (a tangible long-term record).
- **Altitude report:** weekly recap (where your elevation came from — reviews vs Deep Learn).
- **Deferred (post-MVP):** climb-with-friends / leaderboard (this is the strongest "destination" driver — flag for a later iteration; needs server validation, see below).

## Aesthetic / brand
- **Minimalist topographic** — contour-line elevation profile + a clean marker, Space Grotesk numerals, Soft-Stone + Orange accent. NOT a cartoon mountain (off-brand for knowledge workers).
- Subtle motion on milestone hit (reuse `ConfettiView` / `Haptics` sparingly — summit only).

## Data model (client-side; light)
```swift
@Model Expedition {
  id: UUID
  peakName: String        // "Mont Clarté", etc.
  biome: String           // alpine | glacier | volcano | mesa | canyon
  startDate: Date
  durationDays: Int       // 60
  targetElevation: Int    // 9000 (tunable; stored so a re-tune doesn't break live seasons)
  currentElevation: Int
  status: String          // active | summited | expired
}
@Model ElevationDay {       // one row per day, for the altitude report + anti-abuse cap
  id: UUID
  expeditionID: UUID
  date: String            // yyyy-MM-dd local
  elevation: Int          // gained that day (post-cap)
  fromReviews: Int; fromDeepLearn: Int; fromCapture: Int
}
```
- **Reuse:** `StreakEngine` (multiplier), review-completion (already fires `reviewSessionCompleted`), Deep Learn day-complete (`learnDayCompleted`), capture loop. An `ElevationService` listens to these and credits the active expedition.
- Firestore mirror of `Expedition` (cross-device) like `LearningPathSyncService`.

## Pro angle (do NOT pay-to-win learning)
- Free users climb and **can summit**. 
- Pro = cosmetic biomes/peaks, a small bonus multiplier, and Deep Learn itself (which legitimately yields lots of elevation). Never gate the summit behind Pro.

## Anti-abuse / honesty
- Elevation only from **due** reviews + first-time loop completion (no grinding).
- Daily soft cap.
- MVP is **client-side** (solo, no competition) → no server validation needed. **If/when leaderboards ship**, elevation must be server-recomputed from event logs (client values become untrusted).

## Telemetry
Add: `expedition_started`, `camp_reached(camp:)`, `summit_reached(peak:)`, `expedition_expired(elevation:)`. Watch: summit rate, median elevation at day 60, day-N retention vs non-climbers.

## Effort estimate
| Work | Days |
|---|---|
| `ElevationService` + economy + daily cap + streak multiplier | 2 |
| `Expedition`/`ElevationDay` models + Firestore mirror | 1 |
| Ascent tab UI (today's climb, topographic visual, camps) | 3-4 |
| Milestone unlocks + summit ceremony + season reset + trophy room | 2-3 |
| Altitude report + telemetry + polish | 2 |
| **Total** | **~2 weeks** (visual is the long pole) |

## Risks
- **Economy balance is make-or-break** (NOT code): too easy = meaningless, too hard = quit. Ship constants as a remote-config / tunable table; instrument summit rate and adjust. Target moderate-consistency summit.
- **Extrinsic-reward crowding-out:** heavy gamification can cheapen a "serious" tool + cheapen intrinsic learning motivation. Mitigate with restrained, classy visuals + rewarding only real learning (so the points ARE a proxy for value gained).
- **Overlap with streak:** streak = consistency signal; elevation = cumulative effort. Keep both, but streak *feeds* elevation (one system narrative).
- **Tab bloat:** if it never becomes a daily destination, demote to a Home hero. Decide post-MVP from open-rate data.

## Dependencies / timing
- Ships AFTER v1.2 (Deep Learn) is live — needs the learning events + real usage data to tune the economy.
- Reuses existing events; **no new backend** for MVP (Firestore mirror only).

## Decisions locked (2026-05-30 brainstorm)
1. **Reward learning only** — due reviews, Deep Learn days, honest grades, streak multiplier. NEVER add-topic / card-flip / hoarding.
2. **Dedicated tab** (back to 5 tabs), justified by trophy room + milestones + (later) social.
3. **Seasons** (repeatable 60-day expeditions), not a one-shot mountain.
4. **Minimalist topographic** aesthetic, on-brand.

## Open questions
1. Summit target + per-action elevation: starter numbers above are guesses — tune from v1.2 review/Deep-Learn usage data before locking.
2. Leaderboard / climb-with-friends in MVP or deferred? (Strong destination driver but needs server-side anti-cheat.) Default: defer.
3. What unlocks at each camp — purely cosmetic, or functional (e.g., a bonus topic, a Pro trial nudge)?
4. Does missing the summit by day 60 carry anything forward (partial credit / head-start next season), or clean reset?
