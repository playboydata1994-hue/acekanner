import { assert, assertEquals, assertRejects } from "jsr:@std/assert@1.0.13";
import { signerFromSeed, verifyToken } from "../../functions/_shared/jws.ts";
import { base64UrlDecode, base64UrlEncode } from "../../functions/_shared/encoding.ts";
import { TEST_SEED } from "./helpers.ts";

Deno.test("Ed25519 tokens verify, and any edit breaks them", async () => {
  const s = await signerFromSeed(TEST_SEED, "k1");
  assertEquals(atob(s.publicKey).length, 32);
  const token = await s.sign({ sub: "a", plan: "free", lease: 63 });
  const claims = await verifyToken(token, { k1: s.publicKey });
  assertEquals(claims.lease, 63);

  // Edited payload (lease 63 -> 99) with the original signature.
  const [h, p, sig] = token.split(".");
  const edited = JSON.parse(new TextDecoder().decode(base64UrlDecode(p)));
  edited.lease = 99;
  const forged = `${h}.${base64UrlEncode(new TextEncoder().encode(JSON.stringify(edited)))}.${sig}`;
  await assertRejects(() => verifyToken(forged, { k1: s.publicKey }), Error, "bad signature");

  // Signed by another key, or unknown key id.
  const other = await signerFromSeed(btoa(String.fromCharCode(...new Uint8Array(32).fill(9))), "k1");
  const otherToken = await other.sign({ lease: 100 });
  await assertRejects(() => verifyToken(otherToken, { k1: s.publicKey }), Error, "bad signature");
  await assertRejects(() => verifyToken(token, { k2: s.publicKey }), Error, "unknown key id");
  await assertRejects(() => verifyToken("a.b", { k1: s.publicKey }), Error, "malformed");
});

Deno.test("signing is deterministic (Ed25519) and the seed must be 32 bytes", async () => {
  const a = await signerFromSeed(TEST_SEED, "k1");
  const b = await signerFromSeed(TEST_SEED, "k1");
  assertEquals(await a.sign({ x: 1 }), await b.sign({ x: 1 }));
  await assertRejects(() => signerFromSeed(btoa("short"), "k1"), Error, "32 bytes");
  assert(a.publicKey.length > 40);
});
