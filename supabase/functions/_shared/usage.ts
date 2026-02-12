import { createAdminClient } from "./supabase-client.ts";

export interface DailyUsage {
  fast_calls: number;
  smart_calls: number;
  deep_calls: number;
  max_calls: number;
}

export interface TierLimits {
  fast_calls_per_day: number;
  smart_calls_per_day: number;
  deep_calls_per_day: number;
  max_calls_per_day: number;
  allowed_models: string[];
}

/** Check if user can make a call of the given model tier */
export async function checkUsageLimits(
  userId: string,
  modelTier: string,
  isByok: boolean,
): Promise<{ allowed: boolean; reason?: string; usage?: DailyUsage; limits?: TierLimits }> {
  // BYOK calls are always unlimited
  if (isByok) return { allowed: true };

  const admin = createAdminClient();

  // Get user's subscription tier
  const { data: sub } = await admin
    .from("subscriptions")
    .select("tier")
    .eq("user_id", userId)
    .single();

  const tier = sub?.tier ?? "free";

  // Get tier limits
  const { data: tierConfig } = await admin
    .from("subscription_tiers")
    .select("*")
    .eq("id", tier)
    .single();

  if (!tierConfig) return { allowed: false, reason: "Invalid subscription tier" };

  // Check if model is allowed for this tier
  const modelTierToModel: Record<string, string[]> = {
    fast: ["gpt-4o-mini", "claude-haiku-4.5"],
    smart: ["gpt-4o", "claude-sonnet-4.5"],
    deep: ["claude-opus-4.6"],
    max: ["claude-opus-4.6-max"],
  };

  const modelsForTier = modelTierToModel[modelTier] ?? [];
  const hasAccess = modelsForTier.some((m) =>
    tierConfig.allowed_models.includes(m)
  );

  if (!hasAccess) {
    return { allowed: false, reason: `${modelTier} models not available on ${tier} tier` };
  }

  // Get today's usage
  const { data: usageRows } = await admin.rpc("get_daily_usage", {
    p_user_id: userId,
  });

  const usage: DailyUsage = usageRows?.[0] ?? {
    fast_calls: 0,
    smart_calls: 0,
    deep_calls: 0,
    max_calls: 0,
  };

  const limits: TierLimits = {
    fast_calls_per_day: tierConfig.fast_calls_per_day,
    smart_calls_per_day: tierConfig.smart_calls_per_day,
    deep_calls_per_day: tierConfig.deep_calls_per_day,
    max_calls_per_day: tierConfig.max_calls_per_day,
    allowed_models: tierConfig.allowed_models,
  };

  // Check specific tier limit
  const limitMap: Record<string, { used: number; limit: number }> = {
    fast: { used: usage.fast_calls, limit: limits.fast_calls_per_day },
    smart: { used: usage.smart_calls, limit: limits.smart_calls_per_day },
    deep: { used: usage.deep_calls, limit: limits.deep_calls_per_day },
    max: { used: usage.max_calls, limit: limits.max_calls_per_day },
  };

  const check = limitMap[modelTier];
  if (check && check.used >= check.limit) {
    return {
      allowed: false,
      reason: `Daily ${modelTier} limit reached (${check.used}/${check.limit})`,
      usage,
      limits,
    };
  }

  return { allowed: true, usage, limits };
}

/** Increment usage after successful call */
export async function incrementUsage(
  userId: string,
  modelTier: string,
  tokens: number,
  isByok: boolean,
  isAutomation: boolean = false,
): Promise<void> {
  const admin = createAdminClient();
  await admin.rpc("increment_usage", {
    p_user_id: userId,
    p_model_tier: modelTier,
    p_tokens: tokens,
    p_is_byok: isByok,
    p_is_automation: isAutomation,
  });
}
