import type { ScanFinding } from "../scan-result.ts";

/** Validate and flag any URLs found in template prompts */

const URL_PATTERN = /https?:\/\/[^\s"'<>)}\]]+/gi;

/** Domains that are safe in prompts (used as examples) */
const SAFE_DOMAINS = new Set([
  "example.com",
  "example.org",
  "example.net",
  "placeholder.com",
  "test.com",
]);

/** Suspicious TLDs often used in phishing */
const SUSPICIOUS_TLDS = new Set([
  ".xyz", ".tk", ".ml", ".ga", ".cf", ".gq",
  ".top", ".click", ".work", ".date", ".bid",
]);

export function urlValidatorCheck(template: Record<string, unknown>): ScanFinding[] {
  const findings: ScanFinding[] = [];

  const textsToScan: Array<{ text: string; location: string }> = [];

  if (template.ai && typeof template.ai === "object") {
    const ai = template.ai as Record<string, unknown>;
    if (typeof ai.systemPrompt === "string") {
      textsToScan.push({ text: ai.systemPrompt, location: "ai.systemPrompt" });
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
    const urls = text.match(URL_PATTERN) ?? [];

    for (const url of urls) {
      try {
        const parsed = new URL(url);
        const hostname = parsed.hostname.toLowerCase();

        // Safe domains are OK
        if (SAFE_DOMAINS.has(hostname)) continue;

        // Check for IP addresses (suspicious in prompts)
        if (/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(hostname)) {
          findings.push({
            check: "url_validator",
            severity: "high",
            message: `IP address URL found: ${url}`,
            location,
            suggestion: "Use domain names instead of IP addresses in prompts",
          });
          continue;
        }

        // Check suspicious TLDs
        for (const tld of SUSPICIOUS_TLDS) {
          if (hostname.endsWith(tld)) {
            findings.push({
              check: "url_validator",
              severity: "high",
              message: `Suspicious TLD in URL: ${url}`,
              location,
              suggestion: `The TLD '${tld}' is commonly used in phishing`,
            });
            break;
          }
        }

        // Any non-safe URL gets a medium flag
        findings.push({
          check: "url_validator",
          severity: "medium",
          message: `External URL in prompt: ${url}`,
          location,
          suggestion: "Prompts generally should not contain external URLs",
        });
      } catch {
        findings.push({
          check: "url_validator",
          severity: "low",
          message: `Malformed URL: ${url}`,
          location,
        });
      }
    }
  }

  return findings;
}
