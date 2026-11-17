// OAuth access tokens for a Google service account (JWT bearer grant, RS256).
// The service-account JSON comes only from the GOOGLE_PLAY_SERVICE_ACCOUNT secret.

import { base64Decode, base64UrlEncode, utf8 } from "./encoding.ts";

export interface ServiceAccount {
  client_email: string;
  private_key: string;
  private_key_id?: string;
  token_uri?: string;
}

export type Fetch = (input: string | URL | Request, init?: RequestInit) => Promise<Response>;

export function parseServiceAccount(json: string): ServiceAccount {
  let sa: ServiceAccount;
  try {
    sa = JSON.parse(json);
  } catch {
    throw new Error("GOOGLE_PLAY_SERVICE_ACCOUNT is not valid JSON");
  }
  if (!sa.client_email || !sa.private_key?.includes("PRIVATE KEY")) {
    throw new Error("GOOGLE_PLAY_SERVICE_ACCOUNT lacks client_email or private_key");
  }
  return sa;
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const body = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  return await crypto.subtle.importKey(
    "pkcs8",
    base64Decode(body),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

export class GoogleTokenSource {
  private cached: { token: string; expires: number } | null = null;

  constructor(
    private readonly sa: ServiceAccount,
    private readonly scope: string,
    private readonly fetchFn: Fetch = fetch,
    private readonly now: () => number = Date.now,
  ) {}

  /** Signed JWT assertion for the token endpoint. */
  async assertion(): Promise<string> {
    const iat = Math.floor(this.now() / 1000);
    const header = { alg: "RS256", typ: "JWT", ...(this.sa.private_key_id ? { kid: this.sa.private_key_id } : {}) };
    const claims = {
      iss: this.sa.client_email,
      scope: this.scope,
      aud: this.sa.token_uri ?? "https://oauth2.googleapis.com/token",
      iat,
      exp: iat + 3600,
    };
    const input = `${base64UrlEncode(utf8(JSON.stringify(header)))}.${base64UrlEncode(utf8(JSON.stringify(claims)))}`;
    const key = await importPrivateKey(this.sa.private_key);
    const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, utf8(input));
    return `${input}.${base64UrlEncode(sig)}`;
  }

  async token(): Promise<string> {
    if (this.cached && this.cached.expires - 60_000 > this.now()) return this.cached.token;
    const res = await this.fetchFn(this.sa.token_uri ?? "https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: await this.assertion(),
      }),
    });
    if (!res.ok) throw new Error(`Google token endpoint returned ${res.status}`);
    const body = await res.json();
    if (typeof body.access_token !== "string") throw new Error("Google token endpoint returned no token");
    this.cached = { token: body.access_token, expires: this.now() + (Number(body.expires_in) || 3600) * 1000 };
    return this.cached.token;
  }
}
