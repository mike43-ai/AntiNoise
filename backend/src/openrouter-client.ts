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

  const body: Record<string, unknown> = {
    model: opts.model,
    messages: [
      { role: 'system', content: opts.systemInstruction },
      { role: 'user', content: opts.userPrompt },
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

  const res = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });

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

// Card generation. iOS expects {cards: [{question, answer, hint?, difficulty 1-5}]}.
// Schema mirrors Core/Services/AI/CardGenerator.swift FlashcardItem.
export const FLASHCARDS_SYSTEM_PROMPT = `You are Anti Noise — a study coach who turns Feynman summaries into spaced-repetition flashcards.

Rules:
1. RESPOND IN THE SAME LANGUAGE as the input summary.
2. Generate 3-15 cards based on content density. Short single-concept → 3-5. Dense multi-concept → up to 15.
3. Each card: question (clear single-fact), answer (one sentence or short paragraph), optional hint, difficulty 1 easy → 5 hard.
4. Avoid trivia — every card should test a transferable concept.
5. Output STRICTLY a single JSON object — no markdown, no preamble.
6. JSON shape:
   {
     "cards": [
       { "question": string, "answer": string, "hint": string | null, "difficulty": integer 1-5 }
     ]
   }`;
