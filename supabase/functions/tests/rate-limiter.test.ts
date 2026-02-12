import { assertEquals, assert } from "https://deno.land/std@0.220.0/assert/mod.ts";

// Inline rate limiter for testing (same logic as _shared/rate-limiter.ts)

const memoryStore = new Map<string, number[]>();

interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
  keyPrefix?: string;
}

function checkRateLimit(
  userId: string,
  config: RateLimitConfig,
): { allowed: boolean; remaining: number; retryAfterMs?: number } {
  const key = `${config.keyPrefix ?? "default"}:${userId}`;
  const now = Date.now();
  const windowStart = now - config.windowMs;

  let timestamps = memoryStore.get(key) ?? [];
  timestamps = timestamps.filter((t) => t > windowStart);

  if (timestamps.length >= config.maxRequests) {
    const oldestInWindow = timestamps[0];
    const retryAfterMs = oldestInWindow + config.windowMs - now;
    return { allowed: false, remaining: 0, retryAfterMs: Math.max(0, retryAfterMs) };
  }

  timestamps.push(now);
  memoryStore.set(key, timestamps);
  return { allowed: true, remaining: config.maxRequests - timestamps.length };
}

function resetStore() {
  memoryStore.clear();
}

// --- Tests ---

Deno.test("allows first request", () => {
  resetStore();
  const result = checkRateLimit("user-1", { windowMs: 60000, maxRequests: 5 });
  assert(result.allowed);
  assertEquals(result.remaining, 4);
});

Deno.test("allows up to max requests", () => {
  resetStore();
  const config: RateLimitConfig = { windowMs: 60000, maxRequests: 3 };

  const r1 = checkRateLimit("user-2", config);
  const r2 = checkRateLimit("user-2", config);
  const r3 = checkRateLimit("user-2", config);

  assert(r1.allowed);
  assert(r2.allowed);
  assert(r3.allowed);
  assertEquals(r3.remaining, 0);
});

Deno.test("blocks after max requests", () => {
  resetStore();
  const config: RateLimitConfig = { windowMs: 60000, maxRequests: 2 };

  checkRateLimit("user-3", config);
  checkRateLimit("user-3", config);
  const r3 = checkRateLimit("user-3", config);

  assert(!r3.allowed);
  assertEquals(r3.remaining, 0);
  assert((r3.retryAfterMs ?? 0) > 0);
});

Deno.test("different users have separate limits", () => {
  resetStore();
  const config: RateLimitConfig = { windowMs: 60000, maxRequests: 1 };

  checkRateLimit("user-a", config);
  const result = checkRateLimit("user-b", config);

  assert(result.allowed, "Different users should have separate counters");
});

Deno.test("different prefixes have separate limits", () => {
  resetStore();

  checkRateLimit("user-x", { windowMs: 60000, maxRequests: 1, keyPrefix: "api" });
  const result = checkRateLimit("user-x", { windowMs: 60000, maxRequests: 1, keyPrefix: "auth" });

  assert(result.allowed, "Different prefixes should have separate counters");
});

Deno.test("expired entries are cleaned up", () => {
  resetStore();
  const config: RateLimitConfig = { windowMs: 100, maxRequests: 1 }; // 100ms window

  checkRateLimit("user-exp", config);

  // Manually set old timestamp
  memoryStore.set("default:user-exp", [Date.now() - 200]); // 200ms ago

  const result = checkRateLimit("user-exp", config);
  assert(result.allowed, "Expired entries should be cleaned, allowing new requests");
});

Deno.test("remaining count decreases correctly", () => {
  resetStore();
  const config: RateLimitConfig = { windowMs: 60000, maxRequests: 5 };

  const r1 = checkRateLimit("user-rem", config);
  const r2 = checkRateLimit("user-rem", config);
  const r3 = checkRateLimit("user-rem", config);

  assertEquals(r1.remaining, 4);
  assertEquals(r2.remaining, 3);
  assertEquals(r3.remaining, 2);
});

Deno.test("retryAfterMs is reasonable", () => {
  resetStore();
  const windowMs = 60000;
  const config: RateLimitConfig = { windowMs, maxRequests: 1 };

  checkRateLimit("user-retry", config);
  const result = checkRateLimit("user-retry", config);

  assert(!result.allowed);
  assert((result.retryAfterMs ?? 0) > 0);
  assert((result.retryAfterMs ?? 0) <= windowMs);
});
