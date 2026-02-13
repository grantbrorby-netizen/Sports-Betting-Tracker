import { assertEquals, assert } from "https://deno.land/std@0.220.0/assert/mod.ts";
import { checkRateLimit, _resetForTesting } from "../_shared/rate-limiter.ts";

// --- Tests ---

Deno.test("allows first request", async () => {
  _resetForTesting();
  const result = await checkRateLimit("user-1", { windowMs: 60000, maxRequests: 5 });
  assert(result.allowed);
  assertEquals(result.remaining, 4);
});

Deno.test("allows up to max requests", async () => {
  _resetForTesting();
  const config = { windowMs: 60000, maxRequests: 3 };

  const r1 = await checkRateLimit("user-2", config);
  const r2 = await checkRateLimit("user-2", config);
  const r3 = await checkRateLimit("user-2", config);

  assert(r1.allowed);
  assert(r2.allowed);
  assert(r3.allowed);
  assertEquals(r3.remaining, 0);
});

Deno.test("blocks after max requests", async () => {
  _resetForTesting();
  const config = { windowMs: 60000, maxRequests: 2 };

  await checkRateLimit("user-3", config);
  await checkRateLimit("user-3", config);
  const r3 = await checkRateLimit("user-3", config);

  assert(!r3.allowed);
  assertEquals(r3.remaining, 0);
  assert((r3.retryAfterMs ?? 0) > 0);
});

Deno.test("different users have separate limits", async () => {
  _resetForTesting();
  const config = { windowMs: 60000, maxRequests: 1 };

  await checkRateLimit("user-a", config);
  const result = await checkRateLimit("user-b", config);

  assert(result.allowed, "Different users should have separate counters");
});

Deno.test("different prefixes have separate limits", async () => {
  _resetForTesting();

  await checkRateLimit("user-x", { windowMs: 60000, maxRequests: 1, keyPrefix: "api" });
  const result = await checkRateLimit("user-x", { windowMs: 60000, maxRequests: 1, keyPrefix: "auth" });

  assert(result.allowed, "Different prefixes should have separate counters");
});

Deno.test("remaining count decreases correctly", async () => {
  _resetForTesting();
  const config = { windowMs: 60000, maxRequests: 5 };

  const r1 = await checkRateLimit("user-rem", config);
  const r2 = await checkRateLimit("user-rem", config);
  const r3 = await checkRateLimit("user-rem", config);

  assertEquals(r1.remaining, 4);
  assertEquals(r2.remaining, 3);
  assertEquals(r3.remaining, 2);
});

Deno.test("retryAfterMs is reasonable", async () => {
  _resetForTesting();
  const windowMs = 60000;
  const config = { windowMs, maxRequests: 1 };

  await checkRateLimit("user-retry", config);
  const result = await checkRateLimit("user-retry", config);

  assert(!result.allowed);
  assert((result.retryAfterMs ?? 0) > 0);
  assert((result.retryAfterMs ?? 0) <= windowMs);
});
