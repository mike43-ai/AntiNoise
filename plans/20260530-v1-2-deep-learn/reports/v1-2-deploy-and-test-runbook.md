# v1.2 Deep Learn — Deploy + Test Runbook

Everything code-side is done and pushed (`origin/v1.2-deep-learn` @ `ed051a0`).
This is the copy-paste checklist for the parts only you can run: deploy the
backend, then verify on a device. Backend URL: `https://anti-noise-api.huynguyenvan090.workers.dev`.

> Ordering: **ship v1.1 first** (it's the App Store release in flight). Do v1.2
> deploy/test whenever you want to exercise Deep Learn; it doesn't block v1.1.

---

## 1. Deploy the backend (adds /v1/learn/* routes)

The two new endpoints are additive — deploying does NOT change existing
summarize/flashcards/daily behaviour. No new secrets needed (same OpenRouter +
Firebase env as v1.0.1).

```bash
cd "/Users/huyai/Documents/Projects/Anti Noise/backend"

# 1. Sanity before deploy
npm run typecheck        # tsc --noEmit — must be clean
npm test                 # vitest — 38 tests incl. learn-endpoints must pass

# 2. Deploy
wrangler deploy          # prints the new version id + live URL
```

### Verify the routes are live (no real account needed)

Auth gate should reject — these prove the routes exist and are protected:

```bash
BASE=https://anti-noise-api.huynguyenvan090.workers.dev

# health still 200
curl -s -o /dev/null -w "health %{http_code}\n" $BASE/health

# no auth → 401 (route exists, auth enforced)
curl -s -o /dev/null -w "learn/path no-auth %{http_code}\n" \
  -X POST $BASE/v1/learn/path -H 'content-type: application/json' -d '{"topic":"RAG"}'

curl -s -o /dev/null -w "learn/day no-auth %{http_code}\n" \
  -X POST $BASE/v1/learn/day -H 'content-type: application/json' -d '{"topic":"RAG","dayIndex":2,"subtopic":"x"}'
```

Expected: `health 200`, both learn routes `401`. (A `404` means the deploy
didn't pick up the new routes — re-run `wrangler deploy`.)

Tail logs while testing from the app:

```bash
wrangler tail   # watch for learn.path.* / learn.day.* and auth lines
```

---

## 2. Build + install on device

```bash
cd "/Users/huyai/Documents/Projects/Anti Noise"
xcodegen generate
# then open AntiNoise.xcodeproj, select your device, Run — OR archive via Xcode Cloud.
```

> **Migration is the key risk.** To prove the SwiftData migration (FocusSession
> entity removed, LearningPath/LearningDay added) is safe on a *real* store:
> 1. Make sure the device currently has a **v1.1 build installed with real data**
>    (some captures + decks). Do NOT delete the app.
> 2. Install the v1.2 build **over** it (Run from Xcode / TestFlight update).
> 3. ✅ App launches with **no crash**; existing decks/captures intact; the
>    streak number is preserved (now driven by review activity).

If it crashes on launch → capture the Xcode console / Crashlytics trace and send
it; the migration would need a custom `VersionedSchema` migration plan.

---

## 3. Pro 7-day course end-to-end (needs Pro account + deployed backend)

On a **Pro** account (RevenueCat entitlement active):

- [ ] Learn tab → open a deck → **Start Deep Learn · 7 days**.
- [ ] Loading → **Day 1** shows: concept text + apply prompt + "Review today's cards".
- [ ] Tap **Review today's cards** → the day's new layered cards appear (Recognize→Recall→Apply order).
- [ ] **Mark day complete** → back on the path, Day 1 = ✓, Day 2 = "Today's lesson".
- [ ] Open **Day 2** → it lazy-loads (brief spinner) → new concept/cards (not a repeat of Day 1).
- [ ] Re-open a completed day → shows ✓, **no regeneration** (no second spinner / no new cards).
- [ ] Finish through **Day 7** → **"Mastered in 7 days 🏆"** badge; path status = completed.
- [ ] Learn hub shows the active-course card while in progress (Day N/7), gone after completion.
- [ ] **Resurfacing**: after a couple of days, the daily review includes prior-day cards that are due (SM-2).
- [ ] **One active path**: try starting a course from a *different* deck → "Finish your current course first" alert.

### Free-tier gate (on a Free account)

- [ ] Tap **Start Deep Learn** → **paywall sheet** appears.
- [ ] `wrangler tail` shows **NO** `/v1/learn/path` request fired (gated client-side before network).

---

## 4. Telemetry sanity (optional, Firebase DebugView)

Enable debug mode then watch Firebase Analytics → DebugView for:
`learn_path_started`, `learn_day_completed`, `learn_path_completed`,
`learn_path_abandoned`, and `paywall_shown` (param `trigger=deep_learn`).

```bash
# enable analytics debug for the app on a connected sim/device build (Xcode scheme arg):
#   -FIRDebugEnabled
```

---

## 5. Ship

1. v1.1.0 reaches the App Store first (separate submission from `main`).
2. When ready for v1.2: open the PR and merge **after** v1.1 is live.
   ```bash
   gh pr create --base main --head v1.2-deep-learn \
     --title "v1.2 Deep Learn (replaces Focus)" \
     --body "7-day Pro mastery course; removes Focus. See plans/20260530-v1-2-deep-learn/plan.md"
   ```
3. Bump `MARKETING_VERSION` to `1.2.0` in `project.yml` for the v1.2 archive.
4. ASC: paste v1.2 What's New + the Deep-Learn description swap (both EN/VI ready
   in `ASC_METADATA.md`); confirm App Privacy unchanged (no new data types — Deep
   Learn content is the same User Content category, processed by the same gateway).

---

## Rollback

- Backend: the routes are additive; to remove, revert the P3 commit and
  `wrangler deploy`. Existing endpoints are untouched.
- iOS: the whole feature lives on `v1.2-deep-learn`; `main` is unaffected until merge.

## Unresolved (decide at/after ship)
- Cron pre-generation of upcoming days (lower lesson-open latency) — deferred.
- 14-day course option, adaptive difficulty, share-on-complete card — all deferred.
