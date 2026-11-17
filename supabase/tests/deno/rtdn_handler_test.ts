import { assertEquals } from "jsr:@std/assert@1.0.13";
import { handleRtdn, type RtdnDeps } from "../../functions/play-rtdn/handler.ts";
import { EXPECTED, goodClaims, googleSigner, NOW } from "./oidc_test.ts";
import { FakePlay, MemoryStore, sub } from "./helpers.ts";

async function setup() {
  const g = await googleSigner();
  const store = new MemoryStore();
  const play = new FakePlay();
  await store.state("acc-maria", "install-phone-aaaa-0001", true);
  const deps: RtdnDeps = {
    store,
    play,
    jwks: g.jwks,
    config: { packageName: "com.acekanner.app", audience: EXPECTED.audience, serviceAccountEmail: EXPECTED.email },
    now: () => new Date(NOW),
    log: () => {},
  };
  const push = async (note: Record<string, unknown>, auth?: string | null) => {
    const res = await handleRtdn(
      new Request("https://x/functions/v1/play-rtdn", {
        method: "POST",
        headers: auth === null ? {} : { authorization: auth ?? await g.sign(goodClaims()) },
        body: JSON.stringify({
          message: { data: btoa(JSON.stringify({ packageName: "com.acekanner.app", ...note })) },
        }),
      }),
      deps,
    );
    return { status: res.status, body: await res.json() };
  };
  return { store, play, push, deps, g };
}

const subNote = (type: number) => ({
  subscriptionNotification: {
    version: "1.0",
    notificationType: type,
    purchaseToken: "tok-123456789",
    subscriptionId: "acekanner_premium_yearly",
  },
});

Deno.test("rejects notifications not signed by Google for our endpoint", async () => {
  const t = await setup();
  assertEquals((await t.push(subNote(4), null)).status, 401);
  assertEquals((await t.push(subNote(4), await t.g.sign({ ...goodClaims(), aud: "https://evil" }))).status, 401);
});

Deno.test("a purchase made in the app is linked by account ref and acknowledged", async () => {
  const t = await setup();
  t.play.subs.set("tok-123456789", sub({ ref: "ref-acc-maria", expiry: "2028-01-15T00:00:00Z" }));
  const r = await t.push(subNote(4)); // SUBSCRIPTION_PURCHASED
  assertEquals(r.body.ok, "subscription");
  assertEquals(t.play.acked, ["tok-123456789"]);
  assertEquals(t.store.accounts.get("acc-maria")!.premiumUntil, "2028-01-15T00:00:00Z");
});

Deno.test("expiry and refund remove Premium", async () => {
  const t = await setup();
  t.play.subs.set(
    "tok-123456789",
    sub({
      ref: "ref-acc-maria",
      expiry: "2028-01-15T00:00:00Z",
      acknowledgementState: "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
    }),
  );
  await t.push(subNote(2)); // RENEWED
  t.play.subs.get("tok-123456789")!.subscriptionState = "SUBSCRIPTION_STATE_EXPIRED";
  await t.push(subNote(13)); // EXPIRED
  assertEquals(t.store.accounts.get("acc-maria")!.premiumUntil, null);

  t.play.subs.get("tok-123456789")!.subscriptionState = "SUBSCRIPTION_STATE_ACTIVE";
  await t.push(subNote(2));
  const r = await t.push({
    voidedPurchaseNotification: { purchaseToken: "tok-123456789", orderId: "GPA.1", productType: 1 },
  });
  assertEquals(r.body, { ok: "voided", known: true });
  assertEquals(t.store.accounts.get("acc-maria")!.premiumUntil, null);
});

Deno.test("test, foreign-package, unknown and malformed notifications are acknowledged", async () => {
  const t = await setup();
  assertEquals((await t.push({ testNotification: { version: "1.0" } })).body.ok, "test");
  assertEquals((await t.push({ packageName: "other.app", ...subNote(4) })).body.ignored, "other_package");
  assertEquals((await t.push(subNote(4))).body.ignored, "unknown_token");
  t.play.subs.set("tok-123456789", sub({ ref: "ref-nobody" }));
  assertEquals((await t.push(subNote(4))).body.ignored, "unlinked");
});

Deno.test("Google API failure asks Pub/Sub to retry; missing configuration is reported", async () => {
  const t = await setup();
  t.play.fail = 503;
  assertEquals((await t.push(subNote(4))).status, 500);
  t.deps.config.audience = null;
  assertEquals((await t.push(subNote(4))).status, 503);
});
