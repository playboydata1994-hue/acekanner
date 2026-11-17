import type { AccountState } from "../../functions/_shared/entitlement.ts";
import type { PlayClient, PlaySubscription } from "../../functions/_shared/play.ts";
import { PlayApiError } from "../../functions/_shared/play.ts";
import {
  type Charge,
  type LicenseStore,
  OwnedByOtherAccountError,
  type SubscriptionRecord,
} from "../../functions/_shared/store.ts";

/** In-memory store with the same rules as the SQL functions (simplified). */
export class MemoryStore implements LicenseStore {
  accounts = new Map<string, { lease: string | null; premiumUntil: string | null; ref: string }>();
  charges = new Map<string, Charge & { account: string }>();
  subs = new Map<string, SubscriptionRecord & { revoked?: boolean }>();
  deleted: string[] = [];
  calls: string[] = [];

  async state(account: string, install: string, claim: boolean): Promise<AccountState> {
    this.calls.push(`state:${claim}`);
    let a = this.accounts.get(account);
    if (!a) {
      a = { lease: null, premiumUntil: null, ref: `ref-${account}` };
      this.accounts.set(account, a);
    }
    if (claim || a.lease === null) a.lease = install;
    const used = [...this.charges.values()].filter((c) => c.account === account && c.t === "free").length;
    return {
      free_limit: 100,
      free_used: used,
      lease: a.lease === install ? Math.max(100 - used, 0) : 0,
      lease_holder: a.lease === install,
      premium_until: a.premiumUntil,
      play_account_ref: a.ref,
    };
  }
  async recordCharges(account: string, _install: string, charges: Charge[]) {
    let n = 0;
    for (const c of charges) {
      const key = `${account}:${c.k}`;
      if (!this.charges.has(key)) {
        this.charges.set(key, {
          ...c,
          account,
          t: c.t === "premium" && this.accounts.get(account)?.premiumUntil ? "premium" : "free",
        });
        n++;
      }
    }
    return n;
  }
  async applySubscription(s: SubscriptionRecord) {
    const existing = this.subs.get(s.token);
    if (existing && existing.account !== s.account) {
      throw new OwnedByOtherAccountError("purchase_owned_by_other_account");
    }
    this.subs.set(s.token, { ...s });
    return { premium_until: this.recompute(s.account) };
  }
  private recompute(account: string): string | null {
    const grants = ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD", "SUBSCRIPTION_STATE_CANCELED"];
    const until = [...this.subs.values()]
      .filter((s) => s.account === account && !s.revoked && grants.includes(s.state) && s.expiry)
      .map((s) => s.expiry!)
      .sort()
      .pop() ?? null;
    this.accounts.get(account)!.premiumUntil = until;
    return until;
  }
  async revokePurchase(token: string) {
    const s = this.subs.get(token);
    if (!s) return null;
    s.revoked = true;
    this.recompute(s.account);
    return s.account;
  }
  async findPurchaseAccount(token: string, ref: string | null) {
    const s = this.subs.get(token);
    if (s) return s.account;
    for (const [id, a] of this.accounts) if (ref && a.ref === ref) return id;
    return null;
  }
  async subscriptionsToRefresh(account: string) {
    return [...this.subs.values()].filter((s) => s.account === account && !s.revoked)
      .map((s) => ({ purchase_token: s.token, product_id: s.product }));
  }
  async deleteAccount(account: string) {
    this.deleted.push(account);
    this.accounts.delete(account);
  }
}

export class FakePlay implements PlayClient {
  subs = new Map<string, PlaySubscription>();
  acked: string[] = [];
  fail: number | null = null;
  async getSubscription(token: string) {
    if (this.fail) throw new PlayApiError(this.fail, "fail");
    const s = this.subs.get(token);
    if (!s) throw new PlayApiError(404, "not found");
    return structuredClone(s);
  }
  async acknowledge(_product: string, token: string) {
    this.acked.push(token);
    const s = this.subs.get(token);
    if (s) s.acknowledgementState = "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED";
  }
}

export function sub(
  over: Partial<PlaySubscription> & { expiry?: string; product?: string; ref?: string } = {},
): PlaySubscription {
  return {
    subscriptionState: over.subscriptionState ?? "SUBSCRIPTION_STATE_ACTIVE",
    acknowledgementState: over.acknowledgementState ?? "ACKNOWLEDGEMENT_STATE_PENDING",
    externalAccountIdentifiers: over.ref === undefined ? undefined : { obfuscatedExternalAccountId: over.ref },
    testPurchase: {},
    lineItems: [{
      productId: over.product ?? "acekanner_premium_yearly",
      expiryTime: over.expiry ?? "2027-11-17T00:00:00Z",
      autoRenewingPlan: { autoRenewEnabled: true },
      latestSuccessfulOrderId: "GPA.1234",
    }],
  };
}

/** 32-byte test seed (never used in production). */
export const TEST_SEED = btoa(String.fromCharCode(...Array.from({ length: 32 }, (_, i) => i + 1)));
