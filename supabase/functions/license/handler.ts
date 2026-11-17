// POST /functions/v1/license  { action: "checkin" | "verify-purchase" | "delete-account", ... }
//
// Every request needs the user's Supabase session (Authorization: Bearer <jwt>).
// Responses carry a fresh entitlement token signed with the server's Ed25519 key.

import { type AccountState, buildClaims } from "../_shared/entitlement.ts";
import { randomHex, sha256Hex } from "../_shared/encoding.ts";
import { fail, json } from "../_shared/http.ts";
import type { Signer } from "../_shared/jws.ts";
import { evaluate, PlayApiError, type PlayClient } from "../_shared/play.ts";
import { type Charge, type LicenseStore, OwnedByOtherAccountError } from "../_shared/store.ts";

export interface AuthUser {
  id: string;
  email: string | null;
  /** Google account subject, when the user signed in with Google. */
  googleSub: string | null;
}

export interface LicenseDeps {
  getUser(jwt: string): Promise<AuthUser | null>;
  deleteAuthUser(id: string): Promise<void>;
  store: LicenseStore;
  signer: Signer;
  /** null when the Play service account is not configured yet. */
  play: PlayClient | null;
  config: { productId: string };
  now(): Date;
  log(message: string): void;
}

const INSTALL_ID = /^[A-Za-z0-9-]{16,64}$/;
const KEY_HASH = /^[0-9a-f]{64}$/;
const MAX_CHARGES = 500;

/** One-way hash of the Google identity, kept after account deletion. */
export async function identityHash(user: AuthUser): Promise<string | null> {
  if (user.googleSub) return await sha256Hex(`acekanner-identity|v1|google|${user.googleSub}`);
  if (user.email) return await sha256Hex(`acekanner-identity|v1|email|${user.email.trim().toLowerCase()}`);
  return null;
}

export async function handleLicense(req: Request, deps: LicenseDeps): Promise<Response> {
  if (req.method !== "POST") return fail(405, "method_not_allowed", "Use POST.");
  const jwt = /^Bearer\s+(.+)$/.exec(req.headers.get("authorization") ?? "")?.[1];
  const user = jwt ? await deps.getUser(jwt).catch(() => null) : null;
  if (!user) return fail(401, "not_signed_in", "Please sign in again.");

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return fail(400, "bad_request", "The request was not valid JSON.");
  }
  const deviceId = typeof body.deviceId === "string" ? body.deviceId : "";
  if (body.action !== "delete-account" && !INSTALL_ID.test(deviceId)) {
    return fail(400, "bad_request", "Missing or invalid device ID.");
  }

  try {
    switch (body.action) {
      case "checkin":
        return await checkin(user, deviceId, body, deps);
      case "verify-purchase":
        return await verifyPurchase(user, deviceId, body, deps);
      case "delete-account":
        return await deleteAccount(user, body, deps);
      default:
        return fail(400, "bad_request", "Unknown action.");
    }
  } catch (e) {
    deps.log(`license error: ${e instanceof Error ? e.message : String(e)}`);
    return fail(500, "server_error", "The licensing server had a problem. Try again later.");
  }
}

async function tokenFor(user: AuthUser, deviceId: string, state: AccountState, deps: LicenseDeps) {
  const claims = buildClaims({ accountId: user.id, installId: deviceId, state, now: deps.now(), jti: randomHex(16) });
  return { token: await deps.signer.sign({ ...claims }), claims };
}

function parseCharges(raw: unknown): Charge[] | null {
  if (raw === undefined) return [];
  if (!Array.isArray(raw) || raw.length > MAX_CHARGES) return null;
  const out: Charge[] = [];
  for (const c of raw) {
    if (typeof c !== "object" || c === null) return null;
    const k = (c as Record<string, unknown>).k;
    const t = (c as Record<string, unknown>).t;
    const at = (c as Record<string, unknown>).at;
    if (typeof k !== "string" || !KEY_HASH.test(k)) return null;
    if (t !== "free" && t !== "premium") return null;
    if (typeof at !== "string" || Number.isNaN(Date.parse(at))) return null;
    out.push({ k, t, at });
  }
  return out;
}

/** Re-checks Premium with Google (catches renewals or refunds if a notification was missed). */
async function refreshSubscriptions(user: AuthUser, playAccountRef: string, deps: LicenseDeps) {
  if (!deps.play) return;
  for (const s of await deps.store.subscriptionsToRefresh(user.id)) {
    try {
      const sub = await deps.play.getSubscription(s.purchase_token);
      const ev = evaluate(sub, { productId: s.product_id, playAccountRef, now: deps.now() });
      if (ev.needsAck) await deps.play.acknowledge(s.product_id, s.purchase_token);
      await deps.store.applySubscription({
        account: user.id,
        token: s.purchase_token,
        product: s.product_id,
        state: ev.otherAccount ? "ACEKANNER_OTHER_ACCOUNT" : ev.state,
        expiry: ev.expiryTime,
        autoRenewing: ev.autoRenewing,
        acknowledged: ev.acknowledged || ev.needsAck,
        test: ev.test,
        linkedToken: ev.linkedPurchaseToken,
        orderId: ev.orderId,
      });
    } catch (e) {
      // Keep the stored state; the next check-in tries again.
      deps.log(`refresh failed: ${e instanceof Error ? e.message : String(e)}`);
    }
  }
}

async function checkin(user: AuthUser, deviceId: string, body: Record<string, unknown>, deps: LicenseDeps) {
  const charges = parseCharges(body.charges);
  if (charges === null) return fail(400, "bad_request", "Invalid scan records.");
  const appVersion = typeof body.appVersion === "string" ? body.appVersion.slice(0, 40) : null;
  const hash = await identityHash(user);
  let state = await deps.store.state(user.id, deviceId, body.claim === true, hash, appVersion);
  let accepted = 0;
  if (charges.length > 0) accepted = await deps.store.recordCharges(user.id, deviceId, charges);
  await refreshSubscriptions(user, state.play_account_ref, deps);
  state = await deps.store.state(user.id, deviceId, false, hash, appVersion);
  const { token } = await tokenFor(user, deviceId, state, deps);
  return json({ token, received: charges.length, newlyCounted: accepted });
}

async function verifyPurchase(user: AuthUser, deviceId: string, body: Record<string, unknown>, deps: LicenseDeps) {
  if (!deps.play) {
    return fail(503, "billing_not_configured", "Purchases cannot be verified yet. Please try again later.");
  }
  const purchaseToken = typeof body.purchaseToken === "string" ? body.purchaseToken : "";
  if (purchaseToken.length < 10 || purchaseToken.length > 1000) {
    return fail(400, "bad_request", "Missing purchase token.");
  }
  if (body.productId !== deps.config.productId) return fail(400, "wrong_product", "Unknown product.");

  const hash = await identityHash(user);
  const state = await deps.store.state(user.id, deviceId, false, hash, null);
  const owner = await deps.store.findPurchaseAccount(purchaseToken, null);
  if (owner && owner !== user.id) {
    return fail(
      409,
      "other_account",
      "This purchase belongs to another ACEkanner account. Sign in with that Google account.",
    );
  }

  let sub;
  try {
    sub = await deps.play.getSubscription(purchaseToken);
  } catch (e) {
    if (e instanceof PlayApiError && [400, 404, 410].includes(e.status)) {
      return fail(400, "invalid_purchase", "Google Play did not recognise this purchase.");
    }
    throw e;
  }
  const ev = evaluate(sub, {
    productId: deps.config.productId,
    playAccountRef: state.play_account_ref,
    now: deps.now(),
  });
  if (ev.wrongProduct) return fail(400, "wrong_product", "This purchase is not ACEkanner Premium.");
  if (ev.otherAccount) {
    return fail(
      409,
      "other_account",
      "This purchase was made from another ACEkanner account. Sign in with that Google account.",
    );
  }

  let acknowledged = ev.acknowledged;
  if (ev.needsAck) {
    try {
      await deps.play.acknowledge(deps.config.productId, purchaseToken);
      acknowledged = true;
    } catch (e) {
      // Retried at the next check-in (Play allows 3 days).
      deps.log(`acknowledge failed: ${e instanceof Error ? e.message : String(e)}`);
    }
  }
  try {
    await deps.store.applySubscription({
      account: user.id,
      token: purchaseToken,
      product: deps.config.productId,
      state: ev.state,
      expiry: ev.expiryTime,
      autoRenewing: ev.autoRenewing,
      acknowledged,
      test: ev.test,
      linkedToken: ev.linkedPurchaseToken,
      orderId: ev.orderId,
    });
  } catch (e) {
    if (e instanceof OwnedByOtherAccountError) {
      return fail(
        409,
        "other_account",
        "This purchase belongs to another ACEkanner account. Sign in with that Google account.",
      );
    }
    throw e;
  }
  const after = await deps.store.state(user.id, deviceId, false, hash, null);
  const { token, claims } = await tokenFor(user, deviceId, after, deps);
  return json({
    token,
    purchase: {
      state: ev.state,
      pending: ev.pending,
      granted: claims.plan === "premium",
      expiryTime: ev.expiryTime,
      acknowledged,
    },
  });
}

async function deleteAccount(user: AuthUser, body: Record<string, unknown>, deps: LicenseDeps) {
  if (body.confirm !== true) return fail(400, "bad_request", "Deletion was not confirmed.");
  await deps.store.deleteAccount(user.id, await identityHash(user));
  await deps.deleteAuthUser(user.id);
  return json({ deleted: true });
}
