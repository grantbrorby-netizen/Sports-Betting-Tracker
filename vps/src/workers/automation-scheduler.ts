import { Queue } from "bullmq";
import IORedis from "ioredis";
import cronParser from "cron-parser";
import { config } from "../config.js";
import {
  getDueAutomations,
  updateAutomationAfterRun,
  setAutomationError,
  type DueAutomation,
} from "../services/supabase-service.js";

const connection = new IORedis(config.redisUrl, {
  maxRetriesPerRequest: null,
});

const automationQueue = new Queue("automations", { connection });

let pollTimer: ReturnType<typeof setInterval> | null = null;
let isPolling = false;

/**
 * Calculate the next run time from a cron expression and timezone.
 * Returns an ISO string for the next occurrence.
 */
function calculateNextRunAt(cronExpression: string, timezone: string): string {
  try {
    const interval = cronParser.parseExpression(cronExpression, {
      currentDate: new Date(),
      tz: timezone,
    });
    const nextDate = interval.next().toDate();
    return nextDate.toISOString();
  } catch (err) {
    console.error(
      `[Scheduler] Failed to parse cron expression "${cronExpression}" with tz "${timezone}":`,
      err
    );
    throw err;
  }
}

/**
 * Process a single due automation: enqueue it and update its next_run_at.
 */
async function enqueueAutomation(automation: DueAutomation): Promise<void> {
  const jobId = `automation-${automation.id}-${Date.now()}`;

  await automationQueue.add(
    "execute",
    {
      automationId: automation.id,
      userId: automation.user_id,
      name: automation.name,
      installedAgentId: automation.installed_agent_id,
      templateId: automation.template_id,
      inputValues: automation.input_values,
      steps: automation.steps,
      actionType: automation.action_type,
      pushTitle: automation.push_title,
      modelTier: automation.model_tier,
    },
    {
      jobId,
      attempts: 3,
      backoff: {
        type: "exponential",
        delay: 5000,
      },
      removeOnComplete: { count: 1000 },
      removeOnFail: { count: 500 },
    }
  );

  // Calculate next run and update the automation record
  const now = new Date().toISOString();
  const nextRunAt = calculateNextRunAt(
    automation.cron_expression,
    automation.timezone
  );

  await updateAutomationAfterRun(automation.id, nextRunAt, now);

  console.log(
    `[Scheduler] Enqueued automation "${automation.name}" (${automation.id}). Next run: ${nextRunAt}`
  );
}

/**
 * Single poll cycle: fetch due automations and enqueue each one.
 */
async function pollCycle(): Promise<void> {
  if (isPolling) {
    console.log("[Scheduler] Previous poll cycle still running, skipping...");
    return;
  }

  isPolling = true;

  try {
    const dueAutomations = await getDueAutomations();

    if (dueAutomations.length > 0) {
      console.log(
        `[Scheduler] Found ${dueAutomations.length} due automation(s)`
      );
    }

    for (const automation of dueAutomations) {
      try {
        await enqueueAutomation(automation);
      } catch (err) {
        const errorMessage =
          err instanceof Error ? err.message : "Unknown error during enqueue";
        console.error(
          `[Scheduler] Failed to enqueue automation "${automation.name}" (${automation.id}):`,
          errorMessage
        );

        // Mark the automation as errored so it does not block the loop
        try {
          await setAutomationError(automation.id, errorMessage);
        } catch (updateErr) {
          console.error(
            `[Scheduler] Failed to set error state for automation ${automation.id}:`,
            updateErr
          );
        }
      }
    }
  } catch (err) {
    console.error("[Scheduler] Error during poll cycle:", err);
  } finally {
    isPolling = false;
  }
}

/**
 * Start the polling loop. Runs pollCycle every POLL_INTERVAL_MS.
 */
export function startScheduler(): void {
  // Run an initial poll immediately
  pollCycle();

  pollTimer = setInterval(pollCycle, config.pollIntervalMs);
}

/**
 * Stop the polling loop and close the BullMQ queue.
 */
export function stopScheduler(): void {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }

  automationQueue.close().catch((err) => {
    console.error("[Scheduler] Error closing automation queue:", err);
  });

  connection.disconnect();
}
