// POST /functions/v1/acekor-license
//   { action: "checkin" | "start-trial" | "verify-purchase" | "delete-account", ... }
//
// ACEKOR Calculator's plan server. Every request needs the user's Supabase
// session (Authorization: Bearer <jwt>). Responses carry a fresh entitlement
// token (EdDSA, typ ACEKOR-ENT+JWS). Never receives student data.

import { ACEKOR_PRODUCTS, type AcekorState, type AcekorStore, buildAcekorClaims } from "../_shared/acekor.ts";
import { randomHex, sha256Hex } from "../_shared/encoding.ts";
import { fail, json } from "../_shared/http.ts";
import type { Signer } from "../_shared/jws.ts";
import { evaluate, PlayApiError, type PlayClient } from "../_shared/play.ts";
import { OwnedByOtherAccountError } from "../_shared/store.ts";

export interface AuthUser {
  id: string;
  email: string | null;
  googleSub: string | null;
}

export interface AcekorDeps {
  getUser(jwt: string): Promise<AuthUser | null>;
  deleteAuthUser(id: string): Promise<void>;
  store: AcekorStore;
  signer: Signer;
  /** null when the Play service account is not configured yet. */
  play: PlayClient | null;
  now(): Date;
  log(message: string): void;
}

const INSTALL_ID = /^[A-Za-z0-9-]{16,64}$/;
const PRODUCTS = new Set<string>(Object.values(ACEKOR_PRODUCTS));

/** One-way hash of the Google identity, kept after account deletion so the
 * free trial cannot be taken twice. */
export async function acekorIdentityHash(user: AuthUser): Promise<string | null> {
  if (user.googleSub) return await sha256Hex(`acekor-identity|v1|google|${user.googleSub}`);
  if (user.email) return await sha256Hex(`acekor-identity|v1|email|${user.email.trim().toLowerCase()}`);
  return null;
}

export async function handleAcekor(req: Request, deps: AcekorDeps): Promise<Response> {
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
      case "start-trial":
        return await startTrial(user, deviceId, deps);
      case "verify-purchase":
        return await verifyPurchase(user, deviceId, body, deps);
      case "delete-account":
        return await deleteAccount(user, body, deps);
      default:
        return fail(400, "bad_request", "Unknown action.");
    }
  } catch (e) {
    deps.log(`acekor-license error: ${e instanceof Error ? e.message : String(e)}`);
    return fail(500, "server_error", "The licensing server had a problem. Try again later.");
  }
}

async function tokenFor(user: AuthUser, deviceId: string, state: AcekorState, deps: AcekorDeps) {
  const claims = buildAcekorClaims({
    accountId: user.id,
    installId: deviceId,
    state,
    now: deps.now(),
    jti: randomHex(16),
  });
  return { token: await deps.signer.sign({ ...claims }), claims };
}

/** Re-checks subscriptions with Google (catches renewals, cancellations and
 * refunds without needing a push notification). */
async function refreshSubscriptions(user: AuthUser, playAccountRef: string, deps: AcekorDeps) {
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
        state: ev.otherAccount ? "ACEKOR_OTHER_ACCOUNT" : ev.state,
        expiry: ev.expiryTime,
        autoRenewing: ev.autoRenewing,
        acknowledged: ev.acknowledged || ev.needsAck,
        test: ev.test,
        linkedToken: ev.linkedPurchaseToken,
        orderId: ev.orderId,
      });
    } catch (e) {
      deps.log(`refresh failed: ${e instanceof Error ? e.message : String(e)}`);
    }
  }
}

async function checkin(user: AuthUser, deviceId: string, body: Record<string, unknown>, deps: AcekorDeps) {
  const appVersion = typeof body.appVersion === "string" ? body.appVersion.slice(0, 40) : null;
  const hash = await acekorIdentityHash(user);
  let state = await deps.store.state(user.id, deviceId, hash, appVersion);
  await refreshSubscriptions(user, state.play_account_ref, deps);
  state = await deps.store.state(user.id, deviceId, hash, appVersion);
  const { token } = await tokenFor(user, deviceId, state, deps);
  return json({ token });
}

async function startTrial(user: AuthUser, deviceId: string, deps: AcekorDeps) {
  const hash = await acekorIdentityHash(user);
  await deps.store.state(user.id, deviceId, hash, null);
  await deps.store.startTrial(user.id);
  const state = await deps.store.state(user.id, deviceId, hash, null);
  const { token, claims } = await tokenFor(user, deviceId, state, deps);
  const active = claims.trial_until !== null && claims.trial_until > claims.iat;
  return json({ token, trial: { active, startedAt: state.trial_started, endsAt: state.trial_until } });
}

async function verifyPurchase(user: AuthUser, deviceId: string, body: Record<string, unknown>, deps: AcekorDeps) {
  if (!deps.play) {
    return fail(503, "billing_not_configured", "Purchases cannot be verified yet. Please try again later.");
  }
  const purchaseToken = typeof body.purchaseToken === "string" ? body.purchaseToken : "";
  if (purchaseToken.length < 10 || purchaseToken.length > 1000) {
    return fail(400, "bad_request", "Missing purchase token.");
  }
  const productId = typeof body.productId === "string" ? body.productId : "";
  if (!PRODUCTS.has(productId)) return fail(400, "wrong_product", "Unknown product.");

  const hash = await acekorIdentityHash(user);
  const state = await deps.store.state(user.id, deviceId, hash, null);
  const owner = await deps.store.findPurchaseAccount(purchaseToken);
  if (owner && owner !== user.id) {
    return fail(409, "other_account", "This purchase belongs to another Google account. Sign in with that account.");
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
  const ev = evaluate(sub, { productId, playAccountRef: state.play_account_ref, now: deps.now() });
  if (ev.wrongProduct) return fail(400, "wrong_product", "This purchase is not an ACEKOR plan.");
  if (ev.otherAccount) {
    return fail(409, "other_account", "This purchase was made from another Google account. Sign in with that account.");
  }
  let acknowledged = ev.acknowledged;
  if (ev.needsAck) {
    try {
      await deps.play.acknowledge(productId, purchaseToken);
      acknowledged = true;
    } catch (e) {
      deps.log(`acknowledge failed: ${e instanceof Error ? e.message : String(e)}`);
    }
  }
  try {
    await deps.store.applySubscription({
      account: user.id,
      token: purchaseToken,
      product: productId,
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
      return fail(409, "other_account", "This purchase belongs to another Google account. Sign in with that account.");
    }
    throw e;
  }
  const after = await deps.store.state(user.id, deviceId, hash, null);
  const { token, claims } = await tokenFor(user, deviceId, after, deps);
  const granted = ev.grants && claims.paid !== "none" && claims.paid_until !== null && claims.paid_until > claims.iat;
  return json({
    token,
    purchase: { state: ev.state, pending: ev.pending, granted, expiryTime: ev.expiryTime, acknowledged },
  });
}

async function deleteAccount(user: AuthUser, body: Record<string, unknown>, deps: AcekorDeps) {
  if (body.confirm !== true) return fail(400, "bad_request", "Deletion was not confirmed.");
  const sharedWithAcekanner = await deps.store.deleteAccount(user.id, await acekorIdentityHash(user));
  // The sign-in is shared with ACEkanner; keep it while that app uses it.
  if (!sharedWithAcekanner) await deps.deleteAuthUser(user.id);
  return json({ deleted: true });
}
