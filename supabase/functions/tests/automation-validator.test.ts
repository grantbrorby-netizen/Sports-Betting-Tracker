import { assertEquals, assert } from "https://deno.land/std@0.220.0/assert/mod.ts";

// Inline validator logic (same as automation-validator.ts)
interface AutomationConfig {
  name: string;
  template_id: string;
  cron_expression: string;
  timezone?: string;
  steps?: Array<{ name: string; systemPrompt: string; maxTokens?: number }>;
  input_values?: Record<string, string>;
  action_type?: string;
  push_title?: string;
  model_tier?: string;
}

interface ValidationResult {
  valid: boolean;
  errors: string[];
}

function isValidCronField(field: string, min: number, max: number): boolean {
  if (field === "*") return true;
  const values = field.split(",");
  for (const value of values) {
    if (value.includes("-")) {
      const [start, end] = value.split("-").map(Number);
      if (isNaN(start) || isNaN(end) || start < min || end > max || start > end) return false;
      continue;
    }
    if (value.includes("/")) {
      const [base, step] = value.split("/");
      if (base !== "*" && (isNaN(Number(base)) || Number(base) < min || Number(base) > max)) return false;
      if (isNaN(Number(step)) || Number(step) < 1) return false;
      continue;
    }
    const num = Number(value);
    if (isNaN(num) || num < min || num > max) return false;
  }
  return true;
}

function isValidCron(expression: string): boolean {
  const parts = expression.trim().split(/\s+/);
  if (parts.length !== 5) return false;
  const ranges = [
    { min: 0, max: 59 }, { min: 0, max: 23 },
    { min: 1, max: 31 }, { min: 1, max: 12 }, { min: 0, max: 6 },
  ];
  for (let i = 0; i < 5; i++) {
    if (!isValidCronField(parts[i], ranges[i].min, ranges[i].max)) return false;
  }
  return true;
}

function validateAutomationConfig(config: AutomationConfig): ValidationResult {
  const errors: string[] = [];

  if (!config.name || config.name.trim().length === 0) {
    errors.push("name is required");
  } else if (config.name.length > 100) {
    errors.push("name must be 100 characters or fewer");
  }

  if (!config.template_id || config.template_id.trim().length === 0) {
    errors.push("template_id is required");
  }

  if (!config.cron_expression) {
    errors.push("cron_expression is required");
  } else if (!isValidCron(config.cron_expression)) {
    errors.push("Invalid cron expression. Format: minute hour day-of-month month day-of-week");
  }

  if (config.steps) {
    if (config.steps.length > 3) {
      errors.push("Maximum 3 steps allowed");
    }
    for (let i = 0; i < config.steps.length; i++) {
      const step = config.steps[i];
      if (!step.name) errors.push(`Step ${i + 1}: name is required`);
      if (!step.systemPrompt || step.systemPrompt.length < 10) {
        errors.push(`Step ${i + 1}: systemPrompt must be at least 10 characters`);
      }
      if (step.maxTokens && (step.maxTokens < 100 || step.maxTokens > 4096)) {
        errors.push(`Step ${i + 1}: maxTokens must be between 100 and 4096`);
      }
    }
  }

  if (config.action_type && !["push_notification", "save_result"].includes(config.action_type)) {
    errors.push(`Invalid action_type. Use: push_notification, save_result`);
  }

  if (config.model_tier && !["fast", "smart", "deep", "max"].includes(config.model_tier)) {
    errors.push(`Invalid model_tier. Use: fast, smart, deep, max`);
  }

  return { valid: errors.length === 0, errors };
}

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

Deno.test("valid cron expressions", () => {
  const valid = [
    "0 7 * * *",       // daily at 7am
    "30 21 * * *",     // daily at 9:30pm
    "0 17 * * 5",      // friday at 5pm
    "*/15 * * * *",    // every 15 min
    "0 9 * * 1,2,3,4,5", // weekdays at 9am
    "0 0 1 * *",       // monthly
  ];
  for (const cron of valid) {
    assert(isValidCron(cron), `Expected valid: ${cron}`);
  }
});

Deno.test("invalid cron expressions", () => {
  const invalid = [
    "60 7 * * *",      // minute > 59
    "0 25 * * *",      // hour > 23
    "0 7 32 * *",      // day > 31
    "0 7 * 13 *",      // month > 12
    "0 7 * * 7",       // dow > 6
    "* * *",           // only 3 fields
    "a b c d e",       // non-numeric
  ];
  for (const cron of invalid) {
    assert(!isValidCron(cron), `Expected invalid: ${cron}`);
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
