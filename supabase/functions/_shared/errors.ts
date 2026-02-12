import { corsHeaders } from "./cors.ts";

export function errorResponse(
  code: string,
  message: string,
  status: number = 400,
  details?: Record<string, unknown>,
): Response {
  return new Response(
    JSON.stringify({
      error: { code, message, ...(details && { details }) },
    }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}

export function unauthorizedResponse(
  message = "Missing or invalid authorization",
): Response {
  return errorResponse("UNAUTHORIZED", message, 401);
}

export function forbiddenResponse(message = "Forbidden"): Response {
  return errorResponse("FORBIDDEN", message, 403);
}

export function rateLimitResponse(message = "Rate limit exceeded"): Response {
  return errorResponse("RATE_LIMIT", message, 429);
}

export function successResponse(
  data: unknown,
  status: number = 200,
): Response {
  return new Response(
    JSON.stringify({ data }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}
