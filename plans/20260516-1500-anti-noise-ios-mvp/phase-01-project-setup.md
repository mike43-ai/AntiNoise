# Phase 01 — Project Setup

## Context Links
- Parent: [plan.md](./plan.md)
- Deps: none
- Mockups: `Product UI/anti_noise_minimal_wordmark/screen.png`
- Spec: `Anti Noise _ Thông Tin Sản Phẩm.docx`

## Overview
- Date: 2026-05-16
- Description: Bootstrap Xcode project + share extension target, SPM deps, folder skeleton, base configs.
- Priority: P0 (gates all others)
- Implementation status: pending
- Review status: pending
- Effort: 1d

## Key Insights
- Share Extension must live in same workspace; share App Group for SwiftData/UserDefaults handoff.
- iOS 17+ unlocks `@Observable`, SwiftData, `Inspector`, `ContentUnavailableView`.
- Add `Info.plist` privacy keys early (Camera, Photo Library) to avoid late-stage rework.

## Requirements
**Functional**
- Xcode project `AntiNoise.xcodeproj` builds for iOS 17+ simulator + device.
- `AntiNoiseShareExtension` target builds and is signed.
- Shared App Group (`group.com.antinoise.shared`) enabled both targets.
- SPM resolves: firebase-ios-sdk (Auth, Firestore, Analytics, Crashlytics), RevenueCat (purchases-ios + RevenueCatUI), an OpenAI lib OR raw URLSession (decide phase 06). RevenueCat trial offer / entitlement config deferred to phase-11 (no IAP product setup needed in phase-01 beyond SPM).

**Non-functional**
- Deployment target iOS 17.0.
- Swift 5.10 language mode.
- Bundle IDs reserved (placeholder OK).

## Architecture
```
AntiNoise.xcworkspace
├── AntiNoise (app target)
│   ├── App/                        AntiNoiseApp.swift, RootView.swift
│   ├── Core/
│   │   ├── DesignSystem/           (filled in phase 02)
│   │   ├── Persistence/            SwiftData container
│   │   ├── Services/               Auth, OpenAI, RevenueCat, FeatureFlags
│   │   ├── Networking/             URLSession+JSON
│   │   └── Models/
│   └── Features/                   Home, Learn, Capture, Focus, Profile, Auth, Onboarding
└── AntiNoiseShareExtension (share target)
    ├── ShareViewController.swift
    └── Info.plist (NSExtension config)
```

## Related Code Files (to create)
- `AntiNoise/App/AntiNoiseApp.swift`
- `AntiNoise/App/RootView.swift`
- `AntiNoise/Resources/Info.plist`
- `AntiNoise/Resources/AntiNoise.entitlements`
- `AntiNoiseShareExtension/ShareViewController.swift`
- `AntiNoiseShareExtension/Info.plist`
- `AntiNoiseShareExtension/AntiNoiseShareExtension.entitlements`
- `Package.resolved` (committed)
- `.gitignore` (Xcode + macOS noise)
- `README.md` (basic build instructions)

## Implementation Steps
1. `git init` in repo root; add `.gitignore` (xcuserdata, DerivedData, .DS_Store).
2. Create Xcode project → iOS App → SwiftUI → Swift 5.10 → iOS 17.0.
3. Add Share Extension target.
4. Enable App Groups capability on both targets, set `group.com.antinoise.shared`.
5. Add SPM packages: firebase-ios-sdk (Auth, Firestore, Analytics), purchases-ios.
6. Create folder structure under `AntiNoise/` per architecture above (empty Swift placeholders OK).
7. Wire `AntiNoiseApp.swift` → `RootView` (empty `Text("Anti Noise")` placeholder).
8. Add privacy strings to Info.plist: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`.
9. Add `URLTypes` placeholder + universal links entitlement stub (for future deep links).
10. Build + run on simulator → blank screen renders.
11. Commit: `feat: scaffold ios app + share extension targets`.

## Todo
- [ ] git init + .gitignore
- [ ] Xcode project created
- [ ] Share Extension target added
- [ ] App Group enabled both targets
- [ ] SPM deps resolved
- [ ] Folder skeleton created
- [ ] Privacy Info.plist keys added
- [ ] Builds + runs on simulator
- [ ] First commit pushed

## Success Criteria
- `xcodebuild -scheme AntiNoise -destination 'platform=iOS Simulator,name=iPhone 15' build` succeeds.
- Share Extension shows in iOS Share Sheet (placeholder UI).
- App Group readable from both targets via simple `UserDefaults(suiteName:)` smoke test.

## Risk Assessment
- **R1**: Provisioning profile delay for Share Extension on real device. → Use simulator until Apple Dev account configured.
- **R2**: SPM resolution conflicts between Firebase + RevenueCat. → Pin both to latest stable; Firebase 10.x + RevenueCat 5.x known compatible.

## Security Considerations
- No secrets in repo. `.env` / API keys deferred to phase 06.
- App Group container is sandboxed; safe for capture payload handoff.

## Next Steps
- Phase 02 (design system) unblocked immediately after this.
