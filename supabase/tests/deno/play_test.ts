import { assert, assertEquals } from "jsr:@std/assert@1.0.13";
import { evaluate } from "../../functions/_shared/play.ts";
import { sub } from "./helpers.ts";

const now = new Date("2026-11-17T00:00:00Z");
const expected = { productId: "acekanner_premium_yearly", playAccountRef: "ref-a", now };

Deno.test("active, unacknowledged purchase grants Premium and needs acknowledgement", () => {
  const e = evaluate(sub({ ref: "ref-a" }), expected);
  assert(e.grants && e.needsAck && !e.otherAccount && !e.wrongProduct);
  assertEquals(e.orderId, "GPA.1234");
});

Deno.test("states: grace and cancelled grant until expiry; hold, pending, expired do not", () => {
  const states: Array<[string, boolean]> = [
    ["SUBSCRIPTION_STATE_IN_GRACE_PERIOD", true],
    ["SUBSCRIPTION_STATE_CANCELED", true],
    ["SUBSCRIPTION_STATE_ON_HOLD", false],
    ["SUBSCRIPTION_STATE_PAUSED", false],
    ["SUBSCRIPTION_STATE_PENDING", false],
    ["SUBSCRIPTION_STATE_EXPIRED", false],
  ];
  for (const [s, grants] of states) assertEquals(evaluate(sub({ subscriptionState: s }), expected).grants, grants, s);
  assert(evaluate(sub({ subscriptionState: "SUBSCRIPTION_STATE_PENDING" }), expected).pending);
  assertEquals(evaluate(sub({ expiry: "2026-11-16T00:00:00Z" }), expected).grants, false, "past expiry");
});

Deno.test("another account's purchase or another product never grants", () => {
  const other = evaluate(sub({ ref: "ref-b" }), expected);
  assert(other.otherAccount && !other.grants && !other.needsAck);
  const product = evaluate(sub({ product: "something_else" }), expected);
  assert(product.wrongProduct && !product.grants);
  // No obfuscated account ID (bought outside the app): allowed, first claim wins.
  assert(evaluate(sub({}), expected).grants);
});
