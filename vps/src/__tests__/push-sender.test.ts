import { describe, it, expect } from "vitest";
import { truncateForPush, formatPushBody, buildPushPayload } from "../utils/push-utils.js";

describe("truncateForPush", () => {
  it("returns short text as-is", () => {
    expect(truncateForPush("Hello world")).toBe("Hello world");
  });

  it("truncates at sentence boundary", () => {
    const text = "First sentence. Second sentence. Third sentence that goes on and on and on and on and on to make it really long enough to exceed the limit that we have set for this particular test case here.";
    const result = truncateForPush(text, 80);
    expect(result.endsWith(".")).toBe(true);
    expect(result.length).toBeLessThanOrEqual(80);
  });

  it("truncates at word boundary with ellipsis", () => {
    const text = "A long run-on thought without periods that just keeps going and going and going until it exceeds the character limit we set for push notifications in our application";
    const result = truncateForPush(text, 80);
    expect(result.endsWith("...")).toBe(true);
    expect(result.length).toBeLessThanOrEqual(83); // 80 + "..."
  });

  it("respects custom max length", () => {
    const text = "A".repeat(500);
    const result = truncateForPush(text, 100);
    expect(result.length).toBeLessThanOrEqual(103);
  });
});

describe("formatPushBody", () => {
  it("strips markdown headers", () => {
    const result = formatPushBody("## Today's Plan\nDo something great");
    expect(result).not.toContain("##");
    expect(result).toContain("Today's Plan");
  });

  it("strips bold and italic", () => {
    const result = formatPushBody("**Important** and *italic* text");
    expect(result).toBe("Important and italic text");
  });

  it("converts markdown bullets to dots", () => {
    const result = formatPushBody("- Item one\n- Item two");
    expect(result).toContain("• Item one");
    expect(result).toContain("• Item two");
  });

  it("strips inline code", () => {
    const result = formatPushBody("Run `npm install` now");
    expect(result).toBe("Run npm install now");
  });

  it("truncates long output", () => {
    const longOutput = "## Plan\n" + "Do important task. ".repeat(50);
    const result = formatPushBody(longOutput, 200);
    expect(result.length).toBeLessThanOrEqual(203);
  });
});

describe("buildPushPayload", () => {
  it("creates correct APNs payload structure", () => {
    const payload = buildPushPayload(
      "Daily Plan",
      "Start with the report",
      { automationId: "uuid-1", runId: "uuid-2" }
    );

    expect(payload.aps.alert.title).toBe("Daily Plan");
    expect(payload.aps.alert.body).toBe("Start with the report");
    expect(payload.aps.sound).toBe("default");
    expect(payload.data?.automationId).toBe("uuid-1");
  });

  it("works without custom data", () => {
    const payload = buildPushPayload("Title", "Body");
    expect(payload.aps.alert.title).toBe("Title");
    expect(payload).not.toHaveProperty("data");
  });
});
