/**
 * Assemble the final prompt by substituting {{placeholder}} tokens
 * in the system prompt with user-provided input values.
 */
export function assemblePrompt(
  systemPrompt: string,
  inputs: Record<string, string | number | boolean>,
): string {
  let assembled = systemPrompt;

  for (const [key, value] of Object.entries(inputs)) {
    const placeholder = `{{${key}}}`;
    const replacement = value != null ? String(value) : "";
    assembled = assembled.replaceAll(placeholder, replacement);
  }

  // Remove any unreplaced placeholders (optional fields not provided)
  assembled = assembled.replace(/\{\{[a-z_]+\}\}/g, "(not provided)");

  return assembled;
}

/** Build the messages array for the AI provider */
export function buildMessages(
  assembledPrompt: string,
  userMessage?: string,
): Array<{ role: string; content: string }> {
  const messages: Array<{ role: string; content: string }> = [
    { role: "system", content: assembledPrompt },
  ];

  if (userMessage) {
    messages.push({ role: "user", content: userMessage });
  } else {
    messages.push({
      role: "user",
      content: "Please generate the output based on the information provided.",
    });
  }

  return messages;
}
