# Anti Noise

Cut The Noise — Focus on What Matters. iOS app + Share Extension that captures content (URL, text, image), AI-summarizes via the Feynman method, and turns deep-dives into spaced-repetition flashcards.

## Stack

- iOS 17+, Swift 5.10, SwiftUI
- Firebase Auth + Firestore + Analytics + Crashlytics
- OpenAI GPT-4o (vision + chat completions)
- RevenueCat (7-day Pro trial + free tier with daily/monthly caps)
- SwiftData (local-first), Firestore mirror (cross-device sync)

## Build

```bash
# 1. Install xcodegen (one-time)
brew install xcodegen   # or download the prebuilt binary from the releases page

# 2. Generate the Xcode project
xcodegen generate

# 3. Open
open AntiNoise.xcodeproj

# 4. Or CLI build (simulator)
xcodebuild -scheme AntiNoise \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -skipPackagePluginValidation \
  build
```

The `.xcodeproj` is gitignored — regenerate after pulling.

### Device signing

`DEVELOPMENT_TEAM` is intentionally empty in `project.yml` so the repo is portable. For device builds, set your team ID in Xcode → Signing & Capabilities, or create a local-only `Config.local.xcconfig` (gitignored) with:

```
DEVELOPMENT_TEAM = ABC1234DEF
```

Apple Sign-In (Phase 03) and the Share Extension both require a paid Apple Developer account on device.

## Layout

```
AntiNoise/                       app target
├── App/                         entry + root view
├── Core/
│   ├── DesignSystem/            tokens, components       (phase 02)
│   ├── Persistence/             SwiftData container      (phase 05)
│   ├── Services/                Auth / OpenAI / Revenue  (phases 03, 06, 11)
│   ├── Networking/              URLSession + JSON
│   └── Models/                  SwiftData models
└── Features/
    ├── Home / Learn / Capture / Focus / Profile
    ├── Auth (Email + Apple Sign-In)
    └── Onboarding
AntiNoiseShareExtension/         share target (URL + text + image)
plans/                           implementation plan + phase docs
Product UI/                      mockups (HTML + PNG, 12 screens)
```

## Plan

See `plans/20260516-1500-anti-noise-ios-mvp/plan.md` — 12-phase MVP roadmap (~22 dev-days).
