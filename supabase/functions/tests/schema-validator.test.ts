import { assertEquals, assert } from "https://deno.land/std@0.220.0/assert/mod.ts";

// Inline validator for testing (same logic as validate-template.ts)
function validateTemplateFields(template: Record<string, unknown>): string[] {
  const errors: string[] = [];

  const required = ["id", "version", "metadata", "inputs", "output", "ai"];
  for (const field of required) {
    if (!(field in template)) errors.push(`Missing: ${field}`);
  }

  if (typeof template.id === "string" && !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(template.id)) {
    errors.push("Invalid id format");
  }

  if (typeof template.version === "string" && !/^\d+\.\d+\.\d+$/.test(template.version)) {
    errors.push("Invalid version format");
  }

  if (template.metadata && typeof template.metadata === "object") {
    const meta = template.metadata as Record<string, unknown>;
    const validCategories = ["writing", "finance", "productivity", "health", "cooking", "legal"];
    if (meta.category && !validCategories.includes(meta.category as string)) {
      errors.push(`Invalid category: ${meta.category}`);
    }
  }

  if (template.ai && typeof template.ai === "object") {
    const ai = template.ai as Record<string, unknown>;
    const validTiers = ["fast", "smart", "deep", "max"];
    if (ai.defaultModelTier && !validTiers.includes(ai.defaultModelTier as string)) {
      errors.push(`Invalid model tier: ${ai.defaultModelTier}`);
    }
  }

  return errors;
}

Deno.test("valid template passes", () => {
  const template = {
    id: "email-writer",
    version: "1.0.0",
    metadata: { name: "Email Writer", description: "Writes emails", category: "writing", iconName: "envelope", author: "Test" },
    inputs: [{ id: "topic", type: "text", label: "Topic" }],
    output: { format: "markdown" },
    ai: { defaultModelTier: "fast", systemPrompt: "You are an email writer. Write about {{topic}}." },
  };
  const errors = validateTemplateFields(template);
  assertEquals(errors.length, 0);
});

Deno.test("missing required fields", () => {
  const template = { id: "test" };
  const errors = validateTemplateFields(template);
  assert(errors.length > 0);
  assert(errors.some(e => e.includes("Missing")));
});

Deno.test("invalid id format", () => {
  const template = {
    id: "Invalid_ID",
    version: "1.0.0",
    metadata: { name: "T", description: "D", category: "writing", iconName: "i", author: "A" },
    inputs: [{ id: "x", type: "text", label: "X" }],
    output: { format: "text" },
    ai: { defaultModelTier: "fast", systemPrompt: "Do something {{x}}" },
  };
  const errors = validateTemplateFields(template);
  assert(errors.some(e => e.includes("Invalid id")));
});

Deno.test("invalid category", () => {
  const template = {
    id: "test",
    version: "1.0.0",
    metadata: { name: "T", description: "D", category: "invalid", iconName: "i", author: "A" },
    inputs: [{ id: "x", type: "text", label: "X" }],
    output: { format: "text" },
    ai: { defaultModelTier: "fast", systemPrompt: "Do something {{x}}" },
  };
  const errors = validateTemplateFields(template);
  assert(errors.some(e => e.includes("Invalid category")));
});

Deno.test("invalid model tier", () => {
  const template = {
    id: "test",
    version: "1.0.0",
    metadata: { name: "T", description: "D", category: "writing", iconName: "i", author: "A" },
    inputs: [{ id: "x", type: "text", label: "X" }],
    output: { format: "text" },
    ai: { defaultModelTier: "ultra", systemPrompt: "Do something {{x}}" },
  };
  const errors = validateTemplateFields(template);
  assert(errors.some(e => e.includes("Invalid model tier")));
});
