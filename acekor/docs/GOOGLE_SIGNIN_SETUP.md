# Google sign-in setup (ACEkor Grading Sheet and ACEkanner)

The free trial and the subscriptions use a one-time Google sign-in. One Google Cloud project and
one Supabase project serve both apps, so these steps turn on sign-in for ACEkanner too.

**Never send in chat:** the client **secret**, passwords, or any downloaded JSON file.
The **Web client ID** is public (it is compiled into the apps).

## Status (2026-11-18)

| Step | State |
|---|---|
| A. Google Cloud project | Done |
| B. Consent screen "ACE apps by NYE94", External, Testing | Done |
| C. Web client `Supabase (ACE apps)` | Done: `424055951654-36ljq6g443009ivu3f0ave1fpi96jm2g.apps.googleusercontent.com` |
| D. Supabase Google provider | Done through the Management API: enabled, Client ID set, nonce check on, no secret |
| Web client ID in both apps' build settings | Done (`acekor/app/config/acekor.json`, `app/config/acekanner.json`) |
| E. Android clients for the upload keys (ACEkor and ACEkanner) | Done (listed as "Android client 1" and "Android client 2") |
| E. Android client for ACEkor's Play app-signing key | Done (2026-11-19, "ACEkor Play builds") |
| E. Android client for ACEkanner's Play app-signing key | After ACEkanner's first Play upload |
| Publish the consent screen | Before the public release |

## A. Google Cloud project

1. Open **console.cloud.google.com** and sign in with the developer Google account.
2. In the project picker (top left), choose the ACEkanner project if it exists; otherwise create
   one named `ACE apps`, and make sure it is selected.

## B. Consent screen (what instructors see when they sign in)

1. Open **Google Auth Platform** (formerly "OAuth consent screen") and click **Get started**.
2. **App name:** `ACE apps by NYE94`; **User support email** and **Contact email:** the developer
   email; **Audience:** **External**. Click **Create**.
   - If Google answers "Create failed because the brand was created while you were editing",
     refresh the page: the settings were saved. Check **Branding** and fix anything missing.
3. **Branding → App domain** and **Authorized domains:** leave empty. They are only needed if
   Google reviews the app, and basic name-and-email sign-in needs no review.
   Do not upload a logo: a logo makes Google verify the app first.
4. **Audience → Test users → Add users:** add the Gmail accounts used for testing. While the
   status is "Testing", only these accounts can sign in.
5. Before the public release: **Audience → Publish app**.

## C. Web client (its ID is what both apps send to Google)

1. **Clients → Create client → Web application**, named `Supabase (ACE apps)`.
2. Leave **Authorized JavaScript origins** and **Authorized redirect URIs** empty. Both apps sign
   in natively (`google_sign_in` → `signInWithIdToken`); no browser redirect is used.
3. **Create**, then copy the **Client ID**. The secret is not needed by either app or by Supabase.

## D. Supabase

Done through the Management API (`PATCH /v1/projects/ajmdnsdhrpktkvkxnmuo/config/auth`):

- `external_google_enabled = true`
- `external_google_client_id = <Web client ID>`. Supabase accepts ID tokens whose audience is
  this ID.
- `external_google_skip_nonce_check = false`. The apps send no nonce, so the check passes.
- No secret is stored. It is only needed for browser sign-in, which neither app uses.

Check: a token exchange with a dummy token now answers `Bad ID token` (before: `provider_disabled`).

To do it by hand instead: **supabase.com → project `acekanner` → Authentication → Sign In /
Providers → Google** → on; **Client IDs:** the Web client ID; leave **Skip nonce checks** off; Save.

## E. Android clients (one per app and per signing key)

Google checks that sign-in comes from the real app. For each signing key below, go to
**Clients → Create client → Android**, enter the package name and the key's SHA-1, and click
**Create**. Without the matching client, sign-in fails with "Google sign-in is not set up correctly
for this app version".

| Client name | Package | SHA-1 |
|---|---|---|
| ACEkor upload key | `com.acekor.calculator` | `55:7E:4A:02:F4:0A:50:C3:24:20:09:1A:88:39:E0:52:7F:80:BA:4F` |
| ACEkor Play builds | `com.acekor.calculator` | `EB:31:6C:42:90:1C:0E:17:EB:01:6A:09:19:D1:12:B0:34:88:00:28` (Play App Signing, classical key; Play Console → Protected with Play → Play Store protection → Manage Play app signing) |
| ACEkanner upload key | `com.acekanner.app` | `65:75:4A:42:B5:46:71:98:9B:BB:30:2E:D7:52:B6:32:22:4D:3E:01` |
| ACEkanner Play builds | `com.acekanner.app` | From ACEkanner's App signing page |

The upload-key clients cover APKs installed directly (sideloaded test builds). The Play clients cover
copies installed from Google Play, which Google re-signs with its own key.
