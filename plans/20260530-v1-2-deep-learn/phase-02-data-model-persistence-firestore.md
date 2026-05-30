# Phase 02 — Data model + persistence + Firestore mirror

**Context:** `reports/scout-corrections.md` · `docs/v1-2-deep-learn-spec.md` §Data model

## Overview
- **Priority:** P1
- **Status:** pending
- **Depends:** phase 01 (clean schema).
- Add `LearningPath` + `LearningDay` SwiftData models (NO `unlocksAt`), register in the container
  migration-safe, and mirror paths to Firestore for cross-device sync.

## Key insights
- Existing `Flashcard` already has every SM-2 field + `layerIndex`. Deep Learn cards are **plain
  `Flashcard`s** with `deckID` = the path's deck → they auto-enter the shared SRS queue.
  `LearningDay.cardIDs` only *links* which cards belong to which day for display.
- `DailySkillItem.swift` is the template for an "added later" `@Model` with literal defaults — follow
  it so SwiftData lightweight migration succeeds (every new non-optional field needs a default or the
  model must be brand-new; brand-new entities are additive-safe).

## Requirements
- Functional: persist a path + 7 days locally; query active path; write/read Firestore mirror at
  `learning_paths/{uid}/{pathId}`.
- Non-functional: Swift 5.9-compat; models < 200 lines each; container init cannot crash existing stores.

## Architecture / data flow
```
opt-in → create LearningPath(status=active, outlineJSON) + 7 LearningDay rows (dayIndex 1..7,
         conceptText=nil until generated) → SwiftData. Day 1 content arrives from backend (phase 03)
         → fill day 1 conceptText/applyPrompt + create Flashcards(deckID=path.deckID) + set cardIDs.
         → mirror path doc to Firestore.
open day N (N>1) → if conceptText==nil → call /v1/learn/day → fill row + cards.
```

## Related code files
**Create:**
- `AntiNoise/Core/Models/LearningPath.swift` — `@Model`:
  `id:UUID(.unique)`, `deckID:UUID`, `topic:String`, `durationDays:Int = 7`, `startedAt:Date`,
  `currentDay:Int = 1`, `status:String = "active"` (active|completed|abandoned), `outlineJSON:String?`.
- `AntiNoise/Core/Models/LearningDay.swift` — `@Model`:
  `id:UUID(.unique)`, `pathID:UUID`, `dayIndex:Int`, `conceptText:String?`, `applyPrompt:String?`,
  `cardIDs:[UUID] = []`, `completedAt:Date?`. **No `unlocksAt`.**
- `AntiNoise/Core/Services/Learning/LearningPathStore.swift` — CRUD helpers
  (createPath+days, fetchActivePath, fillDay, markDayComplete, markPathComplete/abandon). Keep < 200 lines.
- `AntiNoise/Core/Services/Sync/LearningPathSyncService.swift` — Firestore mirror write (model on
  `UserProfileSyncService.swift`). Path doc: `learning_paths/{uid}/{pathId}`.

**Modify:**
- `AntiNoise/Core/Persistence/PersistenceContainer.swift:11` — add `LearningPath.self, LearningDay.self`
  to `Schema([...])`.

## Implementation steps
1. Add `LearningPath` model with literal defaults (`durationDays=7`, `currentDay=1`, `status="active"`).
2. Add `LearningDay` model (`cardIDs=[]` default; `conceptText`/`applyPrompt`/`completedAt` optional).
3. Register both in `PersistenceContainer` schema.
4. Write `LearningPathStore`: createPath(deckID, topic, outlineJSON) → inserts path + 7 day rows;
   fetchActivePath() (status==active); fillDay(dayIndex, concept, applyPrompt, cardIDs);
   markDayComplete; markPathComplete; abandonPath (keeps cards — default decision).
5. Write `LearningPathSyncService` mirroring path metadata (id, deckID, topic, currentDay, status,
   startedAt) to Firestore. Cards already sync via existing capture/deck sync if present (verify;
   otherwise day content is regenerable on-device, acceptable).
6. `xcodegen generate` + build.

## Todo
- [ ] `LearningPath.swift`
- [ ] `LearningDay.swift` (no `unlocksAt`)
- [ ] Register in `PersistenceContainer` schema
- [ ] `LearningPathStore` CRUD
- [ ] `LearningPathSyncService` Firestore mirror
- [ ] Build + launch on existing store (no migration crash)

## Success criteria
- Create a path in a unit/UI smoke → 1 `LearningPath` + 7 `LearningDay` rows persisted; reopen app →
  rows survive; active-path query returns it.
- Firestore doc appears at `learning_paths/{uid}/{pathId}`.
- Launching with a pre-existing (v1.1) store does not crash.

## Risk assessment
| Risk | L×I | Mitigation |
|------|-----|-----------|
| Lightweight migration fails on real device store | L×H | Use literal defaults only (proven by `DailySkillItem`); both entities are brand-new (additive). Test on device with existing store before ship. |
| `cardIDs:[UUID]` array attribute unsupported | L×M | SwiftData supports `[UUID]` value arrays; if not, store JSON string. Verify at impl. |
| Firestore mirror diverges from local (offline edits) | M×L | Local is source of truth; mirror is best-effort write, no read-back conflict resolution in MVP. |

## Rollback
New files + one schema line. Revert removes both entities (additive removal, safe). No prod data
depends on them yet.

## Next steps
Unblocks phase 04 (UI binds to these models). Phase 03 backend can proceed in parallel.
