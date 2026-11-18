import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { type AcekorDeps, handleAcekor } from "../../functions/acekor-license/handler.ts";
import { ACEKOR_TOKEN_TYPE, type AcekorState, type AcekorStore } from "../../functions/_shared/acekor.ts";
import { signerFromSeed, verifyToken } from "../../functions/_shared/jws.ts";
import { OwnedByOtherAccountError, type SubscriptionRecord } from "../../functions/_shared/store.ts";
import { FakePlay, sub, TEST_SEED } from "./helpers.ts";

const DEVICE = "install-phone-aaaa-0001";
const NOW = new Date("2027-12-01T00:00:00Z");
const PRO = "acekor_pro_yearly";
const MAX = "acekor_max_yearly";

/** In-memory version of the acekor_* SQL functions (same rules, simplified). */
class MemoryAcekorStore implements AcekorStore {
  accounts = new Map<
    string,
    { ref: string; trial: string | null; tier: "pro" | "max" | null; until: string | null; renew: boolean | null }
  >();
  subs = new Map<string, SubscriptionRecord & { revoked?: boolean }>();
  tombstones = new Map<string, string | null>();
  acekanner = new Set<string>();
  constructor(private now: () => Date) {}

  async state(account: string, _install: string, hash: string | null): Promise<AcekorState> {
    let a = this.accounts.get(account);
    if (!a) {
      const trial = hash ? this.tombstones.get(hash) ?? null : null;
      a = { ref: `ref-${account}`, trial, tier: null, until: null, renew: null };
      this.accounts.set(account, a);
    }
    const until = a.trial ? new Date(Date.parse(a.trial) + 7 * 86400e3).toISOString() : null;
    return {
      play_account_ref: a.ref,
      trial_started: a.trial,
      trial_until: until,
      paid_tier: a.tier,
      paid_until: a.until,
      auto_renew: a.renew,
    };
  }
  async startTrial(account: string) {
    const a = this.accounts.get(account)!;
    a.trial ??= this.now().toISOString();
  }
  async applySubscription(s: SubscriptionRecord) {
    const existing = this.subs.get(s.token);
    if (existing && existing.account !== s.account) {
      throw new OwnedByOtherAccountError("purchase_owned_by_other_account");
    }
    this.subs.set(s.token, { ...s, revoked: existing?.revoked });
    if (s.linkedToken) {
      const old = this.subs.get(s.linkedToken);
      if (old && old.account === s.account) old.revoked = true;
    }
    this.recompute(s.account);
  }
  private recompute(account: string) {
    const grants = ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD", "SUBSCRIPTION_STATE_CANCELED"];
    const now = this.now().getTime();
    const list = [...this.subs.values()].filter((s) => s.account === account && !s.revoked && s.expiry);
    list.sort((x, y) => {
      const ax = Number(Date.parse(x.expiry!) > now && grants.includes(x.state));
      const ay = Number(Date.parse(y.expiry!) > now && grants.includes(y.state));
      if (ax !== ay) return ay - ax;
      if ((x.product === MAX) !== (y.product === MAX)) return x.product === MAX ? -1 : 1;
      return Date.parse(y.expiry!) - Date.parse(x.expiry!);
    });
    const best = list[0];
    const a = this.accounts.get(account)!;
    a.tier = best ? (best.product === MAX ? "max" : "pro") : null;
    a.until = best?.expiry ?? null;
    a.renew = best?.autoRenewing ?? false;
  }
  async revokePurchase(token: string) {
    const s = this.subs.get(token);
    if (!s) return null;
    s.revoked = true;
    this.recompute(s.account);
    return s.account;
  }
  async findPurchaseAccount(token: string) {
    return this.subs.get(token)?.account ?? null;
  }
  async subscriptionsToRefresh(account: string) {
    return [...this.subs.values()].filter((s) => s.account === account && !s.revoked)
      .map((s) => ({ purchase_token: s.token, product_id: s.product }));
  }
  async deleteAccount(account: string, hash: string | null) {
    if (hash) this.tombstones.set(hash, this.accounts.get(account)?.trial ?? null);
    this.accounts.delete(account);
    return this.acekanner.has(account);
  }
}

async function setup() {
  let now = NOW;
  const store = new MemoryAcekorStore(() => now);
  const play = new FakePlay();
  const signer = await signerFromSeed(TEST_SEED, "k1", ACEKOR_TOKEN_TYPE);
  const deleted: string[] = [];
  const users: Record<string, { id: string; email: string; googleSub: string }> = {
    "jwt-maria": { id: "acc-maria", email: "maria@example.com", googleSub: "g-1" },
    "jwt-maria-again": { id: "acc-maria-2", email: "maria@example.com", googleSub: "g-1" },
    "jwt-juan": { id: "acc-juan", email: "juan@example.com", googleSub: "g-2" },
  };
  const deps: AcekorDeps = {
    getUser: async (jwt) => users[jwt] ?? null,
    deleteAuthUser: async (id) => void deleted.push(id),
    store,
    signer,
    play,
    now: () => now,
    log: () => {},
  };
  const call = async (body: Record<string, unknown>, jwt = "jwt-maria") => {
    const res = await handleAcekor(
      new Request("https://x/functions/v1/acekor-license", {
        method: "POST",
        headers: { authorization: `Bearer ${jwt}` },
        body: JSON.stringify({ deviceId: DEVICE, ...body }),
      }),
      deps,
    );
    return { status: res.status, body: await res.json() };
  };
  const claims = (t: string) => verifyToken(t, { k1: signer.publicKey }, ACEKOR_TOKEN_TYPE);
  return { store, play, call, claims, deleted, setNow: (d: Date) => (now = d) };
}

Deno.test("checkin without a plan, then a 7-day trial once per account", async () => {
  const t = await setup();
  const first = await t.call({ action: "checkin", appVersion: "1.0.0" });
  assertEquals(first.status, 200);
  const c0 = await t.claims(first.body.token);
  assertEquals([c0.app, c0.paid, c0.trial_started], ["acekor", "none", null]);

  const trial = await t.call({ action: "start-trial" });
  assertEquals(trial.body.trial.active, true);
  const c1 = await t.claims(trial.body.token);
  assertEquals((c1.trial_until as number) - (c1.trial_started as number), 7 * 86400);

  // A second start does not extend it.
  t.setNow(new Date("2027-12-20T00:00:00Z"));
  const again = await t.call({ action: "start-trial" });
  assertEquals(again.body.trial.active, false);
  assertEquals((await t.claims(again.body.token)).trial_started, c1.trial_started);
});

Deno.test("deleting the account does not give a second trial", async () => {
  const t = await setup();
  await t.call({ action: "start-trial" });
  const del = await t.call({ action: "delete-account", confirm: true });
  assertEquals(del.status, 200);
  assertEquals(t.deleted, ["acc-maria"]);
  // Same Google identity, new account.
  const back = await t.call({ action: "start-trial" }, "jwt-maria-again");
  const c = await t.claims(back.body.token);
  assert(c.trial_started !== null);
  assertEquals(back.body.trial.active, true); // same week: still the original trial window
  t.setNow(new Date("2027-12-30T00:00:00Z"));
  const later = await t.call({ action: "start-trial" }, "jwt-maria-again");
  assertEquals(later.body.trial.active, false);
});

Deno.test("delete keeps the sign-in when ACEkanner uses it", async () => {
  const t = await setup();
  await t.call({ action: "checkin" }, "jwt-juan");
  t.store.acekanner.add("acc-juan");
  await t.call({ action: "delete-account", confirm: true }, "jwt-juan");
  assertEquals(t.deleted, []);
});

Deno.test("PRO purchase verified, acknowledged, then upgrade to MAX replaces it", async () => {
  const t = await setup();
  await t.call({ action: "checkin" });
  t.play.subs.set("tok-pro-123456", sub({ product: PRO, ref: "ref-acc-maria", expiry: "2028-12-01T00:00:00Z" }));
  const pro = await t.call({ action: "verify-purchase", purchaseToken: "tok-pro-123456", productId: PRO });
  assertEquals(pro.status, 200);
  assertEquals(pro.body.purchase.granted, true);
  assertEquals(t.play.acked, ["tok-pro-123456"]);
  const cp = await t.claims(pro.body.token);
  assertEquals([cp.paid, cp.auto_renew], ["pro", true]);

  const up = sub({ product: MAX, ref: "ref-acc-maria", expiry: "2028-12-01T00:00:00Z" });
  up.linkedPurchaseToken = "tok-pro-123456";
  t.play.subs.set("tok-max-123456", up);
  const max = await t.call({ action: "verify-purchase", purchaseToken: "tok-max-123456", productId: MAX });
  assertEquals((await t.claims(max.body.token)).paid, "max");
  assert(t.store.subs.get("tok-pro-123456")!.revoked);
});

Deno.test("cancelled subscription keeps access until expiry; refund removes it; other account refused", async () => {
  const t = await setup();
  await t.call({ action: "checkin" });
  const s = sub({
    product: MAX,
    ref: "ref-acc-maria",
    expiry: "2027-12-31T00:00:00Z",
    subscriptionState: "SUBSCRIPTION_STATE_CANCELED",
  });
  s.lineItems![0].autoRenewingPlan = { autoRenewEnabled: false };
  t.play.subs.set("tok-max-abcdef", s);
  const r = await t.call({ action: "verify-purchase", purchaseToken: "tok-max-abcdef", productId: MAX });
  const c = await t.claims(r.body.token);
  assertEquals([c.paid, c.auto_renew, c.paid_until], ["max", false, Date.parse("2027-12-31T00:00:00Z") / 1000]);

  // Juan cannot claim Maria's purchase.
  const juan = await t.call({ action: "verify-purchase", purchaseToken: "tok-max-abcdef", productId: MAX }, "jwt-juan");
  assertEquals([juan.status, juan.body.error], [409, "other_account"]);

  await t.store.revokePurchase("tok-max-abcdef");
  const after = await t.claims((await t.call({ action: "checkin" })).body.token);
  assertEquals(after.paid, "none");
});

Deno.test("bad requests", async () => {
  const t = await setup();
  assertEquals(
    (await t.call({
      action: "verify-purchase",
      purchaseToken: "tok-1234567890",
      productId: "acekanner_premium_yearly",
    })).body.error,
    "wrong_product",
  );
  assertEquals((await t.call({ action: "nope" })).status, 400);
  assertEquals((await t.call({ action: "checkin" }, "jwt-nobody")).status, 401);
  assertEquals((await t.call({ action: "checkin", deviceId: "x" })).status, 400);
  t.play.subs.clear();
  assertEquals(
    (await t.call({ action: "verify-purchase", purchaseToken: "tok-missing-1234", productId: PRO })).body.error,
    "invalid_purchase",
  );
});
