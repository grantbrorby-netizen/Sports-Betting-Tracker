import { describe, it, expect } from "vitest";

// Test chain execution logic (extracted for unit testing)
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

function buildStepPrompt(
  systemPrompt: string,
  inputValues: Record<string, string>,
  previousOutput: string | null
): string {
  let prompt = systemPrompt;

  // Replace input placeholders
  for (const [key, value] of Object.entries(inputValues)) {
    prompt = prompt.replace(new RegExp(`\\{\\{${key}\\}\\}`, "g"), value);
  }

  // Replace previous_output placeholder
  if (previousOutput !== null) {
    prompt = prompt.replace(/\{\{previous_output\}\}/g, previousOutput);
  }

  // Replace date placeholders
  const now = new Date();
  prompt = prompt.replace(/\{\{current_date\}\}/g, now.toISOString().split("T")[0]);
  prompt = prompt.replace(
    /\{\{current_day_of_week\}\}/g,
    now.toLocaleDateString("en-US", { weekday: "long" })
  );

  return prompt;
}

describe("buildStepPrompt", () => {
  it("replaces input placeholders", () => {
    const prompt = buildStepPrompt(
      "Create a plan for {{priorities}} during {{work_hours}}",
      { priorities: "Ship feature X", work_hours: "9 AM - 5 PM" },
      null
    );
    expect(prompt).toContain("Ship feature X");
    expect(prompt).toContain("9 AM - 5 PM");
    expect(prompt).not.toContain("{{priorities}}");
  });

  it("replaces previous_output in chained steps", () => {
    const prompt = buildStepPrompt(
      "Based on {{previous_output}}, create action items",
      {},
      "Step 1 produced this output"
    );
    expect(prompt).toContain("Step 1 produced this output");
    expect(prompt).not.toContain("{{previous_output}}");
  });

  it("replaces date placeholders", () => {
    const prompt = buildStepPrompt(
      "Today is {{current_date}}, {{current_day_of_week}}",
      {},
      null
    );
    expect(prompt).toMatch(/\d{4}-\d{2}-\d{2}/);
    expect(prompt).not.toContain("{{current_date}}");
    expect(prompt).not.toContain("{{current_day_of_week}}");
  });

  it("handles multiple occurrences of same placeholder", () => {
    const prompt = buildStepPrompt(
      "{{name}} is great. {{name}} is the best.",
      { name: "Alice" },
      null
    );
    expect(prompt).toBe("Alice is great. Alice is the best.");
  });

  it("leaves unknown placeholders as-is", () => {
    const prompt = buildStepPrompt(
      "Hello {{unknown_var}}",
      {},
      null
    );
    expect(prompt).toBe("Hello {{unknown_var}}");
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
      { name: "Step 1", systemPrompt: "Analyze: {{priorities}}" },
      { name: "Step 2", systemPrompt: "Improve: {{previous_output}}" },
      { name: "Step 3", systemPrompt: "Finalize: {{previous_output}}" },
    ];

    let previousOutput: string | null = null;
    const prompts: string[] = [];

    for (const step of steps) {
      const prompt = buildStepPrompt(
        step.systemPrompt,
        { priorities: "Build feature" },
        previousOutput
      );
      prompts.push(prompt);
      previousOutput = `Output of ${step.name}`;
    }

    expect(prompts[0]).toBe("Analyze: Build feature");
    expect(prompts[1]).toBe("Improve: Output of Step 1");
    expect(prompts[2]).toBe("Finalize: Output of Step 2");
  });
});
