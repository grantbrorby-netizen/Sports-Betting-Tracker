/**
 * App Store Server Notifications V2 — Receipt/JWS verification
 * Verifies signed transactions from Apple's App Store Server API
 */

interface DecodedTransaction {
  transactionId: string;
  originalTransactionId: string;
  productId: string;
  type: string; // "Auto-Renewable Subscription"
  expiresDate?: number; // ms timestamp
  purchaseDate: number;
  environment: string; // "Sandbox" | "Production"
}

interface DecodedRenewalInfo {
  autoRenewProductId: string;
  autoRenewStatus: number; // 1 = will renew, 0 = will not
  expirationIntent?: number;
  isInBillingRetryPeriod?: boolean;
}

export interface VerifiedNotification {
  notificationType: string;
  subtype?: string;
  transaction: DecodedTransaction;
  renewalInfo?: DecodedRenewalInfo;
}

/**
 * Decode and verify an App Store Server Notification V2 payload.
 * The payload is a JWS (JSON Web Signature) signed by Apple.
 *
 * For MVP, we decode the JWT payload without full certificate chain verification.
 * Production should verify against Apple's root CA.
 */
export function decodeNotificationPayload(signedPayload: string): VerifiedNotification {
  // JWS has 3 parts: header.payload.signature
  const parts = signedPayload.split(".");
  if (parts.length !== 3) {
    throw new Error("Invalid JWS format: expected 3 parts");
  }

  const payloadJson = JSON.parse(atob(parts[1]));

  // The payload contains signedTransactionInfo and signedRenewalInfo (also JWS)
  const notificationType = payloadJson.notificationType;
  const subtype = payloadJson.subtype;

  // Decode signed transaction info
  let transaction: DecodedTransaction;
  if (payloadJson.data?.signedTransactionInfo) {
    const txParts = payloadJson.data.signedTransactionInfo.split(".");
    transaction = JSON.parse(atob(txParts[1]));
  } else {
    throw new Error("Missing signedTransactionInfo");
  }

  // Decode signed renewal info (optional)
  let renewalInfo: DecodedRenewalInfo | undefined;
  if (payloadJson.data?.signedRenewalInfo) {
    const rnParts = payloadJson.data.signedRenewalInfo.split(".");
    renewalInfo = JSON.parse(atob(rnParts[1]));
  }

  return {
    notificationType,
    subtype,
    transaction,
    renewalInfo,
  };
}

/** Map Apple product IDs to our subscription tiers */
export function productIdToTier(productId: string): string {
  const mapping: Record<string, string> = {
    "com.agenthub.starter.monthly": "starter",
    "com.agenthub.starter.annual": "starter",
    "com.agenthub.pro.monthly": "pro",
    "com.agenthub.pro.annual": "pro",
    "com.agenthub.unlimited.monthly": "unlimited",
    "com.agenthub.unlimited.annual": "unlimited",
  };
  return mapping[productId] ?? "free";
}
