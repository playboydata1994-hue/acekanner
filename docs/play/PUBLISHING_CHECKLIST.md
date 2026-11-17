# ACEkanner — Google Play publishing checklist

Follow the steps in order. Each step names the document that has the exact text or
answers. Steps marked **(you)** are done in your Google accounts; steps marked
**(Claude)** I do here.

| Document | Used for |
|---|---|
| `PRIVACY_POLICY.md` | Public privacy policy page (required) |
| `TERMS_OF_USE.md` | Public terms page (linked from the app and the store) |
| `ACCOUNT_DELETION.md` | Public account-deletion page (required: the app has sign-in) |
| `DATA_SAFETY.md` | Data safety form |
| `APP_CONTENT.md` | All other App content declarations, including reviewer access |
| `STORE_LISTING.md` | Name, descriptions, graphics, screenshots, subscription text, release notes |
| `../PHASE6_SETUP.md` | Google sign-in, Play Console app, subscription and server set-up |

## Step 1 — Decisions (you)

- [ ] **Developer name** shown on the store and in the documents (your name or a business
      name). The name must match your Play developer account.
- [ ] **Support email** shown publicly on the store. A separate address for ACEkanner
      (for example a new Gmail) is better than your personal one.
- [ ] **Developer account type**: personal or organisation (see step 6).
- [ ] **Where the three pages are hosted** (privacy, terms, account deletion). They must be
      public web pages that open without signing in.
- [ ] **Sign-in log retention**: whether sign-in logs on the server are deleted after
      90 days (the documents say so once you agree and it is switched on).

## Step 2 — Publish the pages (Claude, then you)

- [ ] Fill in the placeholders in the three documents (`[DEVELOPER NAME]`,
      `[SUPPORT EMAIL]`, `[EFFECTIVE DATE]`, the page addresses).
- [ ] Turn them into web pages and publish them where you chose.
- [ ] Open each address on your phone, while signed out, and check it loads.

## Step 3 — Google sign-in (you, with Claude)

- [ ] Phase 6 setup **Part 2**: Google Cloud project, consent screen, Web and Android
      clients, Google provider in Supabase. Send me the Web client ID.
- [ ] Consent screen **Branding**: app name `ACEkanner`, support email, logo optional,
      **App home page**, **Privacy policy link** and **Terms of service link** = your pages,
      authorised domain = the domain of your pages.
- [ ] Consent screen **Audience → Publish app** (status "In production"). ACEkanner asks
      only for name, email and profile picture, which normally does not need Google's
      verification. Adding a logo can require brand verification (a few days), so leave the
      logo out if you want it to be quick.

## Step 4 — Release build (Claude)

- [ ] Put the Web client ID and the three page addresses in `app/config/acekanner.json`
      (`ACEK_GOOGLE_WEB_CLIENT_ID`, `ACEK_PRIVACY_POLICY_URL`, `ACEK_TERMS_URL`,
      `ACEK_ACCOUNT_DELETION_URL`).
- [ ] Build the signed app bundle:
      `flutter build appbundle --release --dart-define-from-file=config/acekanner.json`.
- [ ] Check: targets Android 16 (API 36) ✔ (required for new apps since 31 Aug 2026);
      permissions match the list in `APP_CONTENT.md` (camera, internet,
      network state, Play Billing); no advertising ID.

## Step 5 — Play Console developer account (you)

- [ ] Register at play.google.com/console (one-time USD 25 fee) and complete **identity
      verification**. An organisation account also needs a **D-U-N-S number** (free, can
      take a few weeks).
- [ ] **Payments profile** and **merchant account** (Setup → Payments profile), needed to
      sell the subscription. Add bank details to receive payouts.

## Step 6 — Create the app and fill in App content (you)

- [ ] **Create app** (Phase 6 setup, Part 3, step 1).
- [ ] App content: privacy policy, app access, ads, content rating, target audience, news,
      data safety, government apps, financial features, health, advertising ID
      (`APP_CONTENT.md`, `DATA_SAFETY.md`).
- [ ] Main store listing, store settings and graphics (`STORE_LISTING.md`).
- [ ] Countries and regions: start with **Philippines** (add more later if you want).

## Step 7 — Internal testing and the subscription (you, with Claude)

- [ ] Phase 6 setup **Part 3** (testers, license testing) and **Part 4** (first upload,
      Play signing SHA-1, subscription `acekanner_premium_yearly`).
- [ ] Phase 6 setup **Part 5** (server checks purchases; real-time notifications).
- [ ] Test on your phone with a license-tester account: sign in, 100 free scans counter,
      buy Premium (test card, no charge), cancel, restore, delete account.

## Step 8 — Closed test (you) — personal accounts only

New **personal** developer accounts must run a closed test before they can publish to
everyone:

- [ ] Create a **Closed testing** track and release the same bundle there.
- [ ] At least **12 testers** must opt in and stay opted in for **14 days in a row**.
      Collect their Gmail addresses (teacher friends and colleagues are ideal), add them
      to the tester list, and send them the opt-in link.
- [ ] Ask them to really use it (create an exam, print a sheet, scan) and to send feedback.
- [ ] After 14 days: **Dashboard → Apply for production** and answer the questions about
      the test.

Organisation accounts skip this step.

## Step 9 — Production release (you)

- [ ] **Production → Create new release**, same or newer bundle, release notes from
      `STORE_LISTING.md` → **Send for review**. Reviews usually take a few days, sometimes
      longer for a new developer account.
- [ ] After approval, open the store page on your phone and check the listing, the Data
      safety section and the subscription.

## After launch

- [ ] Watch **Quality → Android vitals** (crashes, freezes) and the **pre-launch report**.
- [ ] Answer reviews and support emails.
- [ ] Each update: raise `version` in `app/pubspec.yaml`, write release notes, and check
      that `DATA_SAFETY.md` is still true.
- [ ] Keep the upload key file and its password safe. Without them you cannot publish
      updates without a key reset from Google.
