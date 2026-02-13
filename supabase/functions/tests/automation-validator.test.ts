import { assertEquals, assert } from "https://deno.land/std@0.220.0/assert/mod.ts";
import { validateAutomationConfig } from "../automations/automation-validator.ts";
import type { AutomationConfig } from "../automations/automation-validator.ts";

// --- Tests ---

Deno.test("valid automation config passes", () => {
  const config: AutomationConfig = {
    name: "Daily Plan",
    template_id: "daily-plan-builder",
    cron_expression: "0 7 * * *",
    model_tier: "fast",
    action_type: "push_notification",
  };
  const result = validateAutomationConfig(config);
  assert(result.valid);
  assertEquals(result.errors.length, 0);
});

Deno.test("missing name fails", () => {
  const config: AutomationConfig = {
    name: "",
    template_id: "test",
    cron_expression: "0 7 * * *",
  };
  const result = validateAutomationConfig(config);
  assert(!result.valid);
  assert(result.errors.some(e => e.includes("name is required")));
});

Deno.test("missing template_id fails", () => {
  const config: AutomationConfig = {
    name: "Test",
    template_id: "",
    cron_expression: "0 7 * * *",
  };
  const result = validateAutomationConfig(config);
  assert(!result.valid);
  assert(result.errors.some(e => e.includes("template_id is required")));
});

Deno.test("invalid cron expression fails", () => {
  const config: AutomationConfig = {
    name: "Test",
    template_id: "test",
    cron_expression: "invalid cron",
  };
  const result = validateAutomationConfig(config);
  assert(!result.valid);
  assert(result.errors.some(e => e.includes("Invalid cron")));
});

Deno.test("valid cron expressions accepted", () => {
  const valid = [
    "0 7 * * *",
    "30 21 * * *",
    "0 17 * * 5",
    "*/15 * * * *",
    "0 9 * * 1,2,3,4,5",
    "0 0 1 * *",
  ];
  for (const cron of valid) {
    const result = validateAutomationConfig({
      name: "Test",
      template_id: "test",
      cron_expression: cron,
    });
    assert(result.valid, `Expected valid cron: ${cron}, got errors: ${result.errors.join(", ")}`);
  }
});

Deno.test("invalid cron expressions rejected", () => {
  const invalid = [
    "60 7 * * *",
    "0 25 * * *",
    "0 7 32 * *",
    "0 7 * 13 *",
    "0 7 * * 7",
    "* * *",
    "a b c d e",
  ];
  for (const cron of invalid) {
    const result = validateAutomationConfig({
      name: "Test",
      template_id: "test",
      cron_expression: cron,
    });
    assert(!result.valid, `Expected invalid cron: ${cron}`);
    assert(result.errors.some(e => e.includes("Invalid cron")));
  }
});

Deno.test("too many steps fails", () => {
  const config: AutomationConfig = {
    name: "Test",
    template_id: "test",
    cron_expression: "0 7 * * *",
    steps: [
      { name: "S1", systemPrompt: "Do something useful step 1" },
      { name: "S2", systemPrompt: "Do something useful step 2" },
      { name: "S3", systemPrompt: "Do something useful step 3" },
      { name: "S4", systemPrompt: "Do something useful step 4" },
    ],
  };
  const result = validateAutomationConfig(config);
  assert(!result.valid);
  assert(result.errors.some(e => e.includes("Maximum 3 steps")));
});

Deno.test("step with short prompt fails", () => {
  const config: AutomationConfig = {
    name: "Test",
    template_id: "test",
    cron_expression: "0 7 * * *",
    steps: [{ name: "S1", systemPrompt: "short" }],
  };
  const result = validateAutomationConfig(config);
  assert(!result.valid);
  assert(result.errors.some(e => e.includes("at least 10 characters")));
});

Deno.test("invalid model tier fails", () => {
  const config: AutomationConfig = {
    name: "Test",
    template_id: "test",
    cron_expression: "0 7 * * *",
    model_tier: "ultra",
  };
  const result = validateAutomationConfig(config);
  assert(!result.valid);
  assert(result.errors.some(e => e.includes("Invalid model_tier")));
});

Deno.test("invalid action type fails", () => {
  const config: AutomationConfig = {
    name: "Test",
    template_id: "test",
    cron_expression: "0 7 * * *",
    action_type: "send_email",
  };
  const result = validateAutomationConfig(config);
  assert(!result.valid);
  assert(result.errors.some(e => e.includes("Invalid action_type")));
});

Deno.test("valid multi-step config passes", () => {
  const config: AutomationConfig = {
    name: "Evening Reset",
    template_id: "evening-reset",
    cron_expression: "30 21 * * *",
    steps: [
      { name: "Reflect", systemPrompt: "Reflect on the day and summarize accomplishments", maxTokens: 600 },
      { name: "Plan", systemPrompt: "Based on {{previous_output}}, create tomorrow's top 3", maxTokens: 400 },
    ],
    action_type: "push_notification",
    model_tier: "fast",
  };
  const result = validateAutomationConfig(config);
  assert(result.valid);
  assertEquals(result.errors.length, 0);
});

Deno.test("step with invalid maxTokens fails", () => {
  const config: AutomationConfig = {
    name: "Test",
    template_id: "test",
    cron_expression: "0 7 * * *",
    steps: [{ name: "S1", systemPrompt: "A valid system prompt here", maxTokens: 50 }],
  };
  const result = validateAutomationConfig(config);
  assert(!result.valid);
  assert(result.errors.some(e => e.includes("maxTokens must be between")));
});

Deno.test("name too long fails", () => {
  const config: AutomationConfig = {
    name: "A".repeat(101),
    template_id: "test",
    cron_expression: "0 7 * * *",
  };
  const result = validateAutomationConfig(config);
  assert(!result.valid);
  assert(result.errors.some(e => e.includes("100 characters")));
});
