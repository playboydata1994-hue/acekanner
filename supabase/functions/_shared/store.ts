// Database access for the licensing functions: one method per SQL function
// in migrations/20261117000000_licensing.sql (parameter names must match).

import type { AccountState } from "./entitlement.ts";

export interface SubscriptionRecord {
  account: string;
  token: string;
  product: string;
  state: string;
  expiry: string | null;
  autoRenewing: boolean | null;
  acknowledged: boolean;
  test: boolean;
  linkedToken: string | null;
  orderId: string | null;
}

export interface Charge {
  k: string;
  t: "free" | "premium";
  at: string;
}

export class OwnedByOtherAccountError extends Error {}

export interface LicenseStore {
  state(
    account: string,
    install: string,
    claim: boolean,
    identityHash: string | null,
    appVersion: string | null,
  ): Promise<AccountState>;
  recordCharges(account: string, install: string, charges: Charge[]): Promise<number>;
  applySubscription(s: SubscriptionRecord): Promise<{ premium_until: string | null }>;
  revokePurchase(token: string): Promise<string | null>;
  findPurchaseAccount(token: string, playAccountRef: string | null): Promise<string | null>;
  subscriptionsToRefresh(account: string): Promise<Array<{ purchase_token: string; product_id: string }>>;
  deleteAccount(account: string, identityHash: string | null): Promise<void>;
}

/** Minimal shape of supabase-js used here (keeps this file dependency-free). */
export interface RpcClient {
  rpc(
    fn: string,
    args: Record<string, unknown>,
  ): PromiseLike<{ data: unknown; error: { code?: string; message: string } | null }>;
}

export class SupabaseLicenseStore implements LicenseStore {
  constructor(private readonly db: RpcClient) {}

  private async call<T>(fn: string, args: Record<string, unknown>): Promise<T> {
    const { data, error } = await this.db.rpc(fn, args);
    if (error) {
      if (error.message?.includes("purchase_owned_by_other_account")) throw new OwnedByOtherAccountError(error.message);
      throw new Error(`${fn}: ${error.message}`);
    }
    return data as T;
  }

  state(account: string, install: string, claim: boolean, identityHash: string | null, appVersion: string | null) {
    return this.call<AccountState>("license_state", {
      p_account: account,
      p_install: install,
      p_claim: claim,
      p_identity_hash: identityHash,
      p_app_version: appVersion,
    });
  }

  recordCharges(account: string, install: string, charges: Charge[]) {
    return this.call<number>("license_record_charges", { p_account: account, p_install: install, p_charges: charges });
  }

  applySubscription(s: SubscriptionRecord) {
    return this.call<{ premium_until: string | null }>("license_apply_subscription", {
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
    return this.call<string | null>("license_revoke_purchase", { p_token: token });
  }

  findPurchaseAccount(token: string, playAccountRef: string | null) {
    return this.call<string | null>("license_find_purchase_account", {
      p_token: token,
      p_play_account_ref: playAccountRef,
    });
  }

  async subscriptionsToRefresh(account: string) {
    return (await this.call<Array<{ purchase_token: string; product_id: string }> | null>(
      "license_subscriptions_to_refresh",
      { p_account: account },
    )) ?? [];
  }

  async deleteAccount(account: string, identityHash: string | null) {
    await this.call<null>("license_delete_account", { p_account: account, p_identity_hash: identityHash });
  }
}
