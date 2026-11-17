import { assert, assertEquals, assertThrows } from "jsr:@std/assert@1.0.13";
import { GoogleTokenSource, parseServiceAccount } from "../../functions/_shared/google_auth.ts";
import { base64UrlDecode } from "../../functions/_shared/encoding.ts";

async function testServiceAccount() {
  const pair = await crypto.subtle.generateKey(
    { name: "RSASSA-PKCS1-v1_5", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" },
    true,
    ["sign", "verify"],
  ) as CryptoKeyPair;
  const der = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${
    btoa(String.fromCharCode(...der)).match(/.{1,64}/g)!.join("\n")
  }\n-----END PRIVATE KEY-----\n`;
  return {
    pair,
    json: JSON.stringify({
      client_email: "acekanner-play@test.iam.gserviceaccount.com",
      private_key: pem,
      private_key_id: "kid1",
      token_uri: "https://oauth2.googleapis.com/token",
    }),
  };
}

Deno.test("service-account JWT is RS256-signed with the right claims; token is cached", async () => {
  const { pair, json } = await testServiceAccount();
  let calls = 0;
  let sentAssertion = "";
  const fetchFn = async (_url: string | URL | Request, init?: RequestInit) => {
    calls++;
    sentAssertion = new URLSearchParams(init!.body as URLSearchParams).get("assertion")!;
    return new Response(JSON.stringify({ access_token: "ya29.test", expires_in: 3600 }));
  };
  const src = new GoogleTokenSource(
    parseServiceAccount(json),
    "https://www.googleapis.com/auth/androidpublisher",
    fetchFn,
    () => 1_800_000_000_000,
  );
  assertEquals(await src.token(), "ya29.test");
  assertEquals(await src.token(), "ya29.test");
  assertEquals(calls, 1, "cached");

  const [h, p, s] = sentAssertion.split(".");
  const ok = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    pair.publicKey,
    base64UrlDecode(s),
    new TextEncoder().encode(`${h}.${p}`),
  );
  assert(ok, "assertion signature");
  const claims = JSON.parse(new TextDecoder().decode(base64UrlDecode(p)));
  assertEquals(claims.iss, "acekanner-play@test.iam.gserviceaccount.com");
  assertEquals(claims.scope, "https://www.googleapis.com/auth/androidpublisher");
  assertEquals(claims.exp - claims.iat, 3600);
});

Deno.test("bad service-account JSON is refused with a clear message", () => {
  assertThrows(() => parseServiceAccount("{"), Error, "not valid JSON");
  assertThrows(() => parseServiceAccount("{}"), Error, "lacks client_email");
});
