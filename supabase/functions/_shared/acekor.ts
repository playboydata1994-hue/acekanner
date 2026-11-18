// ACEKOR Calculator: account state, entitlement claims and database access.
// Mirrors migrations/20261119000000_acekor_licensing.sql.

import type { SubscriptionRecord } from "./store.ts";
import { OwnedByOtherAccountError, type RpcClient } from "./store.ts";

export const ACEKOR_TOKEN_TYPE = "ACEKOR-ENT+JWS";
export const ACEKOR_OFFLINE_DAYS = 30;
export const ACEKOR_PRODUCTS = { pro: "acekor_pro_yearly", max: "acekor_max_yearly" } as const;

/** What acekor_state() returns. */
export interface AcekorState {
  play_account_ref: string;
  trial_started: string | null;
  trial_until: string | null;
  paid_tier: "pro" | "max" | null;
  paid_until: string | null;
  auto_renew: boolean | null;
}

export interface AcekorClaims {
  v: 1;
  app: "acekor";
  sub: string;
  dev: string;
  paid: "none" | "pro" | "max";
  paid_until: number | null;
  auto_renew: boolean;
  trial_started: number | null;
  trial_until: number | null;
  verified_at: number;
  offline_until: number;
  iat: number;
  jti: string;
}

const secs = (iso: string | null): number | null => {
  if (iso === null) return null;
  const t = Date.parse(iso);
  return Number.isFinite(t) ? Math.floor(t / 1000) : null;
};

/** Claims of the token the app verifies. The paid tier is sent even after it
 * ended (with its date), so the app can say "PRO ended on …"; the app itself
 * decides what is active from the dates. */
export function buildAcekorClaims(args: {
  accountId: string;
  installId: string;
  state: AcekorState;
  now: Date;
  jti: string;
}): AcekorClaims {
  const now = Math.floor(args.now.getTime() / 1000);
  const s = args.state;
  const paidUntil = secs(s.paid_until);
  return {
    v: 1,
    app: "acekor",
    sub: args.accountId,
    dev: args.installId,
    paid: s.paid_tier && paidUntil !== null ? s.paid_tier : "none",
    paid_until: s.paid_tier ? paidUntil : null,
    auto_renew: s.auto_renew === true && paidUntil !== null && paidUntil > now,
    trial_started: secs(s.trial_started),
    trial_until: secs(s.trial_until),
    verified_at: now,
    offline_until: now + ACEKOR_OFFLINE_DAYS * 86400,
    iat: now,
    jti: args.jti,
  };
}

export interface AcekorStore {
  state(account: string, install: string, identityHash: string | null, appVersion: string | null): Promise<AcekorState>;
  startTrial(account: string): Promise<void>;
  applySubscription(s: SubscriptionRecord): Promise<void>;
  revokePurchase(token: string): Promise<string | null>;
  findPurchaseAccount(token: string): Promise<string | null>;
  subscriptionsToRefresh(account: string): Promise<Array<{ purchase_token: string; product_id: string }>>;
  /** Returns true when ACEkanner still uses the same sign-in. */
  deleteAccount(account: string, identityHash: string | null): Promise<boolean>;
}

export class SupabaseAcekorStore implements AcekorStore {
  constructor(private readonly db: RpcClient) {}

  private async call<T>(fn: string, args: Record<string, unknown>): Promise<T> {
    const { data, error } = await this.db.rpc(fn, args);
    if (error) {
      if (error.message?.includes("purchase_owned_by_other_account")) throw new OwnedByOtherAccountError(error.message);
      throw new Error(`${fn}: ${error.message}`);
    }
    return data as T;
  }

  state(account: string, install: string, identityHash: string | null, appVersion: string | null) {
    return this.call<AcekorState>("acekor_state", {
      p_account: account,
      p_install: install,
      p_identity_hash: identityHash,
      p_app_version: appVersion,
    });
  }

  async startTrial(account: string) {
    await this.call<null>("acekor_start_trial", { p_account: account });
  }

  async applySubscription(s: SubscriptionRecord) {
    await this.call<null>("acekor_apply_subscription", {
      p_account: s.account,
      p_token: s.token,
      p_product: s.product,
      p_state: s.state,
      p_expiry: s.expiry,
      p_auto_renewing: s.autoRenewing,
      p_acknowledged: s.acknowledged,
      p_test: s.test,
      p_linked_token: s.linkedToken,
      p_order_id: s.orderId,
    });
  }

  revokePurchase(token: string) {
    return this.call<string | null>("acekor_revoke_purchase", { p_token: token });
  }

  findPurchaseAccount(token: string) {
    return this.call<string | null>("acekor_find_purchase_account", { p_token: token });
  }

  async subscriptionsToRefresh(account: string) {
    return (await this.call<Array<{ purchase_token: string; product_id: string }> | null>(
      "acekor_subscriptions_to_refresh",
      { p_account: account },
    )) ?? [];
  }

  async deleteAccount(account: string, identityHash: string | null) {
    return (await this.call<boolean | null>("acekor_delete_account", {
      p_account: account,
      p_identity_hash: identityHash,
    })) === true;
  }
}
