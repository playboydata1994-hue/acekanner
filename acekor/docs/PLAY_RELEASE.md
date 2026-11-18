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
   existing secrets `ENTITLEMENT_SIGNING_KEY`, `ENTITLEMENT_KEY_ID` and `GOOGLE_PLAY_SERVICE_ACCOUNT`.

## 2. Google sign-in

Click-by-click steps for both apps and their current status are in
[`GOOGLE_SIGNIN_SETUP.md`](GOOGLE_SIGNIN_SETUP.md).

1. ~~Consent screen and Web client~~: done. The Web client ID is in both apps' config files.
2. ~~Supabase Google provider~~: done (no client secret needed; both apps sign in natively).
3. Create an **Android** OAuth client with package `com.acekor.calculator` and the SHA-1 of:
   - the upload key (`keytool -list -v -keystore acekor-upload.jks`), and
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

1. **Create app:** "ACEkor Grading Sheet", free app with in-app purchases, default language English (Philippines or US).
2. **Subscriptions:** Monetize → Products → Subscriptions:
   - `acekor_pro_yearly` → base plan `yearly`, auto-renewing, 1 year, ₱399, Philippines (add other countries if wanted).
   - `acekor_max_yearly` → base plan `yearly`, auto-renewing, 1 year, ₱499.
   - Do **not** add a Play free-trial offer: the 7-day trial is given by the app without payment details.
3. **API access:** under Users and permissions, give the existing Play service account (the one ACEkanner
   uses) access to ACEkor Grading Sheet with "View financial data" and "Manage orders and subscriptions".
4. **Store listing:** text in `acekor/store/listing.md`; icon `acekor/store/play_icon_512.png`; feature graphic
   `acekor/store/feature_graphic_1024x500.png`; phone screenshots from `acekor/app/tool/screenshots/out/`
   (or real ones).
5. **App content:**
   - Privacy policy: `https://playboydata1994-hue.github.io/acekanner/acekor/privacy/`
   - Account deletion URL: `…/acekor/delete-account/`
   - Ads: no.
   - Target audience: 18+, teachers.
   - **Data safety:** see `acekor/store/listing.md` § Data safety.
   - Content rating: Utility/Productivity, no objectionable content.
   - Government app: no. Financial features: no. Health: no.
6. **Testing:** upload the AAB to Internal testing, add tester Gmail accounts, install from the opt-in link,
   then run the device checklist below. Google requires 12+ testers for 14 days in Closed testing for new
   personal developer accounts before Production.

## 6. Device checklist (needs a real phone)

| Area | Check |
|---|---|
| Install | First start shows Welcome; sample class works; app icon and name are right |
| Calculator | Search "JUAN"; type 42 → "42/50" and "84%"; ⌫; 51 refused; ✓ saves; next student comes up; UNDO |
| Offline | Airplane mode, restart the phone: open, search, record, PDF, Excel, backup — everything works |
| Trial | Start trial (Google sign-in) → MAX features; the trial date shows on the Plan screen |
| Billing | Licence-tester account: buy PRO, exams locked; upgrade to MAX (prorated); cancel in Play → "Expires on" |
| Reminders | Set the phone date to 5 days before expiry at 08:55 → notification at 09:00 with the right date; 1-day reminder |
| Restart | Reminders survive a phone restart |
| Lock | PIN on, lock after 1 minute in background, fingerprint |
| Backup | Create a backup, uninstall, reinstall, restore: all records back |
| Reports | Print preview; share PDF and XLSX to Drive; open the XLSX in Google Sheets (formulas recalculate) |
| Accessibility | Settings › Text size Extra large and the phone's largest font: nothing cut off |
