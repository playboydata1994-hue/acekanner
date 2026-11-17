# Play Console — Data safety form answers

Where: **Play Console → ACEkanner → Policy and programs → App content → Data safety**.
These answers match what the app and the licensing server actually do (checked against
the code in `app/lib/data/licensing/`, `supabase/functions/` and
`supabase/migrations/20261117000000_licensing.sql`). Update this page and the form
together if the data handling changes.

## Why student data is not declared

Google asks only about data **sent off the phone** ("collected") or **passed to another
company** ("shared"). Data that stays on the phone is not declared. In ACEkanner:

- Student names, student numbers, answers, scores, answer keys and class lists are
  stored only in the encrypted database on the phone. They are never sent to the server.
- Camera photos are processed on the phone. The original photo is deleted right after
  reading; the corrected sheet image stays on the phone.
- The profile (instructor name, school, logo) stays on the phone.
- Android cloud backup is turned off (`android:allowBackup="false"`).

## Section 1 — Data collection and security

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS/TLS to Supabase and Google) |
| Do you provide a way for users to request that their data is deleted? | **Yes** (in the app, and on the web page https://playboydata1994-hue.github.io/acekanner/delete-account/) |

Account creation: **Yes, the app lets users create an account**. Method: **OAuth (Sign in
with Google)**. Account deletion URL: **https://playboydata1994-hue.github.io/acekanner/delete-account/**.

## Section 2 — Data types

Tick only these. For every one, **Shared = No**, **Processed ephemerally = No**,
**Collection = Required** (scanning needs Google sign-in).

| Category → Data type | Collected | Purposes to tick | What it is in ACEkanner |
|---|---|---|---|
| Personal info → **Name** | Yes | Account management | Google account name, received at sign-in |
| Personal info → **Email address** | Yes | Account management | Google account email |
| Personal info → **User IDs** | Yes | App functionality, Account management, Fraud prevention, security, and compliance | Google account ID; ACEkanner account ID |
| Financial info → **Purchase history** | Yes | App functionality, Account management | Google Play subscription purchase token, product, order ID, status and expiry |
| App activity → **App interactions** | Yes | App functionality, Fraud prevention, security, and compliance | Scan records: a one-way hash per scanned paper, its time and plan type, used to count free scans |
| Device or other IDs → **Device or other IDs** | Yes | App functionality, Fraud prevention, security, and compliance | Random install ID made by the app (not a hardware ID or advertising ID), and the app version |

Do **not** tick: Location, Phone number, Address, Race/ethnicity, Political/religious
beliefs, Sexual orientation, Other info, Payment info, Credit score, Other financial info,
Health and fitness, Messages, Photos, Videos, Audio, Files and docs, Calendar, Contacts,
App activity → Page views/In-app search/Installed apps/Other actions, Web browsing, App info
and performance (no crash logs or diagnostics are sent), Advertising ID.

Notes for the reviewer questions:

- **Is this data shared with third parties?** No. Supabase (database host) and Google (sign-in,
  Play Billing) process data **on our behalf** as service providers. Google's guidance says
  transfers to service providers that process data for you are not "sharing".
- **Analytics / advertising purposes:** none. The app has no analytics SDK and no ads.
- **IP address:** the hosting and sign-in services log IP addresses for security. They are not
  used to find a user's location, so Location is not ticked. This is described in the privacy
  policy.

## Section 3 — Security practices shown on the store page

The form shows these automatically from the answers above:

- Data is encrypted in transit ✔
- You can request that data be deleted ✔

Leave **"Independent security review"** unticked (no MASA review has been done).

## Before you submit

- The privacy policy URL in **App content → Privacy policy** must be the same public page
  linked from the app: https://playboydata1994-hue.github.io/acekanner/privacy/.
- The account deletion URL must open without signing in.
