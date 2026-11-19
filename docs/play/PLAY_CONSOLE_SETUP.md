# ACEkanner — Play Console app and subscription, step by step

Owner's decisions (19 Nov 2026):

- Personal developer account (NYE94): **registered and verified**; payments profile **done (19 Nov)**.
- Premium: **PHP 399 per year, Philippines only**.
- **One service account checks purchases for both apps** (ACEkanner and ACEkor).
- First upload: **ACEkanner 0.7.3 (build 21)** app bundle, to **Internal testing**.
- Testers: only the owner's Gmail (the same account as Play Console) for now.
- Public developer name: **NYE94** (the account showed "Playboy94"; the owner changes it in
  Settings → Developer account → Account details → Developer name, 19 Nov 2026).

Do the steps in order. Steps marked ✉ end with something to send me. Nothing in this
guide is a secret except the service-account key file (step 7), which goes **only** into
Supabase, never into the chat.

You need: a computer with the developer Google account, `ACEkanner-0.7.3.aab`, and your
Android phone.

---

## 1. Payments profile (needed before you can sell a subscription) ✅ done 19 Nov 2026

1. Open **play.google.com/console** (developer account).
2. On the page that lists all your apps: left menu **Settings → Payments profile** →
   **Create payments profile**.
3. Account type **Individual**; your legal name and address exactly as on your ID;
   contact name and phone.
4. Save. If Google asks for **tax information** (TIN) or a **bank account**, fill them in
   now or later; payouts need the bank account, testing does not.

It can take a few minutes to a day before Play Console stops saying "Create a payments
profile" on the subscription pages.

## 2. Create the app ✅ done 19 Nov 2026 (package `com.acekanner.app`)

The current Play Console asks for the **package name** on this form: `com.acekanner.app`
→ Check availability.

1. All apps page → **Create app**.
2. App name `ACEkanner` · Default language **English (United States) – en-US** ·
   **App** · **Free**.
3. Tick both declarations (Developer Program Policies, US export laws) → **Create app**.

"Free" is correct: the app is free to download and Premium is sold inside it.

## 3. Upload the first build to Internal testing ✅ done 19 Nov 2026 (release 21 (0.7.3), available to internal testers)

Until the store listing is filled in and reviewed, testers see the temporary name
"com.acekanner.app (unreviewed)". That is normal.

1. Left menu **Test and release → Testing → Internal testing**.
2. Tab **Testers** → **Create email list**: name `ACEkanner testers`, add your own Gmail
   (and any helper's Gmail) → **Save changes**. Tick the list → **Save**.
3. Tab **Releases** (or **Create new release**):
   - **App signing**: keep **Google-generated key (recommended)** → Continue. Google keeps
     the app-signing key; you keep the upload key I sent you earlier.
   - **App bundles → Upload** `ACEkanner-0.7.3.aab`.
   - Release name: leave `21 (0.7.3)`. Release notes (en-US): `First internal test.`
   - **Next** → **Save and publish** (or **Start rollout to Internal testing**).
4. If Play says something is missing before it can publish, open **Dashboard** and do the
   listed task. Answers: App access, Ads, Content rating, Target audience, Data safety and
   the others are in `APP_CONTENT.md` and `DATA_SAFETY.md`; texts and graphics in
   `STORE_LISTING.md`. Privacy policy:
   `https://playboydata1994-hue.github.io/acekanner/privacy/`.

## 4. Play's signing key → Google sign-in for copies installed from Play ✅ done 19 Nov 2026 (client `ACEkanner Play builds`)

App signing key SHA-1 (19 Nov 2026): `A4:94:10:14:71:94:AA:A0:E4:CF:C5:01:88:F8:8F:06:D2:C8:79:B6`.
In the current Play Console it is under **Protected with Play → Play Store protection →
Play App Signing**.

Copies installed from Play are signed by Google's key, not your upload key, so Google
sign-in needs one more Android client.

1. Play Console → ACEkanner → **Test and release → App integrity → App signing**.
   Copy the **SHA-1** under **App signing key certificate** (not "Upload key").
2. **console.cloud.google.com** → project **ACE apps** → **Google Auth Platform →
   Clients → Create client**:
   - Application type **Android**
   - Name `ACEkanner Play builds`
   - Package name `com.acekanner.app`
   - SHA-1: paste it → **Create**.
3. ✉ Send me that SHA-1 (it is public) so I record it.

## 5. License testers (test purchases are never charged) ✅ done (list "Owner", RESPOND_NORMALLY)

Direct link: `https://play.google.com/console/u/0/developers/<account ID>/license-testing`.
Google sign-in in the Play-installed app was checked on the owner's phone on 19 Nov 2026.

1. All apps page → left menu **Settings → License testing**.
2. Add the same Gmail account(s) as in step 3.
3. License response **RESPOND_NORMALLY** → **Save changes**.

Test subscriptions bought by these accounts use test cards; a yearly plan renews every
30 minutes and ends after 6 renewals.

## 6. The Premium subscription ✅ done 19 Nov 2026

`acekanner_premium_yearly`: icon = app icon, benefits and description set; base plan `yearly`
**Active**: auto-renewing, 1 year, PHP 399, Philippines only, grace period 7 days, account
hold on. Tax category: Digital app sales · Service. On the base plan, first **Manage country /
region availability** (Philippines only), then **Set prices**; otherwise Play shows "One or
more countries / regions have an error".

Available once the bundle from step 3 is uploaded (it contains the billing permission)
and the payments profile from step 1 exists.

1. ACEkanner → **Monetize with Play → Products → Subscriptions → Create subscription**:
   - Product ID **`acekanner_premium_yearly`** (exactly; it can never be changed)
   - Name `ACEkanner Premium` → **Create**.
2. On the subscription page:
   - **Benefits**: `Unlimited answer-sheet scans`, `All features, no ads`,
     `Keep Premium when you change phones`.
   - **Description**: `Unlimited answer-sheet scans for one year.` → **Save**.
3. **Add base plan**:
   - Base plan ID **`yearly`**
   - Type **Auto-renewing** · Billing period **1 year**
   - Grace period **7 days** · Account hold **on** · Resubscribe **allow**
   - **Prices and availability → Set prices**: keep only **Philippines**, price
     **PHP 399.00** → **Update**. Remove the other countries/regions if they are listed.
   - **Save** → **Activate**.
4. Do **not** add offers or a free trial: the app already gives 100 free scans.
5. Countries for the app itself: **Test and release → Production → Countries / regions**
   → add **Philippines** only (testing tracks have their own country list; add
   Philippines there too if asked).

## 7. One service account that checks purchases for both apps ✉

Created 19 Nov 2026: **`play-billing@ace-apps-515103.iam.gserviceaccount.com`**
(Google Cloud project ID `ace-apps-515103`, project name "ACE apps").
JSON key created (kept by the owner). Invited in Play Console → Users and permissions:
**Active** (19 Nov 2026), app permissions on **ACEkanner** and **ACEkor Grading Sheet** (4 each).
Supabase secret `GOOGLE_PLAY_SERVICE_ACCOUNT` set by the owner with this key (19 Nov 2026).

The server uses it to ask Google whether a purchase is real. Until it works, a test
purchase **does not turn Premium on**. That is on purpose: the app never trusts the
phone's "purchase succeeded" message alone.

1. **console.cloud.google.com** → project **ACE apps** → **APIs & Services → Library**:
   enable **Google Play Android Developer API** and **Cloud Pub/Sub API**.
2. **IAM & Admin → Service accounts → Create service account**:
   name `play-billing` → **Create and continue** → no roles → **Done**.
3. Open `play-billing` → **Keys → Add key → Create new key → JSON → Create**.
   A file downloads. **Keep it private; never send it to me.**
4. Play Console (all apps page) → **Users and permissions → Invite new users**:
   - Email: `play-billing@…iam.gserviceaccount.com` (shown on the service account page)
   - **App permissions → Add app → ACEkanner** (add ACEkor too once it exists)
   - Tick **View financial data** and **Manage orders and subscriptions** → **Apply**
     → **Invite user**.
5. **supabase.com** → project **acekanner** → **Edge Functions → Secrets → Add new secret**:
   - Name `GOOGLE_PLAY_SERVICE_ACCOUNT`
   - Value: open the downloaded JSON file in a text editor and paste **all** of it → **Save**.
   - Then delete the downloaded file (or keep it offline, e.g. on a USB stick).
6. ✉ Send me the service account **email** (public).

Google can take **up to 24 hours** before a new service account is accepted. If a test
purchase stays "pending verification" on the first day, wait and tap **Restore** later.

## 8. Real-time notifications (renewals, cancellations, refunds) ✉

19 Nov 2026: topic `play-rtdn` created with Play as publisher; Supabase secrets
`RTDN_AUDIENCE` and `RTDN_SERVICE_ACCOUNT_EMAIL` set. Check from outside: an unsigned POST to
`/functions/v1/play-rtdn` now answers **401 unauthorized** (was 503 not_configured), so the
audience, the service-account email and a well-formed `GOOGLE_PLAY_SERVICE_ACCOUNT` key are all
loaded.

1. Google Cloud (project **ACE apps**) → **Pub/Sub → Topics → Create topic**:
   Topic ID `play-rtdn` (untick "Add a default subscription") → **Create**.
2. Open the topic → **Permissions** (right panel; "Show info panel") → **Add principal**:
   `google-play-developer-notifications@system.gserviceaccount.com`, role
   **Pub/Sub Publisher** → **Save**.
3. **Subscriptions → Create subscription**:
   - Subscription ID `play-rtdn-push`, topic `play-rtdn`
   - Delivery type **Push**, endpoint
     `https://ajmdnsdhrpktkvkxnmuo.supabase.co/functions/v1/play-rtdn`
   - Tick **Enable authentication**, service account `play-billing@…`,
     audience: the same endpoint address → **Create**.
4. Play Console → ACEkanner → **Monetize with Play → Monetization setup →
   Real-time developer notifications**:
   - Topic name `projects/ace-apps-515103/topics/play-rtdn`
   - If there is a choice of notification content, keep the one that includes
     **subscriptions and voided purchases** (refunds) → **Save** → **Send test notification**.
5. ✉ Tell me when it is saved. I then set the server to accept only notifications signed
   for `play-billing` and this address.

## 9. Install from Play and test on your phone

0. While the Google sign-in consent screen is in "Testing", only its listed test users can
   sign in: Google Cloud → **Google Auth Platform → Audience → Test users** → add the
   tester Gmail if it is not there yet.
1. Uninstall the ACEkanner APK you installed by hand (Play cannot update it; it is signed
   differently). Your local data on the phone is deleted with it.
2. Internal testing → **Testers** → **Copy link** under "How testers join your test".
   Open it on the phone (signed in with the tester Gmail) → **Accept** → **Download it
   on Google Play** → Install.
3. Check:
   - Google sign-in works (Settings → Plan and account).
   - The free-scan counter goes down by one when you save a paper or quick-check one.
   - **Plan → Get Premium** shows **PHP 399 / year**; buy with **Test card, always
     approves**. Premium turns on after the server confirms it (step 7 must be working).
   - Cancel in Play Store → Payments & subscriptions; Premium stays until the paid
     period ends (30 minutes for test subscriptions).
   - **Restore purchase** on the Plan screen brings Premium back after reinstalling.

---

## What to send me

| Value | From |
|---|---|
| App signing key SHA-1 | Step 4 |
| Service account email | Step 7 |
| "Notifications saved" | Step 8 |
| Anything Play Console showed that does not match this guide (a screenshot is fine) | Any step |

## Still to do before the public release

- Publish the Google sign-in consent screen (**Google Auth Platform → Audience → Publish
  app**), or Google's reviewers and your testers cannot sign in.
- Closed test: at least 12 testers opted in for 14 days in a row (`PUBLISHING_CHECKLIST.md`,
  step 8).
