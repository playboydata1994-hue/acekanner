# ACEkanner Privacy Policy

**Effective date:** [EFFECTIVE DATE]
**App:** ACEkanner (Android, package `com.acekanner.app`)
**Developer:** [DEVELOPER NAME], Philippines
**Contact / Data Protection Officer:** [SUPPORT EMAIL]

ACEkanner helps teachers and instructors check shaded multiple-choice answer sheets with
their phone. This policy explains what information the app handles, where it is kept, and
your rights under the Philippine **Data Privacy Act of 2012 (Republic Act No. 10173)**.

## The short version

- **Your students' information never leaves your phone.** Names, student numbers, answers,
  scores, answer keys and photos of answer sheets are stored only on your phone,
  encrypted. We do not receive them.
- **To use the free scans and Premium, you sign in with Google once.** Our server then
  keeps your Google email address and name, IDs for your account and phones, your scan
  count (as codes that cannot be turned back into student information), and your
  subscription status.
- **No ads, no tracking, no selling of data.**

## 1. Information that stays on your phone

ACEkanner stores the following **only on your phone**, in a database encrypted with
AES-256 (SQLCipher). The key is kept in the Android Keystore.

- Your profile: name, title, school, department, address, employee number, school logo
  (all optional).
- Classes and students: sections, student names, student numbers, email addresses (if
  you enter or import them).
- Examinations, answer keys, scanned answers, scores and results.
- Photos taken while scanning. The original photo is deleted right after the sheet is
  read; a corrected image of the sheet is kept so you can review the reading. It is
  deleted when you delete the examination.

This information is **not uploaded** to our server or to any cloud service, and the app
turns off Android's automatic cloud backup so it is not copied to Google Drive. It leaves
your phone only if **you** print or share a file (for example an answer-sheet PDF). You
choose where that file goes.

Uninstalling the app or clearing its data deletes all of it from your phone.

## 2. Information our server receives

When you sign in with Google (needed to use scanning and Premium), our licensing server
receives and keeps:

| Information | Why |
|---|---|
| Google account email address, name and profile-picture link, and Google account ID (provided by Google Sign-In) | To create and identify your ACEkanner account |
| An account ID created by our server | To link your phones, scans and subscription |
| An install ID for each phone (a random ID created by the app, not a hardware ID) and the app version | To keep your free scans on one phone at a time and to support you |
| Scan records: for each paper counted, a one-way code (SHA-256 hash), its time and plan type | To count your 100 lifetime free scans and never charge a re-scan twice. These codes cannot be turned back into student names, numbers or answers. |
| Google Play subscription details: purchase token, product, status, expiry date, order ID | To confirm Premium with Google Play |
| Sign-in and technical logs kept by our hosting and sign-in services (for example the time of a sign-in or request, the email address used, IP address and device type) | Security and troubleshooting. [PENDING DECISION — sign-in logs: kept for 90 days] |

We do **not** collect your location, contacts, files, payment card details (Google Play
handles payment), or advertising ID. ACEkanner contains no ads and no analytics or
tracking tools.

## 3. How we use it

To provide your account and plan; to count free scans across reinstalls and phones; to
verify purchases and subscription renewals with Google Play; to prevent abuse of the free
plan; to answer your support requests; and to meet legal obligations. Under RA 10173 we
process this information because it is necessary to provide the service you asked for,
with your consent, and for our legitimate interest in preventing fraud.

## 4. Who processes it for us

We share account information only with service providers that run parts of ACEkanner for
us, under their own security and privacy terms:

- **Supabase** — database and server functions, hosted in **Singapore**.
- **Google** — Google Sign-In, Google Play Billing, and the Google Play Developer API and
  Cloud Pub/Sub, which tell our server about purchases, renewals, cancellations and
  refunds.

We do not sell or rent your information, and we share it with no one else unless the law
requires it.

## 5. International transfer

Our server is in Singapore, and Google may process information in other countries. We use
providers that protect information with encryption and access controls.

## 6. How long we keep it

- **Account information** is kept while your account exists.
- **When you delete your account**, we delete your account, phones, scan records and
  subscription records from our server. We keep only a one-way code made from your Google
  account ID and the number of free scans you had used. This prevents "delete and get 100
  new free scans"; it cannot identify you by itself.
- **Sign-in and technical logs**: [PENDING DECISION — sign-in logs: kept for 90 days].
- **Google Play** keeps its own purchase records under Google's policies.
- **Information on your phone** stays until you delete it in the app, clear the app's
  data or uninstall the app.

How to delete your account: [ACCOUNT DELETION PAGE URL]

## 7. Your rights

Under the Data Privacy Act you have the right to be informed, to access, to object, to
correct, to have your information erased or blocked, to data portability, to damages, and
to file a complaint with the **National Privacy Commission** (privacy.gov.ph).

To use these rights, email **[SUPPORT EMAIL]** from the Google account you use with
ACEkanner. We reply within 15 working days.

## 8. Security

- The phone database is encrypted; the key stays in the Android Keystore.
- All connections to our server use HTTPS (TLS).
- Server tables cannot be read by app users; only our server functions can access them.
- Plan information sent to the app is digitally signed, so it cannot be altered.

No system is perfectly secure. Please protect your phone with a screen lock.

## 9. Children and students

ACEkanner is meant for teachers and instructors aged 18 and over, and is not directed to
children. Students do not use the app. Information about students that a teacher enters
stays on the teacher's phone.

## 10. Teachers' responsibility for student information

When you enter or scan your students' information, you (and your school) decide how it
is used. Please follow your school's data-privacy rules, keep your phone locked, and
delete examinations you no longer need.

## 11. Changes

If we change this policy, we will update the effective date above and, for important
changes, tell you in the app.

## 12. Contact

[DEVELOPER NAME] — [SUPPORT EMAIL]

See also: [Terms of Use]([TERMS URL]) · [Delete your account]([ACCOUNT DELETION PAGE URL])
