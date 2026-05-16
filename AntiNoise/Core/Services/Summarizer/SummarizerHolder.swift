import Observation

// Lightweight environment-injectable holder so we can swap the summarizer
// implementation between Phase 05 (NoopSummarizerService) and Phase 06
// (OpenAISummarizer) without rewriting every consumer.
@Observable
@MainActor
final class SummarizerHolder {
    var summarizer: SummarizerService

    init(summarizer: SummarizerService) {
        self.summarizer = summarizer
    }
}
