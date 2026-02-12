/**
 * Sync App Store subscription state to Supabase.
 * Called after verifying an App Store Server Notification.
 */

import { createAdminClient } from "$shared/supabase-client.ts";
import type { VerifiedNotification } from "./receipt-verifier.ts";
import { productIdToTier } from "./receipt-verifier.ts";

/**
 * Handle a verified notification and update the user's subscription.
 * Returns the action taken for logging.
 */
export async function syncEntitlements(
  notification: VerifiedNotification,
  userId: string,
): Promise<{ action: string; details: string }> {
  const admin = createAdminClient();
  const { notificationType, subtype, transaction, renewalInfo } = notification;

  const tier = productIdToTier(transaction.productId);
  const expiresAt = transaction.expiresDate
    ? new Date(transaction.expiresDate).toISOString()
    : null;

  switch (notificationType) {
    case "SUBSCRIBED":
    case "DID_RENEW": {
      // New subscription or renewal — activate
      const { error } = await admin
        .from("subscriptions")
        .update({
          tier,
          storekit_product_id: transaction.productId,
          storekit_transaction_id: transaction.transactionId,
          status: "active",
          trial_active: subtype === "INITIAL_BUY" && notificationType === "SUBSCRIBED",
          current_period_start: new Date(transaction.purchaseDate).toISOString(),
          current_period_end: expiresAt,
        })
        .eq("user_id", userId);

      if (error) throw new Error(`Failed to update subscription: ${error.message}`);

      return {
        action: "activated",
        details: `Tier: ${tier}, expires: ${expiresAt}`,
      };
    }

    case "DID_CHANGE_RENEWAL_STATUS": {
      if (renewalInfo?.autoRenewStatus === 0) {
        // User turned off auto-renew — will expire at end of period
        await admin
          .from("subscriptions")
          .update({ status: "cancel_pending" })
          .eq("user_id", userId);

        return {
          action: "cancel_pending",
          details: `Will expire: ${expiresAt}`,
        };
      }

      // Re-enabled auto-renew
      await admin
        .from("subscriptions")
        .update({ status: "active" })
        .eq("user_id", userId);

      return {
        action: "reactivated",
        details: "Auto-renew re-enabled",
      };
    }

    case "EXPIRED": {
      // Subscription expired — downgrade to free
      await admin
        .from("subscriptions")
        .update({
          tier: "free",
          status: "expired",
          trial_active: false,
          storekit_product_id: null,
          storekit_transaction_id: null,
          current_period_end: expiresAt,
        })
        .eq("user_id", userId);

      return {
        action: "expired",
        details: `Downgraded to free from ${tier}`,
      };
    }

    case "DID_FAIL_TO_RENEW": {
      if (subtype === "GRACE_PERIOD") {
        // Billing retry — keep access during grace period
        await admin
          .from("subscriptions")
          .update({ status: "billing_retry" })
          .eq("user_id", userId);

        return {
          action: "billing_retry",
          details: "In grace period, retrying payment",
        };
      }

      // Failed beyond grace — downgrade
      await admin
        .from("subscriptions")
        .update({
          tier: "free",
          status: "expired",
          trial_active: false,
        })
        .eq("user_id", userId);

      return {
        action: "billing_failed",
        details: "Downgraded to free after payment failure",
      };
    }

    case "REFUND": {
      // User got a refund — revoke immediately
      await admin
        .from("subscriptions")
        .update({
          tier: "free",
          status: "revoked",
          trial_active: false,
          storekit_product_id: null,
          storekit_transaction_id: null,
        })
        .eq("user_id", userId);

      return {
        action: "revoked",
        details: `Refund processed for ${tier}`,
      };
    }

    case "DID_CHANGE_RENEWAL_INFO": {
      // Upgrade/downgrade at next renewal
      if (renewalInfo?.autoRenewProductId) {
        const newTier = productIdToTier(renewalInfo.autoRenewProductId);
        return {
          action: "pending_change",
          details: `Will change to ${newTier} at next renewal`,
        };
      }
      return { action: "renewal_info_changed", details: "Renewal info updated" };
    }

    default:
      return {
        action: "unhandled",
        details: `Notification type: ${notificationType}, subtype: ${subtype}`,
      };
  }
}
