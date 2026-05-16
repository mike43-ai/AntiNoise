# Phase 05 — Capture Flow + Share Extension

## Context Links
- Parent: [plan.md](./plan.md)
- Deps: phase-01 (App Group), phase-02 (UI), phase-04 (capture sheet entry)
- Mockups: `Product UI/refined_quick_capture_flow/screen.png`, `Product UI/kinetic_command/screen.png`
- Phase that consumes captures: phase-06 (AI summary)

## Overview
- Date: 2026-05-16
- Description: In-app capture (image, URL, text) + iOS Share Extension that drops payloads into shared App Group queue. SwiftData model `Capture` persists items. AI processing kicked off in phase-06.
- Priority: P0
- Implementation status: completed (2026-05-16)
- Review status: approved with fixes
- Effort: 2.5d

## Key Insights
- Share Extension has 120 MB memory + ~30s execution budget — must NOT call OpenAI directly. Persist payload to App Group + post Darwin notification; main app processes when foregrounded.
- Three capture types LOCKED: `url`, `text`, `image`. Configured in extension `Info.plist` via `NSExtensionActivationRule` (see below).
- Image pipeline goes directly to GPT-4o vision in phase-06 (no on-device OCR). Phase-05 just persists the image blob.
- Capture flow is the central differentiator — UX must feel <2s from intent to "captured" toast.
- Offline mode LOCKED: capture row writes to SwiftData immediately regardless of network. AI-summary job (phase-06) is enqueued, retried on reachability change. Status transitions: `.queued` (no network) → `.processing` (online, calling OpenAI) → `.summarized | .failed`. Re-queue automatically on `NWPathMonitor` `.satisfied`.

## Requirements
**Functional**
- In-app capture from sheet: paste link, pick image, type quick note.
- Share Extension accepts: URL, image (1+), plain text (all three, locked).
- All captures persisted as `Capture` with `status = .queued`, REGARDLESS of network reachability.
- After persistence + when reachable: `AISummarizer.process(capture:)` (impl in phase-06) enqueued.
- When offline: status stays `.queued`; `ReachabilityObserver` re-drives queue on `.satisfied`.
- Captures viewable in Learn tab inbox (phase-07) with status badge (Queued / Summarizing / Ready / Failed).

**Non-functional**
- Share Extension cold-launch → confirmation toast in ≤ 1.5s.
- Captures survive app force-quit.

## Architecture
```mermaid
flowchart LR
  SE[Share Extension] --AppGroup write--> Queue[(SharedQueueStore)]
  SE --Darwin notify--> App
  App --on launch/foreground--> Drain[DrainQueueService]
  Drain --> SwiftData[(Capture)]
  InAppSheet --> SwiftData
  SwiftData --> Phase06[OpenAISummarizer]
```

`SharedQueueStore` writes JSON files under `group.com.antinoise.shared/queue/<uuid>.json` + binary image blobs under `/queue/blobs/`.

## Related Code Files (to create)
- `AntiNoise/Core/Models/Capture.swift` (SwiftData `@Model`)
- `AntiNoise/Core/Models/CaptureKind.swift` (enum: image/url/text)
- `AntiNoise/Core/Models/CaptureStatus.swift` (enum: queued/processing/summarized/failed/archived)
- `AntiNoise/Core/Persistence/PersistenceContainer.swift` (SwiftData ModelContainer)
- `AntiNoise/Core/Services/Capture/SharedQueueStore.swift`
- `AntiNoise/Core/Services/Capture/DrainQueueService.swift`
- `AntiNoise/Core/Services/Capture/CaptureRepository.swift`
- `AntiNoise/Features/Capture/Views/CaptureFlowView.swift` (replaces phase-04 placeholder)
- `AntiNoise/Features/Capture/Views/CaptureUrlInputView.swift`
- `AntiNoise/Features/Capture/Views/CaptureNoteInputView.swift`
- `AntiNoise/Features/Capture/Views/CaptureImagePickerView.swift`
- `AntiNoise/Features/Capture/ViewModels/CaptureFlowModel.swift` (`@Observable`)
- `AntiNoiseShareExtension/ShareViewController.swift` (replaces phase-01 stub)
- `AntiNoiseShareExtension/ShareItemExtractor.swift`
- `AntiNoise/Core/Services/Capture/ReachabilityObserver.swift` (wraps `NWPathMonitor`, posts `.online` / `.offline`)
- `AntiNoise/Core/Services/Capture/PendingJobQueue.swift` (re-drives `.queued` rows on connectivity restore)

## Implementation Steps
1. Define `Capture` SwiftData model: `id, kind, rawText?, sourceUrl?, imagePath?, capturedAt, status, summary? (relation, phase-06), classification? (phase-07)`.
2. Set up `PersistenceContainer` with App Group store URL.
3. `SharedQueueStore`: write `(id, kind, payload, capturedAt)` JSON + images.
4. Build `ShareViewController`: extract `NSItemProvider` types (URL, image, text) via `ShareItemExtractor`, persist via `SharedQueueStore`, post Darwin notification `com.antinoise.queue.updated`, dismiss.
5. In main app, `DrainQueueService.start()` on `.scenePhase = .active`: reads queue dir, inserts SwiftData rows, deletes queue files.
6. `CaptureFlowView`: tab selector (URL / Image / Note), input UI, "Capture" CTA.
7. `CaptureFlowModel.save()` → write to SwiftData → if reachable, trigger phase-06 service; else leave `.queued`.
8. Toast: online → "Captured. Summarizing…"; offline → "Captured. Will summarize when online."
9. `ReachabilityObserver` posts `.online` → `PendingJobQueue.drain()` picks rows where `status == .queued` (created locally or via share extension) and dispatches each to `AISummarizer`.
10. Configure `AntiNoiseShareExtension/Info.plist` `NSExtension.NSExtensionAttributes.NSExtensionActivationRule` to accept all three types (use predicate; not the `TRUEPREDICATE` shortcut so App Review sees explicit intent):
   - `NSExtensionActivationSupportsWebURLWithMaxCount = 1`
   - `NSExtensionActivationSupportsText = YES`
   - `NSExtensionActivationSupportsImageWithMaxCount = 5`
11. Test: kill app, share URL from Safari, relaunch → capture appears in Learn. Repeat with airplane-mode toggled → capture present + status badge `.queued`; flip airplane mode off → status flips to `.summarized` within ~10s.

## Todo
- [x] SwiftData models defined (Capture, CaptureKind, CaptureStatus)
- [x] PersistenceContainer with App Group URL + fallback for simulator-without-entitlement
- [x] SharedQueueStore read/write + LocalizedError messages + Darwin notify post
- [x] DrainQueueService drains on foreground + cleanupOrphanedBlobs() GC pass on bootstrap
- [x] ShareViewController extracts URL/image/text + auto-persist + 300ms ack + dismiss
- [x] Darwin notification posted by SharedQueueStore + observed by DrainQueueService
- [x] CaptureFlowView 3-mode input (Link/Note/Image chip selector)
- [x] CaptureFlowModel persists via injected ModelContext; summarizer accessed lazily
- [~] Toast on success — model exposes toastMessage but the host MainTabView doesn't render it yet (deferred to Phase 10 dashboard polish)
- [~] End-to-end share-while-killed test — deferred (no simulator runtime)
- [x] NSExtensionActivationRule lists URL + text + image with explicit max-counts (not TRUEPREDICATE)
- [x] ReachabilityObserver wired (NWPathMonitor + onChange callback)
- [x] PendingJobQueue re-drives `.queued` rows on reachability restore; loops up to 5 batches × 20 rows
- [~] Offline capture → online resume flow — code wired; runtime verification deferred

## Notes (implementation)
- Code review applied 3 BLOCKING + 7 important WARN:
  - **B1** Replaced sketchy `Task.sleep(milliseconds:)` extension with `Task.sleep(for: .milliseconds(300))`.
  - **B2** `CaptureFlowModel` now takes `summarizerProvider: () -> SummarizerService` so Phase 06 swap propagates to in-flight sheets.
  - **B3** Inlined `"queued"` literal in `#Predicate`; `SummarizerService` protocol contract requires implementations to short-circuit if `status != .queued` (prevents double-processing when DrainQueueService + PendingJobQueue race).
  - **W4** Wrapped UIKit image downscale + JPEG encode in `MainActor.run` (Swift 6 readiness).
  - **W5** `CaptureFlowModel` uses the env `ModelContext` (not a fresh one) so SwiftUI `@Query` observers see new rows without a merge round-trip.
  - **W6** `SharedQueueStore.StoreError` now conforms to `LocalizedError` with actionable copy.
  - **W7** Added `DrainQueueService.cleanupOrphanedBlobs()`; runs once on app bootstrap after drain.
  - **W8** `PendingJobQueue.drain()` now loops up to 5 batches of 20 rows so deep offline backlogs unblock fully.
  - **W11** Added `Capture.resolvedImageURL` helper so Phase 06 doesn't reach into `SharedQueueStore.resolveBlobURL` from view code.
  - Restricted in-app URL capture to http/https (security flavor, N6).
- DEFERRED:
  - Toast surfacing into MainTabView (model has it, view doesn't render — Phase 10).
  - Share Extension App Review risk (W2: `isContentValid() = false` + headless auto-persist) — accept for TestFlight first; if Apple rejects, switch to user-tap-to-post variant.

## Success Criteria
- Share URL from Safari with app killed → URL appears in Learn inbox after relaunch.
- In-app capture from sheet persists across cold-launch.
- Share Extension exits cleanly within 2s.

## Risk Assessment
- **R1**: SwiftData container init failure inside Share Extension. → Use lightweight JSON queue inside extension; do not touch SwiftData from extension process.
- **R2**: Large images blow 120 MB extension budget. → Downscale to max 2048px long edge during extension write.
- **R3**: Darwin notification race on cold-launch. → DrainQueueService also runs on every `.active` scene-phase regardless of notification.

## Security Considerations
- Shared App Group dir is per-app-group sandboxed but readable by both targets — do NOT store auth tokens there.
- Strip EXIF location from images during extension write.

## Next Steps
- Phase-06 picks up `Capture` rows with `status = .queued`.
