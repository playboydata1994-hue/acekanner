# ACEKOR Calculator: architecture (Phase 1)

ACEKOR Calculator is an offline-first Android app for college instructors. The app opens
on the academic calculator, where the instructor searches a student, enters a score on a
three-column keypad and saves it with one button. Everything academic is stored only on
the phone, in an encrypted database.

**Core flow:** open the app, search the student, enter the score, save.

## 0. Decisions confirmed with the owner (2026-11-17)

| Topic | Decision |
|---|---|
| Location | Separate app in `acekor/` of the ACEkanner repository; ACEkanner is untouched |
| Package ID | `com.acekor.calculator` (permanent once on Google Play) |
| Licensing | Reuse the ACEkanner Supabase project. One-time Google sign-in; the server verifies Play purchases, records the trial and signs entitlements. No student data is ever sent |
| Renewal | Auto-renewing yearly subscriptions: PRO ₱399, MAX ₱499; PRO→MAX upgrade through Play |
| After trial, no plan | Both calculators compute; SAVE asks to subscribe; roster, records and PDF/Excel exports stay open |
| Combining activities | Total points by default (Σ scores / Σ maximum points); per subject it can be switched to the average of percentages |
| Default grade scale | 1.00–5.00, passing 75% (editable per subject) |
| Grading periods | One weighted grade per subject for the whole semester; activities can carry a period tag (Prelim, Midterm, Pre-final, Finals) for filtering |

## 1. System overview

```
┌──────────────────────────── Android phone ─────────────────────────────┐
│  Flutter UI (Riverpod state, go_router navigation)                     │
│   Academic calculator · Mini calculator · Roster · Subjects · Records  │
│   Reports · Plan · Settings · App lock                                 │
│        │                                                               │
│  Domain (pure Dart, unit-tested)                                       │
│   ScoreEntry · Percent · ExpressionEngine · StudentSearch ·            │
│   GradingEngine · GradeScale · PlanStatus · ReminderSchedule           │
│        │                                                               │
│  Data                                                                  │
│   Drift + SQLCipher database (256-bit key in Android Keystore)         │
│   Repositories · Backup (AES-GCM, password) · Licensing cache          │
│        │                                                               │
│  Services: PDF (pdf/printing) · XLSX (excel_plus) · Share (share_plus) │
│            Local notifications (flutter_local_notifications)           │
└───────────────┬─────────────────────────────────────┬──────────────────┘
                │ only for sign-in / plan check        │ Play Billing
                ▼                                      ▼
   Supabase project "acekanner"                 Google Play
   Edge Function `acekor-license`               (subscriptions acekor_pro_yearly,
   Tables acekor_* (account, trial,              acekor_max_yearly)
   devices, subscriptions)
   → Ed25519-signed entitlement token
```

Nothing academic leaves the phone. The server sees only: the Supabase user ID created by
Google sign-in, a random install ID per phone, Play purchase tokens and the trial dates.

## 2. Technology stack

| Concern | Choice |
|---|---|
| UI | Flutter 3.50 / Dart 3.14, Material 3, Riverpod 3, go_router |
| Database | Drift 2 on SQLCipher 4 (`net.zetetic:sqlcipher-android`), WAL, `synchronous=FULL` |
| Secrets | `flutter_secure_storage` (Android Keystore) for the database key, PIN hash and session |
| PDF | `pdf` + `printing` (print, preview, save) |
| Excel | `excel_plus` (real .xlsx, with formulas) |
| Import | `csv`, `excel_plus`, `file_picker` |
| Sharing | `share_plus` (Android share sheet) |
| Notifications | `flutter_local_notifications` + `timezone` + `flutter_timezone` |
| Biometrics | `local_auth` |
| Billing | `in_app_purchase` + `in_app_purchase_android` |
| Sign-in | `google_sign_in` + `supabase_flutter` |
| Crypto | `cryptography` (Ed25519 verify, AES-GCM, PBKDF2), `crypto` (SHA-256) |

There are no analytics, no ads and no crash-reporting SDKs.

## 3. Modules

| # | Module | Code |
|---|---|---|
| 1 | Calculator engine | `domain/calculator/expression_engine.dart` (mini calculator), `domain/scoring/score_entry.dart` (keypad entry) |
| 2 | Student search engine | `domain/search/student_search.dart` |
| 3 | Academic scoring engine | `domain/scoring/percent.dart`, `data/repositories/scores_repository.dart` |
| 4 | Student management | `data/repositories/students_repository.dart`, `features/roster/` |
| 5 | Subject management | `data/repositories/subjects_repository.dart`, `features/subjects/` |
| 6 | Grading engine | `domain/grading/grading_engine.dart`, `domain/grading/grade_scale.dart` |
| 7 | Academic records | `data/repositories/records_repository.dart`, `features/records/` |
| 8 | Reporting engine | `services/reports/pdf_reports.dart`, `services/reports/xlsx_reports.dart` |
| 9 | Subscription manager | `data/licensing/`, `domain/licensing/`, `features/plan/` |
| 10 | Notification manager | `services/notifications/reminder_service.dart`, `domain/licensing/reminder_schedule.dart` |
| 11 | Local database | `data/db/` (schema in `schema/acekor.drift`) |
| 12 | Backup and restoration | `data/backup/backup_service.dart`, `features/settings/backup_screen.dart` |

## 4. Navigation map

```
Splash (open encrypted DB) ──► App lock (if PIN on) ──► ACADEMIC CALCULATOR (home)
                                                         │
   ┌───────────────┬──────────────┬──────────────────────┼────────────────┐
   ▼               ▼              ▼                      ▼                ▼
 Calculator icon  Settings icon  Class chip             Activity line    Menu icon
 = Mini           = Calculator   (Subject · Section     (choose/create   ├ Students (roster)
 calculator       settings sheet  picker)               activity)        │   ├ Add / edit / profile
 (history, copy)                                                        │   └ Import CSV / Excel
                                                                         ├ Subjects & sections
                                                                         │   ├ Subject: activities,
                                                                         │   │  enrolment, grading
                                                                         │   │  weights, grade scale
                                                                         │   └ Sections
                                                                         ├ Records
                                                                         │   ├ By activity / student
                                                                         │   ├ Accumulated grades
                                                                         │   └ Change history
                                                                         ├ Reports (PDF / Excel)
                                                                         ├ Plan (trial, PRO, MAX)
                                                                         └ Settings
                                                                             ├ Account & school
                                                                             ├ Academic settings
                                                                             ├ Application settings
                                                                             ├ App lock (PIN, fingerprint)
                                                                             ├ Backup & restore
                                                                             ├ Privacy policy
                                                                             └ About ACEKOR
```

Recording a score never needs more than the home screen.

## 5. Home screen wireframe

```
┌────────────────────────────────────────┐
│ ☰                         🖩    ⚙      │  menu · mini calculator · settings
│ [ IT 101 · BSIT 1-A            ▾ ]     │  class chip
│ ┌────────────────────────────────────┐ │
│ │ 🔍  Search student name or number  │ │  dropdown suggestions while typing
│ └────────────────────────────────────┘ │
│ STUDENT: JUAN DELA CRUZ            ✕   │
│ QUIZ 1                             ▾   │
│                                        │
│                42/50                   │  very large
│                 84%                    │  large, under the score
│                                        │
│     ( 7 )      ( 8 )      ( 9 )        │
│     ( 4 )      ( 5 )      ( 6 )        │
│     ( 1 )      ( 2 )      ( 3 )        │
│     ( ⌫ )      ( 0 )      ( ✓ )        │  red backspace · green save
└────────────────────────────────────────┘
```

There is no separate total-points heading, and nothing is shown under the percentage.

## 6. Database (summary; see `DATABASE.md`)

| Table | Purpose |
|---|---|
| `instructor_profile` | One row: instructor, school, department, report header lines |
| `sections` | Course/program, year level, section name, academic year, semester |
| `students` | Student ID (unique when present), names, suffix, program, year level, section, AY, semester, soft-delete |
| `subjects` | Code, title, AY, semester, combine method, grade scale, rounding, grading active |
| `subject_students` | Enrolment (subject × student) |
| `categories` | Built-in and custom assessment categories (Quiz, Recitation, Prelim, Midterm, Final, Written, Practical, Laboratory, Skills demonstration, Performance assessment, Other, custom…) with their tier (PRO/MAX) |
| `subject_weights` | Weight per category per subject, in basis points (3000 = 30.00%) |
| `activities` | Subject, category, number, title, maximum points, date, period tag, remarks, soft-delete |
| `scores` | Activity × student (unique), integer points 0..max, remarks, timestamps |
| `score_history` | Audit trail: created / changed / deleted, old and new points, time |
| `grade_scales`, `grade_scale_rows` | Grade-equivalent tables (default 1.00–5.00) |
| `calc_history` | Mini-calculator history |
| `app_settings` | Key-value settings |
| `license_cache` | The last verified entitlement token |

Integrity: foreign keys on, CHECK constraints on points (0 ≤ points ≤ max, enforced by a
trigger against the activity's maximum), weights (0..10000) and names; `PRAGMA
integrity_check` from Settings › Backup.

## 7. Formulas

All arithmetic on scores is exact (integers / rationals); rounding happens only for
display.

- **Percentage** = score ÷ maximum points × 100. Display: whole numbers without decimals
  (`84%`), otherwise two decimals (`87.50%`).
- **Category percentage** (per student, per subject):
  - *Total points* (default): Σ scores ÷ Σ maximum points × 100 over the category's activities.
  - *Average of percentages*: mean of the activity percentages.
  - A missing score counts as 0 and is listed as "missing".
- **Weighted contribution** = category percentage × category weight (e.g. 88.33% × 30% = 26.50).
- **Final weighted grade** = Σ weighted contributions over all weighted categories.
  While some weighted categories have no activities yet, a *running grade* is shown:
  Σ contributions ÷ Σ weights of the categories that have activities × 100, labelled
  "based on 3 of 5 components".
- **Weights must total exactly 100.00%** before the subject's grading can be activated.
- **Grade equivalent:** the subject's scale is applied to the final percentage. By default
  the percentage is first rounded to a whole number, half up (74.5 → 75). This is a
  per-scale option. Default 1.00–5.00 table: ≥97 → 1.00, ≥94 → 1.25, ≥91 → 1.50,
  ≥88 → 1.75, ≥85 → 2.00, ≥82 → 2.25, ≥79 → 2.50, ≥76 → 2.75, ≥75 → 3.00 (passing),
  below 75 → 5.00 (failed).
- **Class average** of an activity = mean of the recorded percentages (missing excluded,
  count shown).

## 8. Plans and feature gates

| Feature | No plan | Trial (7 days) | PRO ₱399/yr | MAX ₱499/yr |
|---|---|---|---|---|
| Academic calculator (compute) and mini calculator | ✓ | ✓ | ✓ | ✓ |
| Roster, subjects, sections, import | ✓ | ✓ | ✓ | ✓ |
| View records, PDF/Excel export, backup/restore | ✓ | ✓ | ✓ | ✓ |
| Save quiz and recitation scores | — | ✓ | ✓ | ✓ |
| Quiz and recitation weights | — | ✓ | ✓ | ✓ |
| Save examination scores (Prelim, Midterm, Final, Written, Practical, Laboratory, Skills, Performance, Other, custom categories) | — | ✓ | — | ✓ |
| Examination weights and examination reports | — | ✓ | — | ✓ |
| Additional analytics (distribution, highest/lowest, pass rate) | — | ✓ | — | ✓ |

Existing records are never deleted or hidden when a plan ends.

## 9. Subscription architecture

**Products (Google Play Console):**

- `acekor_pro_yearly`, base plan `yearly`, ₱399, auto-renewing.
- `acekor_max_yearly`, base plan `yearly`, ₱499, auto-renewing.

PRO→MAX uses Play's subscription replacement (`CHARGE_PRORATED_PRICE`: immediate, the
difference is charged and the renewal date is kept).

**Server (`supabase/functions/acekor-license`):**

| Action | What it does |
|---|---|
| `checkin` | Registers the phone, re-checks stored Play subscriptions with Google when stale, and returns a signed entitlement |
| `start-trial` | Starts the 7-day trial once per Google account. It is recorded server-side and survives reinstalling and account deletion (a one-way identity hash is kept) |
| `verify-purchase` | Verifies a purchase token with the Play Developer API, acknowledges it, stores it and returns a new entitlement |
| `delete-account` | Deletes the server account (Play policy); local data stays on the phone |

**Entitlement token:** a compact JWS (`EdDSA`, `typ: ACEKOR-ENT+JWS`) with claims

```
v, app="acekor", sub (account), dev (install), plan (none|trial|pro|max),
trial_started, trial_until, plan_until, auto_renew, verified_at, offline_until, iat, jti
```

The app verifies it with the built-in public key and stores it in `license_cache`. Plans
are unlocked only by a verified token, never by a client-side purchase result.

**Offline validity policy:**

- The last verified token is used offline.
- Paid features stay unlocked until the earliest of:
  - `plan_until`, plus 7 days when auto-renew was on (Play renews while the phone is offline);
  - `offline_until` = last check-in + 30 days.
- The trial ends exactly at `trial_until`.
- If the phone's clock is more than 24 hours earlier than the last verification, an
  online check is required.
- The app checks in at start and on resume when the token is older than 12 hours (silent
  when offline).

**Unconfigured test builds:** with no licensing config compiled in, the app runs a
phone-only 7-day trial so every feature can be tested. A Play upload must use the
configured build.

## 10. Reminders (local notifications)

- They are computed from the verified token by `ReminderSchedule` (a pure function, unit-tested).
- **Five days before** `plan_until` at 9:00 local time (id 5001), and optionally **one day
  before** (id 5002, on by default).
- **Trial:** one day before `trial_until` (id 5003).
- Text, when auto-renew is off:

  > ACEKOR CALCULATOR
  > Your MAX subscription will expire in 5 days (December 31, 2027).
  > Renew your subscription to continue enjoying premium academic scoring features.

  When auto-renew is on, it says "renews on December 31, 2027".
- They are scheduled with `zonedSchedule` (inexact, allowed while idle), so no internet is
  needed to deliver them.
- After a reboot, the plugin's boot receiver restores them.
- Every new token cancels and reschedules them with fixed IDs, so no duplicates occur.
  Renewals move them to the new date.
- On Android 13+ the app asks for the notification permission once, when a plan or trial
  starts. Refusal is respected.

## 11. Offline architecture

- **Offline:** all screens except Plan's buy/restore/sign-in actions.
- **Data location:** `getApplicationSupportDirectory()/acekor.db`, encrypted with a
  random 256-bit key held in the Android Keystore.
- **No silent reset:** if the key is lost, a recovery screen keeps the locked file and
  offers restore from backup.
- **Durability:** WAL with `synchronous=FULL`, so every saved score is on disk before
  "Saved" appears.
- **Android backups:** `allowBackup=false`, because the Keystore key cannot travel with an
  Android backup. Settings and the first-run screen warn that uninstalling or clearing
  data erases records without an ACEKOR backup.

## 12. Backup and restoration

- **Format:** a `.acekor` file. A JSON document of every table, with a header (app
  version, schema version, created time, counts), compressed (gzip) and encrypted with
  AES-256-GCM.
- **Key:** derived from a backup password the instructor types (PBKDF2-HMAC-SHA256,
  200,000 iterations, random salt). Without the password the file is unreadable.
- **Saving:** through the Android save dialog or the share sheet (Drive, email, USB). The
  app itself never uploads it.
- **Restore:**
  1. Pick the file.
  2. Enter the password.
  3. Preview the date, file name, size and counts.
  4. Confirm, warned that current data will be replaced.
  5. The restore runs as one database transaction: all or nothing.
  6. An automatic safety copy of the current data is kept first.
- Settings shows the last backup date.

## 13. Security and privacy

- Encrypted database (SQLCipher, AES-256).
- The Keystore holds the database key, PIN hash and session.
- **Optional app lock:**
  - 4–6 digit PIN (PBKDF2 hash plus salt; 5 wrong tries cause an increasing delay).
  - Fingerprint/face through `local_auth`.
  - Locks at start and after 1 minute in the background.
- **Accidental deletion:** students and activities go to Recently deleted (restorable)
  before permanent removal. Every score change is kept in `score_history`.
- **Network:** no student data is transmitted. The network is used only for sign-in and
  plan checks.
- Screens are not excluded from screenshots (instructors share them on purpose).
- **Privacy:** Philippine Data Privacy Act (RA 10173). The privacy policy page lists
  exactly what the licensing server stores.

## 14. Testing strategy

| Area | Tests |
|---|---|
| Keypad entry | Multi-digit, leading zero, over-maximum rejected, backspace on empty, digit cap |
| Percentage | 42/50 = 84%, 35/40 = 87.50%, 0/50, 50/50, 1/3 = 33.33% |
| Mini calculator | Precedence, parentheses, decimals, %, divide by zero, history |
| Search | First/last/full name, student number, partial, accents (ñ), ranking |
| Grading | Total points vs average, missing scores, weights ≠ 100%, running grade, scale lookup, rounding |
| Repositories | Duplicate student IDs, cascade rules, soft delete/restore, audit rows, max-points trigger |
| Import | CSV and XLSX headers in any order, duplicates, blank rows |
| Licensing | Token signature, wrong app/account/phone, offline window, clock tamper, gates per plan |
| Reminders | 5-day and 1-day dates, past dates skipped, renewal reschedule, auto-renew wording |
| Backup | Encrypt/decrypt round trip, wrong password, full DB restore |
| Reports | PDF builds for all 8 types; XLSX sheets, headings and formulas |
| Widgets | Home layout (3 columns, ⌫ under 1, 0 under 2, ✓ under 3), 42/50 then 84%, save flow |
