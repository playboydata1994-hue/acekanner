import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { handleLicense, type LicenseDeps } from "../../functions/license/handler.ts";
import { signerFromSeed, verifyToken } from "../../functions/_shared/jws.ts";
import { FakePlay, MemoryStore, sub, TEST_SEED } from "./helpers.ts";

const DEVICE = "install-phone-aaaa-0001";
const DEVICE2 = "install-phone-bbbb-0002";
const NOW = new Date("2026-11-17T00:00:00Z");

async function setup(opts: { play?: boolean } = {}) {
  const store = new MemoryStore();
  const play = new FakePlay();
  const signer = await signerFromSeed(TEST_SEED, "k1");
  const users: Record<string, { id: string; email: string; googleSub: string }> = {
    "jwt-maria": { id: "acc-maria", email: "maria@example.com", googleSub: "g-1" },
    "jwt-juan": { id: "acc-juan", email: "juan@example.com", googleSub: "g-2" },
  };
  const deletedUsers: string[] = [];
  const deps: LicenseDeps = {
    getUser: async (jwt) => users[jwt] ?? null,
    deleteAuthUser: async (id) => void deletedUsers.push(id),
    store,
    signer,
    play: opts.play === false ? null : play,
    config: { productId: "acekanner_premium_yearly" },
    now: () => NOW,
    log: () => {},
  };
  const call = async (body: unknown, jwt: string | null = "jwt-maria") => {
    const res = await handleLicense(
      new Request("https://x/functions/v1/license", {
        method: "POST",
        headers: jwt ? { authorization: `Bearer ${jwt}` } : {},
        body: JSON.stringify(body),
      }),
      deps,
    );
    return { status: res.status, body: await res.json() };
  };
  const claims = async (token: string) => await verifyToken(token, { k1: signer.publicKey });
  return { store, play, deps, call, claims, deletedUsers };
}

const charge = (hex: string, t = "free") => ({ k: hex.repeat(64 / hex.length), t, at: "2026-11-16T08:00:00Z" });

Deno.test("check-in needs a signed-in user and a valid device ID", async () => {
  const t = await setup();
  assertEquals((await t.call({ action: "checkin", deviceId: DEVICE }, null)).status, 401);
  assertEquals((await t.call({ action: "checkin", deviceId: DEVICE }, "jwt-unknown")).status, 401);
  assertEquals((await t.call({ action: "checkin", deviceId: "x" })).status, 400);
  assertEquals((await t.call({ action: "nope", deviceId: DEVICE })).status, 400);
});

Deno.test("check-in returns a signed token; uploaded scans reduce the lease once", async () => {
  const t = await setup();
  const first = await t.call({ action: "checkin", deviceId: DEVICE, claim: true });
  assertEquals(first.status, 200);
  const c1 = await t.claims(first.body.token);
  assertEquals([c1.sub, c1.dev, c1.plan, c1.lease, c1.free_used], ["acc-maria", DEVICE, "free", 100, 0]);

  const second = await t.call({
    action: "checkin",
    deviceId: DEVICE,
    charges: [charge("a"), charge("b"), charge("a")],
  });
  assertEquals(second.body.newlyCounted, 2);
  const c2 = await t.claims(second.body.token);
  assertEquals([c2.lease, c2.free_used], [98, 2]);

  // Re-uploading the same scans (lost response) does not charge again.
  const again = await t.call({ action: "checkin", deviceId: DEVICE, charges: [charge("a"), charge("b")] });
  assertEquals((await t.claims(again.body.token)).free_used, 2);
});

Deno.test("invalid scan records are refused", async () => {
  const t = await setup();
  for (
    const charges of [[{ k: "short", t: "free", at: "2026-11-16T00:00:00Z" }], [{ ...charge("a"), t: "gold" }], [{
      ...charge("a"),
      at: "yesterday",
    }], "x"]
  ) {
    assertEquals((await t.call({ action: "checkin", deviceId: DEVICE, charges })).status, 400);
  }
  const tooMany = Array.from({ length: 501 }, (_, i) => charge(i.toString(16).padStart(2, "0")));
  assertEquals((await t.call({ action: "checkin", deviceId: DEVICE, charges: tooMany })).status, 400);
});

Deno.test("a second phone gets the lease only when it signs in (claim)", async () => {
  const t = await setup();
  await t.call({ action: "checkin", deviceId: DEVICE, claim: true });
  const other = await t.claims((await t.call({ action: "checkin", deviceId: DEVICE2 })).body.token);
  assertEquals(other.lease, 0);
  const claimed = await t.claims((await t.call({ action: "checkin", deviceId: DEVICE2, claim: true })).body.token);
  assertEquals(claimed.lease, 100);
  assertEquals((await t.claims((await t.call({ action: "checkin", deviceId: DEVICE })).body.token)).lease, 0);
});

Deno.test("purchase: verified with Google, acknowledged, Premium granted", async () => {
  const t = await setup();
  await t.call({ action: "checkin", deviceId: DEVICE, claim: true });
  t.play.subs.set("tok-123456789", sub({ ref: "ref-acc-maria" }));
  const r = await t.call({
    action: "verify-purchase",
    deviceId: DEVICE,
    purchaseToken: "tok-123456789",
    productId: "acekanner_premium_yearly",
  });
  assertEquals(r.status, 200);
  assertEquals(r.body.purchase.granted, true);
  assertEquals(t.play.acked, ["tok-123456789"]);
  const c = await t.claims(r.body.token);
  assertEquals(c.plan, "premium");
  assertEquals(c.premium_until, Date.parse("2027-11-17T00:00:00Z") / 1000);
});

Deno.test("purchase: pending payment grants nothing and is not acknowledged", async () => {
  const t = await setup();
  t.play.subs.set("tok-pending-1", sub({ subscriptionState: "SUBSCRIPTION_STATE_PENDING" }));
  const r = await t.call({
    action: "verify-purchase",
    deviceId: DEVICE,
    purchaseToken: "tok-pending-1",
    productId: "acekanner_premium_yearly",
  });
  assertEquals(r.status, 200);
  assertEquals([r.body.purchase.pending, r.body.purchase.granted], [true, false]);
  assertEquals(t.play.acked, []);
  assertEquals((await t.claims(r.body.token)).plan, "free");
});

Deno.test("purchase: another account's purchase is refused (no replay)", async () => {
  const t = await setup();
  t.play.subs.set("tok-123456789", sub({ ref: "ref-acc-maria" }));
  await t.call({
    action: "verify-purchase",
    deviceId: DEVICE,
    purchaseToken: "tok-123456789",
    productId: "acekanner_premium_yearly",
  });
  // Juan replays Maria's token.
  const r = await t.call({
    action: "verify-purchase",
    deviceId: DEVICE2,
    purchaseToken: "tok-123456789",
    productId: "acekanner_premium_yearly",
  }, "jwt-juan");
  assertEquals([r.status, r.body.error], [409, "other_account"]);
  // A purchase made with Maria's account ref, first submitted by Juan.
  t.play.subs.set("tok-fresh-0001", sub({ ref: "ref-acc-maria" }));
  const r2 = await t.call({
    action: "verify-purchase",
    deviceId: DEVICE2,
    purchaseToken: "tok-fresh-0001",
    productId: "acekanner_premium_yearly",
  }, "jwt-juan");
  assertEquals([r2.status, r2.body.error], [409, "other_account"]);
  assertEquals(t.store.accounts.get("acc-juan")?.premiumUntil ?? null, null);
});

Deno.test("purchase: unknown token, wrong product, billing not configured", async () => {
  const t = await setup();
  const unknown = await t.call({
    action: "verify-purchase",
    deviceId: DEVICE,
    purchaseToken: "tok-unknown-1",
    productId: "acekanner_premium_yearly",
  });
  assertEquals([unknown.status, unknown.body.error], [400, "invalid_purchase"]);
  const wrong = await t.call({
    action: "verify-purchase",
    deviceId: DEVICE,
    purchaseToken: "tok-unknown-1",
    productId: "other",
  });
  assertEquals(wrong.status, 400);
  const none = await setup({ play: false });
  const r = await none.call({
    action: "verify-purchase",
    deviceId: DEVICE,
    purchaseToken: "tok-unknown-1",
    productId: "acekanner_premium_yearly",
  });
  assertEquals([r.status, r.body.error], [503, "billing_not_configured"]);
});

Deno.test("Google outage during verification is a retryable server error", async () => {
  const t = await setup();
  t.play.fail = 503;
  const r = await t.call({
    action: "verify-purchase",
    deviceId: DEVICE,
    purchaseToken: "tok-123456789",
    productId: "acekanner_premium_yearly",
  });
  assertEquals(r.status, 500);
});

Deno.test("check-in re-checks subscriptions with Google (renewal and cancellation)", async () => {
  const t = await setup();
  t.play.subs.set("tok-123456789", sub({ ref: "ref-acc-maria", expiry: "2026-11-20T00:00:00Z" }));
  await t.call({
    action: "verify-purchase",
    deviceId: DEVICE,
    purchaseToken: "tok-123456789",
    productId: "acekanner_premium_yearly",
  });
  // Renewed: Google now reports a later expiry.
  t.play.subs.get("tok-123456789")!.lineItems![0].expiryTime = "2027-11-20T00:00:00Z";
  const c = await t.claims((await t.call({ action: "checkin", deviceId: DEVICE })).body.token);
  assertEquals(c.premium_until, Date.parse("2027-11-20T00:00:00Z") / 1000);
  // Expired.
  t.play.subs.get("tok-123456789")!.subscriptionState = "SUBSCRIPTION_STATE_EXPIRED";
  assertEquals((await t.claims((await t.call({ action: "checkin", deviceId: DEVICE })).body.token)).plan, "free");
});

Deno.test("delete account removes server records and the sign-in", async () => {
  const t = await setup();
  await t.call({ action: "checkin", deviceId: DEVICE, claim: true });
  assertEquals((await t.call({ action: "delete-account" })).status, 400, "needs confirm");
  const r = await t.call({ action: "delete-account", confirm: true });
  assertEquals(r.body.deleted, true);
  assertEquals(t.store.deleted, ["acc-maria"]);
  assertEquals(t.deletedUsers, ["acc-maria"]);
});

Deno.test("only POST", async () => {
  const t = await setup();
  const res = await (await import("../../functions/license/handler.ts")).handleLicense(
    new Request("https://x", { method: "GET" }),
    t.deps,
  );
  assertEquals(res.status, 405);
  assert(true);
});
