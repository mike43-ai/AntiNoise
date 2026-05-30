# v1.1.0 — Smoke Test + ASC Submit Checklist

Build 20 (v1.1.0) building on Xcode Cloud. When it lands on TestFlight: run §1 smoke on device, then §2 submit. No new build unless §1 finds a blocker.

Commits in this build: `6d88396` (tests + test target + version 1.1.0), `384cf51` (docs). HEAD `384cf51` on origin/main.

---

## 1. Device smoke test (build 20, TestFlight)

Run on a **fresh install** + a **brand-new account** (most v1.1 logic only fires on first run / empty state). Then repeat the daily path on an **existing v1.0 account** for the migration check.

### 1a. New-account first-run (Daily Knowledge core)
- [ ] Sign up (Apple or email) → onboarding shows **topic-packs step (required)**; can pick 1–3.
- [ ] Role / experience / goal: optional, skippable.
- [ ] First-run loading → **Home "Today's skills" shows 3 items** (curated, matched to packs). `/v1/daily/refresh` 200.
- [ ] Each card shows title + why-now/core-concept; tap a skill → **"Study this"** → summary + **15 layered cards** generated.
- [ ] Layered order in review: **Recognize (layer 0) → Recall (1) → Apply (2)**; most-overdue first within a layer.
- [ ] **Seed decks present day-one** (Learn tab not empty before any capture) — matches chosen pack, fallback Productivity.

### 1b. Quota + paywall (Free tier)
- [ ] Capture: 3/day cap → 4th blocked (existing behavior intact).
- [ ] AI summary: 10/month (not 5) — copy shows 10.
- [ ] **Daily refresh: 1/day** — 2nd "Refresh" same day → quota toast/paywall, not a crash.
- [ ] **Lesson (deck gen): 3/month** — 4th deep-dive/study-this → QuotaHitSheet; Try-again does NOT burn a slot on a failed AI call.
- [ ] Pro (if testable): all caps bypassed.

### 1c. Migration (existing v1.0 account — CRITICAL)
- [ ] Sign in to an account that had v1.0 captures/decks → **app launches, no crash** (literal-default schema migration).
- [ ] Old decks (5-card, flat) still review normally in nextReviewAt order.
- [ ] Old captures NOT retro-generated into 15 cards (cost guard).
- [ ] New captures on this account → 15 layered cards.

### 1d. Regression sanity
- [ ] Capture (URL / text / image) → summary still works (server proxy, no API-key prompt anywhere).
- [ ] Share Extension captures from Safari/Photos.
- [ ] Focus timer still launches (Focus stays in v1.1; drop is v1.2).
- [ ] Sign-out / sign-in; no "enter your OpenAI key" screen remains (BYOK fully gone).

> Any blocker here → fix → build 21 → re-smoke. Otherwise proceed to §2.

---

## 2. ASC submit prep (v1.1.0)

### 2a. Must-do before submit
- [ ] **Republish privacy policy** at `https://mike43-ai.github.io/anti-noise-legal/privacy/` (repo `anti-noise-legal`) with the updated `docs/legal/privacy-policy.md` — content changed: server-side AI gateway (Cloudflare + OpenRouter) replaces user API key; added learning-preference signals + daily inbox; "Last updated 30 May 2026". **Reviewers may diff this against app behavior.**
- [ ] **App Privacy nutrition labels** — apply the v1.1 delta (see `ASC_METADATA.md` → "App Privacy nutrition labels — v1.1 delta"): User Content now covers AI-gateway + daily inbox; NEW learning-preference signals (role/level/goal, App Functionality/Personalization, not tracking); BYOK Keychain data type removed.
- [ ] **What's New** — paste v1.1 EN + VI from `ASC_METADATA.md`.
- [ ] **Description** — paste refreshed EN + VI (now leads with Daily Knowledge + layered cards). Confirm voice.
- [ ] **Demo account** for App Review — verify the review account in `ASC_METADATA.md` still signs in AND has completed onboarding (topic packs) so reviewers see Daily Knowledge, not an empty/onboarding wall. Pre-seed a daily inbox + a couple decks if needed.

### 2b. Decide (needs user)
- [ ] **Screenshots** — current ASC set is v1.0 (no Daily Knowledge / no layered cards). UI redesign is deferred to v1.1.1, but v1.1 Home now shows "Today's skills." Options: (a) ship v1.1.0 with existing screenshots (fast, slightly understates the headline feature), or (b) add 1–2 Daily Knowledge / layered-deck shots. **Pick before submit.**
- [ ] **Build number** — `CURRENT_PROJECT_VERSION` left at "2"; Xcode Cloud is auto-incrementing (this is build 20). Confirm ASC picks build 20 and no manual bump needed.

### 2c. Verify (likely already set from v1.0)
- [ ] Support URL + Privacy Policy URL present in ASC (required for v1.0 → already configured; just confirm privacy URL content republished per 2a).
- [ ] Category Productivity / Education, Age 4+ unchanged.
- [ ] Encryption (`ITSAppUsesNonExemptEncryption=false`) unchanged.

---

## Unresolved questions
1. Screenshots: keep v1.0 set or add Daily Knowledge shots for v1.1.0? (§2b)
2. Does the App Review demo account already have onboarding done + a daily inbox, or do we pre-seed it so reviewers land on populated Daily Knowledge?
3. Republish of `anti-noise-legal` privacy page — manual via that repo (do you want me to prep the updated HTML/markdown for it)?
