import { assertEquals, assertRejects } from "jsr:@std/assert@1.0.13";
import { JwksCache, verifyGoogleOidc } from "../../functions/_shared/oidc.ts";
import { base64UrlEncode } from "../../functions/_shared/encoding.ts";

export async function googleSigner() {
  const pair = await crypto.subtle.generateKey(
    { name: "RSASSA-PKCS1-v1_5", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" },
    true,
    ["sign", "verify"],
  ) as CryptoKeyPair;
  const jwk = { ...(await crypto.subtle.exportKey("jwk", pair.publicKey)), kid: "g1" };
  const jwks = new JwksCache(async () => new Response(JSON.stringify({ keys: [jwk] })));
  const sign = async (claims: Record<string, unknown>, kid = "g1") => {
    const enc = (o: unknown) => base64UrlEncode(new TextEncoder().encode(JSON.stringify(o)));
    const input = `${enc({ alg: "RS256", kid, typ: "JWT" })}.${enc(claims)}`;
    const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", pair.privateKey, new TextEncoder().encode(input));
    return `Bearer ${input}.${base64UrlEncode(sig)}`;
  };
  return { jwks, sign };
}

export const NOW = 1_800_000_000_000;
export const EXPECTED = {
  audience: "https://ref.supabase.co/functions/v1/play-rtdn",
  email: "acekanner-play@p.iam.gserviceaccount.com",
};
export const goodClaims = () => ({
  iss: "https://accounts.google.com",
  aud: EXPECTED.audience,
  email: EXPECTED.email,
  email_verified: true,
  iat: NOW / 1000 - 10,
  exp: NOW / 1000 + 3600,
});

Deno.test("accepts a Google-signed token for our endpoint and sender", async () => {
  const g = await googleSigner();
  const c = await verifyGoogleOidc(await g.sign(goodClaims()), EXPECTED, g.jwks, () => NOW);
  assertEquals(c.email, EXPECTED.email);
});

Deno.test("rejects wrong audience, sender, issuer, expiry, key or a missing token", async () => {
  const g = await googleSigner();
  const bad: Array<[Record<string, unknown>, string]> = [
    [{ ...goodClaims(), aud: "https://evil.example" }, "wrong audience"],
    [{ ...goodClaims(), email: "someone@else.com" }, "wrong sender"],
    [{ ...goodClaims(), email_verified: false }, "wrong sender"],
    [{ ...goodClaims(), iss: "https://evil.example" }, "wrong issuer"],
    [{ ...goodClaims(), exp: NOW / 1000 - 3600 }, "expired"],
  ];
  for (const [claims, msg] of bad) {
    await assertRejects(async () => verifyGoogleOidc(await g.sign(claims), EXPECTED, g.jwks, () => NOW), Error, msg);
  }
  await assertRejects(
    async () => verifyGoogleOidc(await g.sign(goodClaims(), "unknown"), EXPECTED, g.jwks, () => NOW),
    Error,
    "unknown signing key",
  );
  const other = await googleSigner();
  await assertRejects(
    async () => verifyGoogleOidc(await other.sign(goodClaims()), EXPECTED, g.jwks, () => NOW),
    Error,
    "bad signature",
  );
  await assertRejects(() => verifyGoogleOidc(null, EXPECTED, g.jwks, () => NOW), Error, "missing bearer");
});
