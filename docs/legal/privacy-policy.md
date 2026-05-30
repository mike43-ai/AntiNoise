# Privacy Policy

**Effective date:** 18 May 2026
**Last updated:** 30 May 2026

This Privacy Policy describes how Anti Noise ("Anti Noise", "we", "us") handles personal information when you use the Anti Noise iOS app and any related services (the "Service"). Anti Noise is operated by an independent developer based in Vietnam.

We aim to collect as little data as possible, never sell your data, and never use it for advertising or third-party tracking.

## 1. Information we collect

We collect the following categories of data, all of which are linked to your account identifier and used only to operate the Service:

### 1.1 Account information
- **Email address** — used to create and authenticate your account, send transactional messages (password reset, account-deletion confirmation).
- **Name** — provided by you when signing in with Apple. Used for personalization in the app. You can leave this blank.
- **User ID** — a unique identifier assigned by Firebase Authentication and used internally to associate your captures, summaries, and flashcards with your account.

### 1.2 Content you create
- **User content** — articles, notes, screenshots, AI-generated summaries, and flashcards you create inside the app. Stored locally on your device (SwiftData) and mirrored to Firebase Firestore so you can sync across your devices.
- **Daily Knowledge inbox** — a short list of curated learning topics with AI-written explainers, generated for you each day from a fixed in-app catalogue. Stored in Firestore so the same list is available across your devices.

### 1.3 Learning preferences
- **Topic packs and signals** — the topic packs you select and, optionally, your role, experience level, and learning goal. Used only to personalize which Daily Knowledge topics you are shown. Stored in your Firestore user document. You can change or clear these at any time in **Profile → Improve your feed**.

### 1.4 Subscription and purchase data
- **Purchase history** — records of in-app subscriptions (free trial, monthly, annual) managed through RevenueCat. Used to deliver subscription entitlements and prevent fraud.

### 1.5 Diagnostic and product data
- **Product interaction** — anonymous, aggregated events about feature usage (e.g., "capture created", "review session completed"). Used to fix bugs and improve the app. We never log the *contents* of your captures.
- **Performance data** — startup time, render time, memory usage. Used to detect performance regressions.
- **Crash data** — automatic crash reports from Firebase Crashlytics, including stack traces and device model. Used to identify and fix crashes.

### 1.6 What we do NOT collect
- We do not collect your precise or coarse location.
- We do not access your contacts, calendar, microphone, or health data.
- We do not collect biometric data, browsing history outside the app, or device advertising identifiers.
- We do not track you across other apps or websites.

## 2. How we use your information

We use the information described above only to:

- Authenticate you and keep your account secure.
- Provide AI summaries, flashcards, and other core app features.
- Sync your captures across your devices.
- Process subscriptions and prevent fraud.
- Diagnose crashes and improve product quality.
- Respond to support requests.

We do not use your data for advertising, third-party marketing, or tracking across apps and websites.

## 3. Third-party services

Anti Noise relies on the following processors. Each operates under its own privacy policy.

| Service | Purpose | Data sent |
|---|---|---|
| **Apple Sign In** | Authentication | Apple ID identifier, name (optional) |
| **Firebase Authentication** (Google LLC) | Account management | Email, hashed password, Firebase UID |
| **Firebase Firestore** (Google LLC) | Cloud sync of captures, summaries, flashcards | Your user content keyed to your Firebase UID |
| **Firebase Analytics** (Google LLC) | Anonymous product analytics | Aggregated event names (no content) |
| **Firebase Crashlytics** (Google LLC) | Crash reporting | Stack traces, device model, iOS version |
| **Anti Noise API** (Cloudflare Workers) | AI gateway for summaries, flashcards, and Daily Knowledge | The content being summarized (URL contents, your notes, your images) and your Firebase UID, forwarded to the AI provider below |
| **OpenRouter** (OpenRouter, Inc.) and the underlying AI model provider | AI summaries, flashcard generation, Daily Knowledge explainers | The content being processed, relayed by our API |
| **RevenueCat** (RevenueCat, Inc.) | Subscription management | Anonymous user ID derived from your Firebase UID, purchase events |

**About AI processing:** AI features are processed server-side. The content you submit is sent to our own gateway (running on Cloudflare Workers), which authenticates your request with your Firebase UID and forwards the content to our AI provider (OpenRouter and the underlying model) using a key we operate — **you no longer need to provide your own API key**. We do not retain the content of your captures on the gateway beyond the time needed to process the request; per our provider's API policy, API inputs are not used to train models by default. We store only the resulting summaries, flashcards, and Daily Knowledge items in your account as described in Section 1.

## 4. International data transfers

Anti Noise is operated from Vietnam. Firebase, Cloudflare, OpenRouter, and RevenueCat process data primarily in the United States and the European Economic Area. By using the Service you consent to your data being processed in these jurisdictions.

## 5. Data retention

- **Active account:** we retain your captures, summaries, and flashcards as long as your account is active.
- **Account deletion:** you can delete your account at any time from **Profile → Settings → Delete Account**. Deletion is a 7-day soft delete: your data is hidden immediately and permanently deleted after 7 days. You can restore your account by signing in within that window.
- **Diagnostic data:** Firebase Crashlytics and Firebase Analytics retain data per Google's retention defaults (up to 14 months for Analytics; configurable). You can request earlier deletion by contacting us.
- **Backups:** Firestore performs daily automated backups for up to 7 days. Soft-deleted accounts are removed from backups during normal retention cycles.

## 6. Your rights

You can:

- **Access your data** — request a JSON export at any time from **Profile → Settings → Export Data**. The export includes all of your captures, summaries, flashcards, goals, and Deep Learn courses.
- **Delete your account** — see Section 5.
- **Correct your data** — edit captures or your display name inside the app.
- **Withdraw consent** — sign out and stop using the Service. Your data will remain until you delete your account.
- **Contact us** to exercise other rights granted by applicable law (GDPR, CCPA).

If you are in the European Economic Area, the United Kingdom, or California, you have additional rights under GDPR / UK GDPR / CCPA, including the right to object to processing and the right to lodge a complaint with a supervisory authority.

## 7. Children's privacy

Anti Noise is rated 4+ in the App Store but is not designed for, and is not directed at, children under 13. We do not knowingly collect personal information from children under 13. If you believe we have collected such information, please contact us and we will delete it promptly.

## 8. Security

We use industry-standard security measures to protect your data, including:

- TLS for all network communication.
- Firebase Authentication for credential hashing and session management.
- Server-side AI gateway that authenticates every request with your Firebase identity, so API keys are never embedded in the app.
- Firestore security rules limiting reads/writes to your own user document tree.

No method of transmission or storage is 100% secure. If you suspect a security incident affecting your account, contact us immediately.

## 9. Changes to this policy

We may update this Privacy Policy from time to time. The "Last updated" date at the top will reflect the most recent change. For material changes, we will notify you in-app or by email before the change takes effect.

## 10. Contact

For questions about this Privacy Policy, to request data export, or to report a privacy concern:

- **Email:** nvhuy2708@gmail.com
- **In-app:** Profile → Settings → Contact Support

---

This policy is provided in English. Translations may be added in future releases. The English version controls in case of conflict.
