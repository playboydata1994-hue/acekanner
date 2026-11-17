import { assertEquals } from "jsr:@std/assert@1.0.13";
import { buildClaims } from "../../functions/_shared/entitlement.ts";

const now = new Date("2026-11-17T00:00:00Z");
const base = { free_limit: 100, free_used: 37, lease: 63, lease_holder: true, play_account_ref: "r" };

Deno.test("free plan: lease, 30-day offline window", () => {
  const c = buildClaims({ accountId: "acc", installId: "dev", state: { ...base, premium_until: null }, now, jti: "j" });
  assertEquals(c.plan, "free");
  assertEquals(c.lease, 63);
  assertEquals(c.premium_until, null);
  assertEquals(c.offline_until - c.verified_at, 30 * 86400);
});

Deno.test("premium only while the subscription has not expired", () => {
  const active = buildClaims({
    accountId: "a",
    installId: "d",
    state: { ...base, premium_until: "2027-11-17T00:00:00Z" },
    now,
    jti: "j",
  });
  assertEquals(active.plan, "premium");
  assertEquals(active.premium_until, Date.parse("2027-11-17T00:00:00Z") / 1000);
  const expired = buildClaims({
    accountId: "a",
    installId: "d",
    state: { ...base, premium_until: "2026-11-16T00:00:00Z" },
    now,
    jti: "j",
  });
  assertEquals(expired.plan, "free");
  assertEquals(expired.premium_until, null);
});
