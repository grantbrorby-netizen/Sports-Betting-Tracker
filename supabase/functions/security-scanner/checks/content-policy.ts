import type { ScanFinding } from "../scan-result.ts";

/** Content policy patterns — flag harmful or inappropriate content in templates */
const HARMFUL_PATTERNS: Array<{ pattern: RegExp; category: string; severity: "critical" | "high" | "medium" }> = [
  // Violence
  {
    pattern: /\b(make|create|build|design)\s+(a\s+)?(bomb|weapon|explosive|poison|drug)/i,
    category: "violence",
    severity: "critical",
  },
  {
    pattern: /how\s+to\s+(harm|kill|attack|hurt|injure|murder)/i,
    category: "violence",
    severity: "critical",
  },

  // Illegal activities
  {
    pattern: /\b(hack|crack|exploit|breach)\s+(into|a|an|the)\s+(system|server|account|database|network)/i,
    category: "illegal",
    severity: "critical",
  },
  {
    pattern: /\b(forge|counterfeit|falsify)\s+(documents?|IDs?|passports?|currency|money)/i,
    category: "illegal",
    severity: "critical",
  },

  // Scam/Fraud
  {
    pattern: /\b(phishing|scam|fraud|impersonat)/i,
    category: "fraud",
    severity: "high",
  },
  {
    pattern: /\bpretend\s+to\s+be\s+(a\s+)?(bank|government|police|IRS|FBI|official)/i,
    category: "fraud",
    severity: "critical",
  },

  // Self-harm (handle sensitively)
  {
    pattern: /\b(encourage|promote|instructions?\s+for)\s+(self[- ]harm|suicide)/i,
    category: "self_harm",
    severity: "critical",
  },

  // Harassment
  {
    pattern: /\b(harass|bully|stalk|intimidate|threaten)\s+(someone|people|a\s+person|them)/i,
    category: "harassment",
    severity: "high",
  },

  // Adult content
  {
    pattern: /\b(generate|create|write)\s+(explicit|sexual|pornographic|nsfw)\s+(content|material|stories|images)/i,
    category: "adult",
    severity: "high",
  },
];

/** Scan template content for content policy violations */
export function contentPolicyCheck(template: Record<string, unknown>): ScanFinding[] {
  const findings: ScanFinding[] = [];

  const textsToScan: Array<{ text: string; location: string }> = [];

  if (template.metadata && typeof template.metadata === "object") {
    const meta = template.metadata as Record<string, unknown>;
    if (typeof meta.name === "string") textsToScan.push({ text: meta.name, location: "metadata.name" });
    if (typeof meta.description === "string") textsToScan.push({ text: meta.description, location: "metadata.description" });
  }

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
    for (const { pattern, category, severity } of HARMFUL_PATTERNS) {
      if (pattern.test(text)) {
        findings.push({
          check: "content_policy",
          severity,
          message: `Content policy violation (${category}): matches harmful content pattern`,
          location,
          suggestion: "Remove or rephrase content that violates platform policies",
        });
      }
    }
  }

  return findings;
}
