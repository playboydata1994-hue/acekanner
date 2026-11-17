// Google Play Developer API: subscription lookup and acknowledgement, and the
// rules that decide whether a purchase grants Premium.

import type { Fetch, GoogleTokenSource } from "./google_auth.ts";

const API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications";

/** Subset of purchases.subscriptionsv2 (SubscriptionPurchaseV2). */
export interface PlaySubscription {
  subscriptionState?: string;
  acknowledgementState?: string;
  linkedPurchaseToken?: string;
  latestOrderId?: string;
  testPurchase?: Record<string, unknown>;
  externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string };
  lineItems?: Array<{
    productId?: string;
    expiryTime?: string;
    latestSuccessfulOrderId?: string;
    autoRenewingPlan?: { autoRenewEnabled?: boolean };
  }>;
}

export class PlayApiError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

export interface PlayClient {
  getSubscription(purchaseToken: string): Promise<PlaySubscription>;
  acknowledge(productId: string, purchaseToken: string): Promise<void>;
}

export class GooglePlayClient implements PlayClient {
  constructor(
    private readonly packageName: string,
    private readonly tokens: GoogleTokenSource,
    private readonly fetchFn: Fetch = fetch,
  ) {}

  private async call(url: string, init: RequestInit = {}): Promise<Response> {
    const res = await this.fetchFn(url, {
      ...init,
      headers: { authorization: `Bearer ${await this.tokens.token()}`, "content-type": "application/json" },
    });
    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new PlayApiError(res.status, `Play API ${res.status}: ${text.slice(0, 200)}`);
    }
    return res;
  }

  async getSubscription(purchaseToken: string): Promise<PlaySubscription> {
    const url = `${API}/${encodeURIComponent(this.packageName)}/purchases/subscriptionsv2/tokens/${
      encodeURIComponent(purchaseToken)
    }`;
    return await (await this.call(url)).json();
  }

  async acknowledge(productId: string, purchaseToken: string): Promise<void> {
    const url = `${API}/${encodeURIComponent(this.packageName)}/purchases/subscriptions/${
      encodeURIComponent(productId)
    }/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`;
    await this.call(url, { method: "POST", body: "{}" });
  }
}

export const GRANTING_STATES = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  // Auto-renew turned off: access continues until the expiry time.
  "SUBSCRIPTION_STATE_CANCELED",
]);

export interface Evaluation {
  /** The product is not in this purchase. */
  wrongProduct: boolean;
  /** Bought from another ACEkanner account (obfuscatedAccountId differs). */
  otherAccount: boolean;
  /** Payment not completed yet (e.g. cash / convenience-store payment). */
  pending: boolean;
  /** Premium is granted now. */
  grants: boolean;
  /** Google expects an acknowledgement (else it refunds after 3 days). */
  needsAck: boolean;
  state: string;
  expiryTime: string | null;
  autoRenewing: boolean | null;
  acknowledged: boolean;
  test: boolean;
  orderId: string | null;
  linkedPurchaseToken: string | null;
  playAccountRef: string | null;
}

export function evaluate(
  sub: PlaySubscription,
  expected: { productId: string; playAccountRef: string | null; now: Date },
): Evaluation {
  const line = sub.lineItems?.find((l) => l.productId === expected.productId);
  const state = sub.subscriptionState ?? "SUBSCRIPTION_STATE_UNSPECIFIED";
  const expiry = line?.expiryTime ?? null;
  const ref = sub.externalAccountIdentifiers?.obfuscatedExternalAccountId ?? null;
  const otherAccount = ref !== null && expected.playAccountRef !== null && ref !== expected.playAccountRef;
  const notExpired = expiry !== null && Date.parse(expiry) > expected.now.getTime();
  const grants = !!line && !otherAccount && GRANTING_STATES.has(state) && notExpired;
  const acknowledged = sub.acknowledgementState === "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED";
  return {
    wrongProduct: !line,
    otherAccount,
    pending: state === "SUBSCRIPTION_STATE_PENDING",
    grants,
    needsAck: grants && !acknowledged,
    state,
    expiryTime: expiry,
    autoRenewing: line?.autoRenewingPlan?.autoRenewEnabled ?? null,
    acknowledged,
    test: sub.testPurchase !== undefined,
    orderId: line?.latestSuccessfulOrderId ?? sub.latestOrderId ?? null,
    linkedPurchaseToken: sub.linkedPurchaseToken ?? null,
    playAccountRef: ref,
  };
}
