# Build configuration

Plans (trial, PRO, MAX) are configured at build time with public values only:

```bash
flutter build appbundle --release --dart-define-from-file=config/acekor.json
```

| Key | Value |
|---|---|
| `ACEKOR_SUPABASE_URL` | Supabase Project URL (the same `acekanner` project) |
| `ACEKOR_SUPABASE_KEY` | Supabase publishable key (public, protected by Row Level Security) |
| `ACEKOR_GOOGLE_WEB_CLIENT_ID` | Google OAuth **Web** client ID (`….apps.googleusercontent.com`) |
| `ACEKOR_ENTITLEMENT_KEYS` | `k1:<base64 Ed25519 public key>` — the same key pair as ACEkanner; ACEkor tokens have their own type (`ACEKOR-ENT+JWS`) and `app: "acekor"` claim, so the two apps never accept each other's tokens |
| `ACEKOR_PRIVACY_POLICY_URL` | Public privacy policy (`docs/acekor/privacy/`) |
| `ACEKOR_TERMS_URL` | Public terms of use (`docs/acekor/terms/`) |
| `ACEKOR_ACCOUNT_DELETION_URL` | Public account-deletion page (`docs/acekor/delete-account/`) |

None of these is a secret. Secrets (the signing key, the Play service account) live only
in Supabase secrets.

A build where any of the first four values is missing is a **test build**: no sign-in,
a 7-day trial kept on the phone only, purchases turned off. `ACEKOR_GOOGLE_WEB_CLIENT_ID`
is still empty until Google sign-in is set up (see `acekor/docs/PLAY_RELEASE.md`).
