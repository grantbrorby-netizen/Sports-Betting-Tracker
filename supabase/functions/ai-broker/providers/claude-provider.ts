/** Anthropic Claude provider: haiku-4.5 (fast), sonnet-4.5 (smart), opus-4.6 (deep/max) */

import type { AIMessage, AIResponse } from "./openai-provider.ts";

const MODELS: Record<string, string> = {
  fast: "claude-haiku-4-5-20251001",
  smart: "claude-sonnet-4-5-20250929",
  deep: "claude-opus-4-6",
  max: "claude-opus-4-6",
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
  if (!model) throw new Error(`Claude does not support model tier: ${modelTier}`);

  // Separate system message from conversation
  const systemMsg = messages.find((m) => m.role === "system");
  const conversationMsgs = messages.filter((m) => m.role !== "system");

  const body: Record<string, unknown> = {
    model,
    max_tokens: maxTokens,
    messages: conversationMsgs.map((m) => ({
      role: m.role === "assistant" ? "assistant" : "user",
      content: m.content,
    })),
  };

  if (systemMsg) {
    body.system = systemMsg.content;
  }

  // Extended thinking for deep/max tiers
  if (modelTier === "deep" || modelTier === "max") {
    body.temperature = 1; // required for extended thinking
    const budgetTokens = modelTier === "max" ? 16000 : 8000;
    body.thinking = { type: "enabled", budget_tokens: budgetTokens };
    // max_tokens must be > budget_tokens for extended thinking
    body.max_tokens = maxTokens + budgetTokens;
  } else {
    body.temperature = temperature;
  }

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Anthropic API error (${response.status}): ${err}`);
  }

  const data = await response.json();

  // Extract text from content blocks (skip thinking blocks)
  const textBlocks = (data.content ?? []).filter(
    (block: { type: string }) => block.type === "text",
  );
  const text = textBlocks.map((b: { text: string }) => b.text).join("\n");

  const tokensUsed =
    (data.usage?.input_tokens ?? 0) + (data.usage?.output_tokens ?? 0);

  return {
    text,
    provider: "anthropic",
    model,
    tokensUsed,
  };
}
