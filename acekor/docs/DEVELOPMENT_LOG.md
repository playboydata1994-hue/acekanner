# ACEKOR Calculator: development log

Newest entries first.

---

## 2026-11-17 · Upload key, signed bundle 1, sign-in name

Owner's choices: Claude creates the upload key and sends it once; the Google sign-in name is
"ACE apps by NYE94"; open a pull request to `main` so the public pages go live.

- Upload key `acekor-upload.jks` (RSA 2048, PKCS12, alias `upload`, CN=NYE94):
  - SHA-1 `55:7E:4A:02:F4:0A:50:C3:24:20:09:1A:88:39:E0:52:7F:80:BA:4F`.
  - Sent to the owner with its password; not in the repository.
- `ACEKOR-1.0.0-build1.aab` signed with it (`jarsigner -verify`: verified, CN=NYE94).
  - It is a test build: no Web client ID yet, so the trial is phone-only.
  - It is for Internal testing and for getting the Play app-signing SHA-1.
- `pubspec.yaml` is now `1.0.0+2`, so the next bundle never collides with build 1.

## 2026-11-17 · Licensing server deployed

Owner's choices: install the server now; keep NYE94 and the same contact email; one instructor
per phone.

- Applied migration `acekor_licensing` to the live `acekanner` project (recorded in its migration
  history). Deployed Edge Function `acekor-license` (version 1, `verify_jwt` off; the function
  checks the session itself).
- **Verified live:**
  - `acekor_accounts`, `acekor_devices`, `acekor_subscriptions` and `acekor_tombstones` exist with
    row-level security on.
  - The 9 `acekor_*` functions exist, and `authenticated` cannot execute them; `anon` cannot read
    the tables.
  - POST without a session → 401 `not_signed_in`; GET → 405. The function starts, so the shared
    signing-key secrets load.
  - ACEkanner's `license` function still answers.
- `GOOGLE_PLAY_SERVICE_ACCOUNT` is not set yet: purchase checks answer `billing_not_configured`
  until Play is linked. Trial and check-in do not need it.
- **Next:** the owner follows `GOOGLE_SIGNIN_SETUP.md` and sends the Web client ID.
- The public pages in `docs/acekor/` go live when this branch reaches `main`, because GitHub
  Pages serves `main` → `/docs`.

---

## 2026-11-17 · 1.0.0 (build 1): Phases 1–8 built and tested on the host

### Owner's decisions

- **Location and ID:** a separate app in `acekor/` of this repository, package `com.acekor.calculator`.
- **Licensing:** reuse the ACEkanner Supabase project (one-time Google sign-in). No student data is sent.
- **Plans:** auto-renewing yearly PRO ₱399 and MAX ₱499; PRO→MAX upgrade through Play.
- **No plan:** compute, view and export stay open; only SAVE needs a plan.
- **Combining activities:** total points by default; average of percentages per subject.
- **Default scale:** 1.00–5.00, passing 75 %.
- **Grading periods:** one weighted grade per semester; activities can be tagged with a period.

### Built

- **Phase 1 (planning):** `docs/ARCHITECTURE.md` (modules, navigation map, wireframe, formulas,
  plan gates, subscription and offline architecture), `docs/DATABASE.md`.
- **Phase 2 (calculators):**
  - Home academic calculator.
    - Class chip; search with dropdown suggestions (first, last or full name, partial, student ID,
      accent-insensitive, recent students, class members first).
    - `STUDENT:` line; activity line.
    - "42/50" with "84%" underneath; three-column keypad (⌫ under 1, 0 under 2, green ✓ under 3).
    - Over-maximum refusal; replace confirmation; save confirmation with UNDO; continuous entry to
      the next student without a score.
    - Messages appear in their own slot and never cover the keypad.
  - Separate full calculator: + − × ÷, %, parentheses, decimals, ±, ⌫, C, history, copy.
- **Phase 3 (roster and records):**
  - Students: add, edit, profile, move section, delete/restore, CSV/XLSX import with duplicate
    detection and template.
  - Sections; subjects with enrolment (whole section or individuals).
  - Quizzes and recitations with numbering, totals, date, period and remarks; score sheets.
  - Records: weighted grades, accumulated recitation, class averages; change history.
- **Phase 4 (advanced scoring):**
  - MAX examination categories, including custom ones.
  - Grading screen: weights must total 100 %, combine method, scale.
  - Grade-scale editor; MAX analytics (distribution, highest and lowest).
- **Phase 5 (reports):**
  - The 8 PDF report types.
  - XLSX workbook: Roster, Quizzes, Recitations, Examinations, Practical, Summary, Weighted Grade,
    with formulas and cached values.
  - Overall workbook; preview/print, share, save.
- **Phase 6 (plans):**
  - Client: entitlement verification, plan gates, offline policy (30 days, 7-day renewal grace,
    turned-back clock check), Play billing with upgrade, phone-only trial in test builds.
  - Server: `acekor-license` Edge Function and `acekor_*` migration (trial once per Google identity,
    survives account deletion; purchase verification and acknowledgement; upgrade replaces PRO;
    refresh on check-in; delete keeps the sign-in when ACEkanner uses it).
  - Local reminders: 5 days before expiry at 9:00, optional 1 day before, and the trial's last day.
    Fixed IDs, rescheduled on every change, restored after reboot.
- **Phase 7 (security and backup):**
  - SQLCipher database with the key in the Android Keystore; recovery screen.
  - Optional PIN (PBKDF2, growing wait after 5 wrong tries) and fingerprint; relock after 1 minute.
  - Encrypted `.acekor` backups (PBKDF2 + AES-256-GCM): save or share; restore with preview and
    confirmation, all-or-nothing, safety copy first.
  - Integrity check.
- **Phase 8:**
  - Adaptive and legacy launcher icons, Play icon and feature graphic (`tools/generate_brand.py`).
  - Real-font screenshots (`app/tool/screenshots/`).
  - Public privacy, terms and account-deletion pages (`docs/acekor/`).
  - Store listing and data-safety answers; release checklist.

### Verification

| Suite | Result |
|---|---|
| Flutter unit and widget tests | **59 / 59 passed**: domain and licensing 42 (including the server test vectors), repositories, backup and PIN 13, reports 3, full calculator flow 1 |
| `dart analyze` | No issues |
| Deno server tests | **40 / 40 passed** (32 ACEkanner + 8 ACEKOR: handler, SQL signature consistency, cross-language token vectors) |
| `deno check`, `deno lint`, `deno fmt --check` | Clean |
| SQL tests on PostgreSQL 16 | ACEkanner and ACEKOR suites all pass (21 ACEKOR checks) |
| Excel formulas | Cached values removed and the workbook recalculated in LibreOffice: identical to the app's grades |
| PDF reports | All 8 rendered and inspected |
| Android release build | `flutter build apk --split-per-abi` and `flutter build appbundle` succeed. APK: `com.acekor.calculator`, minSdk 24, targetSdk 36, compileSdk 37 (needed by flutter_local_notifications 23 and AndroidX core 1.19), `libsqlcipher.so` bundled, `zipalign -P 16` (16 KB pages) passes; arm64 APK 28.5 MB |

Highlights:

- **Full calculator flow test:**
  - welcome → sample class;
  - keypad positions, and no operator keys on the academic calculator;
  - "42/50" then "84%" underneath, and no repeated raw score;
  - 420 refused, backspace;
  - "JUAN" lists Juan Dela Cruz, Juan Miguel Santos and Juan Carlo Reyes before Mark Juan Garcia;
  - SAVE offers the trial, then saves 42 to the database and moves on to Mark Juan Garcia.
- **Owner's reminder example:** expiry December 31, 2027 → reminder December 26, 2027 at 9:00 with
  the requested wording.

### Open items

- ~~Server deployment~~: done (see the entry above).
- **Google sign-in:** `ACEKOR_GOOGLE_WEB_CLIENT_ID` is still empty (ACEkanner's is too). Until it is
  set, builds are test builds: phone-only trial, purchases off.
- **Owner Play Console steps:** upload key, Play Console app, subscriptions, service-account access.
  See `PLAY_RELEASE.md`.
- **Real-phone checklist** (`PLAY_RELEASE.md` §6): billing, notifications at the real time, reboot,
  fingerprint, share sheet, print. These cannot be run in the build container.
- **Single instructor per phone.** Multiple instructor profiles were optional in the brief and are
  not built.
