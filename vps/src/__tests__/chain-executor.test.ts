import { describe, it, expect } from "vitest";
import { resolvePrompt } from "../utils/prompt-utils.js";

interface StepConfig {
  name: string;
  systemPrompt: string;
  maxTokens?: number;
}

interface StepResult {
  stepName: string;
  output: string;
  tokensUsed: number;
  durationMs: number;
}

describe("resolvePrompt", () => {
  it("replaces input placeholders", () => {
    const prompt = resolvePrompt(
      "Create a plan for {{input.priorities}} during {{input.work_hours}}",
      null,
      { priorities: "Ship feature X", work_hours: "9 AM - 5 PM" }
    );
    expect(prompt).toContain("Ship feature X");
    expect(prompt).toContain("9 AM - 5 PM");
    expect(prompt).not.toContain("{{input.priorities}}");
  });

  it("replaces previous_output in chained steps", () => {
    const prompt = resolvePrompt(
      "Based on {{previous_output}}, create action items",
      "Step 1 produced this output",
      {}
    );
    expect(prompt).toContain("Step 1 produced this output");
    expect(prompt).not.toContain("{{previous_output}}");
  });

  it("replaces date placeholders", () => {
    const prompt = resolvePrompt(
      "Today is {{current_date}}, {{current_day_of_week}}",
      null,
      {}
    );
    expect(prompt).toMatch(/\d{4}-\d{2}-\d{2}/);
    expect(prompt).not.toContain("{{current_date}}");
    expect(prompt).not.toContain("{{current_day_of_week}}");
  });

  it("handles multiple occurrences of same placeholder", () => {
    const prompt = resolvePrompt(
      "{{input.name}} is great. {{input.name}} is the best.",
      null,
      { name: "Alice" }
    );
    expect(prompt).toBe("Alice is great. Alice is the best.");
  });

  it("replaces missing input values with empty string", () => {
    const prompt = resolvePrompt(
      "Hello {{input.unknown_var}}!",
      null,
      {}
    );
    expect(prompt).toBe("Hello !");
  });
});

describe("chain execution flow", () => {
  it("aggregates step results correctly", () => {
    const results: StepResult[] = [
      { stepName: "Analyze", output: "Analysis done", tokensUsed: 150, durationMs: 800 },
      { stepName: "Summarize", output: "Summary done", tokensUsed: 100, durationMs: 500 },
    ];

    const totalTokens = results.reduce((sum, r) => sum + r.tokensUsed, 0);
    const totalDuration = results.reduce((sum, r) => sum + r.durationMs, 0);
    const finalOutput = results[results.length - 1].output;

    expect(totalTokens).toBe(250);
    expect(totalDuration).toBe(1300);
    expect(finalOutput).toBe("Summary done");
  });

  it("chains step outputs correctly", () => {
    const steps: StepConfig[] = [
      { name: "Step 1", systemPrompt: "Analyze: {{input.priorities}}" },
      { name: "Step 2", systemPrompt: "Improve: {{previous_output}}" },
      { name: "Step 3", systemPrompt: "Finalize: {{previous_output}}" },
    ];

    let previousOutput: string | null = null;
    const prompts: string[] = [];

    for (const step of steps) {
      const prompt = resolvePrompt(
        step.systemPrompt,
        previousOutput,
        { priorities: "Build feature" }
      );
      prompts.push(prompt);
      previousOutput = `Output of ${step.name}`;
    }

    expect(prompts[0]).toBe("Analyze: Build feature");
    expect(prompts[1]).toBe("Improve: Output of Step 1");
    expect(prompts[2]).toBe("Finalize: Output of Step 2");
  });
});
