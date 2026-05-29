# v1.1 Daily Knowledge: Planning, Red Team, P1–P2 Execution

**Date**: 2026-05-29 04:58–12:45  
**Severity**: High (go/no-go review, scope reset, phase 0–2 completed)  
**Component**: v1.1 Daily Knowledge feature, v1.2 Deep Learn planning, v1.1.1 Kinetic Command redesign  
**Status**: In Progress — Paused at P2; P3–P7 blocked on external

---

## What Happened

Completed brainstorm + planning cycle for v1.1 Daily Knowledge (layered 15-card Bloom ordering + daily Reddit articles + seed content), plus v1.2 Deep Learn scope lock. Executed red-team review (4 hostile reviewers, 19 technical findings). Applied critical fixes to P1–P2, executed both phases through code-review gates. Paused before P3 (backend pipeline) pending external deps (Reddit OAuth, Firestore deploy creds).

Scope impact: red-team cut 9-phase plan to 7 phases (~3.5 weeks → ~2 weeks) by splitting Kinetic Command redesign (P0+P8) into separate plan v1.1.1, removing cron batch (on-demand only), dropping 3-day lock (ordering only), cutting XP/radar shells, making onboarding signals optional, reducing seed to 1–2 lessons.

---

## The Brutal Truth

Two major scope resets collided today. First: the original plan was 3.5 weeks, felt bloated. Second: red-team demo'd it was *worse* than bloat — it was technically risky (SwiftData migration crash-loop on v1.0 users, auth middleware gap, zero Firestore rules). Then: redesign scope was 40% of the work and visually decoupled. So we yanked it.

Result: plan shrunk to 7 phases, timeline halved, but the "layered cards are auto-generated from Study this" myth got **exposed hard**. Card generation is 100% manual in `SummaryDetailView`. What's auto is the 15-card flatten, not the layering. That's a product workflow problem, not a code problem — but it explains why the build felt like moving dirt.

Also stung: v1.2 Deep Learn was *designed* to reuse the 3-day lock/unlock push that we just cut. So v1.2 now has to reinvent day-pacing. Not blocked, but adds 2–3 days to v1.2 planning.

---

## Technical Details

### Red Team Findings (19 after dedup; 6 Critical accepted & applied)

1. **SwiftData migration crash-loop risk** (`Flashcard.swift` schema change): non-optional `unlockedAt: Date` with default `Date()` → existing v1.0 users run migration, hit fatalError (no recovery path). Applied P2 `phase-02-…md` with optional field + backfill logic.

2. **`/daily/refresh` outside auth middleware** (`backend/src/index.ts`): named outside `/v1/*` → shipped unauthenticated. Fixed in P3 phase file: uid must come from JWT token, not body.

3. **Instant-due card flood on Day 1** (`Flashcard.nextReviewAt=Date()`): 15 layered cards default to today → `dueTodayCount` predicate has no unlock filter → all 15 land same morning. Applied P2: only unlocked cards count as due.

4. **Firestore rules absent from repo**: `daily_inbox` + `users/{uid}` collections unsecured. Applied P3 phase file: deploy rules before shipping, field-level read gates on articles.

5. **Backend has zero Firestore code**: `firebase-admin.ts` only does `setUserTier` (delete account). "extend backend" in P3 is net-new: doc structure, read/write paths, error handling. Effort re-estimated in P3 phase file.

6. **"Study this → 15 cards" is false**: card gen is manual (`SummaryDetailView` CTA button), not auto. `CaptureFlowModel.save()` only summarizes. Applied P4: clarify UI workflow — "Study & Create Flashcards" explicit button, no auto-deck-gen from summary alone.

**High-severity finds** (9 more):
- `/daily/refresh` no quota gate (DoS drains shared Gemini key across users)
- SSRF in `ReadabilityExtractor` (no URL scheme/host validation)
- Phase 0 colors live in `.xcassets`, not `AppColor.swift` (no-op risk)
- Quota KV non-atomic (double-tap bypass)
- Cron infra missing entirely (`export default app` has no `scheduled()`)
- Backend prompt generates 3–15 cards, not force-15 (needs 5-5-5 override)
- Existing v1.0 users skip re-onboarding → no signals doc
- iOS only has daily counter, not monthly (quota issue)
- Reddit token in shared KV (leak risk)

All 19 with file:line anchors logged in plan's Red Team Review table.

### Scope & YAGNI Cuts (7 items, 6 accepted by user)

| Item | Accepted | Reason |
|------|----------|--------|
| Split Kinetic Command redesign (P0+P8) to v1.1.1 | ✅ | ~40% scope creep; visual-only, can ship separately |
| Remove XP/SkillRadar shells | ✅ | Gold-plating vs 2-week spec |
| Drop 3-day lock, keep ordering | ✅ | Lock blocks owned cards; flaky time tests |
| Make onboarding signals optional | ✅ | 6-screen flow → 10–20% drop-off |
| Defer cron batch (on-demand only) | ✅ | Premature for soft-launch (200–700 signups/90d) |
| Reduce seed to 1–2 lessons | ✅ | 75 hand-QA'd cards too heavy |
| Collapse "Study this" to 1 button | ⏸️ | User kept 2 options (revisit at build if confusing) |

**Net scope:** 9 → 7 phases; 3.5 weeks → ~2 weeks.

### P1 & P2 Execution (commits 33e0f19, 675d949)

**Phase 1 — Onboarding Topic Packs** (commit 33e0f19):
- Topic packs (required) + optional role/level/goal signals in Profile post-onboarding.
- `UserProfileSyncService` mirrors profile changes to Firestore `users/{uid}`.
- Existing v1.0 users: backfill gate in `RootView` (skip if signals version = 0).
- Code review: APPROVE_WITH_NITS — fixed M1 finding (FieldValue.delete for cleared signals).
- Build ✅.

**Phase 2 — Layered 15 Flashcards** (commit 675d949):
- `Flashcard.layerIndex` (0–2 = Recognize, Recall, Apply) + `nextReviewAt` unlock filter.
- `Deck.isLayered` boolean, literal defaults (migration-safe, verified).
- Backend prompt forces 15/5-5-5 split; thin-source flat fallback if Gemini under-generates.
- No time-lock (3-day unlock cut per red-team C).
- Code review: APPROVE_WITH_NITS.
- Build ✅.

**Commits not pushed**: 3 commits ahead of origin/main. User paused before P3 external blockers.

---

## Root Cause Analysis

**Scope bloat root**: Plan baseline was underspecified. Red-team exposed 6 critical technical gaps (auth, migration, rules, generation pipeline, infra). Parallel redesign scope (Kinetic Command P0+P8) lumped into same plan even though visually decoupled. Solution: split scope by technical risk (v1.1 cards) vs visual refresh (v1.1.1), reduce to 2-week timeline.

**Redesign collision**: User's original v1.1 spec had no design-system changes. Kinetic Command was a "nice to ship same time" add-on. Red-team flagged it as 40% scope + zero design-system anchors in code (colors still in .xcassets). Simple: move to own plan, own ship cycle, own QA/rollback.

**v1.2 Deep Learn fallout**: Originally v1.2 was to reuse v1.1's 3-day unlock infra as baseline. Red-team cut lock (too risky, no time); v1.2 spec didn't account for that fork. Not a blocker, but adds rework when v1.2 planning starts.

---

## Lessons Learned

1. **Scope ownership**: When a feature (redesign) is visually decoupled from core mechanic (cards), split to separate plan + commit cycle. Keeps P0/P8 design churn from affecting card stability.

2. **Red-team as scope reset**: 4 hostile reviewers caught 6 critical findings **before code**, not after ASC rejection. Effort: 2 hours. ROI: avoided migration crash, auth bypass, unsecured Firestore. Worth the cycle delay.

3. **Card generation pipeline clarity**: User expectation was "Study this → auto 15 cards". Reality: "Study this → summarize → manual card-create button → backend enforces 15/5-5-5". That gap is a UX problem (user friction), not a code problem. Expose early, design the workflow, *then* code.

4. **External blockers**: P3 blocked on Reddit OAuth creds + Firestore rules deploy. Not a code-review gate. Listing them upfront saves 1–2 days of "why isn't P3 merging?"

---

## Next Steps

### P3 External Blockers (backend daily pipeline)

- [ ] Reddit OAuth credentials (app ID, secret) — user must request from r/antinoise mod or create bot account
- [ ] Firestore security rules file (`firestore.rules`) — schema + field-level read gates for daily_inbox, users/{uid}
- [ ] Wrangler deploy credentials + Workers KV bindings (DAILY_ARTICLES_CACHE, REDDIT_TOKEN_KV, GEMINI_QUOTA)

### Unpushed Commits

- `33e0f19` — onboarding topic packs + optional signals
- `675d949` — layered 15-card Bloom ordering
- P2 code-review notes (APPROVE_WITH_NITS, fix FieldValue.delete)

Once P3 external deps resolved + pushed, proceed with P4 (iOS daily articles UI + Study this flow refinement).

### Open Questions

- v1.2 Deep Learn: when planning, re-spec day-pacing infra (no 3-day lock assumption). Current delta: +2–3 days dev time.
- "Study this" dual-option (2 buttons vs 1): user kept both for Feynman-also-cards; revisit at P4 build if confusing UX emerges.
- Phase 0 color migration: `AppColor.swift` overhaul deferred to v1.1.1 Kinetic Command plan; current v1.1 uses existing `.xcassets` colorsets.

---

**File written**: `/Users/huyai/Documents/Projects/Anti Noise/docs/journals/2026-05-29-v1-1-daily-knowledge-planning-and-p1-p2.md`
