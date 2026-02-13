/**
 * Replace template variables in a system prompt.
 *
 * Supported variables:
 *   - {{previous_output}} : replaced with the output of the previous step
 *   - {{input.KEY}}       : replaced with the value of inputValues[KEY]
 *   - {{current_date}}    : replaced with today's date (YYYY-MM-DD)
 *   - {{current_day_of_week}} : replaced with the day name (e.g., "Thursday")
 */
export function resolvePrompt(
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

  // Replace date placeholders
  const now = new Date();
  resolved = resolved.replace(
    /\{\{current_date\}\}/g,
    now.toISOString().split("T")[0]
  );
  resolved = resolved.replace(
    /\{\{current_day_of_week\}\}/g,
    now.toLocaleDateString("en-US", { weekday: "long" })
  );

  return resolved;
}
