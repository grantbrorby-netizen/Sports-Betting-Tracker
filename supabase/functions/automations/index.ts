import { handleCors } from "$shared/cors.ts";
import { getUserFromRequest } from "$shared/auth.ts";
import { createAdminClient } from "$shared/supabase-client.ts";
import {
  errorResponse,
  unauthorizedResponse,
  successResponse,
} from "$shared/errors.ts";
import {
  validateAutomationConfig,
  calculateNextRun,
  type AutomationConfig,
} from "./automation-validator.ts";

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const user = getUserFromRequest(req);
  if (!user) return unauthorizedResponse();

  const admin = createAdminClient();
  const url = new URL(req.url);

  try {
    // GET: List user's automations
    if (req.method === "GET") {
      const { data, error } = await admin
        .from("automations")
        .select("*")
        .eq("user_id", user.id)
        .order("created_at", { ascending: false });

      if (error) return errorResponse("QUERY_ERROR", error.message, 500);
      return successResponse({ automations: data ?? [] });
    }

    // POST: Create automation
    if (req.method === "POST") {
      const body: AutomationConfig = await req.json();

      // Validate config
      const validation = validateAutomationConfig(body);
      if (!validation.valid) {
        return errorResponse("VALIDATION", validation.errors.join("; "));
      }

      // Check tier limits for automation count
      const tierCheck = await checkAutomationTierLimit(admin, user.id);
      if (!tierCheck.allowed) {
        return errorResponse("TIER_LIMIT", tierCheck.reason!, 403);
      }

      // Verify template exists
      const { data: template } = await admin
        .from("agent_templates")
        .select("template_id")
        .eq("template_id", body.template_id)
        .single();

      if (!template) {
        return errorResponse("NOT_FOUND", `Template not found: ${body.template_id}`);
      }

      const timezone = body.timezone ?? "America/New_York";
      const nextRun = calculateNextRun(body.cron_expression, timezone);

      const { data, error } = await admin
        .from("automations")
        .insert({
          user_id: user.id,
          name: body.name,
          template_id: body.template_id,
          cron_expression: body.cron_expression,
          timezone,
          steps: body.steps ?? [],
          input_values: body.input_values ?? {},
          action_type: body.action_type ?? "push_notification",
          push_title: body.push_title,
          model_tier: body.model_tier ?? "fast",
          next_run_at: nextRun.toISOString(),
        })
        .select()
        .single();

      if (error) return errorResponse("INSERT_ERROR", error.message, 500);
      return successResponse({ automation: data }, 201);
    }

    // PUT: Update automation
    if (req.method === "PUT") {
      const automationId = url.searchParams.get("id");
      if (!automationId) return errorResponse("VALIDATION", "id is required");

      const body: Partial<AutomationConfig> & { is_enabled?: boolean } = await req.json();

      // If changing config fields, validate them
      if (body.cron_expression || body.name || body.template_id) {
        const existing = await getAutomation(admin, automationId, user.id);
        if (!existing) return errorResponse("NOT_FOUND", "Automation not found", 404);

        const merged: AutomationConfig = {
          name: body.name ?? existing.name,
          template_id: body.template_id ?? existing.template_id,
          cron_expression: body.cron_expression ?? existing.cron_expression,
          timezone: body.timezone ?? existing.timezone,
          steps: body.steps ?? existing.steps,
          input_values: body.input_values ?? existing.input_values,
          action_type: body.action_type ?? existing.action_type,
          model_tier: body.model_tier ?? existing.model_tier,
        };

        const validation = validateAutomationConfig(merged);
        if (!validation.valid) {
          return errorResponse("VALIDATION", validation.errors.join("; "));
        }
      }

      // Build update object (only include provided fields)
      const update: Record<string, unknown> = {};
      if (body.name !== undefined) update.name = body.name;
      if (body.cron_expression !== undefined) {
        update.cron_expression = body.cron_expression;
        update.next_run_at = calculateNextRun(
          body.cron_expression,
          body.timezone ?? "America/New_York",
        ).toISOString();
      }
      if (body.timezone !== undefined) update.timezone = body.timezone;
      if (body.steps !== undefined) update.steps = body.steps;
      if (body.input_values !== undefined) update.input_values = body.input_values;
      if (body.action_type !== undefined) update.action_type = body.action_type;
      if (body.push_title !== undefined) update.push_title = body.push_title;
      if (body.model_tier !== undefined) update.model_tier = body.model_tier;
      if (body.is_enabled !== undefined) {
        update.is_enabled = body.is_enabled;
        if (body.is_enabled) {
          update.status = "active";
          update.error_message = null;
        } else {
          update.status = "paused";
        }
      }

      if (Object.keys(update).length === 0) {
        return errorResponse("VALIDATION", "No fields to update");
      }

      const { data, error } = await admin
        .from("automations")
        .update(update)
        .eq("id", automationId)
        .eq("user_id", user.id)
        .select()
        .single();

      if (error) return errorResponse("UPDATE_ERROR", error.message, 500);
      if (!data) return errorResponse("NOT_FOUND", "Automation not found", 404);
      return successResponse({ automation: data });
    }

    // DELETE: Remove automation
    if (req.method === "DELETE") {
      const automationId = url.searchParams.get("id");
      if (!automationId) return errorResponse("VALIDATION", "id is required");

      const { error } = await admin
        .from("automations")
        .delete()
        .eq("id", automationId)
        .eq("user_id", user.id);

      if (error) return errorResponse("DELETE_ERROR", error.message, 500);
      return successResponse({ deleted: true });
    }

    return errorResponse("METHOD_NOT_ALLOWED", "GET, POST, PUT, DELETE only", 405);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return errorResponse("INTERNAL", message, 500);
  }
});

// --- Helpers ---

async function getAutomation(
  admin: ReturnType<typeof createAdminClient>,
  id: string,
  userId: string,
) {
  const { data } = await admin
    .from("automations")
    .select("*")
    .eq("id", id)
    .eq("user_id", userId)
    .single();
  return data;
}

async function checkAutomationTierLimit(
  admin: ReturnType<typeof createAdminClient>,
  userId: string,
): Promise<{ allowed: boolean; reason?: string }> {
  // Get current subscription
  const { data: sub } = await admin
    .from("subscriptions")
    .select("tier")
    .eq("user_id", userId)
    .single();

  const tier = sub?.tier ?? "free";

  // Get tier config
  const { data: tierConfig } = await admin
    .from("subscription_tiers")
    .select("features")
    .eq("id", tier)
    .single();

  const maxAutomations = tierConfig?.features?.max_automations ?? 0;

  if (maxAutomations === 0) {
    return { allowed: false, reason: "Automations require a Pro or Unlimited subscription" };
  }

  // Count existing automations
  const { count } = await admin
    .from("automations")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId);

  if ((count ?? 0) >= maxAutomations) {
    return {
      allowed: false,
      reason: `Maximum ${maxAutomations} automations on ${tier} tier. Upgrade for more.`,
    };
  }

  return { allowed: true };
}
