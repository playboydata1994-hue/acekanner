# Play Console — App content declarations

Where: **Play Console → ACEkanner → Policy and programs → App content**. Every item
here must be completed before the app can be sent for review. The answers match the app
as built (version 0.6.4, target Android 16 / API 36).

## Privacy policy

- URL: **[PRIVACY POLICY URL]**, the public page made from `PRIVACY_POLICY.md`.
- The same page opens from the app: **Settings → Privacy and your data → Privacy policy**,
  and from **Plan and account**. (The links appear when the release is built with the
  page addresses; see `PUBLISHING_CHECKLIST.md`, step 4.)

## App access

Choose **"All or some functionality in my app is restricted"** and add these
instructions (name: `Google sign-in`):

```text
Scanning answer sheets requires signing in with Google. Please sign in with any Google
account: Settings > Plan and account > Sign in with Google. No ACEkanner username or
password is needed, and new accounts get 100 free scans.

To test scanning:
1. Exams tab > New examination (for example 50 questions, 1 set) > save.
2. Open it > Answer key > enter the key > save.
3. Open it > Answer sheets > choose A4 or Letter > print one page at actual size.
4. Shade some answers with a dark pen or pencil, then tap Scan papers and point the
   camera at the sheet.

Everything except scanning (classes, examinations, answer keys, printing answer sheets)
works without signing in. Premium is a Google Play subscription; license testers can
buy it without being charged.
```

> For this to work, the Google sign-in consent screen must be **published ("In
> production")** in Google Cloud. While it is in "Testing", only listed test users can
> sign in, so Google's reviewers would be blocked. See `PUBLISHING_CHECKLIST.md`, step 3.

## Ads

**No, my app does not contain ads.**

## Content rating

Start the questionnaire with the email address you use for support.

| Question | Answer |
|---|---|
| Category | **All Other App Types** (Utility, Productivity, Communication, or Other) |
| Violence, fear, sexuality, nudity, crude humour, bad language | No |
| Controlled substances (drugs, alcohol, tobacco) | No |
| Gambling or simulated gambling | No |
| Can users interact or exchange content with each other? | **No** |
| Does the app share the user's current physical location with other users? | **No** |
| Does the app allow users to purchase digital goods? | **Yes** (a Google Play subscription) |
| Does the app contain unrestricted internet access (web browser, search engine)? | **No** |

Expected result: **Everyone / Rated for 3+** with the note "In-app purchases".

## Target audience and content

| Question | Answer |
|---|---|
| Target age groups | **18 and over** only |
| Could the app unintentionally appeal to children? | **No** |

Choosing only 18+ means the Families policy does not apply. Do not tick the younger age
groups: the users are teachers, not students.

## News apps

**No**, my app is not a news app.

## Data safety

Fill it in from `DATA_SAFETY.md`.

## Government apps

**No**, my app is not developed for or on behalf of a government.

## Financial features

**My app doesn't provide any financial features.** (Selling a subscription through Google
Play is not a financial feature.)

## Health

**My app does not have any health features.**

## Advertising ID

**No**, my app does not use an advertising ID. (Checked: the release build does not
include the `com.google.android.gms.permission.AD_ID` permission or an advertising
library. See the permission list below.)

## Permissions in the release build

Checked on the built APK with `aapt2 dump permissions`:

| Permission | Why |
|---|---|
| `android.permission.CAMERA` | Scanning answer sheets |
| `android.permission.INTERNET` | Sign-in, plan check, Premium purchase |
| `android.permission.ACCESS_NETWORK_STATE` | Knowing whether the phone is online (added by the network libraries) |
| `com.android.vending.BILLING` | Google Play subscription (added by Play Billing) |
| `com.acekanner.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | Internal Android permission that AndroidX adds; not shown to users |

No location, contacts, storage, microphone, biometric, notification or advertising ID
permission.

None of these needs a separate permission declaration form. CAMERA is requested only when
you open the scanner. If it is refused, the app explains that the camera is needed to scan
answer sheets and how to allow it.

## Sign-in and account deletion

- Account creation: **Yes**, via Sign in with Google.
- In-app deletion: **Settings → Plan and account → Delete account**.
- Web deletion page: **[ACCOUNT DELETION PAGE URL]**, made from `ACCOUNT_DELETION.md`.
