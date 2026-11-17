# Build configuration

Licensing is configured at build time with public values only:

```bash
flutter build appbundle --release --dart-define-from-file=config/acekanner.json
```

`config/acekanner.json` (see `acekanner.example.json`):

| Key | Value |
|---|---|
| `ACEK_SUPABASE_URL` | Supabase Project URL (`https://<ref>.supabase.co`) |
| `ACEK_SUPABASE_KEY` | Supabase publishable / anon key (public, protected by Row Level Security) |
| `ACEK_GOOGLE_WEB_CLIENT_ID` | Google OAuth **Web** client ID (`….apps.googleusercontent.com`) |
| `ACEK_ENTITLEMENT_KEYS` | `k1:<base64 Ed25519 public key>` (comma-separated for key rotation) |
| `ACEK_PRIVACY_POLICY_URL` | Public privacy policy page (`https://…`); shows the in-app "Privacy policy" link |
| `ACEK_TERMS_URL` | Public terms of use page; shows the in-app "Terms of use" link |
| `ACEK_ACCOUNT_DELETION_URL` | Public account-deletion page (for the Play listing and reference) |

None of these is a secret. Secrets (the entitlement signing key, the Play service
account) live only in Supabase secrets.

A build without this file is a **test build**: no sign-in, 100 free scans counted on
the phone, never Premium.
