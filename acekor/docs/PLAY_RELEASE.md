# ACEkor Grading Sheet: release checklist (Google Play)

The app is built and tested. This checklist lists what is left before the Play upload. Steps marked **owner**
need your Google or Play account; never paste passwords, keystore passwords, the Play
service-account JSON or Supabase tokens in chat.

## 1. Licensing server (Supabase project `acekanner`) ✅ done 2026-11-17

The migration `acekor_licensing` was applied and `acekor-license` was deployed (version 1).
Checks: 4 tables with RLS; 9 functions not callable by clients; the live function answers 401
without a session and 405 for GET; ACEkanner's `license` function is unchanged.
The steps below are kept for reference and re-deployments.

1. Apply `supabase/migrations/20261119000000_acekor_licensing.sql`. It adds only `acekor_*` tables and functions.
2. Deploy the Edge Function `acekor-license`:
   `python3 supabase/tool/deploy_function.py <ref> supabase/functions acekor-license`
3. Optional secret `ACEKOR_PLAY_PACKAGE_NAME` (default `com.acekor.calculator`). It reuses the
   existing secrets `ENTITLEMENT_SIGNING_KEY` and `ENTITLEMENT_KEY_ID`, and needs
   `GOOGLE_PLAY_SERVICE_ACCOUNT` for purchases (not set yet; see §5 step 6).

## 2. Google sign-in

Click-by-click steps for both apps and their current status are in
[`GOOGLE_SIGNIN_SETUP.md`](GOOGLE_SIGNIN_SETUP.md).

1. ~~Consent screen and Web client~~: done. The Web client ID is in both apps' config files.
2. ~~Supabase Google provider~~: done (no client secret needed; both apps sign in natively).
3. Create an **Android** OAuth client with package `com.acekor.calculator` and the SHA-1 of:
   - ~~the upload key~~: done, and
   - after the first upload, the **Play app signing** key (Play Console → Test and release → App integrity).

   Use one Android client per SHA-1.
4. Before the public release, publish the consent screen (**Google Auth Platform → Audience →
   Publish app**). Until then only the listed test users can sign in.

## 3. Upload key ✅ created 2026-11-17

Created by Claude and sent to the owner once: `acekor-upload.jks`, alias `upload`.
- SHA-1: `55:7E:4A:02:F4:0A:50:C3:24:20:09:1A:88:39:E0:52:7F:80:BA:4F`
- The password is on the sheet sent with it.

The key is not in the repository. To build signed bundles in a new session, provide the `.jks`
and create `key.properties` as below.

Reference (how to make a new key, should one ever be needed):

```bash
keytool -genkeypair -v -keystore acekor-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `acekor/app/android/key.properties` (it is never committed):

```
storeFile=/absolute/path/acekor-upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Back up the `.jks` file and its passwords in two safe places.

## 4. Build

```bash
cd acekor/app
flutter build appbundle --release --dart-define-from-file=config/acekor.json
# → build/app/outputs/bundle/release/app-release.aab
```

Before each upload, bump `version:` in `pubspec.yaml` (`1.0.0+1` → `1.0.1+2`).

## 5. Play Console (owner)

Owner's answers (2026-11-18):
- ACEkor goes in the **same personal developer account** as ACEkanner.
- ACEkanner is not on Play yet.
- No payments profile yet.
- 12+ colleagues will be the closed testers.

### Phase A: set up and upload to Internal testing

0. ✅ **Developer website** (2026-11-18): `https://playboydata1994-hue.github.io/acekanner/` is verified
   in Google Search Console with the HTML-file method. **Keep `docs/google19503deee5362079.html`**;
   deleting it removes the verification.
0. ✅ **Trader status** (EU Digital Services Act; required): declared **Trader** by the owner (2026-11-18)
   because the app sells subscriptions. Google verifies the contact details and shows them to EU
   users on the Play listing.
1. **Payments profile:** Play Console → **Settings → Payments profile** → create it: legal name,
   address, and later the bank account that receives subscription income. Paid products cannot be
   created without it.
2. **Create app:**
   - **Home → Create app:** "ACEkor Grading Sheet"; default language English; **App**; **Free**.
   - Tick the declarations.
3. **Internal testing:**
   - **Test and release → Testing → Internal testing → Create new release.**
   - Accept **Play App Signing** (Google keeps the app-signing key; you keep the upload key).
   - Upload `ACEkor-1.0.0-build5.aab`, then save and roll out.
   - **Testers** tab: create a list with your own Gmail; open the opt-in link on the phone and
     install from Play.
4. **Play signing SHA-1:**
   - Copy it from **Test and release → App integrity → App signing key certificate → SHA-1**.
   - Create the Google Cloud Android client "ACEkor Play builds" with it (see
     `GOOGLE_SIGNIN_SETUP.md` §E). Without it, sign-in fails in copies installed from Play.
5. **Subscriptions:** Monetize with Play → Products → Subscriptions. Available once the build with
   the billing permission is uploaded.
   - `acekor_pro_yearly` → base plan `yearly`, auto-renewing, 1 year, ₱399, Philippines (add other
     countries if wanted).
   - `acekor_max_yearly` → base plan `yearly`, auto-renewing, 1 year, ₱499.
   - Activate both base plans.
   - Do **not** add a Play free-trial offer: the 7-day trial is given by the app without payment
     details.
6. **Purchase checks: service account.** Created 2026-11-18:
   **`play-billing@ace-apps-515103.iam.gserviceaccount.com`** (Google Cloud project `ace-apps-515103`).
   `GOOGLE_PLAY_SERVICE_ACCOUNT` not set yet.
   - Google Cloud project "ACE apps":
     - **APIs & Services → Library → Google Play Android Developer API → Enable.**
     - **IAM & Admin → Service accounts → Create:** name `play-billing`, no roles. Then
       **Keys → Add key → JSON** downloads a key file. Keep it private.
   - Play Console → **Users and permissions → Invite new users:**
     - the service account's email;
     - app access: ACEkor (and ACEkanner later);
     - permissions: **View financial data** and **Manage orders and subscriptions**.
   - Supabase → project `acekanner` → **Edge Functions → Secrets → Add:**
     - name `GOOGLE_PLAY_SERVICE_ACCOUNT`, value the whole JSON file's text;
     - never in chat;
     - then delete the downloaded file or store it offline.
   - Google can take up to 24 hours to accept a new service account.
7. **License testing:** Play Console → **Settings → License testing**. Add the Gmail accounts that
   test purchases: test cards, no charge, and a yearly plan renews every 30 minutes.

### Phase B: internal test (owner's phone)

- Install from the Internal testing link.
- Run the device checklist below, including Billing: buy PRO, upgrade to MAX, cancel.

### Phase C: closed test, at least 12 testers for 14 days in a row

Google requires this for apps of personal developer accounts made after November 2023 before
Production.
1. **Store listing:**
   - text in `acekor/store/listing.md`;
   - icon `acekor/store/play_icon_512.png`;
   - feature graphic `acekor/store/feature_graphic_1024x500.png`;
   - phone screenshots `acekor/store/screenshots/` (8 × 1080 × 1920 PNG, no transparency; made by
     `acekor/app/tool/screenshots/`), or real ones.
2. **App content:**
   - Privacy policy: `https://playboydata1994-hue.github.io/acekanner/acekor/privacy/` (live once
     PR #1 is merged).
   - Account deletion URL: `…/acekor/delete-account/`.
   - Ads: no.
   - Target audience: 18+.
   - **Data safety:** see `acekor/store/listing.md` § Data safety.
   - Content rating: Utility/Productivity, no objectionable content.
   - Government app: no. Financial features: no. Health: no.
3. **Testers** (group set-up and invitation messages: `acekor/store/tester_invitation.md`):
   - **Closed testing → Create track** (or use "Alpha").
   - Testers: the Google Group **`acekor-testers@googlegroups.com`** (created 2026-11-18). Invite
     15 or more colleagues in case someone drops out.
   - Roll out the same build, then send them the invitation with the opt-in link.
4. **Testers' access:** every trial started from 2026-11-18 lasts until **January 31, 2027**
   (server table `acekor_trial_floor`, migration `20261120000000_acekor_tester_trial.sql`, live
   since 2026-11-18). Testers need no purchase.
5. Keep at least 12 testers opted in for **14 days in a row**. Collect their feedback; fixes go out
   as new builds on the same track.
6. **Apply for production:** Dashboard → **Apply for production**, and answer Google's questions
   about the test. Review usually takes up to 7 days.

### Phase D: production

- **Before the rollout, end the tester trial** (owner tells Claude, or runs it in the Supabase SQL
  editor): `delete from public.acekor_trial_floor;`. New trials are 7 days again; testers keep
  their January 31, 2027 end date.
- Promote the tested release to **Production**, choose the countries, and roll out.
- Before or at the same time: publish the Google consent screen (§2 step 4).

## 6. Device checklist (needs a real phone)

| Area | Check |
|---|---|
| Install | First start shows Welcome; sample class works; app icon and name are right |
| Calculator | Search "JUAN"; type 42 → "42/50" and "84%"; ⌫; 51 refused; ✓ saves; next student comes up; UNDO |
| Offline | Airplane mode, restart the phone: open, search, record, PDF, Excel, backup — everything works |
| Trial | ✅ 2026-11-18, build 5: Google sign-in → trial started on the server; Plan screen shows "Free trial · 7 days left", November 18 – 25, 2026 |
| Billing | Licence-tester account: buy PRO, exams locked; upgrade to MAX (prorated); cancel in Play → "Expires on" |
| Reminders | Set the phone date to 5 days before expiry at 08:55 → notification at 09:00 with the right date; 1-day reminder |
| Restart | Reminders survive a phone restart |
| Lock | PIN on, lock after 1 minute in background, fingerprint |
| Backup | Create a backup, uninstall, reinstall, restore: all records back |
| Reports | Print preview; share PDF and XLSX to Drive; open the XLSX in Google Sheets (formulas recalculate) |
| Accessibility | Settings › Text size Extra large and the phone's largest font: nothing cut off |
