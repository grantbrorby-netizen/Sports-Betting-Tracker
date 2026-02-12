/**
 * App Store Server Notifications V2 Webhook
 *
 * Apple sends POST requests here when subscription events occur.
 * We verify the payload, extract transaction info, and sync entitlements.
 *
 * Configure this URL in App Store Connect:
 * App Store Connect → App → App Information → App Store Server Notifications URL
 */

import { createAdminClient } from "$shared/supabase-client.ts";
import { errorResponse, successResponse } from "$shared/errors.ts";
import { decodeNotificationPayload } from "./receipt-verifier.ts";
import { syncEntitlements } from "./entitlement-sync.ts";

Deno.serve(async (req) => {
  // Apple sends POST with JSON body
  if (req.method !== "POST") {
    return errorResponse("METHOD_NOT_ALLOWED", "POST only", 405);
  }

  try {
    const body = await req.json();
    const { signedPayload } = body;

    if (!signedPayload) {
      return errorResponse("VALIDATION", "Missing signedPayload");
    }

    // Decode and verify the notification
    const notification = decodeNotificationPayload(signedPayload);

    console.log(
      `[Webhook] ${notification.notificationType}${notification.subtype ? `:${notification.subtype}` : ""} ` +
      `for product ${notification.transaction.productId} ` +
      `(tx: ${notification.transaction.transactionId})`
    );

    // Look up user by their original transaction ID
    const admin = createAdminClient();
    const userId = await resolveUserId(
      admin,
      notification.transaction.originalTransactionId,
      notification.transaction.transactionId,
    );

    if (!userId) {
      console.warn(
        `[Webhook] Could not resolve user for transaction: ${notification.transaction.originalTransactionId}`
      );
      // Still return 200 so Apple doesn't retry
      return successResponse({ status: "user_not_found" });
    }

    // Sync subscription state
    const result = await syncEntitlements(notification, userId);

    console.log(`[Webhook] Action: ${result.action} — ${result.details} (user: ${userId})`);

    return successResponse({
      status: "ok",
      action: result.action,
      details: result.details,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error(`[Webhook] Error: ${message}`);

    // Return 200 even on error to prevent Apple from retrying failed payloads
    // (we log the error for debugging)
    return successResponse({ status: "error", message });
  }
});

/**
 * Resolve user ID from transaction ID.
 * First check subscriptions table for matching storekit_transaction_id.
 * Fall back to original_transaction_id lookup.
 */
async function resolveUserId(
  admin: ReturnType<typeof createAdminClient>,
  originalTransactionId: string,
  transactionId: string,
): Promise<string | null> {
  // Try current transaction ID
  const { data: byTx } = await admin
    .from("subscriptions")
    .select("user_id")
    .eq("storekit_transaction_id", transactionId)
    .single();

  if (byTx?.user_id) return byTx.user_id;

  // Try original transaction ID
  const { data: byOriginal } = await admin
    .from("subscriptions")
    .select("user_id")
    .eq("storekit_transaction_id", originalTransactionId)
    .single();

  if (byOriginal?.user_id) return byOriginal.user_id;

  return null;
}
