// The TypeScript store must call the SQL functions with their exact parameter names.
import { assertEquals } from "jsr:@std/assert@1.0.13";
import { SupabaseLicenseStore } from "../../functions/_shared/store.ts";

const sql = await Deno.readTextFile(new URL("../../migrations/20261117000000_licensing.sql", import.meta.url));

function sqlParams(fn: string): string[] {
  const m = new RegExp(`create function public\\.${fn}\\(([^)]*)\\)`, "s").exec(sql);
  if (!m) throw new Error(`no SQL function ${fn}`);
  return m[1].split(",").map((p) => p.trim().split(/\s+/)[0]).filter(Boolean);
}

Deno.test("store RPC calls match the SQL function signatures", async () => {
  const calls: Array<[string, string[]]> = [];
  const store = new SupabaseLicenseStore({
    rpc: (fn, args) => {
      calls.push([fn, Object.keys(args)]);
      return Promise.resolve({ data: fn === "license_subscriptions_to_refresh" ? [] : {}, error: null });
    },
  });
  await store.state("a", "i", true, null, null);
  await store.recordCharges("a", "i", []);
  await store.applySubscription({
    account: "a",
    token: "t",
    product: "p",
    state: "s",
    expiry: null,
    autoRenewing: null,
    acknowledged: false,
    test: false,
    linkedToken: null,
    orderId: null,
  });
  await store.revokePurchase("t");
  await store.findPurchaseAccount("t", null);
  await store.subscriptionsToRefresh("a");
  await store.deleteAccount("a", null);
  for (const [fn, keys] of calls) assertEquals(keys.sort(), sqlParams(fn).sort(), fn);
  assertEquals(calls.length, 7);
});

Deno.test("ACEKOR store RPC calls match the SQL function signatures", async () => {
  const { SupabaseAcekorStore } = await import("../../functions/_shared/acekor.ts");
  const acekorSql = await Deno.readTextFile(
    new URL("../../migrations/20261119000000_acekor_licensing.sql", import.meta.url),
  );
  const params = (fn: string) => {
    const m = new RegExp(`create function public\\.${fn}\\(([^)]*)\\)`, "s").exec(acekorSql);
    if (!m) throw new Error(`no SQL function ${fn}`);
    return m[1].split(",").map((p) => p.trim().split(/\s+/)[0]).filter(Boolean);
  };
  const calls: Array<[string, string[]]> = [];
  const store = new SupabaseAcekorStore({
    rpc: (fn, args) => {
      calls.push([fn, Object.keys(args)]);
      return Promise.resolve({ data: fn === "acekor_subscriptions_to_refresh" ? [] : {}, error: null });
    },
  });
  await store.state("a", "i", null, null);
  await store.startTrial("a");
  await store.applySubscription({
    account: "a",
    token: "t",
    product: "p",
    state: "s",
    expiry: null,
    autoRenewing: null,
    acknowledged: false,
    test: false,
    linkedToken: null,
    orderId: null,
  });
  await store.revokePurchase("t");
  await store.findPurchaseAccount("t");
  await store.subscriptionsToRefresh("a");
  await store.deleteAccount("a", null);
  for (const [fn, keys] of calls) assertEquals(keys.sort(), params(fn).sort(), fn);
  assertEquals(calls.length, 7);
});
