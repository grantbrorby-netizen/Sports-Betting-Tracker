import { createClient, SupabaseClient } from "@supabase/supabase-js";
import { config } from "../config.js";

// Admin client using service role key - bypasses RLS
const supabase: SupabaseClient = createClient(
  config.supabaseUrl,
  config.supabaseServiceRoleKey,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

export { supabase };

// ----- Types -----

export interface DueAutomation {
  id: string;
  user_id: string;
  name: string;
  installed_agent_id: string | null;
  template_id: string | null;
  cron_expression: string;
  timezone: string;
  input_values: Record<string, unknown>;
  steps: AutomationStep[] | null;
  action_type: string;
  push_title: string | null;
  model_tier: string;
  is_enabled: boolean;
  next_run_at: string;
  last_run_at: string | null;
}

export interface AutomationStep {
  step_number: number;
  system_prompt: string;
  template_id?: string;
  inputs?: Record<string, unknown>;
}

export interface AutomationRunInsert {
  automation_id: string;
  user_id: string;
  model_tier: string;
  status: string;
  started_at: string;
}

export interface AutomationRunUpdate {
  status?: string;
  step_results?: Record<string, unknown>[];
  final_output?: string;
  tokens_used?: number;
  duration_ms?: number;
  push_sent?: boolean;
  error_message?: string;
  completed_at?: string;
}

// ----- Functions -----

/**
 * Query automations where next_run_at <= now AND is_enabled = true
 */
export async function getDueAutomations(): Promise<DueAutomation[]> {
  const now = new Date().toISOString();

  const { data, error } = await supabase
    .from("automations")
    .select("*")
    .eq("is_enabled", true)
    .lte("next_run_at", now)
    .order("next_run_at", { ascending: true });

  if (error) {
    console.error("[SupabaseService] Error fetching due automations:", error.message);
    throw error;
  }

  return (data ?? []) as DueAutomation[];
}

/**
 * Update automation timestamps after a successful run
 */
export async function updateAutomationAfterRun(
  id: string,
  nextRunAt: string,
  lastRunAt: string
): Promise<void> {
  const { error } = await supabase
    .from("automations")
    .update({
      next_run_at: nextRunAt,
      last_run_at: lastRunAt,
      status: "active",
    })
    .eq("id", id);

  if (error) {
    console.error(
      `[SupabaseService] Error updating automation ${id} after run:`,
      error.message
    );
    throw error;
  }
}

/**
 * Set automation status to 'error' with an error message
 */
export async function setAutomationError(
  id: string,
  errorMessage: string
): Promise<void> {
  const { error } = await supabase
    .from("automations")
    .update({
      status: "error",
      last_error: errorMessage,
    })
    .eq("id", id);

  if (error) {
    console.error(
      `[SupabaseService] Error setting automation ${id} to error state:`,
      error.message
    );
    throw error;
  }
}

/**
 * Create a new automation_run record. Returns the run id.
 */
export async function createAutomationRun(
  automationId: string,
  userId: string,
  modelTier: string
): Promise<string> {
  const record: AutomationRunInsert = {
    automation_id: automationId,
    user_id: userId,
    model_tier: modelTier,
    status: "running",
    started_at: new Date().toISOString(),
  };

  const { data, error } = await supabase
    .from("automation_runs")
    .insert(record)
    .select("id")
    .single();

  if (error) {
    console.error(
      `[SupabaseService] Error creating automation run for ${automationId}:`,
      error.message
    );
    throw error;
  }

  return data.id as string;
}

/**
 * Update an existing automation_run record
 */
export async function updateAutomationRun(
  runId: string,
  updates: AutomationRunUpdate
): Promise<void> {
  const { error } = await supabase
    .from("automation_runs")
    .update(updates)
    .eq("id", runId);

  if (error) {
    console.error(
      `[SupabaseService] Error updating automation run ${runId}:`,
      error.message
    );
    throw error;
  }
}

/**
 * Get a user's device token for push notifications
 */
export async function getUserDeviceToken(
  userId: string
): Promise<string | null> {
  const { data, error } = await supabase
    .from("profiles")
    .select("device_token")
    .eq("id", userId)
    .single();

  if (error) {
    console.error(
      `[SupabaseService] Error fetching device token for user ${userId}:`,
      error.message
    );
    return null;
  }

  return (data?.device_token as string) ?? null;
}

/**
 * Get decrypted BYOK API key for a user and provider.
 * Calls the user-api-keys edge function or queries the vault directly.
 */
export async function getUserByokKey(
  userId: string,
  provider: string
): Promise<string | null> {
  const { data, error } = await supabase
    .from("user_api_keys")
    .select("api_key_encrypted")
    .eq("user_id", userId)
    .eq("provider", provider)
    .single();

  if (error) {
    console.error(
      `[SupabaseService] Error fetching BYOK key for user ${userId}, provider ${provider}:`,
      error.message
    );
    return null;
  }

  // The key may be decrypted via a Postgres function or handled at the edge function layer.
  // For now, return the stored value; the AI Broker edge function handles decryption.
  return (data?.api_key_encrypted as string) ?? null;
}
