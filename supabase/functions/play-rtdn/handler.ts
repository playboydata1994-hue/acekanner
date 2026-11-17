// POST /functions/v1/play-rtdn — Google Play Real-time Developer Notifications
// delivered by a Pub/Sub push subscription with an OIDC token.
//
// Renewals, cancellations, holds, refunds and revocations update the account's
// Premium status right away; the app receives it at its next check-in.

import { base64Decode } from "../_shared/encoding.ts";
import { fail, json } from "../_shared/http.ts";
import { type JwksCache, verifyGoogleOidc } from "../_shared/oidc.ts";
import { evaluate, PlayApiError, type PlayClient } from "../_shared/play.ts";
import type { LicenseStore } from "../_shared/store.ts";

export interface RtdnDeps {
  store: LicenseStore;
  play: PlayClient | null;
  jwks: JwksCache;
  config: { packageName: string; audience: string | null; serviceAccountEmail: string | null };
  now(): Date;
  log(message: string): void;
}

export async function handleRtdn(req: Request, deps: RtdnDeps): Promise<Response> {
  if (req.method !== "POST") return fail(405, "method_not_allowed", "Use POST.");
  const { audience, serviceAccountEmail } = deps.config;
  if (!audience || !serviceAccountEmail || !deps.play) {
    deps.log("play-rtdn is not configured (RTDN_AUDIENCE, RTDN_SERVICE_ACCOUNT_EMAIL, GOOGLE_PLAY_SERVICE_ACCOUNT)");
    return fail(503, "not_configured", "Notifications are not configured.");
  }
  try {
    await verifyGoogleOidc(
      req.headers.get("authorization"),
      { audience, email: serviceAccountEmail },
      deps.jwks,
      () => deps.now().getTime(),
    );
  } catch (e) {
    deps.log(`rtdn rejected: ${e instanceof Error ? e.message : String(e)}`);
    return fail(401, "unauthorized", "Not a verified Google notification.");
  }

  let note: Record<string, any>;
  try {
    const envelope = await req.json();
    note = JSON.parse(new TextDecoder().decode(base64Decode(envelope?.message?.data ?? "")));
  } catch {
    // Malformed messages are acknowledged so Pub/Sub stops redelivering them.
    return json({ ignored: "malformed" });
  }
  if (note.packageName !== deps.config.packageName) return json({ ignored: "other_package" });
  if (note.testNotification) return json({ ok: "test" });

  try {
    if (note.voidedPurchaseNotification?.purchaseToken) {
      const account = await deps.store.revokePurchase(note.voidedPurchaseNotification.purchaseToken);
      return json({ ok: "voided", known: account !== null });
    }
    const sn = note.subscriptionNotification;
    if (sn?.purchaseToken && sn?.subscriptionId) {
      let sub;
      try {
        sub = await deps.play.getSubscription(sn.purchaseToken);
      } catch (e) {
        if (e instanceof PlayApiError && [400, 404, 410].includes(e.status)) return json({ ignored: "unknown_token" });
        throw e;
      }
      const ref = sub.externalAccountIdentifiers?.obfuscatedExternalAccountId ?? null;
      const account = await deps.store.findPurchaseAccount(sn.purchaseToken, ref);
      // Not linked to an account yet: the app verifies it when the user returns.
      if (!account) return json({ ignored: "unlinked" });
      const ev = evaluate(sub, { productId: sn.subscriptionId, playAccountRef: null, now: deps.now() });
      if (ev.wrongProduct) return json({ ignored: "other_product" });
      let acknowledged = ev.acknowledged;
      if (ev.needsAck) {
        await deps.play.acknowledge(sn.subscriptionId, sn.purchaseToken);
        acknowledged = true;
      }
      await deps.store.applySubscription({
        account,
        token: sn.purchaseToken,
        product: sn.subscriptionId,
        state: ev.state,
        expiry: ev.expiryTime,
        autoRenewing: ev.autoRenewing,
        acknowledged,
        test: ev.test,
        linkedToken: ev.linkedPurchaseToken,
        orderId: ev.orderId,
      });
      return json({ ok: "subscription", state: ev.state });
    }
    return json({ ignored: "unsupported" });
  } catch (e) {
    // Non-2xx makes Pub/Sub retry later.
    deps.log(`rtdn failed: ${e instanceof Error ? e.message : String(e)}`);
    return fail(500, "server_error", "Try again later.");
  }
}
