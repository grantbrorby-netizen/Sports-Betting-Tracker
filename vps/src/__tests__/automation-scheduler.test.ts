import { describe, it, expect } from "vitest";
import { calculateNextRunAt } from "../utils/cron-utils.js";

describe("calculateNextRunAt", () => {
  it("returns an ISO date string", () => {
    const result = calculateNextRunAt("0 7 * * *", "UTC");
    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
  });

  it("calculates next run for daily at 7am", () => {
    const result = calculateNextRunAt("0 7 * * *", "UTC");
    const next = new Date(result);
    expect(next.getUTCHours()).toBe(7);
    expect(next.getUTCMinutes()).toBe(0);
    expect(next > new Date()).toBe(true);
  });

  it("respects timezone", () => {
    const utcResult = calculateNextRunAt("0 7 * * *", "UTC");
    const estResult = calculateNextRunAt("0 7 * * *", "America/New_York");
    // Same cron but different timezones should produce different UTC times
    expect(utcResult).not.toBe(estResult);
  });

  it("handles minutes correctly", () => {
    const result = calculateNextRunAt("30 21 * * *", "UTC");
    const next = new Date(result);
    expect(next.getUTCHours()).toBe(21);
    expect(next.getUTCMinutes()).toBe(30);
  });

  it("throws on invalid cron expression", () => {
    expect(() => calculateNextRunAt("invalid", "UTC")).toThrow();
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
