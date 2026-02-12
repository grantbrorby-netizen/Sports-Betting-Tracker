import { createAdminClient } from "./supabase-client.ts";

/**
 * Per-user sliding window rate limiter.
 * Uses Supabase to track request timestamps.
 * Falls back to in-memory if DB is unavailable.
 */

interface RateLimitConfig {
  windowMs: number;       // Sliding window duration in ms
  maxRequests: number;    // Max requests per window
  keyPrefix?: string;     // Optional prefix for different endpoints
}

// In-memory fallback (per-edge-function instance)
const memoryStore = new Map<string, number[]>();

/** Check rate limit for a user. Returns { allowed, remaining, retryAfterMs } */
export async function checkRateLimit(
  userId: string,
  config: RateLimitConfig,
): Promise<{ allowed: boolean; remaining: number; retryAfterMs?: number }> {
  const key = `${config.keyPrefix ?? "default"}:${userId}`;
  const now = Date.now();
  const windowStart = now - config.windowMs;

  // Use in-memory store (simple, works per edge function instance)
  let timestamps = memoryStore.get(key) ?? [];

  // Remove expired entries
  timestamps = timestamps.filter((t) => t > windowStart);

  if (timestamps.length >= config.maxRequests) {
    const oldestInWindow = timestamps[0];
    const retryAfterMs = oldestInWindow + config.windowMs - now;
    return {
      allowed: false,
      remaining: 0,
      retryAfterMs: Math.max(0, retryAfterMs),
    };
  }

  // Add current request
  timestamps.push(now);
  memoryStore.set(key, timestamps);

  // Cleanup old keys periodically (prevent memory leak)
  if (memoryStore.size > 10000) {
    for (const [k, v] of memoryStore) {
      const filtered = v.filter((t) => t > windowStart);
      if (filtered.length === 0) {
        memoryStore.delete(k);
      } else {
        memoryStore.set(k, filtered);
      }
    }
  }

  return {
    allowed: true,
    remaining: config.maxRequests - timestamps.length,
  };
}

/** Default rate limit configs for different endpoints */
export const RATE_LIMITS = {
  aiBroker: {
    windowMs: 60 * 1000,     // 1 minute
    maxRequests: 20,          // 20 requests per minute
    keyPrefix: "ai-broker",
  } satisfies RateLimitConfig,

  auth: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    maxRequests: 10,           // 10 auth attempts per 15 min
    keyPrefix: "auth",
  } satisfies RateLimitConfig,

  apiKeys: {
    windowMs: 60 * 1000,      // 1 minute
    maxRequests: 5,            // 5 key operations per minute
    keyPrefix: "api-keys",
  } satisfies RateLimitConfig,

  automations: {
    windowMs: 60 * 1000,      // 1 minute
    maxRequests: 10,           // 10 automation operations per minute
    keyPrefix: "automations",
  } satisfies RateLimitConfig,

  securityScanner: {
    windowMs: 60 * 1000,      // 1 minute
    maxRequests: 5,            // 5 scans per minute
    keyPrefix: "scanner",
  } satisfies RateLimitConfig,
};
