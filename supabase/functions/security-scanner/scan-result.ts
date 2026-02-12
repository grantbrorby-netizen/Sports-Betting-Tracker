/** Type definitions for security scan results */

export type SeverityLevel = "critical" | "high" | "medium" | "low" | "info";

export interface ScanFinding {
  check: string;
  severity: SeverityLevel;
  message: string;
  location?: string;
  suggestion?: string;
}

export interface ScanResult {
  templateId: string;
  passedChecks: string[];
  findings: ScanFinding[];
  overallScore: number; // 0-100
  passed: boolean;
  scannedAt: string;
}

export function calculateScore(findings: ScanFinding[]): number {
  const deductions: Record<SeverityLevel, number> = {
    critical: 40,
    high: 25,
    medium: 10,
    low: 5,
    info: 0,
  };

  let score = 100;
  for (const finding of findings) {
    score -= deductions[finding.severity];
  }
  return Math.max(0, score);
}

export function didPass(findings: ScanFinding[]): boolean {
  return !findings.some(
    (f) => f.severity === "critical" || f.severity === "high"
  );
}
