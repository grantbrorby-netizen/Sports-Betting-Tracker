/**
 * Provider Registry: selects which AI provider to use based on
 * model tier, template preference, and BYOK availability.
 */

import * as openai from "./openai-provider.ts";
import * as claude from "./claude-provider.ts";
import type { AIMessage, AIResponse } from "./openai-provider.ts";

export type { AIMessage, AIResponse };

interface ProviderModule {
  supportsModelTier: (tier: string) => boolean;
  complete: (
    messages: AIMessage[],
    modelTier: string,
    apiKey: string,
    maxTokens?: number,
    temperature?: number,
  ) => Promise<AIResponse>;
}

const providers: Record<string, ProviderModule> = {
  openai,
  anthropic: claude,
};

/** Preferred provider order per model tier */
const defaultProviderOrder: Record<string, string[]> = {
  fast: ["openai", "anthropic"],     // gpt-4o-mini is cheapest
  smart: ["anthropic", "openai"],    // sonnet-4.5 is strong
  deep: ["anthropic"],               // only Claude has extended thinking
  max: ["anthropic"],                // only Claude
};

export interface ProviderSelection {
  providerName: string;
  apiKey: string;
}

/**
 * Select provider based on: model tier → BYOK availability → default order.
 * Returns null if no provider is available.
 */
export function selectProvider(
  modelTier: string,
  byokKeys: Record<string, string>,
  platformKeys: Record<string, string>,
): ProviderSelection | null {
  const order = defaultProviderOrder[modelTier] ?? ["openai", "anthropic"];

  // First: try BYOK keys in preferred order
  for (const name of order) {
    const provider = providers[name];
    if (provider?.supportsModelTier(modelTier) && byokKeys[name]) {
      return { providerName: name, apiKey: byokKeys[name] };
    }
  }

  // Second: try platform keys in preferred order
  for (const name of order) {
    const provider = providers[name];
    if (provider?.supportsModelTier(modelTier) && platformKeys[name]) {
      return { providerName: name, apiKey: platformKeys[name] };
    }
  }

  return null;
}

/** Execute completion with the selected provider */
export async function executeCompletion(
  providerName: string,
  messages: AIMessage[],
  modelTier: string,
  apiKey: string,
  maxTokens: number = 1024,
  temperature: number = 0.7,
): Promise<AIResponse> {
  const provider = providers[providerName];
  if (!provider) throw new Error(`Unknown provider: ${providerName}`);

  return await provider.complete(messages, modelTier, apiKey, maxTokens, temperature);
}
