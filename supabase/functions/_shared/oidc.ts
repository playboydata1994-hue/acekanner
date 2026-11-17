// Verifies the Google-signed OIDC token that Pub/Sub push attaches to
// Real-time Developer Notifications (Authorization: Bearer <jwt>).

import { base64UrlDecode, utf8 } from "./encoding.ts";
import type { Fetch } from "./google_auth.ts";

export const GOOGLE_CERTS = "https://www.googleapis.com/oauth2/v3/certs";
const ISSUERS = new Set(["https://accounts.google.com", "accounts.google.com"]);

export class JwksCache {
  private keys: { at: number; keys: Array<JsonWebKey & { kid?: string }> } | null = null;
  constructor(private readonly fetchFn: Fetch = fetch, private readonly now: () => number = Date.now) {}

  async get(kid: string): Promise<(JsonWebKey & { kid?: string }) | undefined> {
    if (!this.keys || this.now() - this.keys.at > 3600_000 || !this.keys.keys.some((k) => k.kid === kid)) {
      const res = await this.fetchFn(GOOGLE_CERTS);
      if (!res.ok) throw new Error(`Google certs returned ${res.status}`);
      this.keys = { at: this.now(), keys: (await res.json()).keys ?? [] };
    }
    return this.keys.keys.find((k) => k.kid === kid);
  }
}

export async function verifyGoogleOidc(
  authorization: string | null,
  expected: { audience: string; email: string },
  jwks: JwksCache,
  now: () => number = Date.now,
): Promise<Record<string, unknown>> {
  const m = /^Bearer\s+(.+)$/.exec(authorization ?? "");
  if (!m) throw new Error("missing bearer token");
  const parts = m[1].split(".");
  if (parts.length !== 3) throw new Error("malformed token");
  const header = JSON.parse(new TextDecoder().decode(base64UrlDecode(parts[0])));
  if (header.alg !== "RS256" || typeof header.kid !== "string") throw new Error("unexpected token header");
  const jwk = await jwks.get(header.kid);
  if (!jwk) throw new Error("unknown signing key");
  const key = await crypto.subtle.importKey(
    "jwk",
    { kty: jwk.kty, n: jwk.n, e: jwk.e, alg: "RS256", ext: true },
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const ok = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    key,
    base64UrlDecode(parts[2]),
    utf8(`${parts[0]}.${parts[1]}`),
  );
  if (!ok) throw new Error("bad signature");
  const c = JSON.parse(new TextDecoder().decode(base64UrlDecode(parts[1])));
  const t = Math.floor(now() / 1000);
  if (!ISSUERS.has(c.iss)) throw new Error("wrong issuer");
  if (c.aud !== expected.audience) throw new Error("wrong audience");
  if (typeof c.exp !== "number" || c.exp < t - 60) throw new Error("expired");
  if (typeof c.iat === "number" && c.iat > t + 300) throw new Error("issued in the future");
  if (c.email !== expected.email || c.email_verified !== true) throw new Error("wrong sender");
  return c;
}
