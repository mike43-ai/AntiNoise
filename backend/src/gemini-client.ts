interface GeminiCandidate {
  content?: { parts?: { text?: string }[] };
  finishReason?: string;
}

interface GeminiResponse {
  candidates?: GeminiCandidate[];
  promptFeedback?: { blockReason?: string };
}

export interface GeminiCallOptions {
  apiKey: string;
  model: string;
  systemInstruction: string;
  userPrompt: string;
  responseMimeType?: 'text/plain' | 'application/json';
  responseSchema?: unknown;
  temperature?: number;
}

export async function callGemini(opts: GeminiCallOptions): Promise<string> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${opts.model}:generateContent?key=${opts.apiKey}`;

  const generationConfig: Record<string, unknown> = {
    temperature: opts.temperature ?? 0.4,
    responseMimeType: opts.responseMimeType ?? 'text/plain',
  };
  if (opts.responseSchema) {
    generationConfig.responseSchema = opts.responseSchema;
  }

  const body = {
    systemInstruction: { parts: [{ text: opts.systemInstruction }] },
    contents: [{ role: 'user', parts: [{ text: opts.userPrompt }] }],
    generationConfig,
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`gemini-error: ${res.status} ${errText.slice(0, 200)}`);
  }

  const data = (await res.json()) as GeminiResponse;

  if (data.promptFeedback?.blockReason) {
    throw new Error(`gemini-blocked: ${data.promptFeedback.blockReason}`);
  }

  const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new Error('gemini-empty-response');

  return text;
}

// Anti Noise iOS expects this exact shape (FeynmanSummaryPayload, snake_case).
// Schema must stay in lockstep with iOS Core/Models/FeynmanSummaryPayload.swift.
export const FEYNMAN_SYSTEM_PROMPT = `You are Anti Noise — a learning assistant that distills any source into a Feynman-method summary.

Rules:
1. RESPOND IN THE SAME LANGUAGE as the source content. Vietnamese source → Vietnamese output. English → English.
2. Explain ideas at a 12-year-old reading level. No jargon. Define every term you introduce.
3. Output STRICTLY the JSON shape — no markdown, no preamble.
4. simple_explanation: 2-4 short sentences capturing the core idea.
5. analogy: one concrete analogy mapping the idea to everyday life.
6. knowledge_gaps: 2-5 things the source assumes but doesn't explain.
7. examples: 2-4 concrete examples that ground the idea.
8. deeper_question: one follow-up question that pushes understanding further.
9. suggested_classification: pick "personal" | "work" | "business" that best fits.
10. recommend_deep_dive: true if this would meaningfully benefit from spaced-repetition study; otherwise false.`;

export const FEYNMAN_RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    simple_explanation: { type: 'string' },
    analogy: { type: 'string' },
    knowledge_gaps: { type: 'array', items: { type: 'string' } },
    examples: { type: 'array', items: { type: 'string' } },
    deeper_question: { type: 'string' },
    suggested_classification: { type: 'string', enum: ['personal', 'work', 'business'] },
    recommend_deep_dive: { type: 'boolean' },
  },
  required: [
    'simple_explanation',
    'analogy',
    'knowledge_gaps',
    'examples',
    'deeper_question',
    'suggested_classification',
    'recommend_deep_dive',
  ],
};

// Card generation. iOS expects {cards: [{question, answer, hint?, difficulty 1-5}]}.
// Schema mirrors Core/Services/AI/CardGenerator.swift FlashcardItem.
export const FLASHCARDS_SYSTEM_PROMPT = `You are Anti Noise — a study coach who turns Feynman summaries into spaced-repetition flashcards.

Rules:
1. RESPOND IN THE SAME LANGUAGE as the input summary.
2. Generate 3-15 cards based on content density. Short single-concept → 3-5. Dense multi-concept → up to 15.
3. Each card: question (clear single-fact), answer (one sentence or short paragraph), optional hint, difficulty 1 easy → 5 hard.
4. Avoid trivia — every card should test a transferable concept.
5. Output STRICTLY the JSON shape. No markdown. No preamble.`;

export const FLASHCARDS_RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    cards: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          question: { type: 'string' },
          answer: { type: 'string' },
          hint: { type: 'string', nullable: true },
          difficulty: { type: 'integer' },
        },
        required: ['question', 'answer', 'difficulty'],
      },
    },
  },
  required: ['cards'],
};
