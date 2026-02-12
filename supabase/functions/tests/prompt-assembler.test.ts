import { assertEquals } from "https://deno.land/std@0.220.0/assert/mod.ts";
import { assemblePrompt, buildMessages } from "../ai-broker/prompt-assembler.ts";

Deno.test("assemblePrompt - replaces all placeholders", () => {
  const prompt = "Write about {{topic}} in {{tone}} tone.";
  const inputs = { topic: "dogs", tone: "friendly" };
  const result = assemblePrompt(prompt, inputs);
  assertEquals(result, "Write about dogs in friendly tone.");
});

Deno.test("assemblePrompt - handles missing optional fields", () => {
  const prompt = "Topic: {{topic}}\nNotes: {{notes}}";
  const inputs = { topic: "cats" };
  const result = assemblePrompt(prompt, inputs);
  assertEquals(result, "Topic: cats\nNotes: (not provided)");
});

Deno.test("assemblePrompt - handles multiple occurrences", () => {
  const prompt = "{{name}} said hi. {{name}} waved.";
  const inputs = { name: "Alice" };
  const result = assemblePrompt(prompt, inputs);
  assertEquals(result, "Alice said hi. Alice waved.");
});

Deno.test("assemblePrompt - handles boolean and number inputs", () => {
  const prompt = "Count: {{count}}, Active: {{active}}";
  const inputs = { count: 5, active: true };
  const result = assemblePrompt(prompt, inputs);
  assertEquals(result, "Count: 5, Active: true");
});

Deno.test("buildMessages - creates system + user messages", () => {
  const messages = buildMessages("You are helpful.", "Tell me a joke.");
  assertEquals(messages.length, 2);
  assertEquals(messages[0].role, "system");
  assertEquals(messages[0].content, "You are helpful.");
  assertEquals(messages[1].role, "user");
  assertEquals(messages[1].content, "Tell me a joke.");
});

Deno.test("buildMessages - generates default user message when none provided", () => {
  const messages = buildMessages("You are helpful.");
  assertEquals(messages.length, 2);
  assertEquals(messages[1].role, "user");
  assertEquals(messages[1].content.length > 0, true);
});
