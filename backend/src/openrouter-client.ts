// OpenRouter chat completions client. OpenAI-compatible, lets us swap models
// (Gemini Flash, Claude Haiku, GPT-4o-mini, etc.) via a model-id string with
// no code change — solves the VN Google-Prepay billing lock that blocked the
// original direct-Gemini setup.
//
// Schema/prompt constants are kept here so the upstream model can swap freely;
// the prompts are model-agnostic (they instruct strict JSON output).

interface OpenRouterChoice {
  message?: { role?: string; content?: string };
  finish_reason?: string;
}

interface OpenRouterResponse {
  id?: string;
  model?: string;
  choices?: OpenRouterChoice[];
  error?: { message?: string; code?: number | string };
}

export interface CallAIOptions {
  apiKey: string;
  model: string;
  systemInstruction: string;
  userPrompt: string;
  // Optional base64 data URI (e.g. "data:image/jpeg;base64,..."). When set, the
  // user message is sent as an OpenAI-style multimodal content array, which
  // OpenRouter forwards to any vision-capable model (Gemini Flash, Claude,
  // GPT-4o, …) without code change.
  imageDataUri?: string;
  jsonResponse?: boolean;
  temperature?: number;
  referer?: string;
  title?: string;
}

export interface CallAIResult {
  text: string;
  // Upstream model id OpenRouter actually routed to (may differ from requested
  // when a provider fallback fires). Returned to iOS for telemetry.
  resolvedModel: string;
}

export async function callAI(opts: CallAIOptions): Promise<CallAIResult> {
  const url = 'https://openrouter.ai/api/v1/chat/completions';

  const userContent: unknown = opts.imageDataUri
    ? [
        { type: 'text', text: opts.userPrompt },
        { type: 'image_url', image_url: { url: opts.imageDataUri } },
      ]
    : opts.userPrompt;

  const body: Record<string, unknown> = {
    model: opts.model,
    messages: [
      { role: 'system', content: opts.systemInstruction },
      { role: 'user', content: userContent },
    ],
    temperature: opts.temperature ?? 0.4,
  };
  if (opts.jsonResponse) {
    body.response_format = { type: 'json_object' };
  }

  const headers: Record<string, string> = {
    'content-type': 'application/json',
    authorization: `Bearer ${opts.apiKey}`,
  };
  if (opts.referer) headers['HTTP-Referer'] = opts.referer;
  if (opts.title) headers['X-Title'] = opts.title;

  const payload = JSON.stringify(body);

  // One retry on 429 (provider-level rate limit) after ~2s. Most 429s on
  // OpenRouter are short hot-spike bursts that clear in <2s — a single retry
  // converts a user-visible "AI busy" into a transparent recovery. We do NOT
  // retry 5xx or network errors here because (a) iOS already retries via
  // AIRetryEngine on transient failures, (b) doubling worker latency on real
  // outages just delays the user's error toast.
  let res = await fetch(url, { method: 'POST', headers, body: payload });
  if (res.status === 429) {
    await sleep(2000);
    res = await fetch(url, { method: 'POST', headers, body: payload });
  }

  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`openrouter-error: ${res.status} ${errText.slice(0, 200)}`);
  }

  const data = (await res.json()) as OpenRouterResponse;

  if (data.error?.message) {
    throw new Error(`openrouter-blocked: ${data.error.message}`);
  }

  const text = data.choices?.[0]?.message?.content;
  if (!text) throw new Error('openrouter-empty-response');

  return { text, resolvedModel: data.model ?? opts.model };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Anti Noise iOS expects this exact shape (FeynmanSummaryPayload, snake_case).
// Schema must stay in lockstep with iOS Core/Models/FeynmanSummaryPayload.swift.
export const FEYNMAN_SYSTEM_PROMPT = `You are Anti Noise — a learning assistant that distills any source into a Feynman-method summary.

Rules:
1. RESPOND IN THE SAME LANGUAGE as the source content. Vietnamese source → Vietnamese output. English → English.
2. Explain ideas at a 12-year-old reading level. No jargon. Define every term you introduce.
3. Output STRICTLY a single JSON object — no markdown, no preamble, no trailing prose.
4. JSON shape:
   {
     "simple_explanation": string (2-4 short sentences capturing the core idea),
     "analogy": string (one concrete analogy mapping the idea to everyday life),
     "knowledge_gaps": string[] (2-5 things the source assumes but doesn't explain),
     "examples": string[] (2-4 concrete examples that ground the idea),
     "deeper_question": string (one follow-up question that pushes understanding further),
     "suggested_classification": "personal" | "work" | "business" (best fit),
     "recommend_deep_dive": boolean (true if this would meaningfully benefit from spaced-repetition study)
   }`;

// Card generation. iOS expects {cards: [{question, answer, hint?, difficulty 1-5, layer 0-2}]}.
// Schema mirrors Core/Services/AI/CardGenerator.swift FlashcardItem.
//
// v1.1 layered decks: a substantive source yields exactly 15 cards across 3
// Bloom layers (5/5/5). A thin/single-concept source yields 3-5 flat cards
// (all layer 0) instead of padding to 15 with filler — iOS treats a single-layer
// response as a flat deck.
export const FLASHCARDS_SYSTEM_PROMPT = `You are Anti Noise — a study coach who turns Feynman summaries into spaced-repetition flashcards using Bloom's taxonomy.

Rules:
1. RESPOND IN THE SAME LANGUAGE as the input summary.
2. Card volume by source richness:
   - SUBSTANTIVE source (enough distinct ideas) → EXACTLY 15 cards: 5 with "layer":0 (Recognize — identify/define/multiple-choice style), 5 with "layer":1 (Recall — explain in your own words, Feynman), 5 with "layer":2 (Apply — use the idea in a scenario).
   - THIN source (one small concept, not enough material for 15 quality cards) → 3-5 cards, ALL "layer":0. Do NOT pad with filler to reach 15.
3. Each card: question (clear, single focus), answer (one sentence or short paragraph), optional hint, difficulty 1 easy → 5 hard, layer 0|1|2 as above.
4. Layer must match cognitive demand: layer 0 recognition, layer 1 explanation, layer 2 application. Avoid trivia — every card tests a transferable concept.
5. Output STRICTLY a single JSON object — no markdown, no preamble.
6. JSON shape:
   {
     "cards": [
       { "question": string, "answer": string, "hint": string | null, "difficulty": integer 1-5, "layer": integer 0-2 }
     ]
   }`;

// Daily Knowledge skill selection + explainer. The user prompt supplies the
// candidate skills (id/title/keyword/seedNote) and the user's signals; the model
// picks the 3 most useful and writes a short grounded explainer for each.
// iOS expects {items:[{id,title,keyword,whyNow,coreConcept,suggestedSearch,pack}]}.
export const DAILY_SKILLS_SYSTEM_PROMPT = `You are Anti Noise — a learning coach picking the 3 most useful "skills to learn in the AI era" for a specific person, from a fixed candidate list.

Rules:
1. RESPOND IN ENGLISH (the taxonomy is English).
2. Choose EXACTLY 3 items from the provided candidates — pick the ones most relevant to the user's role/level/goal when given; otherwise pick a useful spread. You MUST reuse each chosen item's exact "id", "title", "keyword", and "pack" from the candidate — do NOT invent new ones.
3. For each chosen item write:
   - "whyNow": 1-2 sentences on why this skill matters right now (concrete, no hype).
   - "coreConcept": 2-3 sentences explaining the concept at a 12-year-old reading level, grounded in the candidate's "seedNote" (do not contradict it, do not hallucinate beyond it).
   - "suggestedSearch": a short web-search query string to learn more (e.g. "what is RAG in LLMs").
4. Output STRICTLY a single JSON object — no markdown, no preamble.
5. JSON shape:
   {
     "items": [
       { "id": string, "title": string, "keyword": string, "pack": string, "whyNow": string, "coreConcept": string, "suggestedSearch": string }
     ]
   }`;
