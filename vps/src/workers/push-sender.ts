import { getUserDeviceToken, updateAutomationRun } from "../services/supabase-service.js";
import { sendPush } from "../services/apns-service.js";

const PUSH_BODY_MAX_LENGTH = 200;

/**
 * Truncate a string to the given max length, appending ellipsis if truncated.
 */
function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) {
    return text;
  }
  return text.slice(0, maxLength - 3) + "...";
}

/**
 * Send a push notification for a completed automation run.
 *
 * @param userId - The user to send the notification to
 * @param automationName - Name of the automation (for logging)
 * @param pushTitle - Title for the push notification
 * @param output - The automation's final output (will be truncated for the push body)
 * @param runId - The automation_run ID (included in push data and used to update push_sent)
 */
export async function sendAutomationPush(
  userId: string,
  automationName: string,
  pushTitle: string,
  output: string,
  runId: string
): Promise<void> {
  console.log(
    `[PushSender] Sending push for automation "${automationName}" to user ${userId}`
  );

  // 1. Get the user's device token
  const deviceToken = await getUserDeviceToken(userId);

  if (!deviceToken) {
    console.warn(
      `[PushSender] No device token found for user ${userId}. Skipping push.`
    );
    return;
  }

  // 2. Truncate the output for the push body
  const pushBody = truncate(output, PUSH_BODY_MAX_LENGTH);

  // 3. Send the push notification
  const success = await sendPush(deviceToken, pushTitle, pushBody, {
    run_id: runId,
    automation_name: automationName,
    type: "automation_result",
  });

  if (success) {
    console.log(
      `[PushSender] Push sent successfully for automation "${automationName}"`
    );

    // 4. Update the automation_run record to mark push as sent
    try {
      await updateAutomationRun(runId, {
        push_sent: true,
      });
    } catch (err) {
      console.error(
        `[PushSender] Failed to update push_sent for run ${runId}:`,
        err
      );
    }
  } else {
    console.error(
      `[PushSender] Failed to send push for automation "${automationName}" to user ${userId}`
    );
  }
}
