// Builds the claims of an entitlement token from the account state.

export const OFFLINE_DAYS = 30;

/** What license_state() returns. */
export interface AccountState {
  free_limit: number;
  free_used: number;
  lease: number;
  lease_holder: boolean;
  premium_until: string | null;
  play_account_ref: string;
}

export interface EntitlementClaims {
  v: 1;
  sub: string;
  dev: string;
  plan: "free" | "premium";
  free_limit: number;
  free_used: number;
  lease: number;
  premium_until: number | null;
  verified_at: number;
  offline_until: number;
  iat: number;
  jti: string;
}

export function buildClaims(args: {
  accountId: string;
  installId: string;
  state: AccountState;
  now: Date;
  jti: string;
}): EntitlementClaims {
  const now = Math.floor(args.now.getTime() / 1000);
  const until = args.state.premium_until === null ? null : Math.floor(Date.parse(args.state.premium_until) / 1000);
  const premium = until !== null && Number.isFinite(until) && until > now;
  return {
    v: 1,
    sub: args.accountId,
    dev: args.installId,
    plan: premium ? "premium" : "free",
    free_limit: args.state.free_limit,
    free_used: args.state.free_used,
    lease: args.state.lease,
    premium_until: premium ? until : null,
    verified_at: now,
    // Premium works offline until min(premium_until, offline_until); the free
    // lease is usable until offline_until. Then the app must check in again.
    offline_until: now + OFFLINE_DAYS * 86400,
    iat: now,
    jti: args.jti,
  };
}
