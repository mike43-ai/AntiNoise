# Phase 08 — Flash Cards + Spaced Repetition (SM-2)

## Context Links
- Parent: [plan.md](./plan.md)
- Deps: phase-06 (Summary), phase-07 (priority queue triggers deep-dive)
- Mockups: `Product UI/flashcard_learning_view/screen.png`

## Overview
- Date: 2026-05-16
- Description: Generate flash cards from a Summary via OpenAI, persist as a Deck, drive review sessions with SM-2 spaced repetition algorithm.
- Priority: P1
- Implementation status: completed (2026-05-16)
- Review status: approved with fixes
- Effort: 3d

## Key Insights
- SRS algorithm LOCKED: SM-2 (Anki classic). FSRS deferred to v2.
- SM-2 constants LOCKED: `easeFactor` default = 2.5, `easeFactor` min = 1.3, intervals = `[1d, 6d]` for first two repetitions then `round(prevInterval * easeFactor)`. Grades 0–5 (we map UI swipes to {1, 3, 5}).
- Card count LOCKED: AI decides 3–15 per summary based on content density; prompt instructs model to pick the count. Cap at 15 hard to control token cost.
- Card generation prompt produces: question + answer + optional cloze + difficulty hint.
- Review session UX: tap card to flip, swipe right = "Easy", swipe left = "Hard", swipe up = "Again". Maps to SM-2 grades 5/3/1.

## Requirements
**Functional**
- "Deep dive" CTA on Summary → spawn job to generate cards.
- Cards live in a `Deck` tied to source Summary; also browseable as "All decks".
- Review session UI: card flip, grade input, progress bar.
- SM-2 schedules next review per card.
- "Due today" count surfaces on Learn tab and Home.

**Non-functional**
- Card gen p50 ≤ 5s.
- Review interaction ≤ 16ms frame budget (60 fps).

## Architecture
```mermaid
flowchart LR
  Summary --DeepDive--> CardGenerator
  CardGenerator -->|OpenAI| RawCards
  RawCards --> Deck[(Deck + Card[])]
  Deck --> Scheduler[SM-2]
  Scheduler --> ReviewSession
  ReviewSession --grade--> Scheduler
```

SM-2 fields per card: `easeFactor (default 2.5, min 1.3), intervalDays, repetitions, nextReviewAt, lastGrade`.

Locked constants:
```swift
enum SM2Constants {
  static let defaultEaseFactor: Double = 2.5
  static let minEaseFactor:     Double = 1.3
  static let firstIntervalDays:  Int = 1
  static let secondIntervalDays: Int = 6
  static let maxCardsPerDeck:    Int = 15
  static let minCardsPerDeck:    Int = 3
}
```

## Related Code Files (to create)
- `AntiNoise/Core/Models/Deck.swift` (`@Model`)
- `AntiNoise/Core/Models/Flashcard.swift` (`@Model`, fields above + question, answer, hint, clozeRange?)
- `AntiNoise/Core/Services/AI/CardGenerator.swift`
- `AntiNoise/Core/Services/AI/CardGenerationPrompt.swift`
- `AntiNoise/Core/Services/Learning/SpacedRepetitionScheduler.swift` (SM-2 impl)
- `AntiNoise/Core/Services/Learning/ReviewSessionEngine.swift`
- `AntiNoise/Features/Learn/Views/DeckListView.swift`
- `AntiNoise/Features/Learn/Views/DeckDetailView.swift`
- `AntiNoise/Features/Learn/Views/FlashcardReviewView.swift` (matches `flashcard_learning_view`)
- `AntiNoise/Features/Learn/Views/FlashcardFaceView.swift`
- `AntiNoise/Features/Learn/Views/ReviewSummaryView.swift`
- `AntiNoise/Features/Learn/ViewModels/ReviewSessionModel.swift`

## Implementation Steps
1. Define `Deck` (id, sourceSummaryId, title, scope, createdAt, cards: [Flashcard]) and `Flashcard`.
2. `CardGenerationPrompt`: instruct GPT-4o to return JSON array of `{question, answer, hint?, difficulty: 1-5}`. Prompt explicitly says: "Decide card count between 3 and 15 based on the density and breadth of the source material. Short single-concept summaries → 3–5 cards. Dense multi-concept articles → up to 15." Validate `3 ≤ count ≤ 15` on parse; if violated, clamp + log.
3. `CardGenerator.generate(from: Summary)` calls OpenAI (reuses `OpenAIClient` from phase-06), parses, persists Deck.
4. UI: SummaryDetailView "Deep dive" button → loading state → navigates to new DeckDetailView.
5. `SpacedRepetitionScheduler.next(card:, grade:)` — canonical SM-2:
   ```
   if grade < 3:
     repetitions = 0
     intervalDays = SM2Constants.firstIntervalDays   // 1
   else:
     repetitions += 1
     if repetitions == 1: intervalDays = SM2Constants.firstIntervalDays   // 1
     elif repetitions == 2: intervalDays = SM2Constants.secondIntervalDays // 6
     else: intervalDays = round(prevInterval * easeFactor)
     easeFactor = max(SM2Constants.minEaseFactor,                          // 1.3
                      easeFactor + 0.1 - (5-grade)*(0.08 + (5-grade)*0.02))
   nextReviewAt = now + intervalDays
   ```
6. `ReviewSessionEngine.startSession(deck:)` returns queue of `cards where nextReviewAt <= now` ordered by overdue desc.
7. `FlashcardReviewView`: card stack, gesture (`DragGesture`) → grade, animated flip via `.rotation3DEffect`.
8. After session → `ReviewSummaryView` shows correct/incorrect counts + next due time.
9. Home/Learn shows `dueToday = count(cards where nextReviewAt <= endOfDay)`.

## Todo
- [ ] Deck + Flashcard models
- [ ] CardGenerator + prompt
- [ ] SM-2 scheduler with unit tests
- [ ] ReviewSessionEngine
- [ ] DeckListView + DeckDetailView
- [ ] FlashcardReviewView matches mockup
- [ ] Swipe gestures map to grades
- [ ] ReviewSummary at end
- [ ] Due-today count visible on Home + Learn

## Success Criteria
- Generate cards from a Summary → 3 to 15 cards in deck (AI-decided count).
- Grade card "Easy" → next review ≥ 6 days out.
- Grade "Again" → card reappears in same session.
- 60fps maintained during card swipe on iPhone 12+.
- Unit tests for SM-2 scheduler pass canonical Anki reference vectors (EF=2.5, grade=5 → interval=6 on second rep).

## Risk Assessment
- **R1**: OpenAI returns malformed JSON → crash. → Validate with `JSONDecoder` + fallback prompt retry asking strict JSON.
- **R2**: SM-2 misimplemented → users distrust scheduling. → Unit-test scheduler against canonical test cases (Anki reference vectors).
- **R3**: Gesture conflict with tab swipes. → Lock TabView swipes during review (`.gesture(DragGesture().onChanged…)` with priority).

## Security Considerations
- Card content may contain sensitive personal notes — no third-party sync without consent.

## Next Steps
- Phase-09 Focus mode optionally triggers a review session at session end.
- Phase-10 Home shows due-today count.
