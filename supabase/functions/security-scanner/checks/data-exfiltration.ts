import type { ScanFinding } from "../scan-result.ts";

/** Patterns that could indicate data exfiltration attempts */
const URL_PATTERN = /https?:\/\/[^\s"'<>]+/gi;
const EMAIL_PATTERN = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;
const PHONE_PATTERN = /\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/g;
const SSN_PATTERN = /\b\d{3}-\d{2}-\d{4}\b/g;
const CREDIT_CARD_PATTERN = /\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/g;

/** Allowed URL domains in prompts (documentation, examples) */
const ALLOWED_DOMAINS = [
  "example.com",
  "example.org",
  "placeholder.com",
];

/** Scan for URLs, PII patterns, and data exfiltration risks */
export function dataExfiltrationCheck(template: Record<string, unknown>): ScanFinding[] {
  const findings: ScanFinding[] = [];

  const textsToScan: Array<{ text: string; location: string }> = [];

  if (template.ai && typeof template.ai === "object") {
    const ai = template.ai as Record<string, unknown>;
    if (typeof ai.systemPrompt === "string") {
      textsToScan.push({ text: ai.systemPrompt, location: "ai.systemPrompt" });
    }
  }

  if (template.metadata && typeof template.metadata === "object") {
    const meta = template.metadata as Record<string, unknown>;
    if (typeof meta.description === "string") {
      textsToScan.push({ text: meta.description, location: "metadata.description" });
    }
  }

  if (template.automation && typeof template.automation === "object") {
    const auto = template.automation as Record<string, unknown>;
    if (Array.isArray(auto.steps)) {
      for (let i = 0; i < auto.steps.length; i++) {
        const step = auto.steps[i] as Record<string, unknown>;
        if (typeof step.systemPrompt === "string") {
          textsToScan.push({ text: step.systemPrompt, location: `automation.steps[${i}].systemPrompt` });
        }
      }
    }
  }

  for (const { text, location } of textsToScan) {
    // Check for URLs
    const urls = text.match(URL_PATTERN) ?? [];
    for (const url of urls) {
      try {
        const hostname = new URL(url).hostname;
        if (!ALLOWED_DOMAINS.some((d) => hostname.endsWith(d))) {
          findings.push({
            check: "data_exfiltration",
            severity: "high",
            message: `URL found in prompt: ${url}`,
            location,
            suggestion: "Remove external URLs from prompts. They could be used for data exfiltration.",
          });
        }
      } catch {
        // Invalid URL, still flag it
        findings.push({
          check: "data_exfiltration",
          severity: "medium",
          message: `Malformed URL in prompt: ${url}`,
          location,
        });
      }
    }

    // Check for email addresses
    const emails = text.match(EMAIL_PATTERN) ?? [];
    for (const email of emails) {
      findings.push({
        check: "data_exfiltration",
        severity: "medium",
        message: `Email address found in prompt: ${email}`,
        location,
        suggestion: "Remove personal email addresses from templates",
      });
    }

    // Check for SSN patterns
    if (SSN_PATTERN.test(text)) {
      findings.push({
        check: "data_exfiltration",
        severity: "critical",
        message: "Potential SSN pattern found in prompt",
        location,
        suggestion: "Never include social security numbers in templates",
      });
    }

    // Check for credit card patterns
    if (CREDIT_CARD_PATTERN.test(text)) {
      findings.push({
        check: "data_exfiltration",
        severity: "critical",
        message: "Potential credit card number found in prompt",
        location,
        suggestion: "Never include credit card numbers in templates",
      });
    }

    // Check for phone number patterns (lower severity — could be examples)
    const phones = text.match(PHONE_PATTERN) ?? [];
    if (phones.length > 0) {
      findings.push({
        check: "data_exfiltration",
        severity: "low",
        message: `Phone number pattern found in prompt (${phones.length} occurrence(s))`,
        location,
        suggestion: "Verify these are example numbers, not real PII",
      });
    }

    // Check for instructions to send data externally
    if (/send\s+(to|data|results?|output)\s+(to\s+)?https?:/i.test(text)) {
      findings.push({
        check: "data_exfiltration",
        severity: "critical",
        message: "Prompt instructs sending data to external URL",
        location,
        suggestion: "Remove instructions to send data externally",
      });
    }

    if (/webhook|callback\s+url|post\s+to|fetch\s*\(/i.test(text)) {
      findings.push({
        check: "data_exfiltration",
        severity: "high",
        message: "Prompt references webhooks or HTTP callbacks",
        location,
        suggestion: "Prompts should not reference external API calls",
      });
    }
  }

  return findings;
}
