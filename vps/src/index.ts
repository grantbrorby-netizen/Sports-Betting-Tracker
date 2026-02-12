import { config } from "./config.js";
import { startScheduler, stopScheduler } from "./workers/automation-scheduler.js";
import { startAgentExecutor, stopAgentExecutor } from "./workers/agent-executor.js";
import { initApns, shutdownApns } from "./services/apns-service.js";

async function main(): Promise<void> {
  console.log("=== AgentHub VPS Worker ===");
  console.log(`Supabase URL: ${config.supabaseUrl}`);
  console.log(`Redis URL: ${config.redisUrl}`);
  console.log(`AI Broker URL: ${config.aiBrokerUrl}`);
  console.log(`Poll interval: ${config.pollIntervalMs}ms`);
  console.log(`APNs Bundle ID: ${config.apnsBundleId}`);
  console.log("");

  // Initialize APNs provider
  initApns();
  console.log("[APNs] Provider initialized");

  // Start the BullMQ worker that processes automation jobs
  startAgentExecutor();
  console.log("[Worker] Agent executor started, listening on 'automations' queue");

  // Start the polling scheduler that enqueues due automations
  startScheduler();
  console.log(
    `[Scheduler] Polling loop started (every ${config.pollIntervalMs}ms)`
  );

  console.log("");
  console.log("AgentHub VPS Worker is running. Press Ctrl+C to stop.");
}

// Graceful shutdown
async function shutdown(signal: string): Promise<void> {
  console.log(`\n[Shutdown] Received ${signal}, shutting down gracefully...`);

  stopScheduler();
  console.log("[Shutdown] Scheduler stopped");

  await stopAgentExecutor();
  console.log("[Shutdown] Agent executor stopped");

  shutdownApns();
  console.log("[Shutdown] APNs provider shut down");

  console.log("[Shutdown] Cleanup complete. Exiting.");
  process.exit(0);
}

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));

main().catch((err) => {
  console.error("[Fatal] Failed to start AgentHub VPS Worker:", err);
  process.exit(1);
});
