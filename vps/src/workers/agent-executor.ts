import { Worker, Job } from "bullmq";
import IORedis from "ioredis";
import { config } from "../config.js";
import {
  createAutomationRun,
  updateAutomationRun,
  setAutomationError,
  type AutomationStep,
} from "../services/supabase-service.js";
import { executeChain, type StepResult } from "./chain-executor.js";
import { sendAutomationPush } from "./push-sender.js";

// ----- Job payload type -----

export interface AutomationJobData {
  automationId: string;
  userId: string;
  name: string;
  installedAgentId: string | null;
  templateId: string | null;
  inputValues: Record<string, unknown>;
  steps: AutomationStep[] | null;
  actionType: string;
  pushTitle: string | null;
  modelTier: string;
}

// ----- Redis connection for worker -----

const connection = new IORedis(config.redisUrl, {
  maxRetriesPerRequest: null,
});

let worker: Worker | null = null;

/**
 * Build the authorization headers used when calling the AI Broker edge function.
 */
function getAuthHeaders(): Record<string, string> {
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${config.supabaseServiceRoleKey}`,
  };
}

/**
 * Call the AI Broker edge function for a single-step automation.
 */
async function callAiBroker(
  templateId: string | null,
  inputs: Record<string, unknown>,
  modelTier: string,
  installedAgentId: string | null
): Promise<{
  output: string;
  tokensUsed: number;
  provider: string;
  durationMs: number;
}> {
  const body: Record<string, unknown> = {
    inputs,
    model_tier: modelTier,
  };

  if (templateId) {
    body.template_id = templateId;
  }

  if (installedAgentId) {
    body.installed_agent_id = installedAgentId;
  }

  const response = await fetch(config.aiBrokerUrl, {
    method: "POST",
    headers: getAuthHeaders(),
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(
      `AI Broker returned ${response.status}: ${errorText}`
    );
  }

  const json = (await response.json()) as {
    data: {
      output: string;
      tokens_used: number;
      provider: string;
      model_tier: string;
      duration_ms: number;
    };
  };

  return {
    output: json.data.output,
    tokensUsed: json.data.tokens_used,
    provider: json.data.provider,
    durationMs: json.data.duration_ms,
  };
}

/**
 * Process a single automation job.
 */
async function processAutomationJob(job: Job<AutomationJobData>): Promise<void> {
  const {
    automationId,
    userId,
    name,
    installedAgentId,
    templateId,
    inputValues,
    steps,
    actionType,
    pushTitle,
    modelTier,
  } = job.data;

  const startTime = Date.now();
  let runId: string | null = null;

  console.log(
    `[Executor] Processing automation "${name}" (${automationId}) for user ${userId}`
  );

  try {
    // 1. Create an automation_run record
    runId = await createAutomationRun(automationId, userId, modelTier);

    let finalOutput: string;
    let totalTokens = 0;
    let stepResults: StepResult[] = [];

    // 2. Determine single-step vs multi-step
    if (steps && steps.length > 1) {
      // Multi-step chain execution
      console.log(
        `[Executor] Running chain with ${steps.length} steps for "${name}"`
      );

      const chainResult = await executeChain(
        steps,
        inputValues,
        modelTier,
        config.aiBrokerUrl,
        getAuthHeaders()
      );

      stepResults = chainResult.stepResults;
      finalOutput = chainResult.finalOutput;
      totalTokens = chainResult.stepResults.reduce(
        (sum, s) => sum + s.tokensUsed,
        0
      );
    } else {
      // Single step: call AI Broker directly
      console.log(`[Executor] Running single-step automation "${name}"`);

      const result = await callAiBroker(
        templateId,
        inputValues,
        modelTier,
        installedAgentId
      );

      finalOutput = result.output;
      totalTokens = result.tokensUsed;
      stepResults = [
        {
          stepNumber: 1,
          output: result.output,
          tokensUsed: result.tokensUsed,
          durationMs: result.durationMs,
        },
      ];
    }

    const durationMs = Date.now() - startTime;

    // 3. Update automation_run with results
    await updateAutomationRun(runId, {
      status: "completed",
      step_results: stepResults as unknown as Record<string, unknown>[],
      final_output: finalOutput,
      tokens_used: totalTokens,
      duration_ms: durationMs,
      completed_at: new Date().toISOString(),
    });

    console.log(
      `[Executor] Automation "${name}" completed in ${durationMs}ms (${totalTokens} tokens)`
    );

    // 4. If action_type is push_notification, send push
    if (actionType === "push_notification") {
      await sendAutomationPush(
        userId,
        name,
        pushTitle ?? name,
        finalOutput,
        runId
      );
    }
  } catch (err) {
    const errorMessage =
      err instanceof Error ? err.message : "Unknown execution error";

    console.error(
      `[Executor] Automation "${name}" (${automationId}) failed:`,
      errorMessage
    );

    // Update the run record if it was created
    if (runId) {
      await updateAutomationRun(runId, {
        status: "failed",
        error_message: errorMessage,
        duration_ms: Date.now() - startTime,
        completed_at: new Date().toISOString(),
      }).catch((updateErr) => {
        console.error(
          `[Executor] Failed to update run ${runId} with error:`,
          updateErr
        );
      });
    }

    // Also mark the automation itself as errored
    await setAutomationError(automationId, errorMessage).catch((setErr) => {
      console.error(
        `[Executor] Failed to set automation ${automationId} error state:`,
        setErr
      );
    });

    // Re-throw so BullMQ can handle retries
    throw err;
  }
}

/**
 * Start the BullMQ worker listening on the 'automations' queue.
 */
export function startAgentExecutor(): void {
  worker = new Worker<AutomationJobData>(
    "automations",
    processAutomationJob,
    {
      connection,
      concurrency: 5,
      limiter: {
        max: 10,
        duration: 60_000, // max 10 jobs per minute
      },
    }
  );

  worker.on("completed", (job) => {
    console.log(
      `[Executor] Job ${job.id} completed for automation ${job.data.automationId}`
    );
  });

  worker.on("failed", (job, err) => {
    console.error(
      `[Executor] Job ${job?.id} failed for automation ${job?.data.automationId}:`,
      err.message
    );
  });

  worker.on("error", (err) => {
    console.error("[Executor] Worker error:", err);
  });
}

/**
 * Stop the BullMQ worker gracefully.
 */
export async function stopAgentExecutor(): Promise<void> {
  if (worker) {
    await worker.close();
    worker = null;
  }

  connection.disconnect();
}
