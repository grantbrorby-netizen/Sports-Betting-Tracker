#!/usr/bin/env -S deno run --allow-read

/**
 * CLI: Scan an agent template for security issues
 * Usage: deno run --allow-read scripts/scan-template.ts <path-to-agent.json>
 */

import { schemaCheck } from "../supabase/functions/security-scanner/checks/schema-check.ts";
import { promptInjectionCheck } from "../supabase/functions/security-scanner/checks/prompt-injection.ts";
import { dataExfiltrationCheck } from "../supabase/functions/security-scanner/checks/data-exfiltration.ts";
import { contentPolicyCheck } from "../supabase/functions/security-scanner/checks/content-policy.ts";
import { urlValidatorCheck } from "../supabase/functions/security-scanner/checks/url-validator.ts";
import { calculateScore, didPass, type ScanFinding } from "../supabase/functions/security-scanner/scan-result.ts";

const CHECKS = [
  { name: "Schema Validation", fn: schemaCheck },
  { name: "Prompt Injection", fn: promptInjectionCheck },
  { name: "Data Exfiltration", fn: dataExfiltrationCheck },
  { name: "Content Policy", fn: contentPolicyCheck },
  { name: "URL Validator", fn: urlValidatorCheck },
];

const SEVERITY_COLORS: Record<string, string> = {
  critical: "\x1b[91m",  // bright red
  high: "\x1b[31m",      // red
  medium: "\x1b[33m",    // yellow
  low: "\x1b[36m",       // cyan
  info: "\x1b[90m",      // gray
};
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";
const RED = "\x1b[31m";
const BOLD = "\x1b[1m";

async function main() {
  const args = Deno.args;

  if (args.length === 0) {
    console.log("Usage: deno run --allow-read scripts/scan-template.ts <path-to-agent.json> [path2.json ...]");
    Deno.exit(1);
  }

  let allPassed = true;

  for (const filePath of args) {
    console.log(`\n${BOLD}Scanning: ${filePath}${RESET}`);
    console.log("─".repeat(60));

    let template: Record<string, unknown>;
    try {
      const content = await Deno.readTextFile(filePath);
      template = JSON.parse(content);
    } catch (err) {
      console.error(`${RED}Error reading file: ${err instanceof Error ? err.message : err}${RESET}`);
      allPassed = false;
      continue;
    }

    const allFindings: ScanFinding[] = [];
    const passedChecks: string[] = [];

    for (const { name, fn } of CHECKS) {
      const findings = fn(template);
      if (findings.length === 0) {
        console.log(`  ${GREEN}✓${RESET} ${name}`);
        passedChecks.push(name);
      } else {
        console.log(`  ${RED}✗${RESET} ${name} (${findings.length} issue${findings.length > 1 ? "s" : ""})`);
        for (const f of findings) {
          const color = SEVERITY_COLORS[f.severity] ?? "";
          console.log(`    ${color}[${f.severity.toUpperCase()}]${RESET} ${f.message}`);
          if (f.location) console.log(`      at: ${f.location}`);
          if (f.suggestion) console.log(`      fix: ${f.suggestion}`);
        }
        allFindings.push(...findings);
      }
    }

    const score = calculateScore(allFindings);
    const passed = didPass(allFindings);

    console.log("");
    console.log(`  Score: ${score}/100`);
    console.log(`  Status: ${passed ? `${GREEN}PASSED${RESET}` : `${RED}FAILED${RESET}`}`);
    console.log(`  Findings: ${allFindings.length} (${passedChecks.length}/${CHECKS.length} checks passed)`);

    if (!passed) allPassed = false;
  }

  console.log("");
  if (allPassed) {
    console.log(`${GREEN}${BOLD}All templates passed security scan.${RESET}`);
  } else {
    console.log(`${RED}${BOLD}Some templates failed security scan.${RESET}`);
    Deno.exit(1);
  }
}

main();
