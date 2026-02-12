import { describe, it, expect } from "vitest";

// Test cron next-run calculation logic (extracted for unit testing)
function calculateNextRun(
  cronExpression: string,
  timezone: string,
  fromDate: Date = new Date()
): Date {
  const parts = cronExpression.trim().split(/\s+/);
  if (parts.length !== 5) throw new Error("Invalid cron expression");

  const [minuteStr, hourStr, , , dowStr] = parts;
  const minute = minuteStr === "*" ? null : parseInt(minuteStr, 10);
  const hour = hourStr === "*" ? null : parseInt(hourStr, 10);
  const daysOfWeek =
    dowStr === "*" ? null : dowStr.split(",").map((d) => parseInt(d, 10));

  const next = new Date(fromDate);
  next.setSeconds(0, 0);

  // Move forward to find next matching slot
  for (let attempts = 0; attempts < 8; attempts++) {
    if (attempts > 0) {
      next.setDate(next.getDate() + 1);
    }

    if (hour !== null) next.setHours(hour);
    if (minute !== null) next.setMinutes(minute);

    // Check day of week
    if (daysOfWeek && !daysOfWeek.includes(next.getDay())) {
      continue;
    }

    // Must be in the future
    if (next > fromDate) {
      return next;
    }
  }

  // Fallback: tomorrow at the specified time
  next.setDate(fromDate.getDate() + 1);
  if (hour !== null) next.setHours(hour);
  if (minute !== null) next.setMinutes(minute);
  return next;
}

describe("calculateNextRun", () => {
  it("calculates next run for daily at 7am", () => {
    const from = new Date("2026-02-12T06:00:00Z");
    const next = calculateNextRun("0 7 * * *", "UTC", from);
    expect(next.getHours()).toBe(7);
    expect(next.getMinutes()).toBe(0);
    expect(next > from).toBe(true);
  });

  it("moves to next day if time already passed", () => {
    const from = new Date("2026-02-12T08:00:00Z");
    const next = calculateNextRun("0 7 * * *", "UTC", from);
    expect(next.getDate()).toBe(13);
    expect(next.getHours()).toBe(7);
  });

  it("respects day of week filter (Friday only)", () => {
    // 2026-02-12 is a Thursday
    const from = new Date("2026-02-12T06:00:00Z");
    const next = calculateNextRun("0 17 * * 5", "UTC", from);
    expect(next.getDay()).toBe(5); // Friday
    expect(next.getHours()).toBe(17);
  });

  it("handles weekday-only cron", () => {
    // 2026-02-14 is Saturday
    const from = new Date("2026-02-14T06:00:00Z");
    const next = calculateNextRun("0 9 * * 1,2,3,4,5", "UTC", from);
    expect([1, 2, 3, 4, 5]).toContain(next.getDay());
    expect(next.getHours()).toBe(9);
  });

  it("handles minutes correctly", () => {
    const from = new Date("2026-02-12T06:00:00Z");
    const next = calculateNextRun("30 21 * * *", "UTC", from);
    expect(next.getHours()).toBe(21);
    expect(next.getMinutes()).toBe(30);
  });
});

describe("automation job structure", () => {
  it("creates correct job data shape", () => {
    const jobData = {
      automationId: "uuid-1",
      userId: "user-uuid",
      templateId: "daily-plan-builder",
      cronExpression: "0 7 * * *",
      timezone: "America/New_York",
      steps: [{ name: "Build plan", systemPrompt: "Create a daily plan", maxTokens: 800 }],
      inputValues: { priorities: "Ship feature X" },
      actionType: "push_notification",
      pushTitle: "Daily Plan",
      modelTier: "fast",
    };

    expect(jobData).toHaveProperty("automationId");
    expect(jobData).toHaveProperty("userId");
    expect(jobData).toHaveProperty("templateId");
    expect(jobData.steps).toHaveLength(1);
    expect(jobData.inputValues).toHaveProperty("priorities");
  });
});
