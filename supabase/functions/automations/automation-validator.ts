/** Validate automation configuration before saving */

export interface AutomationConfig {
  name: string;
  template_id: string;
  cron_expression: string;
  timezone?: string;
  steps?: Array<{ name: string; systemPrompt: string; maxTokens?: number }>;
  input_values?: Record<string, string>;
  action_type?: string;
  push_title?: string;
  model_tier?: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
}

const VALID_MODEL_TIERS = ["fast", "smart", "deep", "max"];
const VALID_ACTION_TYPES = ["push_notification", "save_result"];
const MAX_STEPS = 3;

export function validateAutomationConfig(config: AutomationConfig): ValidationResult {
  const errors: string[] = [];

  // Name
  if (!config.name || config.name.trim().length === 0) {
    errors.push("name is required");
  } else if (config.name.length > 100) {
    errors.push("name must be 100 characters or fewer");
  }

  // Template ID
  if (!config.template_id || config.template_id.trim().length === 0) {
    errors.push("template_id is required");
  }

  // Cron expression
  if (!config.cron_expression) {
    errors.push("cron_expression is required");
  } else if (!isValidCron(config.cron_expression)) {
    errors.push("Invalid cron expression. Format: minute hour day-of-month month day-of-week");
  }

  // Timezone
  if (config.timezone && !isValidTimezone(config.timezone)) {
    errors.push(`Invalid timezone: ${config.timezone}`);
  }

  // Steps
  if (config.steps) {
    if (config.steps.length > MAX_STEPS) {
      errors.push(`Maximum ${MAX_STEPS} steps allowed`);
    }
    for (let i = 0; i < config.steps.length; i++) {
      const step = config.steps[i];
      if (!step.name) errors.push(`Step ${i + 1}: name is required`);
      if (!step.systemPrompt || step.systemPrompt.length < 10) {
        errors.push(`Step ${i + 1}: systemPrompt must be at least 10 characters`);
      }
      if (step.maxTokens && (step.maxTokens < 100 || step.maxTokens > 4096)) {
        errors.push(`Step ${i + 1}: maxTokens must be between 100 and 4096`);
      }
    }
  }

  // Action type
  if (config.action_type && !VALID_ACTION_TYPES.includes(config.action_type)) {
    errors.push(`Invalid action_type. Use: ${VALID_ACTION_TYPES.join(", ")}`);
  }

  // Model tier
  if (config.model_tier && !VALID_MODEL_TIERS.includes(config.model_tier)) {
    errors.push(`Invalid model_tier. Use: ${VALID_MODEL_TIERS.join(", ")}`);
  }

  return { valid: errors.length === 0, errors };
}

/** Validate cron expression (5-field: min hour dom month dow) */
function isValidCron(expression: string): boolean {
  const parts = expression.trim().split(/\s+/);
  if (parts.length !== 5) return false;

  const ranges = [
    { min: 0, max: 59 },  // minute
    { min: 0, max: 23 },  // hour
    { min: 1, max: 31 },  // day of month
    { min: 1, max: 12 },  // month
    { min: 0, max: 6 },   // day of week
  ];

  for (let i = 0; i < 5; i++) {
    if (!isValidCronField(parts[i], ranges[i].min, ranges[i].max)) {
      return false;
    }
  }

  return true;
}

function isValidCronField(field: string, min: number, max: number): boolean {
  if (field === "*") return true;

  // Handle comma-separated values
  const values = field.split(",");
  for (const value of values) {
    // Handle ranges (e.g., 1-5)
    if (value.includes("-")) {
      const [start, end] = value.split("-").map(Number);
      if (isNaN(start) || isNaN(end) || start < min || end > max || start > end) {
        return false;
      }
      continue;
    }

    // Handle step values (e.g., */5)
    if (value.includes("/")) {
      const [base, step] = value.split("/");
      if (base !== "*" && (isNaN(Number(base)) || Number(base) < min || Number(base) > max)) {
        return false;
      }
      if (isNaN(Number(step)) || Number(step) < 1) return false;
      continue;
    }

    // Simple number
    const num = Number(value);
    if (isNaN(num) || num < min || num > max) return false;
  }

  return true;
}

function isValidTimezone(tz: string): boolean {
  try {
    Intl.DateTimeFormat(undefined, { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

/** Calculate next run time from cron expression (simplified — returns next occurrence) */
export function calculateNextRun(cronExpression: string, timezone: string): Date {
  const now = new Date();
  const parts = cronExpression.trim().split(/\s+/);
  const [minute, hour] = parts.map(Number);

  // Simple next-occurrence: find the next time that matches minute + hour
  const next = new Date(now);

  if (!isNaN(hour) && !isNaN(minute)) {
    next.setHours(hour, minute, 0, 0);
    if (next <= now) {
      next.setDate(next.getDate() + 1);
    }
  } else {
    // Fallback: next hour
    next.setHours(next.getHours() + 1, 0, 0, 0);
  }

  return next;
}
