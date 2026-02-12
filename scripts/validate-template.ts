#!/usr/bin/env -S deno run --allow-read

/**
 * CLI: Validate agent template JSON against schema.
 * Usage: deno run --allow-read scripts/validate-template.ts agent-templates/templates/email-writer/agent.json
 */

const schemaPath = "agent-templates/schema/agent-template.schema.json";

async function loadJSON(path: string): Promise<unknown> {
  const text = await Deno.readTextFile(path);
  return JSON.parse(text);
}

interface ValidationError {
  path: string;
  message: string;
}

function validateTemplate(template: Record<string, unknown>, schema: Record<string, unknown>): ValidationError[] {
  const errors: ValidationError[] = [];

  // Required top-level fields
  const required = schema.required as string[] ?? [];
  for (const field of required) {
    if (!(field in template)) {
      errors.push({ path: field, message: `Missing required field: ${field}` });
    }
  }

  // Validate id format
  if (typeof template.id === "string") {
    if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(template.id)) {
      errors.push({ path: "id", message: "ID must be kebab-case" });
    }
  }

  // Validate version format
  if (typeof template.version === "string") {
    if (!/^\d+\.\d+\.\d+$/.test(template.version)) {
      errors.push({ path: "version", message: "Version must be semver (e.g., 1.0.0)" });
    }
  }

  // Validate metadata
  if (template.metadata && typeof template.metadata === "object") {
    const meta = template.metadata as Record<string, unknown>;
    const metaRequired = ["name", "description", "category", "iconName", "author"];
    for (const field of metaRequired) {
      if (!(field in meta)) {
        errors.push({ path: `metadata.${field}`, message: `Missing required field` });
      }
    }
    const validCategories = ["writing", "finance", "productivity", "health", "cooking", "legal"];
    if (meta.category && !validCategories.includes(meta.category as string)) {
      errors.push({ path: "metadata.category", message: `Invalid category. Must be one of: ${validCategories.join(", ")}` });
    }
  }

  // Validate inputs
  if (Array.isArray(template.inputs)) {
    if (template.inputs.length === 0) {
      errors.push({ path: "inputs", message: "Must have at least 1 input" });
    }
    if (template.inputs.length > 10) {
      errors.push({ path: "inputs", message: "Maximum 10 inputs" });
    }
    const validTypes = ["text", "textarea", "select", "number", "toggle", "photo"];
    for (let i = 0; i < template.inputs.length; i++) {
      const input = template.inputs[i] as Record<string, unknown>;
      if (!input.id) errors.push({ path: `inputs[${i}].id`, message: "Missing id" });
      if (!input.type) errors.push({ path: `inputs[${i}].type`, message: "Missing type" });
      if (input.type && !validTypes.includes(input.type as string)) {
        errors.push({ path: `inputs[${i}].type`, message: `Invalid type: ${input.type}` });
      }
      if (!input.label) errors.push({ path: `inputs[${i}].label`, message: "Missing label" });
    }
  }

  // Validate ai
  if (template.ai && typeof template.ai === "object") {
    const ai = template.ai as Record<string, unknown>;
    if (!ai.defaultModelTier) {
      errors.push({ path: "ai.defaultModelTier", message: "Missing defaultModelTier" });
    }
    if (!ai.systemPrompt) {
      errors.push({ path: "ai.systemPrompt", message: "Missing systemPrompt" });
    }
    if (typeof ai.systemPrompt === "string" && ai.systemPrompt.length < 10) {
      errors.push({ path: "ai.systemPrompt", message: "System prompt too short (min 10 chars)" });
    }
    const validTiers = ["fast", "smart", "deep", "max"];
    if (ai.defaultModelTier && !validTiers.includes(ai.defaultModelTier as string)) {
      errors.push({ path: "ai.defaultModelTier", message: `Invalid tier: ${ai.defaultModelTier}` });
    }
  }

  // Validate output
  if (template.output && typeof template.output === "object") {
    const output = template.output as Record<string, unknown>;
    const validFormats = ["text", "markdown", "structured"];
    if (output.format && !validFormats.includes(output.format as string)) {
      errors.push({ path: "output.format", message: `Invalid format: ${output.format}` });
    }
  }

  return errors;
}

// Main
async function main() {
  const args = Deno.args;
  if (args.length === 0) {
    console.log("Usage: deno run --allow-read scripts/validate-template.ts <path-to-agent.json>");
    console.log("       deno run --allow-read scripts/validate-template.ts --all");
    Deno.exit(1);
  }

  const schema = await loadJSON(schemaPath) as Record<string, unknown>;
  let allPassed = true;

  const files = args[0] === "--all"
    ? await getTemplateFiles()
    : args;

  for (const file of files) {
    try {
      const template = await loadJSON(file) as Record<string, unknown>;
      const errors = validateTemplate(template, schema);

      if (errors.length === 0) {
        console.log(`✓ ${file}`);
      } else {
        allPassed = false;
        console.log(`✗ ${file}`);
        for (const err of errors) {
          console.log(`  - ${err.path}: ${err.message}`);
        }
      }
    } catch (e) {
      allPassed = false;
      console.log(`✗ ${file}: ${e instanceof Error ? e.message : "Unknown error"}`);
    }
  }

  if (!allPassed) {
    Deno.exit(1);
  }
  console.log(`\nAll ${files.length} templates valid.`);
}

async function getTemplateFiles(): Promise<string[]> {
  const files: string[] = [];
  for await (const entry of Deno.readDir("agent-templates/templates")) {
    if (entry.isDirectory) {
      files.push(`agent-templates/templates/${entry.name}/agent.json`);
    }
  }
  return files.sort();
}

main();
