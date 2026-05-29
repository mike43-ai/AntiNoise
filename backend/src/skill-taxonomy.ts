// Curated "skills worth learning in the AI era" taxonomy. Replaces the Reddit
// content source (decision 2026-05-29): Daily Knowledge is a CURRICULUM, not a
// news feed. Version-controlled here — update by editing + redeploy, no external
// API/creds. The daily pipeline picks unseen items for the user's topic packs,
// then Gemini writes a grounded explainer per item.
//
// Pack ids MUST match iOS TopicPack rawValues:
// aiml | engineering | productDesign | startup | productivity

export interface SkillItem {
  id: string; // stable, unique across all packs (used for seen-tracking)
  title: string;
  keyword: string; // the concept to anchor the explainer (anti-hallucination)
  seedNote: string; // one-line factual anchor so Gemini explains the RIGHT thing
}

export const SKILL_TAXONOMY: Record<string, SkillItem[]> = {
  aiml: [
    { id: 'aiml-rag', title: 'Retrieval-Augmented Generation', keyword: 'RAG', seedNote: 'Ground an LLM answer in retrieved documents instead of model memory.' },
    { id: 'aiml-evals', title: 'LLM Evals', keyword: 'evals', seedNote: 'Systematically measuring LLM output quality with datasets + scorers.' },
    { id: 'aiml-finetune', title: 'Fine-tuning vs Prompting', keyword: 'fine-tuning', seedNote: 'When to adapt model weights vs just engineer the prompt/context.' },
    { id: 'aiml-agents', title: 'Agentic Workflows', keyword: 'agents', seedNote: 'LLMs that plan, call tools, and loop toward a goal autonomously.' },
    { id: 'aiml-promptcache', title: 'Prompt Caching', keyword: 'prompt caching', seedNote: 'Reusing cached prompt prefixes to cut latency and token cost.' },
    { id: 'aiml-embeddings', title: 'Embeddings', keyword: 'embeddings', seedNote: 'Turning text into vectors so similarity can be computed numerically.' },
    { id: 'aiml-context', title: 'Context Engineering', keyword: 'context window', seedNote: 'Designing what goes into the context window for best results.' },
    { id: 'aiml-funccall', title: 'Function / Tool Calling', keyword: 'tool calling', seedNote: 'Letting an LLM invoke typed functions to act on the world.' },
    { id: 'aiml-guardrails', title: 'Guardrails & Safety', keyword: 'guardrails', seedNote: 'Constraining LLM I/O to prevent unsafe or off-spec outputs.' },
    { id: 'aiml-rerank', title: 'Reranking', keyword: 'reranking', seedNote: 'A second model reorders retrieved candidates for relevance.' },
    { id: 'aiml-multimodal', title: 'Multimodal Models', keyword: 'multimodal', seedNote: 'Models that handle text, images, audio in one pipeline.' },
  ],
  engineering: [
    { id: 'eng-typesafety', title: 'End-to-end Type Safety', keyword: 'type safety', seedNote: 'Shared types from DB to UI to catch errors at compile time.' },
    { id: 'eng-observability', title: 'Observability', keyword: 'observability', seedNote: 'Logs, metrics, traces to understand a system in production.' },
    { id: 'eng-featureflags', title: 'Feature Flags', keyword: 'feature flags', seedNote: 'Toggle features at runtime to decouple deploy from release.' },
    { id: 'eng-edge', title: 'Edge Compute', keyword: 'edge compute', seedNote: 'Running code near users (e.g. Workers) for low latency.' },
    { id: 'eng-idempotency', title: 'Idempotency', keyword: 'idempotency', seedNote: 'Making repeated requests safe (no double charge/write).' },
    { id: 'eng-ratelimit', title: 'Rate Limiting', keyword: 'rate limiting', seedNote: 'Capping request volume to protect cost and stability.' },
    { id: 'eng-eventdriven', title: 'Event-Driven Architecture', keyword: 'event-driven', seedNote: 'Components react to events/queues instead of direct calls.' },
    { id: 'eng-iac', title: 'Infrastructure as Code', keyword: 'IaC', seedNote: 'Defining infra in version-controlled config, not clicks.' },
    { id: 'eng-caching', title: 'Caching Strategies', keyword: 'caching', seedNote: 'TTL, invalidation, and layers to serve data fast.' },
    { id: 'eng-apiversion', title: 'API Versioning', keyword: 'API versioning', seedNote: 'Evolving APIs without breaking existing clients.' },
  ],
  productDesign: [
    { id: 'pd-jtbd', title: 'Jobs To Be Done', keyword: 'JTBD', seedNote: 'Frame features around the job a user hires the product for.' },
    { id: 'pd-tokens', title: 'Design Tokens', keyword: 'design tokens', seedNote: 'Named design values (color/space/type) shared across platforms.' },
    { id: 'pd-research', title: 'User Research', keyword: 'user research', seedNote: 'Learning real user needs via interviews and observation.' },
    { id: 'pd-northstar', title: 'North Star Metric', keyword: 'north star metric', seedNote: 'One metric capturing the core value delivered to users.' },
    { id: 'pd-ia', title: 'Information Architecture', keyword: 'information architecture', seedNote: 'Structuring content/navigation so users find things.' },
    { id: 'pd-a11y', title: 'Accessibility', keyword: 'accessibility', seedNote: 'Designing usable products for people with disabilities.' },
    { id: 'pd-designsys', title: 'Design Systems', keyword: 'design system', seedNote: 'Reusable components + rules for consistent UI at scale.' },
    { id: 'pd-usability', title: 'Usability Testing', keyword: 'usability testing', seedNote: 'Watching users attempt tasks to find friction.' },
    { id: 'pd-onboarding', title: 'Onboarding Design', keyword: 'onboarding', seedNote: 'Getting a new user to first value with minimal friction.' },
    { id: 'pd-prototyping', title: 'Rapid Prototyping', keyword: 'prototyping', seedNote: 'Cheap mockups to test ideas before building.' },
  ],
  startup: [
    { id: 'su-pmf', title: 'Product-Market Fit', keyword: 'product-market fit', seedNote: 'When the market strongly pulls your product from you.' },
    { id: 'su-gtm', title: 'Go-To-Market', keyword: 'GTM', seedNote: 'The plan to reach and convert your first customers.' },
    { id: 'su-pricing', title: 'Pricing Strategy', keyword: 'pricing', seedNote: 'Setting price to capture value and signal positioning.' },
    { id: 'su-retention', title: 'Retention', keyword: 'retention', seedNote: 'Keeping users coming back — the engine of growth.' },
    { id: 'su-cacltv', title: 'CAC vs LTV', keyword: 'CAC LTV', seedNote: 'Cost to acquire vs lifetime value — unit economics.' },
    { id: 'su-positioning', title: 'Positioning', keyword: 'positioning', seedNote: 'How your product is perceived vs alternatives.' },
    { id: 'su-cohort', title: 'Cohort Analysis', keyword: 'cohort analysis', seedNote: 'Tracking groups over time to see real retention/behavior.' },
    { id: 'su-moat', title: 'Moats', keyword: 'moat', seedNote: 'Durable advantages that resist competition.' },
    { id: 'su-distribution', title: 'Distribution', keyword: 'distribution', seedNote: 'Channels matter more than product in early growth.' },
    { id: 'su-fundraising', title: 'Fundraising Basics', keyword: 'fundraising', seedNote: 'Raising capital: rounds, dilution, investor fit.' },
  ],
  productivity: [
    { id: 'pr-deepwork', title: 'Deep Work', keyword: 'deep work', seedNote: 'Distraction-free focus on cognitively demanding tasks.' },
    { id: 'pr-srs', title: 'Spaced Repetition', keyword: 'spaced repetition', seedNote: 'Reviewing at increasing intervals to fight forgetting.' },
    { id: 'pr-timeblock', title: 'Time Blocking', keyword: 'time blocking', seedNote: 'Assigning every task a slot on the calendar.' },
    { id: 'pr-secondbrain', title: 'Second Brain', keyword: 'second brain', seedNote: 'An external system to capture and resurface knowledge.' },
    { id: 'pr-weeklyreview', title: 'Weekly Review', keyword: 'weekly review', seedNote: 'A recurring checkpoint to reset priorities (GTD).' },
    { id: 'pr-energy', title: 'Energy Management', keyword: 'energy management', seedNote: 'Scheduling work to your energy, not just your time.' },
    { id: 'pr-singletask', title: 'Single-tasking', keyword: 'single-tasking', seedNote: 'Doing one thing at a time beats context-switching.' },
    { id: 'pr-async', title: 'Async Communication', keyword: 'async communication', seedNote: 'Writing clearly so work flows without live meetings.' },
    { id: 'pr-feynman', title: 'Feynman Technique', keyword: 'Feynman technique', seedNote: 'Learn by explaining a concept in simple terms.' },
    { id: 'pr-pareto', title: 'Pareto / 80-20', keyword: '80/20 rule', seedNote: 'A small fraction of inputs drives most of the output.' },
  ],
};

export type SkillCandidate = SkillItem & { pack: string };

/// Flatten candidates for the user's selected packs, excluding already-seen ids.
/// Each candidate carries its pack id so the pipeline/model can echo it back.
export function unseenCandidates(packIds: string[], seen: Set<string>): SkillCandidate[] {
  const out: SkillCandidate[] = [];
  for (const pack of packIds) {
    for (const item of SKILL_TAXONOMY[pack] ?? []) {
      if (!seen.has(item.id)) out.push({ ...item, pack });
    }
  }
  return out;
}
