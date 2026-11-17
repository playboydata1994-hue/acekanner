// Ed25519 compact JWS for entitlement tokens.
//
// header.payload.signature, each base64url. The app verifies the signature with
// the public key built into it, so a token cannot be forged or edited.

import { base64Decode, base64UrlDecode, base64UrlEncode, utf8 } from "./encoding.ts";

export const TOKEN_TYPE = "ACEK-ENT+JWS";

// PKCS#8 DER prefix for an Ed25519 private key with a 32-byte seed (RFC 8410).
const PKCS8_ED25519_PREFIX = new Uint8Array([
  0x30,
  0x2e,
  0x02,
  0x01,
  0x00,
  0x30,
  0x05,
  0x06,
  0x03,
  0x2b,
  0x65,
  0x70,
  0x04,
  0x22,
  0x04,
  0x20,
]);

export interface Signer {
  keyId: string;
  /** Raw 32-byte public key, base64. */
  publicKey: string;
  sign(claims: Record<string, unknown>): Promise<string>;
}

/** Builds a signer from a base64 32-byte Ed25519 seed (the ENTITLEMENT_SIGNING_KEY secret). */
export async function signerFromSeed(seedBase64: string, keyId: string): Promise<Signer> {
  const seed = base64Decode(seedBase64);
  if (seed.length !== 32) throw new Error("ENTITLEMENT_SIGNING_KEY must be 32 bytes (base64)");
  const der = new Uint8Array(PKCS8_ED25519_PREFIX.length + 32);
  der.set(PKCS8_ED25519_PREFIX);
  der.set(seed, PKCS8_ED25519_PREFIX.length);
  const extractable = await crypto.subtle.importKey("pkcs8", der, { name: "Ed25519" }, true, ["sign"]);
  const jwk = await crypto.subtle.exportKey("jwk", extractable);
  const key = await crypto.subtle.importKey("pkcs8", der, { name: "Ed25519" }, false, ["sign"]);
  const publicKey = btoa(String.fromCharCode(...base64UrlDecode(jwk.x!)));
  return {
    keyId,
    publicKey,
    async sign(claims) {
      const header = { alg: "EdDSA", typ: TOKEN_TYPE, kid: keyId };
      const input = `${base64UrlEncode(utf8(JSON.stringify(header)))}.${base64UrlEncode(utf8(JSON.stringify(claims)))}`;
      const sig = await crypto.subtle.sign({ name: "Ed25519" }, key, utf8(input));
      return `${input}.${base64UrlEncode(sig)}`;
    },
  };
}

/** Verifies a token against raw base64 public keys by key ID. Returns the claims or throws. */
export async function verifyToken(
  token: string,
  publicKeys: Record<string, string>,
): Promise<Record<string, unknown>> {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("malformed token");
  const header = JSON.parse(new TextDecoder().decode(base64UrlDecode(parts[0])));
  if (header.alg !== "EdDSA" || header.typ !== TOKEN_TYPE) throw new Error("unexpected token header");
  const pub = publicKeys[header.kid];
  if (!pub) throw new Error("unknown key id");
  const key = await crypto.subtle.importKey("raw", base64Decode(pub), { name: "Ed25519" }, false, ["verify"]);
  const ok = await crypto.subtle.verify(
    { name: "Ed25519" },
    key,
    base64UrlDecode(parts[2]),
    utf8(`${parts[0]}.${parts[1]}`),
  );
  if (!ok) throw new Error("bad signature");
  return JSON.parse(new TextDecoder().decode(base64UrlDecode(parts[1])));
}
