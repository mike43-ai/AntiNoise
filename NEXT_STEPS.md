# Next Steps — Anti Noise

**State at 2026-05-18 (end of evening session):** HEAD = `7e791b8`. Working tree clean. 6 commits shipped today, all pushed to `mike43-ai/AntiNoise`.

For the full external checklist see `LAUNCH_CHECKLIST.md`. For ASC copy see `ASC_METADATA.md`. For legal text see `docs/legal/`.

---

## Done today (2026-05-18)

### Config + secrets (committed)
- ✅ `aps-environment` flipped to `production` in `project.yml`
- ✅ `RCAppPublicKey` swapped to production `appl_TDhiRXcoLJLcbQcRKhdRbVJOwuV`
- ✅ App icon 1024×1024 verified (no alpha, RGB)
- ✅ `Product UI/index.html` gitignored

### Demo account (Firebase + RC)
- ✅ Email/Password auth provider enabled in Firebase Console
- ✅ Firebase Auth user `nvhuy2708@gmail.com` (UID `AaEQK2j7uHUeKNpdYoNhS0VActP2`)
- ✅ RC entitlement `pro` created (was missing on RC project) + granted Lifetime to demo UID
- ✅ Seeded 3 captures + Feynman summaries + flashcards + 1 completed Focus session
- ✅ Streak = 1 verified on Home dashboard

### Apple Dev portal
- ✅ App ID `com.antinoise.focus` with capabilities: Sign In with Apple, Push Notifications, App Groups
- ✅ App ID `com.antinoise.focus.ShareExtension` with capability: App Groups
- ✅ App Group `group.com.antinoise.shared` registered + assigned to both App IDs

### App Store Connect
- ✅ Paid Apps Agreement + W-8BEN tax + Bank info submitted — **awaiting Apple verify (1-7 business days)**

### Docs (committed)
- ✅ `ASC_METADATA.md` — VI + EN copy ready to paste into ASC
- ✅ `docs/legal/privacy-policy.md` — 10 sections, matches 8 xcprivacy data types
- ✅ `docs/legal/support.md` — 20+ FAQ entries
- ✅ `LAUNCH_CHECKLIST.md` updated to reflect all the above

### Memory + strategy (saved for future sessions)
- ✅ v1.0.1 server-proxy plan saved at `anti-noise-v1-0-1-server-proxy.md` (kill BYOK after MVP)

---

## Tonight / next session — quick wins

Pick from these. Each is independent so you can do in any order.

### 1. Deploy legal docs to public URL (10-30 min) — RECOMMENDED FIRST

ASC submission needs **Privacy URL + Support URL** live. Three host options, easiest first:

- **Notion public page** (~5 min) — paste markdown from `docs/legal/*.md` into 2 Notion pages → Share → publish to web → grab URLs. No domain needed.
- **GitHub Pages** (~10 min) — Repo Settings → Pages → enable, branch `main`, folder `/docs`. URLs will be `https://mike43-ai.github.io/AntiNoise/legal/privacy-policy` and `.../support`. Free, no domain.
- **Cloudflare Pages** (~20 min) — connect GitHub repo, deploy `docs/legal/` as static site. Free, more control. Best if you'll later own `antinoise.app` domain.

After hosting → paste URLs into `ASC_METADATA.md` (the "URLs (TODO)" section near the bottom).

### 2. Screenshots 6.7" + 6.1" from demo account (30-60 min)

Demo data is fresh on the sim (3 captures, Feynman summary, flashcards, 1 Focus session, Pro badge). Workflow:

- Sim iPhone 15 Pro (booted) for 6.1" → 1179×2556 native
- Sim iPhone 15 Pro Max (shutdown — boot via `xcrun simctl boot BD6C6D94-B636-461B-AA3C-E97D4A08148F`) for 6.7" → 1290×2796 native
- Capture 6 key screens: Home → Capture flow → Feynman summary detail → Flashcard study → Focus timer running → Profile (Pro badge)
- Tool: `xcrun simctl io booted screenshot ~/Desktop/screenshots-6.1/01-home.png`
- Save to `~/Desktop/screenshots-6.7/` and `~/Desktop/screenshots-6.1/` for ASC paste later

### 3. ASC: create app record (10-15 min)

Bundle ID is now registered on Apple Dev portal. You can create the app record in ASC even before Paid Apps verify completes (only IAP setup is blocked).

- ASC → My Apps → "+" → New App
- Platform: iOS, Name: Anti Noise, Primary Language: English, Bundle ID: `com.antinoise.focus`, SKU: `antinoise-ios-1-0` (or similar)
- After creation → fill App Information (subtitle, category, etc.) by pasting from `ASC_METADATA.md`

### 4. Test Sign In with Apple on simulator (5-10 min)

Apple Dev portal Sign In with Apple capability was just enabled. To make sure the entitlement now resolves in fresh archive builds:
- In Xcode → Product → Clean Build Folder (⇧⌘K)
- ⌘R again → tap "Sign in with Apple" → should work end-to-end (sim supports it)

---

## Pending / blocked (not tonight)

- ⏳ **Pro SKUs** — blocked on Paid Apps verify (1-7 days)
- ⏳ **Privacy nutrition label** — fill in ASC after app record created (item 3 above)
- ⏳ **TestFlight build** — upload archive after Pro SKUs configured + 1 week soak
- ⏳ **App Review submit** — final step

## Known accepted risks (locked, don't re-open)

- OpenAI key in client — v1.0.1 server proxy is the plan (see memory `anti-noise-v1-0-1-server-proxy`)
- Timezone gaming of daily quotas — acceptable for MVP
- Apple intro-offer eligibility on re-installs — UI states it conditionally
- `Localizable.xcstrings` covers paywall / onboarding / tab / Profile shells only. Long-form copy still EN-only.

## Cross-references in repo

- `LAUNCH_CHECKLIST.md` — full external launch checklist
- `ASC_METADATA.md` — VI + EN App Store Connect copy
- `docs/legal/privacy-policy.md` — for hosting at Privacy URL
- `docs/legal/support.md` — for hosting at Support URL
- `plans/20260516-1500-anti-noise-ios-mvp/plan.md` — phase-by-phase status table
