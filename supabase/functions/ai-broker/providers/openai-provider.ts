/** OpenAI provider: gpt-4o-mini (fast), gpt-4o (smart) */

export interface AIMessage {
  role: string;
  content: string;
}

export interface AIResponse {
  text: string;
  provider: string;
  model: string;
  tokensUsed: number;
}

const MODELS: Record<string, string> = {
  fast: "gpt-4o-mini",
  smart: "gpt-4o",
};

export function supportsModelTier(tier: string): boolean {
  return tier in MODELS;
}

export async function complete(
  messages: AIMessage[],
  modelTier: string,
  apiKey: string,
  maxTokens: number = 1024,
  temperature: number = 0.7,
): Promise<AIResponse> {
  const model = MODELS[modelTier];
  if (!model) throw new Error(`OpenAI does not support model tier: ${modelTier}`);

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages,
      max_tokens: maxTokens,
      temperature,
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`OpenAI API error (${response.status}): ${err}`);
  }

  const data = await response.json();
  const choice = data.choices?.[0];

  return {
    text: choice?.message?.content ?? "",
    provider: "openai",
    model,
    tokensUsed: data.usage?.total_tokens ?? 0,
  };
}
