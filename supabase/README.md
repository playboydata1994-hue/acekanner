# ACEkanner licensing server (Supabase)

Counts scans, verifies Google Play subscriptions and signs entitlement tokens.
It stores no student data.

| Path | What |
|---|---|
| `migrations/20261117000000_licensing.sql` | Tables, Row Level Security, `license_*` SQL functions |
| `functions/license` | `checkin`, `verify-purchase`, `delete-account` (called by the app) |
| `functions/play-rtdn` | Google Play Real-time Developer Notifications (Pub/Sub push, OIDC) |
| `functions/_shared` | Ed25519 tokens, Google service-account auth, Play API, OIDC |

## Secrets (Supabase → Edge Functions → Secrets)

| Name | Set by | Value |
|---|---|---|
| `ENTITLEMENT_SIGNING_KEY` | deployment | base64 32-byte Ed25519 seed (the app holds the public key) |
| `ENTITLEMENT_KEY_ID` | deployment | `k1` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | **the owner, in the dashboard** | the service-account JSON |
| `RTDN_AUDIENCE` | deployment | `https://<ref>.supabase.co/functions/v1/play-rtdn` |
| `RTDN_SERVICE_ACCOUNT_EMAIL` | deployment | the Pub/Sub push service account email |
| `PLAY_PACKAGE_NAME`, `PLAY_PRODUCT_ID` | optional | default `com.acekanner.app`, `acekanner_premium_yearly` |

## Tests

```bash
# SQL: migration + behaviour checks on a throwaway PostgreSQL database
PGHOST=localhost PGPORT=5432 PGUSER=postgres supabase/tests/run_sql_tests.sh
```

```bash
# Edge functions (Deno 2)
cd supabase && deno task check && deno task test
```

`deno task vectors` regenerates `app/test/fixtures/entitlement_vectors.json`, which the
app's verifier test uses to prove it accepts exactly what this server signs.

## Deployment (production)

| Item | Value |
|---|---|
| Project | `acekanner`, ref `ajmdnsdhrpktkvkxnmuo`, region Southeast Asia (Singapore) |
| Migration | `licensing` applied 2026-11-17 (Database → Migrations) |
| Functions | `license` and `play-rtdn`, deployed with `tool/deploy_function.py` (verify_jwt off; both check authorization themselves) |
| Secrets set | `ENTITLEMENT_SIGNING_KEY` (generated, never stored elsewhere), `ENTITLEMENT_KEY_ID=k1`, `RTDN_AUDIENCE` |
| Still to set | `GOOGLE_PLAY_SERVICE_ACCOUNT` (owner, dashboard), `RTDN_SERVICE_ACCOUNT_EMAIL` |
| App config | `app/config/acekanner.json` (public values; Web client ID added after Google setup) |

Live end-to-end check (2026-11-17, temporary user, cleaned up afterwards): requests without a
session refused; check-in returns a token signed by `k1` and bound to user and phone; 3 scans
reduce the lease to 97; re-upload counts nothing; an unverified "premium" scan counts as free;
purchase verification reports `billing_not_configured` until the Play service account is set;
account deletion removes the sign-in.

Rotating the signing key: generate a new seed, set `ENTITLEMENT_SIGNING_KEY` and
`ENTITLEMENT_KEY_ID=k2`, and ship an app whose `ACEK_ENTITLEMENT_KEYS` lists both `k1` and `k2`
before switching.
