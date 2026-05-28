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
  temperature?: number;
}

export async function callGemini(opts: GeminiCallOptions): Promise<string> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${opts.model}:generateContent?key=${opts.apiKey}`;

  const body = {
    systemInstruction: { parts: [{ text: opts.systemInstruction }] },
    contents: [{ role: 'user', parts: [{ text: opts.userPrompt }] }],
    generationConfig: {
      temperature: opts.temperature ?? 0.7,
      responseMimeType: opts.responseMimeType ?? 'text/plain',
    },
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

export const FEYNMAN_SYSTEM_PROMPT = `You are a Feynman-style explainer for knowledge workers.
Given a captured article or note, rewrite the core idea in plain language as if explaining to a smart friend who is new to the topic.

Rules:
- 3-5 short paragraphs, no jargon.
- Lead with the single most important insight.
- Use concrete examples where the source has them.
- End with one sentence stating why this matters for someone trying to apply it.
- Output plain text. No markdown headers, no bullets.`;

export const FLASHCARDS_SYSTEM_PROMPT = `You generate spaced-repetition flashcards from a captured insight.

Output strict JSON array of 5 cards. Each card:
{ "front": "<question>", "back": "<answer>", "type": "recognize" | "recall" | "apply" }

Rules:
- 2 recognize (factual / definition).
- 2 recall (open-ended, force the learner to explain in own words).
- 1 apply (scenario-based, force the learner to use the idea in context).
- Front MUST be a question or prompt. Back MUST be the answer.
- No markdown. No prose outside the JSON.`;
