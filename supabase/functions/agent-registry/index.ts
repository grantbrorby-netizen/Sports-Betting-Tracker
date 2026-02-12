import { handleCors } from "$shared/cors.ts";
import { getUserFromRequest } from "$shared/auth.ts";
import { createAdminClient } from "$shared/supabase-client.ts";
import {
  errorResponse,
  unauthorizedResponse,
  successResponse,
} from "$shared/errors.ts";

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  if (req.method !== "GET") {
    return errorResponse("METHOD_NOT_ALLOWED", "GET only", 405);
  }

  const user = getUserFromRequest(req);
  if (!user) return unauthorizedResponse();

  const url = new URL(req.url);
  const search = url.searchParams.get("search");
  const category = url.searchParams.get("category");
  const featured = url.searchParams.get("featured");
  const limit = parseInt(url.searchParams.get("limit") ?? "50");
  const offset = parseInt(url.searchParams.get("offset") ?? "0");

  const admin = createAdminClient();

  try {
    let query = admin
      .from("agent_templates")
      .select("*")
      .eq("is_public", true)
      .order("is_featured", { ascending: false })
      .order("name")
      .range(offset, offset + limit - 1);

    // Filter by category
    if (category) {
      query = query.eq("category", category);
    }

    // Filter featured only
    if (featured === "true") {
      query = query.eq("is_featured", true);
    }

    // Full-text search
    if (search) {
      query = query.textSearch("name", search, {
        type: "websearch",
        config: "english",
      });
    }

    const { data: templates, error } = await query;

    if (error) {
      return errorResponse("QUERY_ERROR", error.message, 500);
    }

    // Also get user's installed agents to mark which are installed
    const { data: installed } = await admin
      .from("installed_agents")
      .select("template_id")
      .eq("user_id", user.id);

    const installedSet = new Set(
      (installed ?? []).map((i: { template_id: string }) => i.template_id),
    );

    const enriched = (templates ?? []).map((t) => ({
      ...t,
      is_installed: installedSet.has(t.id),
    }));

    return successResponse({
      templates: enriched,
      total: enriched.length,
      offset,
      limit,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return errorResponse("INTERNAL", message, 500);
  }
});
