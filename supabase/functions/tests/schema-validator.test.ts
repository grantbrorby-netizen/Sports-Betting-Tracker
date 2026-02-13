import { assertEquals, assert } from "https://deno.land/std@0.220.0/assert/mod.ts";
import { schemaCheck } from "../security-scanner/checks/schema-check.ts";

// --- Tests ---

Deno.test("valid template passes all schema checks", () => {
  const template = {
    id: "email-writer",
    version: "1.0.0",
    metadata: { name: "Email Writer", description: "Writes emails", category: "writing", iconName: "envelope", author: "Test" },
    inputs: [{ id: "topic", type: "text", label: "Topic" }],
    output: { format: "markdown" },
    ai: { defaultModelTier: "fast", systemPrompt: "Write about {{topic}}", temperature: 0.7, maxTokens: 1024 },
  };
  assertEquals(schemaCheck(template).length, 0);
});

Deno.test("missing required fields detected", () => {
  const findings = schemaCheck({ id: "test" });
  assert(findings.length >= 4);
  assert(findings.some(f => f.severity === "critical" && f.message.includes("Missing")));
});

Deno.test("invalid id format detected", () => {
  const template = {
    id: "Invalid_ID!",
    version: "1.0.0",
    metadata: { category: "writing" },
    inputs: [],
    output: {},
    ai: { defaultModelTier: "fast" },
  };
  const findings = schemaCheck(template);
  assert(findings.some(f => f.message.includes("Invalid id")));
});

Deno.test("invalid category detected", () => {
  const template = {
    id: "test-agent",
    version: "1.0.0",
    metadata: { category: "gaming" },
    inputs: [],
    output: {},
    ai: { defaultModelTier: "fast" },
  };
  const findings = schemaCheck(template);
  assert(findings.some(f => f.message.includes("Invalid category")));
});

Deno.test("invalid model tier detected", () => {
  const template = {
    id: "test-agent",
    version: "1.0.0",
    metadata: { category: "writing" },
    inputs: [],
    output: {},
    ai: { defaultModelTier: "turbo" },
  };
  const findings = schemaCheck(template);
  assert(findings.some(f => f.message.includes("Invalid model tier")));
});

Deno.test("invalid version format detected", () => {
  const template = {
    id: "test-agent",
    version: "v1.0",
    metadata: { category: "writing" },
    inputs: [],
    output: {},
    ai: { defaultModelTier: "fast" },
  };
  const findings = schemaCheck(template);
  assert(findings.some(f => f.message.includes("Invalid version")));
});

Deno.test("too many inputs detected", () => {
  const inputs = Array(12).fill({ id: "field", type: "text", label: "Field" });
  const template = {
    id: "test-agent",
    version: "1.0.0",
    metadata: { category: "writing" },
    inputs,
    output: {},
    ai: { defaultModelTier: "fast" },
  };
  const findings = schemaCheck(template);
  assert(findings.some(f => f.message.includes("Too many inputs")));
});

Deno.test("invalid input type detected", () => {
  const template = {
    id: "test-agent",
    version: "1.0.0",
    metadata: { category: "writing" },
    inputs: [{ id: "field", type: "dropdown", label: "Field" }],
    output: {},
    ai: { defaultModelTier: "fast" },
  };
  const findings = schemaCheck(template);
  assert(findings.some(f => f.message.includes("Invalid input type")));
});
