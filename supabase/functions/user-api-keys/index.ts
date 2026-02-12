import { handleCors } from "$shared/cors.ts";
import { getUserFromRequest } from "$shared/auth.ts";
import { createAdminClient } from "$shared/supabase-client.ts";
import { encrypt, decrypt, createKeyHint } from "$shared/encryption.ts";
import {
  errorResponse,
  unauthorizedResponse,
  rateLimitResponse,
  successResponse,
} from "$shared/errors.ts";
import { checkRateLimit, RATE_LIMITS } from "$shared/rate-limiter.ts";

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const user = getUserFromRequest(req);
  if (!user) return unauthorizedResponse();

  const rateCheck = await checkRateLimit(user.id, RATE_LIMITS.apiKeys);
  if (!rateCheck.allowed) return rateLimitResponse("Too many requests. Try again shortly.");

  const admin = createAdminClient();
  const url = new URL(req.url);

  try {
    // GET: List user's API keys (masked)
    if (req.method === "GET") {
      const { data: keys, error } = await admin
        .from("user_api_keys")
        .select("id, provider, key_hint, is_active, last_used_at, created_at")
        .eq("user_id", user.id)
        .order("created_at");

      if (error) return errorResponse("QUERY_ERROR", error.message, 500);
      return successResponse({ keys: keys ?? [] });
    }

    // POST: Add a new API key
    if (req.method === "POST") {
      const { provider, api_key } = await req.json();

      if (!provider || !api_key) {
        return errorResponse("VALIDATION", "provider and api_key are required");
      }

      const validProviders = ["openai", "anthropic"];
      if (!validProviders.includes(provider)) {
        return errorResponse("VALIDATION", `Invalid provider. Use: ${validProviders.join(", ")}`);
      }

      // Validate key with a test call
      const isValid = await testApiKey(provider, api_key);
      if (!isValid) {
        return errorResponse("VALIDATION", "API key validation failed. Check the key and try again.");
      }

      // Encrypt and store
      const encryptedKey = await encrypt(api_key);
      const keyHint = createKeyHint(api_key);

      const { data, error } = await admin
        .from("user_api_keys")
        .upsert(
          {
            user_id: user.id,
            provider,
            encrypted_key: encryptedKey,
            key_hint: keyHint,
            is_active: true,
          },
          { onConflict: "user_id,provider" },
        )
        .select("id, provider, key_hint, is_active, created_at")
        .single();

      if (error) return errorResponse("INSERT_ERROR", error.message, 500);
      return successResponse({ key: data }, 201);
    }

    // DELETE: Remove an API key
    if (req.method === "DELETE") {
      const keyId = url.searchParams.get("id");
      if (!keyId) return errorResponse("VALIDATION", "id is required");

      const { error } = await admin
        .from("user_api_keys")
        .delete()
        .eq("id", keyId)
        .eq("user_id", user.id);

      if (error) return errorResponse("DELETE_ERROR", error.message, 500);
      return successResponse({ deleted: true });
    }

    return errorResponse("METHOD_NOT_ALLOWED", "GET, POST, DELETE only", 405);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return errorResponse("INTERNAL", message, 500);
  }
});

/** Test API key validity with a minimal request */
async function testApiKey(provider: string, apiKey: string): Promise<boolean> {
  try {
    if (provider === "openai") {
      const res = await fetch("https://api.openai.com/v1/models", {
        headers: { Authorization: `Bearer ${apiKey}` },
      });
      return res.ok;
    }

    if (provider === "anthropic") {
      const res = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-haiku-4-5-20251001",
          max_tokens: 1,
          messages: [{ role: "user", content: "hi" }],
        }),
      });
      // 200 means valid key (we'll get a response)
      // 401 means invalid key
      return res.status !== 401;
    }

    return false;
  } catch {
    return false;
  }
}
