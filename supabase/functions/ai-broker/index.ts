import { handleCors, corsHeaders } from "$shared/cors.ts";
import {
  getUserFromRequest,
  getTokenFromRequest,
} from "$shared/auth.ts";
import { createAdminClient } from "$shared/supabase-client.ts";
import { checkUsageLimits, incrementUsage } from "$shared/usage.ts";
import { decrypt } from "$shared/encryption.ts";
import {
  errorResponse,
  unauthorizedResponse,
  rateLimitResponse,
  successResponse,
} from "$shared/errors.ts";
import { checkRateLimit, RATE_LIMITS } from "$shared/rate-limiter.ts";
import { assemblePrompt, buildMessages } from "./prompt-assembler.ts";
import {
  selectProvider,
  executeCompletion,
} from "./providers/provider-registry.ts";

Deno.serve(async (req) => {
  // CORS preflight
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  if (req.method !== "POST") {
    return errorResponse("METHOD_NOT_ALLOWED", "POST only", 405);
  }

  // 1. Auth
  const user = getUserFromRequest(req);
  if (!user) return unauthorizedResponse();

  // 1b. Rate limit
  const rateCheck = await checkRateLimit(user.id, RATE_LIMITS.aiBroker);
  if (!rateCheck.allowed) return rateLimitResponse("Too many requests. Try again shortly.");

  // 1c. Payload size limit (100KB)
  const contentLength = parseInt(req.headers.get("Content-Length") ?? "0", 10);
  if (contentLength > 102400) {
    return errorResponse("PAYLOAD_TOO_LARGE", "Request body exceeds 100KB limit", 413);
  }

  const startTime = Date.now();

  try {
    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return errorResponse("VALIDATION", "Invalid JSON in request body");
    }
    const { template_id, inputs, model_tier: requestedTier } = body;

    if (!template_id || !inputs) {
      return errorResponse("VALIDATION", "template_id and inputs are required");
    }

    const admin = createAdminClient();

    // 2. Get template
    const { data: template, error: tplErr } = await admin
      .from("agent_templates")
      .select("*")
      .eq("template_id", template_id)
      .single();

    if (tplErr || !template) {
      return errorResponse("NOT_FOUND", `Template not found: ${template_id}`, 404);
    }

    const modelTier = requestedTier ?? template.default_model_tier ?? "fast";

    // 3. Check for BYOK keys
    const { data: userKeys } = await admin
      .from("user_api_keys")
      .select("provider, encrypted_key")
      .eq("user_id", user.id)
      .eq("is_active", true);

    const byokKeys: Record<string, string> = {};
    for (const uk of userKeys ?? []) {
      try {
        byokKeys[uk.provider] = await decrypt(uk.encrypted_key);
      } catch {
        // Skip invalid keys
      }
    }

    const hasByokForTier = Object.keys(byokKeys).length > 0;

    // 4. Check usage limits (skipped for BYOK)
    const usageCheck = await checkUsageLimits(user.id, modelTier, hasByokForTier);
    if (!usageCheck.allowed) {
      return rateLimitResponse(usageCheck.reason);
    }

    // 5. Select provider
    const platformKeys: Record<string, string> = {};
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (openaiKey) platformKeys.openai = openaiKey;
    if (anthropicKey) platformKeys.anthropic = anthropicKey;

    const selection = selectProvider(modelTier, byokKeys, platformKeys);
    if (!selection) {
      return errorResponse(
        "NO_PROVIDER",
        "No AI provider available for this model tier",
        503,
      );
    }

    const isByok = !!byokKeys[selection.providerName];

    // 6. Assemble prompt
    const assembledPrompt = assemblePrompt(template.system_prompt, inputs);
    const messages = buildMessages(assembledPrompt);

    // 7. Call AI provider
    const result = await executeCompletion(
      selection.providerName,
      messages,
      modelTier,
      selection.apiKey,
      template.max_tokens,
      template.temperature,
    );

    const durationMs = Date.now() - startTime;

    // 8. Track usage
    await incrementUsage(user.id, modelTier, result.tokensUsed, isByok);

    // 9. Save execution record
    await admin.from("agent_executions").insert({
      user_id: user.id,
      template_id: template.id,
      input: inputs,
      output: result.text,
      provider: result.provider,
      model_tier: modelTier,
      tokens_used: result.tokensUsed,
      duration_ms: durationMs,
      is_byok: isByok,
      triggered_by: body.triggered_by ?? "manual",
      status: "completed",
    });

    // 10. Update last_used_at on installed agent (if provided)
    if (body.installed_agent_id) {
      await admin
        .from("installed_agents")
        .update({ last_used_at: new Date().toISOString() })
        .eq("id", body.installed_agent_id)
        .eq("user_id", user.id);
    }

    return successResponse({
      output: result.text,
      provider: result.provider,
      model: result.model,
      model_tier: modelTier,
      tokens_used: result.tokensUsed,
      duration_ms: durationMs,
      is_byok: isByok,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("AI Broker error:", message);
    return errorResponse("INTERNAL", message, 500);
  }
});
