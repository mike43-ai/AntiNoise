# Anti Noise — Support

Welcome. This page covers the most common questions about Anti Noise and how to reach us if you need help.

**Need direct help?** Email **nvhuy2708@gmail.com** — we respond within 1–2 business days.

---

## What is Anti Noise?

Anti Noise is an iOS app for solo learners and knowledge workers. Save an article, drop a note, snap a screenshot — Anti Noise turns each capture into a Feynman-style summary and automatically generates spaced-repetition flashcards from the ideas worth remembering. Go deeper with Deep Learn — 7-day mastery courses built from your decks.

Available on iPhone, iOS 17 and later. English and Vietnamese.

---

## Frequently asked questions

### Getting started

**How do I create my first capture?**
Open the Capture tab → choose URL, Text, or Image → submit. You will see a status banner (Queued → Processing → Done). When done, tap the capture to read the Feynman summary and review the generated flashcards.

**Why do I need to enter an OpenAI API key?**
Anti Noise uses OpenAI's GPT-4o model to generate summaries and flashcards. In v1.0 you supply your own API key, which is stored only in the iOS Keychain on your device. We do not see, transmit, or store your key. A future update will offer a server-side option so you do not need to bring your own key.

**Where do I get an OpenAI API key?**
Sign up at https://platform.openai.com → API keys → Create new secret key. Add a small amount of credit (typically $5 is plenty for a month of personal use).

**Why is my first capture failing with "HTTP 429"?**
This usually means your OpenAI account has no credit balance. Add $5 at https://platform.openai.com/settings/organization/billing/overview and tap "Try again" on the failed capture.

### Captures and AI summaries

**What kinds of content can I capture?**
- URLs to articles, blog posts, or any public web page
- Text notes you type or paste
- Images and screenshots (processed with GPT-4o vision)

**What is a Feynman summary?**
Each summary follows the Feynman learning method and contains five sections: a simple explanation, an analogy, knowledge gaps the model identified, real-world examples, and a deeper question for further reflection.

**Can I edit a summary?**
Summaries are read-only in v1.0. We are considering editing in a future release. Tell us if this matters to you.

**A summary stalled or shows an error. What do I do?**
Open the capture and tap **Try again** in the summary detail view. If it keeps failing, check your OpenAI credit balance and your network connection.

### Flashcards

**Where do the flashcards come from?**
For each capture, the AI selects 3–15 flashcards based on content density. You do not have to build decks manually.

**Which spaced-repetition algorithm do you use?**
SM-2, the classic Anki algorithm. Easy cards return after weeks; difficult cards return within days.

**How do I review cards?**
Open the Learn tab. The deck shows cards due today. Tap a card to flip, then rate your recall.

### Deep Learn

**What is Deep Learn?**
A Pro feature: turn any deck into a 7-day mastery course. Each day is a short lesson — a plain-language explanation, a few new flashcards (Recognize → Recall → Apply), and a prompt to apply the idea. All seven days are available right away; open them at your own pace. You run one course at a time.

**Why is my streak not updating?**
Streak counts consecutive days with at least one **completed** card review (any review — a normal deck, a layered deck, or a Deep Learn lesson). Review at least one card today to add to your streak.

### Subscription

**What is included in Free?**
- 3 captures per day
- 10 AI summaries per month
- Daily Knowledge — a few suggested skills to learn each day
- Unlimited reading of existing captures and flashcards

**What is included in Pro?**
- Unlimited captures
- Unlimited AI summaries
- Deep Learn — 7-day mastery courses from your decks
- 7-day free trial when you first subscribe
- Same Learn and Share Extension features

**How do I subscribe?**
Profile → Subscription → choose monthly or annual.

**How do I cancel?**
Subscriptions are managed by Apple. iOS Settings → your Apple ID → Subscriptions → Anti Noise → Cancel.

**Will Apple charge me during the free trial?**
No. You will be charged only at the end of the 7-day trial unless you cancel beforehand.

**Can I get a refund?**
Refunds are handled by Apple. Open the Report a Problem page at https://reportaproblem.apple.com and select your purchase.

### Privacy and data

**Where is my data stored?**
On your device first (SwiftData) and mirrored to Firebase Firestore so you can sync across your devices. We do not sell or share your data.

**How do I export my data?**
Profile → Settings → Export Data → choose JSON. You will receive a download containing all of your captures, summaries, decks, flashcards, goals, and Deep Learn courses.

**How do I delete my account?**
Profile → Settings → Delete Account. Your data is hidden immediately and permanently deleted after 7 days. You can sign in within that window to restore your account.

**Do you collect my OpenAI key?**
No. Your key is stored in the iOS Keychain on your device only. It never leaves your phone except in direct requests to OpenAI's API.

**See the full Privacy Policy:** [Privacy Policy](./privacy-policy.md)

### Sign-in

**Which sign-in methods are supported?**
Apple Sign In and email/password.

**I lost my password.**
On the sign-in screen, tap "Forgot password" — we will email a reset link.

**I signed in with Apple and want to switch to email/password.**
This is not supported in v1.0. You will have to create a new account with email/password and re-import data via JSON export from the Apple Sign In account.

### Sync

**Do my captures appear on my other iPhone or iPad?**
Yes, once you sign in to the same account. SwiftData is the source of truth on each device; Firestore mirrors and reconciles across devices.

**A capture I created on another device is missing.**
Pull-to-refresh on Home, or sign out and back in. If still missing, contact us.

### Notifications

**What notifications does Anti Noise send?**
Daily review reminder and a streak nudge. Both opt-in at the first prompt after onboarding. Toggle anytime in Profile → Settings → Notifications.

**Why am I not receiving notifications?**
Check iOS Settings → Notifications → Anti Noise. All toggles must be enabled. We use local notifications only — no remote push in v1.0.

### Languages

**Which languages does the app support?**
English and Vietnamese at launch. The app follows your iOS language setting. To request another language, email us.

### Bugs and feedback

**I found a bug. Where do I report it?**
Email nvhuy2708@gmail.com with:
- A short description of what you expected vs what happened
- Your iOS version and iPhone model
- A screenshot or screen recording if possible

**Can I suggest a feature?**
Yes. Email us the use case in one or two sentences. We read every message.

---

## Contact

- **Email:** nvhuy2708@gmail.com
- **Response time:** 1–2 business days
- **Office hours:** GMT+7, Mon–Fri

If you do not hear back within 3 business days, please resend — the message may have been filtered.

---

**App version:** 1.0
**Last updated:** 18 May 2026
