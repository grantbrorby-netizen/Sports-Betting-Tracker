import type { ScanFinding } from "../scan-result.ts";

/** Validate template structure against strict schema requirements */
export function schemaCheck(template: Record<string, unknown>): ScanFinding[] {
  const findings: ScanFinding[] = [];

  // Required top-level fields
  const requiredFields = ["id", "version", "metadata", "inputs", "output", "ai"];
  for (const field of requiredFields) {
    if (!(field in template)) {
      findings.push({
        check: "schema",
        severity: "critical",
        message: `Missing required field: ${field}`,
        suggestion: `Add the '${field}' field to the template`,
      });
    }
  }

  // ID format
  if (typeof template.id === "string") {
    if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(template.id)) {
      findings.push({
        check: "schema",
        severity: "high",
        message: `Invalid id format: '${template.id}'. Must be kebab-case.`,
        suggestion: "Use only lowercase letters, numbers, and hyphens",
      });
    }
    if (template.id.length > 60) {
      findings.push({
        check: "schema",
        severity: "medium",
        message: "Template id is too long (max 60 characters)",
      });
    }
  }

  // Version format
  if (typeof template.version === "string") {
    if (!/^\d+\.\d+\.\d+$/.test(template.version)) {
      findings.push({
        check: "schema",
        severity: "high",
        message: `Invalid version format: '${template.version}'. Must be semver (e.g., 1.0.0).`,
      });
    }
  }

  // Metadata validation
  if (template.metadata && typeof template.metadata === "object") {
    const meta = template.metadata as Record<string, unknown>;
    const validCategories = ["writing", "finance", "productivity", "health", "cooking", "legal"];
    if (meta.category && !validCategories.includes(meta.category as string)) {
      findings.push({
        check: "schema",
        severity: "high",
        message: `Invalid category: '${meta.category}'`,
        suggestion: `Use one of: ${validCategories.join(", ")}`,
      });
    }
  }

  // Inputs validation
  if (Array.isArray(template.inputs)) {
    if (template.inputs.length > 10) {
      findings.push({
        check: "schema",
        severity: "medium",
        message: `Too many inputs: ${template.inputs.length} (max 10)`,
      });
    }

    const validTypes = ["text", "textarea", "select", "number", "toggle", "photo"];
    for (let i = 0; i < template.inputs.length; i++) {
      const input = template.inputs[i] as Record<string, unknown>;
      if (input.type && !validTypes.includes(input.type as string)) {
        findings.push({
          check: "schema",
          severity: "high",
          message: `Invalid input type '${input.type}' at index ${i}`,
          location: `inputs[${i}]`,
        });
      }
    }
  }

  // AI config validation
  if (template.ai && typeof template.ai === "object") {
    const ai = template.ai as Record<string, unknown>;
    const validTiers = ["fast", "smart", "deep", "max"];
    if (ai.defaultModelTier && !validTiers.includes(ai.defaultModelTier as string)) {
      findings.push({
        check: "schema",
        severity: "high",
        message: `Invalid model tier: '${ai.defaultModelTier}'`,
      });
    }

    if (typeof ai.temperature === "number" && (ai.temperature < 0 || ai.temperature > 1.5)) {
      findings.push({
        check: "schema",
        severity: "medium",
        message: `Temperature ${ai.temperature} out of range (0-1.5)`,
      });
    }

    if (typeof ai.maxTokens === "number" && (ai.maxTokens < 100 || ai.maxTokens > 4096)) {
      findings.push({
        check: "schema",
        severity: "medium",
        message: `maxTokens ${ai.maxTokens} out of range (100-4096)`,
      });
    }
  }

  return findings;
}
