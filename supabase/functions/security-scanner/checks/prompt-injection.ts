import type { ScanFinding } from "../scan-result.ts";

/** Known prompt injection patterns to detect in system prompts */
const INJECTION_PATTERNS: Array<{ pattern: RegExp; description: string; severity: "critical" | "high" | "medium" }> = [
  {
    pattern: /ignore\s+(all\s+)?previous\s+(instructions|prompts|rules)/i,
    description: "Attempts to override system instructions",
    severity: "critical",
  },
  {
    pattern: /you\s+are\s+now\s+(DAN|unrestricted|jailbroken|unfiltered)/i,
    description: "Known jailbreak pattern (DAN/unrestricted mode)",
    severity: "critical",
  },
  {
    pattern: /pretend\s+(you('re|re|\s+are)\s+)?(a\s+)?(different|new|another)\s+(AI|assistant|model)/i,
    description: "Role-play escape attempt",
    severity: "high",
  },
  {
    pattern: /system\s*:\s*you\s+are/i,
    description: "Embedded system prompt injection",
    severity: "critical",
  },
  {
    pattern: /\[INST\]|\[\/INST\]|<\|im_start\|>|<\|im_end\|>/i,
    description: "Chat template injection tokens",
    severity: "critical",
  },
  {
    pattern: /reveal\s+(your|the)\s+(system\s+)?(prompt|instructions|rules)/i,
    description: "Prompt extraction attempt",
    severity: "high",
  },
  {
    pattern: /output\s+(your|the)\s+(system\s+)?(prompt|instructions)/i,
    description: "Prompt extraction via output request",
    severity: "high",
  },
  {
    pattern: /bypass\s+(safety|content|ethical)\s+(filters?|policies|guidelines)/i,
    description: "Safety bypass attempt",
    severity: "critical",
  },
  {
    pattern: /do\s+not\s+(follow|obey|comply\s+with)\s+(your|the|any)\s+(rules|guidelines|instructions)/i,
    description: "Instruction override attempt",
    severity: "high",
  },
  {
    pattern: /base64_decode|eval\s*\(|exec\s*\(|__import__|subprocess/i,
    description: "Code execution attempt in prompt",
    severity: "critical",
  },
];

/** Scan all text fields in a template for prompt injection patterns */
export function promptInjectionCheck(template: Record<string, unknown>): ScanFinding[] {
  const findings: ScanFinding[] = [];

  // Collect all text to scan
  const textsToScan: Array<{ text: string; location: string }> = [];

  if (typeof template.id === "string") {
    textsToScan.push({ text: template.id, location: "id" });
  }

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

  // Scan automation steps too
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

  // Check each text against patterns
  for (const { text, location } of textsToScan) {
    for (const { pattern, description, severity } of INJECTION_PATTERNS) {
      if (pattern.test(text)) {
        findings.push({
          check: "prompt_injection",
          severity,
          message: description,
          location,
          suggestion: "Remove or rephrase the flagged content",
        });
      }
    }
  }

  return findings;
}
