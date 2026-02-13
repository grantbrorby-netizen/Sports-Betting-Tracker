import cronParser from "cron-parser";

/**
 * Calculate the next run time from a cron expression and timezone.
 * Returns an ISO string for the next occurrence.
 */
export function calculateNextRunAt(
  cronExpression: string,
  timezone: string
): string {
  try {
    const interval = cronParser.parseExpression(cronExpression, {
      currentDate: new Date(),
      tz: timezone,
    });
    const nextDate = interval.next().toDate();
    return nextDate.toISOString();
  } catch (err) {
    console.error(
      `[CronUtils] Failed to parse cron expression "${cronExpression}" with tz "${timezone}":`,
      err
    );
    throw err;
  }
}
