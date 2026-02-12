import type { AutomationStep } from "../services/supabase-service.js";

// ----- Types -----

export interface StepResult {
  stepNumber: number;
  output: string;
  tokensUsed: number;
  durationMs: number;
}

export interface ChainResult {
  stepResults: StepResult[];
  finalOutput: string;
}

interface AiBrokerResponse {
  data: {
    output: string;
    tokens_used: number;
    provider: string;
    model_tier: string;
    duration_ms: number;
  };
}

// ----- Functions -----

/**
 * Call the AI Broker edge function with a given system prompt and inputs.
 */
async function callAiBrokerStep(
  step: AutomationStep,
  resolvedPrompt: string,
  inputValues: Record<string, unknown>,
  modelTier: string,
  aiBrokerUrl: string,
  authHeaders: Record<string, string>
): Promise<{
  output: string;
  tokensUsed: number;
  durationMs: number;
}> {
  const body: Record<string, unknown> = {
    model_tier: modelTier,
    inputs: {
      ...inputValues,
      system_prompt: resolvedPrompt,
    },
  };

  // If the step references a specific template, include it
  if (step.template_id) {
    body.template_id = step.template_id;
  }

  // Merge step-specific inputs if present
  if (step.inputs) {
    body.inputs = {
      ...(body.inputs as Record<string, unknown>),
      ...step.inputs,
    };
  }

  const response = await fetch(aiBrokerUrl, {
    method: "POST",
    headers: authHeaders,
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(
      `AI Broker returned ${response.status} on step ${step.step_number}: ${errorText}`
    );
  }

  const json = (await response.json()) as AiBrokerResponse;

  return {
    output: json.data.output,
    tokensUsed: json.data.tokens_used,
    durationMs: json.data.duration_ms,
  };
}

/**
 * Replace template variables in a system prompt.
 *
 * Supported variables:
 *   - {{previous_output}} : replaced with the output of the previous step
 *   - {{input.KEY}}       : replaced with the value of inputValues[KEY]
 */
function resolvePrompt(
  systemPrompt: string,
  previousOutput: string | null,
  inputValues: Record<string, unknown>
): string {
  let resolved = systemPrompt;

  // Replace {{previous_output}} with the prior step's output
  if (previousOutput !== null) {
    resolved = resolved.replace(/\{\{previous_output\}\}/g, previousOutput);
  }

  // Replace {{input.KEY}} patterns with input values
  resolved = resolved.replace(/\{\{input\.(\w+)\}\}/g, (_match, key: string) => {
    const value = inputValues[key];
    if (value === undefined || value === null) {
      return "";
    }
    return String(value);
  });

  return resolved;
}

/**
 * Execute a multi-step automation chain.
 *
 * Each step's system prompt can reference {{previous_output}} to receive
 * the output of the prior step, enabling sequential reasoning chains.
 *
 * @param steps - Array of automation steps, ordered by step_number
 * @param inputValues - User-provided input values for the automation
 * @param modelTier - The AI model tier to use (e.g., "fast", "standard", "premium")
 * @param aiBrokerUrl - URL of the AI Broker edge function
 * @param authHeaders - Authorization headers for the AI Broker
 * @returns ChainResult with all step results and the final output
 */
export async function executeChain(
  steps: AutomationStep[],
  inputValues: Record<string, unknown>,
  modelTier: string,
  aiBrokerUrl: string,
  authHeaders: Record<string, string>
): Promise<ChainResult> {
  // Sort steps by step_number to ensure correct execution order
  const sortedSteps = [...steps].sort(
    (a, b) => a.step_number - b.step_number
  );

  const stepResults: StepResult[] = [];
  let previousOutput: string | null = null;

  for (const step of sortedSteps) {
    console.log(
      `[ChainExecutor] Executing step ${step.step_number} of ${sortedSteps.length}`
    );

    const resolvedPrompt = resolvePrompt(
      step.system_prompt,
      previousOutput,
      inputValues
    );

    const stepStart = Date.now();

    const result = await callAiBrokerStep(
      step,
      resolvedPrompt,
      inputValues,
      modelTier,
      aiBrokerUrl,
      authHeaders
    );

    const stepDuration = Date.now() - stepStart;

    const stepResult: StepResult = {
      stepNumber: step.step_number,
      output: result.output,
      tokensUsed: result.tokensUsed,
      durationMs: result.durationMs || stepDuration,
    };

    stepResults.push(stepResult);
    previousOutput = result.output;

    console.log(
      `[ChainExecutor] Step ${step.step_number} completed (${result.tokensUsed} tokens, ${stepResult.durationMs}ms)`
    );
  }

  const finalOutput = previousOutput ?? "";

  console.log(
    `[ChainExecutor] Chain completed: ${stepResults.length} steps, ` +
      `${stepResults.reduce((s, r) => s + r.tokensUsed, 0)} total tokens`
  );

  return {
    stepResults,
    finalOutput,
  };
}
