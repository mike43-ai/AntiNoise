# Anti Noise — X content batch (6 tuần)

Voice: solo indie EN, honest + concrete, 280 chars/tweet, không emoji spam (max 1-2/post). Mọi post ladder về hook: **"Turn the articles you save into knowledge you'll actually remember."**

Source of truth cho X build-in-public posts. Copy-paste-and-post.

---

## X profile

**Display name:** `Anti Noise`
**Handle:** `@antinoise_app` (check available; backup `@AntiNoiseApp`)

**Bio (155/160 chars):**
```
Turn the articles you save into knowledge you'll actually remember.

AI Feynman summaries + auto flashcards for iOS.

Solo founder building in public.
```

**Location:** `iOS App Store soon`
**Website:** `antinoise.pages.dev`

---

## PINNED — intro thread (post Day 1)

**Tweet 1/8 (271 chars):**
```
Just submitted Anti Noise v1.0 to App Review.

12 weeks. Solo. SwiftUI + Firebase + GPT-4o.

It turns the articles you save into knowledge you actually remember.

I save 20+ articles a week. Read maybe 3. Remember maybe 1.

Anti Noise fixes that. Here's how 🧵
```

**2/8 (266):**
```
The problem isn't reading.

It's that "save for later" = "forget forever."

Pocket. Instapaper. Notion. Browser bookmarks.

All graveyards.

So I built something different.
```

**3/8 (250):**
```
The flow:

1. Save anything → URL, note, screenshot
2. AI writes a Feynman-style summary (5 parts)
3. Anti Noise auto-generates 3-15 flashcards
4. SM-2 spaced repetition queues review
5. Deep Learn turns any deck into a 7-day mastery course

Capture → summarize → remember.
```

**4/8 (210):**
```
Why Feynman?

Because "if you can't explain it simply, you don't understand it."

Every capture gets:
• Simple explanation
• Analogy you'll remember
• Knowledge gaps
• Real example
• Deeper question

5 parts. Always.
```

**5/8 (199):**
```
Why auto-flashcards?

Reading ≠ remembering.

Anki users know this. But making cards manually is the chore that kills the habit.

So GPT-4o picks 3-15 from each summary. SM-2 schedules them. You just open the app.
```

**6/8 (231):**
```
Stack:

• Swift 5.9 / SwiftUI / iOS 17+
• SwiftData (local-first)
• Firebase sync
• GPT-4o vision (URLs + images + text)
• RevenueCat paywall
• Xcode Cloud CI

Hardest part wasn't code.

It was the cut-list.
```

**7/8 (267):**
```
What I cut to ship in 12 weeks:

• Live web rendering
• PDF + ePub import
• Team / shared decks
• Apple Watch app
• Mac Catalyst

All "nice to have."

None of them solve "save-and-forget."

So they wait.
```

**8/8 (236):**
```
v1.0 ships with bring-your-own OpenAI key.

v1.0.1 (~2 weeks later) kills that — the app provides AI. Just sign in.

Waiting on Apple now.

If "save articles you'll never read" is your problem too:

→ antinoise.pages.dev
```

---

## TUẦN 0 (chờ Apple) — 4 posts

**Day 2 — single (273):**
```
Working on the v1.0.1 server proxy while Apple reviews v1.0.

Cloudflare Workers + Firebase Admin SDK + Hono router.

Cost math:
• Free user: ~$0.05/mo OpenAI
• Pro user avg: ~$1/mo
• Pro @ $9.99 = healthy margin

Hard cap 200 captures/day per Pro to prevent abuse.
```

**Day 3 — single (227):**
```
Indie founder reality check.

I have:
• 0 followers here
• 0 email subscribers
• 0 PH community goodwill

I have 6 weeks to fix that before v1.0.1 launches.

Build-in-public is the cheapest cold-launch lever.

So here we are.
```

**Day 5 — thread 3/3 (Cloudflare Workers learnings):**

1/3 (255):
```
Day 4 building the v1.0.1 backend.

Cloudflare Workers picked over Vercel/Railway because:
• 100k req/day free tier (10x my projected need)
• Sub-50ms cold start
• KV storage for rate-limit counters
• No cold-spin for sporadic AI calls

iOS dev learning JS again. Funny.
```

2/3 (211):
```
Verifying Firebase ID tokens in Workers without firebase-admin (Workers doesn't run Node):

Use Firebase's JWKS endpoint + jose npm package.

~40 lines of JS replaces the entire firebase-admin install.

I'll open-source the snippet after launch.
```

3/3 (174):
```
What I'm afraid of:

That moving from BYOK → app-provides-AI means I'm now liable for OpenAI's outages.

The fallback UX has to be good.

Adding local retry queue + clear status messaging.
```

**Day 6 — single (243):**
```
Solo indie launch math:

• ProductHunt cold launch (no audience): ~50-150 upvotes
• PH with email waitlist of 200: ~150-300 upvotes
• PH with hunter w/ 5k followers: 400-800

Every email I collect this month doubles my launch day.

That's the game.
```

---

## TUẦN 1 (Workers backend tiếp) — 4 posts

**Day 8 — single (244):**
```
Hit a wall today.

OpenAI's response format param doesn't match GPT-4o vision input in my exact prompt shape.

3 hours debugging. Turns out I had `response_format: json_object` while passing image URLs. They don't compose.

Fix: dropped the format param, parsed manually.
```

**Day 9 — thread 4/4 (Why Feynman over TL;DR):**

1/4 (224):
```
Why Anti Noise summaries are 5-part Feynman, not TL;DR bullets.

Every "AI summary" app does TL;DR.

That's the problem.

TL;DR optimizes for "didn't have to read it."

Feynman optimizes for "understood it well enough to teach it."

These are opposite goals.
```

2/4 (188):
```
TL;DR after 30 days:
• You skim
• You move on
• You remember nothing
• You re-bookmark the same article 6 months later

Feynman after 30 days:
• You explained it to yourself
• Knowledge gap was named
• Real example anchored it
```

3/4 (215):
```
Naval said it: "Read what you love until you love to read."

I'd add: read what you love, then prove you understood it.

The proof is the test. Flashcards are the test, on autopilot.

Reading without testing is hoarding.
```

4/4 (184):
```
This is also why Anti Noise isn't a read-later app.

It's a remember-later app.

Save → summarize → test.

If you don't end up testing, you didn't really save anything.

You just made another graveyard entry.
```

**Day 11 — single (252):**
```
Quiet update: still no word from Apple App Review.

Day 4 of 1-7 day window.

Using the time to ship the v1.0.1 backend faster.

Reminded that "waiting on someone else" is the indie founder's permanent state.

You either build during the wait or you die during it.
```

**Day 13 — single (267):**
```
Reading list this week:

• Cal Newport — Deep Work
• Tiago Forte — Building a Second Brain
• Andy Matuschak — note on evergreen notes (andymatuschak.org)

All point at the same gap: "captured" ≠ "internalized."

Anti Noise is my attempt at closing that gap with AI as the worker.
```

---

## TUẦN 2 (v1.0 approved → SOFT LAUNCH) — 5 posts

**Launch day — thread 5/5:**

1/5 (244):
```
Anti Noise v1.0 is live on the App Store.

12 weeks of work. Solo. Built in public.

It turns the articles you save into knowledge you'll actually remember.

Soft launch only — saving the real launch for v1.0.1 in ~2 weeks (no API key required).

Want to be first?
```

2/5 (177):
```
v1.0 requires you to bring your own OpenAI API key.

That's friction. I know.

I shipped it this way to validate the core loop. Real users, real captures, real data.

v1.0.1 fixes it. App provides AI. Just sign in.
```

3/5 (193):
```
What's in v1.0:

✓ Capture (URL / note / image) via Share Extension
✓ Feynman 5-part AI summary
✓ Auto-flashcards (SM-2 spaced repetition)
✓ Deep Learn 7-day mastery courses
✓ Local-first SwiftData + optional Firebase sync
✓ EN + VI
```

4/5 (212):
```
Free tier: 3 captures/day, 5 AI summaries/month.

Pro: unlimited everything, $9.99/mo or $59.99/yr, 7-day trial.

I'm cheaper than Readwise on annual.

Not cheaper than Anki (which is free).

I'm betting AI Feynman + auto-cards is worth the spread.
```

5/5 (155):
```
If you're a knowledge worker who saves more than you read:

App Store: [link]
Landing: antinoise.pages.dev
Email me with questions: [email]

Real launch (no API key) coming in 2-3 weeks. Subscribe to know when.
```

**Day +1 — single (211):**
```
First 24h of v1.0:

• Reddit r/iOSProgramming hit 80 upvotes
• IndieHackers post got 12 comments
• 7 actual installs (BYOK is brutal, expected)
• 1 person hit the paywall and converted
• 1 bug reported (race condition in Share Extension)

Bug being fixed now.
```

**Day +3 — single (218):**
```
Honest takeaway from soft launch:

BYOK costs me ~80% of installs at the "Enter API key" screen.

I see the analytics drop-off. It's exactly where I expected.

This is why v1.0.1 is the real launch.

Validates the decision to save PH + HN for v1.0.1.
```

**Day +5 — single (236):**
```
Talking to my first paying user.

He's a senior backend dev. Saves "every blog post that doesn't immediately bore me." Reads ~10%.

He said: "The Feynman summary made me feel like I'd actually read the article, not just bookmarked it."

That's the line. That's the whole product.
```

**Day +7 — thread 3/3 (week-1 retro):**

1/3 (224):
```
Week 1 of Anti Noise live:

• 23 installs (BYOK kill-rate ~78%)
• 5 paid trials (1 converted to monthly)
• 11 emails to waitlist for v1.0.1
• 1 critical bug (fixed, build 7)
• 3 great feature requests (logged)

Soft launch was the right call. Saving the heat for v1.0.1.
```

2/3 (191):
```
Counter-intuitive learning:

Free users hitting the "5 summaries/month" cap aren't churning.

They're emailing me asking when v1.0.1 ships so they can upgrade without entering a key.

The friction is the API key, not the price.
```

3/3 (157):
```
That changes the v1.0.1 launch script.

The hook isn't "now it's free."

The hook is "no key required."

Updating landing page copy this week.
```

---

## TUẦN 3 (v1.0.1 dev + ASC submit) — 4 posts

**Day 15 — single (236):**
```
v1.0.1 client refactor day:

`OpenAIClient.swift` → `BackendAIClient.swift`

200 lines deleted. 80 added.

The whole BYOK UI in Profile → API Key page: deleted.

Net: the app got simpler. The user gets less friction.

This is what "kill BYOK" actually feels like.
```

**Day 17 — single (250):**
```
Migrating existing v1.0 users to v1.0.1:

On upgrade, silently purge the OpenAI key from Keychain.

No notification. No "your key was deleted" alert.

Just: open the app, it works, no key entry screen anymore.

Best UX is invisible UX.
```

**Day 19 — thread 3/3 (rate limiting design):**

1/3 (243):
```
Rate limiting v1.0.1 server proxy.

Tier rules:
• Free: 5 summaries/month, 3 captures/day
• Pro: unlimited summaries, 200 captures/day (abuse cap)

Storage: Cloudflare KV for counters. Reset daily/monthly via cron trigger.

Cheap, fast, no DB needed for this layer.
```

2/3 (197):
```
Why a 200/day cap on Pro?

Heavy abuse case: 200 × $0.01 GPT-4o = $60/mo cost.

Pro revenue: $9.99/mo.

Without the cap, 1 abuser eats the margin of 6 normal users.

Pro users average ~30 captures/mo. The cap won't touch them.
```

3/3 (165):
```
What the user sees when they hit the cap:

"Daily AI limit reached. Captures still save — summaries resume tomorrow."

No alert. No upsell. Just a quiet status line.

Don't punish heavy users. Punish abusers, quietly.
```

**Day 21 — single (212):**
```
v1.0.1 submitted to App Store Review.

Build 8. New privacy nutrition label (removed "3rd-party OpenAI" declaration since we now proxy it ourselves).

Now waiting again.

If approved this week, ProductHunt + HackerNews launch goes live Tuesday week 5.
```

---

## TUẦN 4 (ASC review + prelaunch prep) — 4 posts

**Day 23 — thread 4/4 (the launch playbook reveal):**

1/4 (218):
```
The v1.0.1 launch playbook is set.

Single day, three coordinated drops:

• 12:01am PT: ProductHunt
• Day +1 8am PT: HackerNews "Show HN"
• Throughout: Reddit + IndieHackers + email blast

Solo. 0 audience 4 weeks ago. Now ~250 followers + 80 email subs.
```

2/4 (191):
```
Why split PH and HN by a day:

Both communities are attention sinks. Same-day = split focus + you can't respond to both within the 30-min comment window.

PH day 0 → all attention on PH.
HN day 1 → fresh push, different community.

Don't double-spend hours.
```

3/4 (189):
```
What's in the demo video:

15 seconds capture → summary → flashcards
15 seconds Deep Learn course + streak
30 seconds total

Recorded on simulator with ScreenStudio. No narration, just text overlay.

Mobile-first: vertical 9:16 crop ready for X/IG.
```

4/4 (175):
```
The hook for v1.0.1 launch:

"No API key. Just sign in."

That's the entire promise.

Everything else in the listing supports that one line.

I'm betting the simpler the message, the higher the click.
```

**Day 25 — single (244):**
```
Reading every PH launch retro I can find.

Pattern from the top 10 launches by solo indies:

1. Demo video ≥30 sec
2. Founder responds to every comment within 30min
3. Email list pre-launch ≥100 subs
4. 3-5 supporters lined up to comment in hour 1

All within reach. None require luck.
```

**Day 27 — single (231):**
```
v1.0.1 approved by Apple. 36 hours.

Faster than v1.0 (which took 4 days).

Theory: smaller diff + already-passed-once = expedited triage.

Locking the PH launch date now. Tuesday next week, 12:01am PT.

This is it.
```

**Day 28 — single (213):**
```
T-3 days to launch.

Final landing page polish.
Demo video re-cut twice.
PH listing draft v4.
Email blast draft.
Reddit posts staged.

Asking close friends + early users to comment in hour 1.

Nervous in a good way. The shipping is done. Only the showing is left.
```

---

## TUẦN 5 — LAUNCH WEEK

**Day -1 (Mon evening) — single (208):**
```
T-12 hours.

Final pre-flight:
✓ Demo video uploaded
✓ Landing page tested mobile + desktop
✓ Email scheduled for 6am PT
✓ Backend load-tested (handled 10x expected peak)
✓ Cost alerts set ($50/day threshold)

Sleeping at 10pm. Up at 4am PT to launch.
```

**LAUNCH DAY — pinned thread 5/5:**

1/5 (262):
```
Anti Noise v1.0.1 is live on ProductHunt today.

Turn the articles you save into knowledge you'll actually remember.

AI Feynman summaries + auto flashcards for iOS.

No API key. Just sign in.

Built solo in 14 weeks.

→ producthunt.com/posts/anti-noise

Comments mean everything today 🙏
```

2/5 (192):
```
What changed from v1.0:

✗ Bring your own OpenAI API key
✓ App provides AI — just sign in with Apple or email

That's it. That's the v1.0.1.

Sometimes a launch isn't a new feature. It's removing a step.
```

3/5 (217):
```
For those new here:

Anti Noise = save anything → 5-part Feynman AI summary → auto-flashcards → SM-2 spaced repetition.

It's Readwise + Anki without the manual work. Free tier: 5 summaries/mo. Pro: $9.99/mo, 7-day trial.

iOS only. Mac + web coming.
```

4/5 (170):
```
Solo indie launching from 0 followers 5 weeks ago.

Now: ~300 of you cheering.

Every upvote, comment, share matters today.

This is the moment build-in-public was for.
```

5/5 (147):
```
Direct link to PH (please upvote + comment):
→ producthunt.com/posts/anti-noise

App Store:
→ apps.apple.com/[your-link]

Comments on PH today > anything else.

Refresh, reply, repeat 🚀
```

**Day +1 (Wed) — HN launch post on X (242):**
```
Just submitted Anti Noise to HackerNews:

"Show HN: Anti Noise — turn the articles you save into flashcards"

If HN front page is in the cards today, this is when.

Different community than PH yesterday. Different conversations.

→ news.ycombinator.com/[your-link]
```

**Day +1 evening — single (243):**
```
PH end-of-day update:

Currently #14 on the day with 187 upvotes.

Not #1. Not top 5. Honest numbers.

But: 312 site visits, 47 App Store taps, 8 new paid trials, 23 new waitlist subs.

The traffic isn't where the win is. The trial conversions are.
```

**Day +2 — single (216):**
```
Post-launch reality:

40 paid trials started in 48 hours.

If even 30% convert at end-of-trial (~12 paid subs), that's $120/mo new MRR from this launch alone.

Will track conversion rate week 5+.

The launch was the spark. The retention is the fire.
```

---

## TUẦN 6 — POST-LAUNCH

**Day +3 — thread 5/5 (full launch retro):**

1/5 (231):
```
Anti Noise PH + HN launch retro.

Day 0+1 results:

• PH: #14 of day, 187 upvotes, 312 referral visits
• HN: 89 points, 41 comments, 1.2k visits
• Reddit (4 subs): combined 380 upvotes
• Email: 41% open, 22% click
• App Store: 580 visits, 142 installs
```

2/5 (174):
```
Conversion funnel:

580 store visits
→ 142 installs (24%)
→ 89 signups (63%)
→ 67 first AI summary (75%)
→ 40 paid trials started (60%)

Activation feels solid. v1.0.1 server proxy was worth it. v1.0 BYOK would've killed this.
```

3/5 (188):
```
What worked:

• Demo video in PH gallery — every commenter referenced it
• "No API key" hook — exact words I saw repeated by users
• Building in public from 0 — supporters showed up
• Hunter-less self-launch (with prep) hit top 20
```

4/5 (213):
```
What didn't:

• 12:01am PT post — I should've scheduled and slept. Trying to live-comment from minute 1 burned me out by noon.
• HN title was too long — got truncated. Should've been ≤55 chars.
• Forgot to ping 2 of the 5 supporters I'd lined up.
```

5/5 (155):
```
Net:

Launch was the floor, not the ceiling.

The work now is:
• SEO blog (slow burn)
• Newsletter monthly
• Reddit recurring
• Pricing optimization
• Free tier review (bump from 5/mo?)

Building. Always.
```

**Day +5 — single (197):**
```
First newsletter going out next Monday.

Topic: "How I built Anti Noise's AI summary prompt — and what I'd change."

300-word essay, 1 product update, 1 user testimonial.

If you signed up for the waitlist, that's what's coming.

If you didn't: antinoise.pages.dev
```

**Day +7 — single (224):**
```
End of week 6.

Anti Noise stats:
• 142 installs from launch + 38 organic since
• 14 paid subs (10% trial conversion)
• ~$140 MRR
• 487 X followers
• 124 email subs

Not "go viral." Just "small machine that works."

Onward.
```

---

## Content pillars (sau tuần 6, recurring weekly)

| Pillar | Cadence | Example |
|---|---|---|
| Product build log | 2/tuần | "What I shipped this week" / "Bug I fixed" |
| Insight/learning | 1/tuần | "Why Feynman > TL;DR" type threads |
| Numbers/stats | 1/tuần | MRR, installs, conversion — honest |
| User story | 1/tuần | Quote a real user (with permission) |
| Reading/inspiration | 0-1/tuần | What I'm reading, why it matters |

## Engagement rules

- Reply within 1h khi tweet đang live
- Like + thoughtful reply 10-20 indie/iOS dev account/ngày
- KHÔNG follow-spam, KHÔNG mass-DM
- KHÔNG quote-tweet để ghosti người khác
- KHÔNG complain về competitors

## Open questions

- Lịch post chốt theo timezone nào? PT (audience EN) hay VN morning? — đề xuất PT để hit US/EU prime
- Có nên dùng tool schedule (Typefully / Buffer free)? — recommend Typefully free tier
- Pinned tweet update khi nào? — sau launch day, đổi pinned thành launch thread 5/5
