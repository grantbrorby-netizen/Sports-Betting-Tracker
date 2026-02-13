/**
 * Push notification formatting utilities.
 */

const DEFAULT_MAX_LENGTH = 200;

/** Truncate text at a clean break point (sentence or word boundary). */
export function truncateForPush(
  text: string,
  maxLength: number = DEFAULT_MAX_LENGTH
): string {
  if (text.length <= maxLength) return text;

  // Find a clean break point (end of sentence or word)
  const truncated = text.slice(0, maxLength);
  const lastPeriod = truncated.lastIndexOf(".");
  const lastSpace = truncated.lastIndexOf(" ");

  if (lastPeriod > maxLength * 0.6) {
    return truncated.slice(0, lastPeriod + 1);
  }
  if (lastSpace > maxLength * 0.6) {
    return truncated.slice(0, lastSpace) + "...";
  }
  return truncated + "...";
}

/** Strip markdown formatting from text for push notification display. */
export function formatPushBody(
  output: string,
  maxLength: number = DEFAULT_MAX_LENGTH
): string {
  let clean = output
    .replace(/#{1,6}\s+/g, "")           // headers
    .replace(/\*\*(.*?)\*\*/g, "$1")      // bold
    .replace(/\*(.*?)\*/g, "$1")          // italic
    .replace(/`(.*?)`/g, "$1")           // inline code
    .replace(/\n{2,}/g, "\n")            // multiple newlines
    .replace(/^[-*]\s+/gm, "• ")         // bullet points
    .trim();

  return truncateForPush(clean, maxLength);
}

/** Build an APNs-compatible push payload. */
export function buildPushPayload(
  title: string,
  body: string,
  data?: Record<string, string>
) {
  return {
    aps: {
      alert: { title, body },
      sound: "default" as const,
      badge: 1,
    },
    ...(data && { data }),
  };
}
