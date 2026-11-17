// Production wiring from environment variables (Supabase secrets).

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.118.0";
import { GoogleTokenSource, parseServiceAccount } from "./google_auth.ts";
import { type Signer, signerFromSeed } from "./jws.ts";
import { GooglePlayClient, type PlayClient } from "./play.ts";
import { SupabaseLicenseStore } from "./store.ts";

export const env = (name: string): string | null => {
  const v = Deno.env.get(name);
  return v && v.trim() ? v.trim() : null;
};

export const packageName = () => env("PLAY_PACKAGE_NAME") ?? "com.acekanner.app";
export const productId = () => env("PLAY_PRODUCT_ID") ?? "acekanner_premium_yearly";

let admin: SupabaseClient | null = null;
export function adminClient(): SupabaseClient {
  if (!admin) {
    const url = env("SUPABASE_URL");
    const key = env("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !key) throw new Error("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY missing");
    admin = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  }
  return admin;
}

export const store = () => new SupabaseLicenseStore(adminClient());

let signer: Promise<Signer> | null = null;
export function entitlementSigner(): Promise<Signer> {
  if (!signer) {
    const seed = env("ENTITLEMENT_SIGNING_KEY");
    if (!seed) throw new Error("ENTITLEMENT_SIGNING_KEY missing");
    signer = signerFromSeed(seed, env("ENTITLEMENT_KEY_ID") ?? "k1");
  }
  return signer;
}

let play: PlayClient | null | undefined;
export function playClient(): PlayClient | null {
  if (play === undefined) {
    const json = env("GOOGLE_PLAY_SERVICE_ACCOUNT");
    play = json
      ? new GooglePlayClient(
        packageName(),
        new GoogleTokenSource(parseServiceAccount(json), "https://www.googleapis.com/auth/androidpublisher"),
      )
      : null;
  }
  return play;
}

export const log = (m: string) => console.error(m);
