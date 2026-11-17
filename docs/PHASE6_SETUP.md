# ACEkanner — Phase 6 setup guide (accounts and keys)

These steps create the online services that ACEkanner's licensing needs: Google
sign-in, the Supabase server that counts scans and checks subscriptions, and the
Google Play subscription. Do them in order. Parts 1–3 can be done right away;
Part 4 needs the first app bundle (`.aab`), which I will send you; Part 5 is last.

**Never send these in chat:** passwords, the Google OAuth *client secret*, the
Google Play *service-account JSON file*, or a Supabase *access token*. You will type
each of them directly into the Supabase or Google website (or into a secure form I
open for you). Everything I ask you to send me is a public value.

---

## Part 1 — Supabase project ✅ done (2026-11-17)

Project `acekanner` (Singapore) is created; the server is installed and tested.
The steps below are kept for reference.

### Reference

1. Go to **supabase.com** → sign in (your Google account is fine) → **New project**.
   - Name: `acekanner`
   - Database password: click **Generate a password** and keep it in a safe place
     (you will not need to give it to me).
   - Region: **Southeast Asia (Singapore)**
   - Plan: Free is enough for testing.
2. Wait until the project is ready, then open **Project Settings → API Keys**
   (or **Connect**). Copy:
   - the **Project URL**, which looks like `https://abcdefghijklmnop.supabase.co`
   - the **publishable key** (`sb_publishable_…`), or the legacy **anon public** key
   → **Send me both.** They are public by design (they only allow what the
   server's security rules permit).
3. Create a deployment token so I can install the server code for you:
   **Account (your avatar) → Account preferences → Access Tokens → Generate new token**,
   name it `acekanner-deploy`. **Do not paste it in chat.** When I'm ready to deploy,
   I'll open a secure form in this chat for you to paste it into. You can delete the
   token afterwards.

## Part 2 — Google Cloud: sign-in with Google (about 20 minutes)

1. Go to **console.cloud.google.com** → project picker → **New project** → name
   `ACEkanner` → Create. Make sure it is selected at the top.
2. **APIs & Services → OAuth consent screen** (also called *Google Auth Platform*)
   → **Get started**:
   - App name: `ACEkanner`; User support email: your email.
   - Audience: **External**.
   - Contact email: your email → Create.
   - **Audience → Test users → Add users**: add the Gmail account(s) you will test
     with. (While the app is in "Testing", only these accounts can sign in.)
3. **Clients → Create client → Web application**
   - Name: `ACEkanner server`
   - Authorized redirect URIs: `https://<your-project-ref>.supabase.co/auth/v1/callback`
     (use your Supabase Project URL from Part 1 + `/auth/v1/callback`).
   - Create. A box shows the **Client ID** and **Client secret**.
   - **Send me the Client ID** (ends in `.apps.googleusercontent.com`).
   - Keep the box open for step 5 — the secret goes only into Supabase.
4. **Clients → Create client → Android**
   - Name: `ACEkanner test builds`
   - Package name: `com.acekanner.app`
   - SHA-1 certificate fingerprint:
     `65:75:4A:42:B5:46:71:98:9B:BB:30:2E:D7:52:B6:32:22:4D:3E:01`
     (the fingerprint of the ACEkanner upload key I created; it is public).
   - Create. (A second Android client for Play-installed builds is added in Part 4.)
5. In **Supabase → Authentication → Sign In / Providers → Google**:
   - Enable **Sign in with Google**.
   - **Client IDs**: paste the *Web* Client ID from step 3.
   - **Client Secret**: paste the *Web* client secret from step 3.
   - Leave "Skip nonce checks" off → **Save**.

## Part 3 — Google Play Console: create the app (about 15 minutes)

1. **play.google.com/console** → **Create app**:
   - App name `ACEkanner`, default language English (United States),
     **App**, **Free** (the subscription is sold inside the app).
   - Accept the declarations → Create app.
2. **Test and release → Testing → Internal testing → Testers**:
   create an email list with your test Gmail account(s) and save.
3. **Settings (gear, left menu) → License testing**: add the same Gmail account(s),
   License response **RESPOND_NORMALLY** → Save. Test purchases from these accounts
   are never charged, and a yearly test subscription renews every 30 minutes.

Stop here and tell me Parts 1–3 are done. I will then deploy the server and send you
the first signed app bundle.

## Part 4 — First upload and the subscription (after I send the `.aab`)

1. **Internal testing → Create new release**. When asked about app signing, keep
   **Google-generated key (recommended)**. Upload `ACEkanner-<version>.aab`, add a
   release name, **Save → Review release → Start rollout to Internal testing**.
2. **Test and release → App integrity → App signing**: copy the **SHA-1** of the
   *App signing key certificate*. In Google Cloud (Part 2), create another
   **Android** client, `ACEkanner Play builds`, package `com.acekanner.app`, with
   that SHA-1.
3. **Monetize with Play → Products → Subscriptions → Create subscription**:
   - Product ID: **`acekanner_premium_yearly`** (exactly this)
   - Name: `ACEkanner Premium`
   - **Add base plan**: Base plan ID `yearly`, **Auto-renewing**, Billing period
     **1 year**, Grace period 7 days (default is fine), Account hold on.
   - **Set prices**: Philippines **PHP 399**; let Play convert the other countries
     (or remove countries you don't sell in) → **Activate** the base plan.
4. **Internal testing → Testers → copy the opt-in link**, open it on your phone
   (signed in with the test Gmail), accept, then install ACEkanner from the Play Store
   page it shows. Remove the sideloaded test APK first if it is installed.

## Part 5 — Let the server verify purchases (about 20 minutes)

1. **Google Cloud → APIs & Services → Library**: enable
   **Google Play Android Developer API** and **Cloud Pub/Sub API**.
2. **IAM & Admin → Service accounts → Create service account**:
   name `acekanner-play`, no roles needed → Done. Open it → **Keys → Add key →
   Create new key → JSON**. A file downloads.
3. **Play Console → Users and permissions → Invite new users**: paste the service
   account's email (`acekanner-play@….iam.gserviceaccount.com`). App permissions:
   add ACEkanner with **View financial data** and **Manage orders and
   subscriptions** → Invite.
4. **Supabase → Edge Functions → Secrets → Add new secret**:
   - Name: `GOOGLE_PLAY_SERVICE_ACCOUNT`
   - Value: open the downloaded JSON file and paste its **entire** contents.
   - Save. Then delete the JSON file from your computer (or keep it somewhere
     private). **Never send it to me.**
5. **Real-time notifications** (renewals, cancellations, refunds reach the server
   immediately):
   - Google Cloud → **Pub/Sub → Topics → Create topic** `play-rtdn`.
   - Open the topic → **Permissions / Add principal**:
     `google-play-developer-notifications@system.gserviceaccount.com`,
     role **Pub/Sub Publisher**.
   - **Create subscription** on the topic: ID `play-rtdn-push`, delivery type
     **Push**, endpoint `https://<your-project-ref>.supabase.co/functions/v1/play-rtdn`,
     **Enable authentication**, service account `acekanner-play@…`, audience: the
     same endpoint URL → Create.
   - Play Console → **Monetize with Play → Monetization setup → Real-time developer
     notifications**: topic name `projects/<your-cloud-project-id>/topics/play-rtdn`
     → Save → **Send test notification**.
   - Send me the **service account email** (public) so I can set the server to
     accept only Google's signed notifications.

---

## What to send me (all public values)

| Value | From |
|---|---|
| Supabase Project URL | Part 1, step 2 |
| Supabase publishable / anon key | Part 1, step 2 |
| Google Web Client ID | Part 2, step 3 |
| Service account email | Part 5, step 2 |

## What you enter yourself (never in chat)

| Secret | Where it goes |
|---|---|
| Supabase database password | Your password manager |
| Supabase access token | The secure form I open in this chat |
| Google Web client secret | Supabase → Authentication → Google |
| Play service-account JSON | Supabase → Edge Functions → Secrets → `GOOGLE_PLAY_SERVICE_ACCOUNT` |
| ACEkanner upload key file + password | I will send it to you once; keep it private (Google Drive or a USB stick). It is needed for every Play upload. |
