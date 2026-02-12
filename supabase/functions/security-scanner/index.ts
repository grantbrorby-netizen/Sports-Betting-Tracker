import { handleCors } from "$shared/cors.ts";
import { getUserFromRequest } from "$shared/auth.ts";
import { createAdminClient } from "$shared/supabase-client.ts";
import {
  errorResponse,
  unauthorizedResponse,
  forbiddenResponse,
  successResponse,
} from "$shared/errors.ts";

import { schemaCheck } from "./checks/schema-check.ts";
import { promptInjectionCheck } from "./checks/prompt-injection.ts";
import { dataExfiltrationCheck } from "./checks/data-exfiltration.ts";
import { contentPolicyCheck } from "./checks/content-policy.ts";
import { urlValidatorCheck } from "./checks/url-validator.ts";
import { calculateScore, didPass, type ScanFinding, type ScanResult } from "./scan-result.ts";

const ALL_CHECKS = [
  { name: "schema", fn: schemaCheck },
  { name: "prompt_injection", fn: promptInjectionCheck },
  { name: "data_exfiltration", fn: dataExfiltrationCheck },
  { name: "content_policy", fn: contentPolicyCheck },
  { name: "url_validator", fn: urlValidatorCheck },
];

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const user = getUserFromRequest(req);
  if (!user) return unauthorizedResponse();

  // Only service role or admin can run scans
  if (user.role !== "service_role") {
    return forbiddenResponse("Security scanning requires service role access");
  }

  if (req.method !== "POST") {
    return errorResponse("METHOD_NOT_ALLOWED", "POST only", 405);
  }

  try {
    const body = await req.json();
    const { template, template_id } = body;

    let templateToScan: Record<string, unknown>;

    if (template) {
      // Scan a template object directly
      templateToScan = template;
    } else if (template_id) {
      // Fetch template from DB
      const admin = createAdminClient();
      const { data, error } = await admin
        .from("agent_templates")
        .select("*")
        .eq("template_id", template_id)
        .single();

      if (error || !data) {
        return errorResponse("NOT_FOUND", `Template not found: ${template_id}`, 404);
      }
      templateToScan = data as Record<string, unknown>;
    } else {
      return errorResponse("VALIDATION", "Provide either 'template' or 'template_id'");
    }

    // Run all checks
    const allFindings: ScanFinding[] = [];
    const passedChecks: string[] = [];

    for (const { name, fn } of ALL_CHECKS) {
      const findings = fn(templateToScan);
      if (findings.length === 0) {
        passedChecks.push(name);
      } else {
        allFindings.push(...findings);
      }
    }

    const score = calculateScore(allFindings);
    const passed = didPass(allFindings);

    const result: ScanResult = {
      templateId: (templateToScan.id as string) ?? (templateToScan.template_id as string) ?? "unknown",
      passedChecks,
      findings: allFindings,
      overallScore: score,
      passed,
      scannedAt: new Date().toISOString(),
    };

    // Store result if template_id was provided
    if (template_id) {
      const admin = createAdminClient();
      await admin.from("security_scan_results").insert({
        template_id,
        score,
        passed,
        findings: allFindings,
        passed_checks: passedChecks,
      });
    }

    return successResponse({ scan: result });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return errorResponse("INTERNAL", message, 500);
  }
});
