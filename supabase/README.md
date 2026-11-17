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
