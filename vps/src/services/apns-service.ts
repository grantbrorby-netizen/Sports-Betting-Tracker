import apn from "apn";
import { config } from "../config.js";

let apnsProvider: apn.Provider | null = null;

/**
 * Initialize the APNs provider with token-based (JWT) authentication.
 * Must be called once at startup.
 */
export function initApns(): void {
  apnsProvider = new apn.Provider({
    token: {
      key: config.apnsKeyPath,
      keyId: config.apnsKeyId,
      teamId: config.apnsTeamId,
    },
    production: process.env.NODE_ENV === "production",
  });
}

/**
 * Shut down the APNs provider, closing HTTP/2 connections.
 */
export function shutdownApns(): void {
  if (apnsProvider) {
    apnsProvider.shutdown();
    apnsProvider = null;
  }
}

export interface PushData {
  [key: string]: unknown;
}

/**
 * Send a push notification via APNs.
 *
 * @param deviceToken - The user's APNs device token
 * @param title - Notification title
 * @param body - Notification body text
 * @param data - Optional custom data payload
 * @returns true if the notification was sent successfully, false otherwise
 */
export async function sendPush(
  deviceToken: string,
  title: string,
  body: string,
  data?: PushData
): Promise<boolean> {
  if (!apnsProvider) {
    console.error("[APNs] Provider not initialized. Call initApns() first.");
    return false;
  }

  const notification = new apn.Notification();

  notification.alert = {
    title,
    body,
  };

  notification.topic = config.apnsBundleId;
  notification.sound = "default";
  notification.badge = 1;
  notification.mutableContent = true;

  // Set a 24-hour expiry
  notification.expiry = Math.floor(Date.now() / 1000) + 86400;

  // Attach custom data payload if provided
  if (data) {
    notification.payload = data;
  }

  try {
    const result = await apnsProvider.send(notification, deviceToken);

    if (result.failed.length > 0) {
      const failure = result.failed[0];
      console.error(
        `[APNs] Failed to send push to ${deviceToken}:`,
        failure.response?.reason ?? "Unknown error",
        failure.status ?? ""
      );
      return false;
    }

    console.log(`[APNs] Push sent successfully to ${deviceToken.slice(0, 8)}...`);
    return true;
  } catch (err) {
    console.error("[APNs] Error sending push notification:", err);
    return false;
  }
}
