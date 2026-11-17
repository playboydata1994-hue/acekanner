# ACEkanner — System Architecture (Phase 1)

Status: **approved baseline for Phases 2–9.** Changes to this document are recorded in
[`DEVELOPMENT_LOG.md`](DEVELOPMENT_LOG.md).

ACEkanner is an offline-first Android app that lets college instructors print standardized
answer sheets, scan the shaded sheets with the phone camera, grade them against an answer
key and export reports. Scanning, recognition, grading and reporting never need the internet.
The internet is needed only to sign in once, to buy or re-verify Premium, and for optional
cloud backup.

Confirmed product decisions (from the owner):

| Decision | Value |
|---|---|
| Package / application ID | `com.acekanner.app` |
| Sheet sizes (items) | 50, 75, 100 |
| Choices per item | 5 (A–E) |
| Language | English |
| Student identification | Shaded student-number grid on every sheet **and** optional personalized sheets with a per-student QR code |
| Free-scan protection | One-time Google sign-in; lifetime count kept on a Supabase backend |
| Backend | Supabase (Auth + Postgres + Edge Functions), used only for licensing, recovery and opt-in backup |
| Paper sizes | A4, US Letter, 8.5×13 in ("long bond") |

---

## 1. System architecture

```
┌──────────────────────────── Android phone (works fully offline) ───────────────────────────┐
│                                                                                             │
│  Flutter UI (Dart, Material 3)                                                              │
│   screens ─ widgets ─ Riverpod controllers ─ go_router                                      │
│        │                                                                                    │
│  Application services (pure Dart, unit-tested)                                              │
│   ExamService · AnswerKeyService · GradingEngine · AnalyticsService · ReportService         │
│   ScanWorkflow · ScanLedger · EntitlementService · BackupService · AuditLog                 │
│        │                         │                                     │                    │
│  Data layer                      │ platform channel (binary + JSON)    │                    │
│   Drift ORM ── SQLCipher DB      ▼                                     │                    │
│   (AES-256, key in Keystore)   Kotlin OMR engine (OpenCV 4.14)         │                    │
│   App-private files            · marker detection · perspective warp   │                    │
│   (scans, reports)             · bubble scoring · QR decode            │                    │
│   flutter_secure_storage       · image-quality checks                  │                    │
│   (DB key, device key,                                                 │                    │
│    signed entitlement)                                                 │                    │
│                                                                        │ only when online   │
└────────────────────────────────────────────────────────────────────────┼────────────────────┘
                                                                         ▼
              ┌──────────────────────── Supabase (licensing only) ────────────────────────┐
              │ Auth: Google ID-token sign-in                                              │
              │ Edge Functions: verify-purchase · play-rtdn · sync-ledger · entitlement    │
              │ Postgres (RLS): accounts · devices · purchases · scan_consumptions         │
              │ Ed25519 private key (secret) signs entitlement tokens                     │
              └───────────────┬────────────────────────────────────────────────────────────┘
                              │ service account (secret, server-side only)
                              ▼
              Google Play Developer API (subscriptionsv2.get, acknowledge, voided purchases)
              Google Play Real-time Developer Notifications (Pub/Sub push → play-rtdn)
```

Principles:

1. **Offline core.** Exam setup, sheet generation, scanning, OMR, grading, analytics,
   PDF/Excel/CSV export and printing all run on the device with no network.
2. **Deterministic recognition.** Answers are read with classical image processing
   (OpenCV). No generative AI and no cloud recognition.
3. **Never guess.** Any mark the engine is not sure about is flagged for the instructor.
   It is never silently scored as correct or incorrect.
4. **Student data stays on the phone.** Nothing about students, papers or results leaves
   the device unless the instructor explicitly turns on cloud backup. The licensing
   server only ever receives salted hashes and counts.
5. **Server-trusted licensing.** Premium is granted only from a server-signed entitlement,
   never from a client-side "purchase succeeded" callback or an editable flag.

### Why the OMR engine is Kotlin + OpenCV (not a Dart OpenCV binding)

The Dart OpenCV bindings (`opencv_dart`) download prebuilt native libraries from GitHub
during the build. The official OpenCV Android library is published on Maven Central
(`org.opencv:opencv:4.14.0`, 16 KB page-aligned as Google Play requires). Using it from a
Kotlin module behind a platform channel gives:

- the official, maintained OpenCV build;
- full-speed native processing of 12-megapixel photos with no copying through Dart;
- host-side unit tests: the same Kotlin sources compile against
  `org.openpnp:opencv` (desktop OpenCV with Linux natives) for JVM tests that run in CI
  without a phone.

Trade-off: an iOS version would need the engine ported (Swift + OpenCV). The app is
Android-first, so this is accepted.

---

## 2. Technology stack and dependencies

Versions are the current stable releases as of November 2026 and are pinned in
`app/pubspec.lock` and the Gradle files.

| Area | Choice | Notes |
|---|---|---|
| SDK | Flutter 3.50.0, Dart 3.14 | Material from `package:material_ui` (the Flutter 3.47+ split) |
| Android | compileSdk/targetSdk 36, minSdk 24, AGP 9.3, Gradle 9.5, NDK r28c | 16 KB page-size compliant |
| State | `flutter_riverpod` 3.x | No code generation for providers |
| Navigation | `go_router` 18.x | Declarative routes, redirect for onboarding |
| Database | `drift` 2.35 + `sqlite3` 3.9 | Schema written in SQL (`.drift` files) |
| DB encryption | SQLCipher 4.20 (`net.zetetic:sqlcipher-android`, Maven Central) | Loaded by `sqlite3` with `source: system, name: sqlcipher` |
| Secrets on device | `flutter_secure_storage` 11.x | Android Keystore-backed |
| Computer vision | OpenCV 4.14.0 (Maven Central AAR) in Kotlin | ArUco markers, homography, QR decoding |
| Camera | `camera` 0.12 (CameraX) | Preview + still capture, focus/exposure points |
| PDF / printing | `pdf` 3.13, `printing` 5.15 | Answer sheets and reports, Android print service |
| Excel / CSV | `excel_plus` 2.29, `csv` 8.0 | Fully offline export. `excel_plus` (MIT) replaces `excel`, which has been unmaintained since 2024 and conflicts with the current `pdf` package. |
| Crypto | `cryptography` 2.9 | Ed25519 verify, HMAC-SHA256, AES-GCM for backups |
| Billing | `in_app_purchase` 3.3 (Play Billing Library 8) | Subscription `acekanner_premium_yearly` |
| Sign-in | `google_sign_in` 7.x → Supabase `signInWithIdToken` | One-time, online |
| Backend client | `supabase_flutter` 2.x | Licensing calls only |
| Sharing / files | `share_plus`, `file_picker`, `path_provider` | |
| IDs | `uuid` 4.x (UUID v7, time-ordered) | |

**Play product ID correction:** Google Play product IDs must be lowercase
(letters, digits, `_` and `.`). `ACEKANNER_PREMIUM_YEARLY` is rejected by Play Console, so
the product is **`acekanner_premium_yearly`**, with base plan **`yearly-autorenew`**
(PHP 399, 1-year auto-renewing).

---

## 3. Project directory structure

```
acekanner/
├── README.md
├── docs/
│   ├── ARCHITECTURE.md          ← this file
│   ├── DATABASE.md              ← table-by-table schema reference
│   ├── sql/                     ← exported SQL migration scripts (v1, v2, …)
│   ├── DEVELOPMENT_LOG.md       ← progress log, known issues, next steps
│   └── (later) OMR_TEST_PROTOCOL.md, PLAY_RELEASE.md, PRIVACY_POLICY.md, USER_MANUAL.md
├── app/                         ← Flutter application
│   ├── lib/
│   │   ├── main.dart            ← bootstrap: DB open, providers, error handling
│   │   ├── app/                 ← AcekannerApp, router, bootstrap
│   │   ├── core/
│   │   │   ├── theme/           ← colors, typography, spacing, Material 3 theme
│   │   │   ├── widgets/         ← reusable components (StatCard, SectionHeader, EmptyState…)
│   │   │   └── util/            ← ids, clock, formatting, result types
│   │   ├── data/
│   │   │   ├── db/              ← Drift database, .drift schema, DAOs, migrations
│   │   │   └── secure/          ← key management (DB key, device key)
│   │   └── features/
│   │       ├── splash/  onboarding/  dashboard/  settings/
│   │       ├── exams/  answer_key/  students/          (Phase 3)
│   │       ├── sheets/  scanner/                       (Phase 4)
│   │       ├── grading/  analytics/                    (Phase 5)
│   │       ├── subscription/                           (Phase 6)
│   │       └── reports/                                (Phase 7)
│   ├── android/app/src/main/kotlin/com/acekanner/app/
│   │   ├── MainActivity.kt
│   │   └── omr/                 ← OMR channel + engine (Phase 4)
│   └── test/                    ← unit + widget tests
├── omr_engine/                  ← (Phase 4) JVM test harness for the shared Kotlin OMR sources
└── backend/supabase/            ← (Phase 6) SQL migrations + Edge Functions (TypeScript)
```

Layering rule: `features/*` may depend on `core/` and `data/`; `data/` never imports
`features/`; the grading and licensing logic is pure Dart with no Flutter imports, so it is
unit-tested without a device.

---

## 4. Database schema (summary)

Full reference: [`DATABASE.md`](DATABASE.md). Source of truth:
`app/lib/data/db/schema/*.drift` (plain SQL `CREATE TABLE` / `CREATE INDEX` /
`CREATE TRIGGER`).

- UUID v7 text primary keys (sortable, merge-safe for backup/restore).
- Timestamps stored as Unix epoch seconds (`DATETIME` in Drift).
- Foreign keys enforced (`PRAGMA foreign_keys = ON`).
- Soft delete (`deleted_at`) on instructor-managed master data. Derived scan data is hard
  deleted only when its examination is permanently purged.
- `scan_ledger` and `audit_logs` are **append-only**: SQLite triggers abort `DELETE` and any
  `UPDATE` other than sync bookkeeping. Each row stores a SHA-256 hash chain, plus an
  HMAC (keyed by a per-install secret in the Keystore) on ledger rows.
- Every multi-row write (finalize a scan, regrade, import roster) runs in one transaction.

Tables: `instructor_profiles`, `subjects`, `courses`, `sections`, `section_students`,
`students`, `examinations`, `examination_sections`, `examination_versions`, `answer_keys`,
`answer_key_items`, `printed_sheets`, `scan_sessions`, `answer_sheets`, `student_answers`,
`examination_results`, `subscription_entitlements`, `scan_ledger`, `audit_logs`,
`application_settings`, `backup_records`.

These are the 18 required tables, plus three join/support tables:
`section_students`, `examination_sections` and `printed_sheets`.

### Android permissions

| Permission | Why |
|---|---|
| `CAMERA` | Scanning (requested only when the scanner opens) |
| `INTERNET`, `ACCESS_NETWORK_STATE` | Sign-in, Premium verification, opt-in backup |
| `BILLING` | Google Play subscription |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | Optional app lock (normal permissions, never prompted) |

Removed on purpose (plugins declare them for features ACEkanner doesn't use):
`RECORD_AUDIO`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`.

---

## 5. OMR algorithm design

### 5.1 Answer-sheet template (designed for machine reading)

All three item counts share one **paper-size-independent frame** of 190 × 250 mm. It is
centered on A4, Letter or 8.5×13 paper, so the OMR geometry is identical for every paper
size.

- **Four ArUco corner markers** (OpenCV `DICT_4X4_50`, 10 mm), one in each frame corner.
  The marker IDs encode the sheet design, template and orientation (TL, TR, BR, BL):

  | Design | 50 items | 75 items | 100 items |
  |---|---|---|---|
  | 3 — circles, letter inside, dark outline (current, from 0.5.2) | IDs 24–27 | 28–31 | 32–35 |
  | 2 — ovals (test build 0.5.1, retired) | 12–15 | 16–19 | 20–23 |
  | 1 — first circles (test builds 0.4–0.5, retired) | 0–3 | 4–7 | 8–11 |

  A photo taken upside down or of the wrong template is detected immediately. A sheet of
  a retired design is rejected with "older sheet design, print new sheets" and is never
  read with the wrong geometry.
- **QR code** (top right): `ACK3|<exam code>|<items>|<id digits>|<sets>|G` on generic
  sheets, or `…|P<sheet code>` on personalized ones. The number after `ACK` is the
  sheet design.
  Generic sheets carry the exam identity. Personalized sheets also carry a per-student sheet
  code, which links the paper to the roster with no shading needed.
- **Student-number grid**: one column of bubbles 0–9 per digit. The number of columns
  follows the school's ID format (for example `####-#####` gives 9 columns; up to
  12 supported). Write-in boxes sit above each column.
- **Exam set row** (A–E) for exams with shuffled versions. Rows of 2–4 sets start under the QR code's left edge; a 5-set row starts 5.8 mm further left so it fits inside the frame (clear of a 12-digit student-number grid).
- **Answer area**: 25 rows per column. 50 items = 2 columns, 75 = 3, 100 = 4.
  5 **circles** (A–E) per item, 4.6 mm across, with the letter printed inside;
  6.4 mm horizontal and row pitch. Student-number circles are 3.5 mm across, 5.0 mm
  apart and 4.6 mm between rows. Outlines are dark grey (0.3 mm) and the letters light
  grey, so they add little "ink" to the reading. Every bubble is at least 1 mm from
  its neighbours (a unit test checks this). The geometry stores each bubble's
  half-width and half-height, so the engine reads any bubble shape the same way.
- Student instructions printed on the sheet (shade one circle completely, dark pencil
  or pen, erase cleanly, don't fold across the markers), with a **correct / wrong
  shading example** (filled circle vs. check, cross, half and dot).
- **Header**: school name, examination title, subject and date. An optional **school
  logo** (11 × 11 mm, beside the top-left marker, outside its quiet zone) and an
  optional **instructor name** (footer). Both are switched on or off on the Answer
  sheets screen; the logo is added in Profile. The footer also names the form
  (e.g. `ACK3-75`) so a sheet's design can be identified on paper.

The exact coordinates come from one Dart layout function. It produces both the PDF and a
JSON geometry file that the Kotlin engine reads. A unit test fails the build if the two ever
disagree.

### 5.2 Recognition pipeline (Kotlin, OpenCV)

Source: `app/android/app/src/main/kotlin/com/acekanner/app/omr/core/OmrEngine.kt`.
The pipeline below is as built and tested in Phase 4. It changed from the first plan
in steps 4 and 5, because of what the tests showed.

1. **Capture.** A 1080p still from CameraX. Live preview frames (luminance plane,
   downscaled to 720 px) only run marker detection, to drive the on-screen guidance and
   auto-capture (all four corners found and steady for 3 frames).
2. **Marker detection.** ArUco `DICT_4X4_50` with sub-pixel corner refinement. All
   four markers of the template must be found. Their IDs give the sheet design,
   the template (50/75/100) and the orientation, so a sheet photographed sideways
   or upside down is fine. Markers of another template give "wrong sheet type";
   markers of an older design give "older sheet design".
3. **Perspective correction.** A homography from the 16 marker corners to the
   canonical frame (8 px/mm), then `warpPerspective`. A leave-one-out marker check
   rejects only gross distortion: at phone resolutions, extrapolating one corner
   from the other three is too noisy for anything finer.
4. **Quality gate**, checked in this order: contrast (paper minus marker ink), then
   focus, then glare. Focus is measured as the **10–90 % edge width of the corner
   markers in mm**. This replaced the Laplacian variance, which sensor noise kept
   artificially high on blurred photos.
5. **Flat-field normalization**, then **local alignment.** For each block of about
   40 answer bubbles (each column split into thirds) and for the student-number
   grid, the engine searches ±2.5 mm for the shift that best aligns the printed
   bubble outlines. This corrects slight curl, lens distortion and corner noise; flat
   sheets need about 0.2 mm. A block needing more than 2 mm means a folded or
   curled sheet, and the photo is rejected.
6. **Bubble scoring**: darkness of the inner area (62 % of the bubble's half-width and
   half-height, so it excludes the printed outline), at the aligned position.
7. **Per-sheet calibration**: the empty level is the 40th percentile of all bubble
   scores. The filled level is the median of the clearly marked per-question maxima.
8. **Classification**: see §5.3. Then the student-number columns, the set row,
   and the QR code (decoded inside its known box).
9. **Output**: JSON with per-question state, scores and confidence, the
   student number, set, QR, quality metrics and engine version. A
   perspective-corrected JPEG (1520×2000) is saved for the review screen. The
   original photo is deleted immediately after reading.

### 5.3 Decision rules (`OmrThresholds`)

Scores are normalized per sheet: 0 is this sheet's empty level, 1 its filled level.

| Preset | Filled ≥ | Empty ≤ | Erasure auto-accept |
|---|---|---|---|
| Lenient | 0.50 | 0.28 | yes (dominance 0.30, residue ≤ 0.45) |
| **Standard** (default) | 0.55 | 0.15 | yes (dominance 0.40, residue ≤ 0.35) |
| Strict | 0.60 | 0.12 | no |

- One filled bubble, others empty: **answered**.
- None filled, all empty: **blank**.
- Two or more filled, none ambiguous: **multiple** (scored per the exam's policy).
- Anything ambiguous (light, partial, check mark, strong second mark):
  **uncertain**. The instructor must decide on the review screen before the paper
  can be saved. The engine's suggestion is shown but never applied silently.

### 5.4 Accuracy targets and measured results

Measured results to date (simulation, plus the app's real PDFs) are in
[`OMR_TEST_PROTOCOL.md`](OMR_TEST_PROTOCOL.md): **0 misread answers out of 4,050**
across all scenarios. The physical test campaign in Phase 8 decides whether the
targets below are met.

The figures below are targets only. They will be measured with the physical test protocol in
Phase 8 (at least 30 printed sheets per condition, two or more phone models, pencil and pen,
good and poor light). Results go into `docs/OMR_TEST_PROTOCOL.md`.

| Metric | Target |
|---|---|
| Unflagged answers read correctly (well-printed sheet, normal indoor light) | ≥ 99.9 % |
| Questions flagged for review on normal sheets | ≤ 2 % |
| Silent wrong reading of a deliberately ambiguous mark | 0 (must be flagged) |
| Capture → result on a mid-range phone | ≤ 2 s |

ACEkanner will never claim 100 % accuracy.

---

## 6. Grading engine

A pure Dart, deterministic function: `(answer key revision, student answers, rules) → result`.

- Each key item has accepted choices stored as a bitmask (A=1, B=2, C=4, D=8, E=16). More
  than one accepted answer is allowed after a key correction. Each item also has points,
  optional negative points, and a mode: `normal`, `bonus` (everyone gets the points) or
  `dropped` (excluded from the total).
- Rules: multiple marks score as incorrect (default) or zero; negative marking on or off,
  never below 0 total (configurable); passing percentage (default 75 %).
- Percentage = earned points ÷ total possible points × 100, rounded only for display.
- A paper with unresolved *uncertain* items cannot be finalized.
- **Regrading:** editing a key creates a new key revision. Every finalized paper is
  regraded in one transaction, and the new result rows become current. Old results stay
  for audit, and an `audit_logs` entry records who changed what and why.

---

## 7. Subscription and scan-licensing architecture

### 7.1 What counts as a scan

One scan = one student paper **saved** after review. Nothing is consumed by camera
failures, rejected or unreadable photos, cancelled reviews, or re-scans of a paper already
saved.

*As built (Phase 6):* the charge key is the submission key
`SHA-256("acekanner-submission|v1|" ‖ examination_id ‖ "|" ‖ student_id)`, so each student
is charged once per examination however often the paper is re-scanned or re-graded. A
paper saved without an identified student is charged per paper
(`…|sheet:<sheet id>`). `scan_ledger` has a UNIQUE constraint on the key and the charge is
written in the same transaction as the saved paper: a refused charge saves nothing.

### 7.2 Free plan (100 lifetime scans) across reinstalls

- On first setup the instructor signs in with Google once (online). Supabase returns a
  signed **entitlement token**, an Ed25519-signed compact JWS:

  ```json
  { "sub": "<account uuid>", "dev": "<install id>", "plan": "free|premium",
    "free_limit": 100, "free_used": 37, "lease": 63,
    "premium_until": null, "verified_at": 1763251200,
    "offline_until": 1765843200, "iat": 1763251200, "jti": "<nonce>" }
  ```
- The app verifies the signature offline with the public key built into the app. A token
  that is forged, edited or belongs to another account is rejected.
- **Remaining free scans offline** = `lease − (local ledger rows after the token was issued)`.
  The server *leases* the remaining allowance to one active device at a time. Signing in on
  a new phone moves the lease. The count lives on the server, so uninstalling,
  clearing data or reinstalling never restores used scans.
- When online, unsynced ledger rows are uploaded idempotently (`sync-ledger`). The server
  adds them to the account's lifetime count and issues a fresh token. Uploaded rows hold
  only the submission-key hash, a timestamp and the plan, never names or answers.
- Scans finalized while Premium is active are recorded as `premium` and do **not** use the
  free allowance. If Premium lapses, the remaining free allowance is whatever was left
  (never a fresh 100). An account that used all 100 has 0 left.

### 7.3 Premium (PHP 399 / year)

1. The app queries `acekanner_premium_yearly` (base plan `yearly`) through Play Billing and
   launches the purchase with `obfuscatedAccountId = SHA-256("acekanner-account|v1|" ‖ account
   id)`. This ties the purchase token to the signed-in account.
2. The purchase update stream returns a purchase token. The app sends it to
   `verify-purchase` with the user's Supabase session.
3. The server calls `purchases.subscriptionsv2.get` with a Google service account (kept
   only in Supabase secrets). It checks the package, product, state (`ACTIVE` /
   `IN_GRACE_PERIOD`), expiry time and account binding. It then acknowledges the purchase
   (Play refunds unacknowledged purchases after 3 days), stores it, and returns a signed
   Premium entitlement.
4. Only then does the app unlock unlimited scanning and call `completePurchase`.
5. **Pending purchases** show "Payment pending" and grant nothing until Play confirms.
6. **Renewal, cancellation, expiry, grace period, account hold, refund and revocation**
   arrive as Real-time Developer Notifications (Pub/Sub push to `play-rtdn`, OIDC-verified),
   including voided-purchase notifications for refunds. Each check-in also re-checks
   subscriptions with Google that were not checked for 6 hours or expire within a day, in
   case a notification was missed. The next app check-in receives the result.
7. **Restore purchases:** after sign-in, the server returns any Premium linked to the
   account. The app also re-submits tokens from `queryPastPurchases` for verification.

### 7.4 Offline rule for Premium (30 days)

Premium works offline until **min(Play expiry time, last successful verification + 30 days)**.
The app shows the date when online verification is next required and warns from 7 days
before. Past that date, new Premium scans pause (falling back to any remaining free
allowance) until the app re-verifies. **No data is ever deleted or locked** because of this:
viewing, grading, regrading and exporting existing results always work.

### 7.5 Clock tampering

The app keeps a high-water mark of trusted time (server time from the last check-in,
moved forward by device time and elapsed real time). If the device clock is set backwards
past it, the offline window is treated as expired until the app reaches the server.

### 7.6 As built (Phase 6)

| Part | Where | Notes |
|---|---|---|
| Server schema and rules | `supabase/migrations/20261117000000_licensing.sql` | Tables `accounts`, `devices`, `scan_charges`, `play_subscriptions`, `account_tombstones`. RLS on, no client access; only the service role calls the `license_*` functions. |
| `license` function | `supabase/functions/license` | `checkin` (upload scan hashes, refresh, signed token), `verify-purchase`, `delete-account`. Validates the user's session with Supabase Auth. |
| `play-rtdn` function | `supabase/functions/play-rtdn` | Pub/Sub push; accepts only Google-signed OIDC tokens for its own URL and service account. |
| Token | `_shared/jws.ts` → `lib/domain/licensing/entitlement.dart` | Ed25519 compact JWS, `typ: ACEK-ENT+JWS`, key ID for rotation. Test vectors shared by both sides. |
| Phone | `lib/data/licensing/*` | Ledger (hash chain + HMAC, Keystore key), repository (verified token, trusted time), service (check-in, sign-in, purchase), billing controller. |

- **Lease:** the free allowance is leased to one phone. Signing in on another phone moves it;
  scans the old phone made offline are still uploaded and counted.
- **Premium charges are checked:** a scan reported as `premium` counts as free unless the
  account had a subscription around that time.
- **Account deletion** removes the account, phones, scan counts and subscriptions. A
  tombstone keeps only `SHA-256(Google account ID)` and the number of free scans used, so
  deleting and re-creating an account never restores free scans.
- **Offline:** both plans work offline for 30 days after the last check-in; then new scans
  pause until the phone reaches the server (saved papers, grading and exports are never
  blocked).
- **Builds without licensing** (no `--dart-define-from-file`): 100 free scans counted on the
  phone, no sign-in, never Premium. Used for development and early test builds.

---

## 8. Security architecture

| Asset | Protection |
|---|---|
| Local database | SQLCipher AES-256. Random 256-bit key created on first run and stored with `flutter_secure_storage` (Android Keystore). |
| Scan images and reports | App-private internal storage (not visible to other apps; Android file-based encryption). Shared only when the instructor exports. |
| Licensing state | Server-signed Ed25519 token (public key in app, private key only in Supabase secrets). Append-only, hash-chained, HMAC'd scan ledger. Triggers block edits. |
| Secrets | No API secrets in the app. Only the Supabase URL and publishable anon key (protected by Row Level Security) and the entitlement public key. The Play service-account key lives only in Supabase secrets. |
| Android backup | `allowBackup=false`, and data-extraction rules exclude everything. Student data is never copied to Google Drive automatically. |
| Local backups | Instructor-initiated `.acekbackup` file: database export + images, encrypted with AES-256-GCM and a key derived from the instructor's passphrase (PBKDF2-HMAC-SHA256, 310,000 iterations). Checksum verified before restore. |
| Cloud backup | Off by default. Opt-in only, encrypted on the device before upload. |
| App access | Optional app lock (device PIN/biometric). Optional screenshot blocking on result screens. |
| Audit | `audit_logs`: key edits, regrades, manual answer overrides, deletions, restores, entitlement changes. |
| Input validation | All forms validate on the device (lengths, ranges, ID format); every DB write uses parameterized queries (Drift). |
| Errors | User-facing messages never show stack traces or student data. Diagnostic logs stay on the device. |

Honest limit: a determined attacker with a rooted phone can tamper with any local client.
These measures stop the realistic attacks (editing the database or preferences, clearing
data, reinstalling, changing the clock, replaying another user's purchase). Server-side
counting bounds the damage of any local bypass to the remaining leased allowance.

### Privacy (Philippine Data Privacy Act of 2012, RA 10173)

- **Purpose limitation:** student names, numbers, answers and scores are processed only
  to grade the instructor's examinations.
- **Data minimization:** the server stores the instructor's Google account email and ID,
  device install IDs, purchase tokens and hashed scan counts. No student data.
- **Consent and transparency:** onboarding explains what is stored where. Cloud backup
  needs an explicit opt-in with a plain-language notice.
- **Retention:** the instructor controls deletion. Deleting an examination purges its
  papers, images and results after confirmation. "Delete all data" wipes the device
  database and files. Account deletion is available in the app and on the web (a Play
  requirement) and removes server records.
- **Security measures:** encryption at rest, no automatic cloud copies, export only by
  instructor action.
- The privacy policy, terms and Google Play Data Safety answers will be drafted in Phase 9
  from this design.

---

## 9. Implementation roadmap

| Phase | Scope | Exit criteria |
|---|---|---|
| 1 | Architecture, schema, OMR, licensing and security design | This document, DATABASE.md |
| 2 | Flutter project, Android config, dependencies, encrypted DB, design system, navigation, splash, onboarding, dashboard | `flutter analyze` clean, tests green, APK builds |
| 3 | Instructor profile, subjects, courses, sections, students (CSV roster import), examinations, versions, answer keys | CRUD + validation tests |
| 4 | Sheet layout + PDF generator, Kotlin OMR engine, camera screen, verification screen | Synthetic-image test suite green; first physical test on your phone |
| 5 | Grading engine, results, regrade + audit, class analytics, item analysis | Grading unit tests |
| 6 | Supabase backend, Google sign-in, entitlement tokens, scan ledger, Play Billing, RTDN | License test matrix (sandbox testers) |
| 7 | PDF/Excel/CSV reports, printing, history | Exports open in Excel/Sheets/PDF viewers |
| 8 | Physical OMR accuracy campaign, offline/crash, security, performance tests | Documented results; critical bugs closed |
| 9 | Release build, signing, store listing, privacy policy, Data Safety, manual | Release-readiness checklist |

---

## 10. Estimated complexity

| Module | Complexity | Main difficulty |
|---|---|---|
| Exam / key / roster management | Medium | Validation, regrade-safe key revisions |
| Answer-sheet generator | Medium | Exact geometry shared with the OMR engine |
| OMR engine | **High** | Lighting, shading variance, erasures, real-paper tuning |
| Camera UX | Medium-High | Live guidance, device camera differences |
| Grading and analytics | Low-Medium | Deterministic; well covered by unit tests |
| Licensing and billing | **High** | Offline enforcement, Play state machine, abuse resistance |
| Reports | Medium | Layout quality in PDF and Excel |
| Backup / restore | Medium | Encryption, integrity, schema-version compatibility |

---

## 11. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Recognition errors on real paper (light pencil, erasures, glare) | Wrong grades | Per-sheet calibration, "uncertain" flagging, mandatory review, physical test campaign before release |
| Poor photocopies of sheets (faded markers) | Unreadable sheets | High-contrast ArUco markers, printing guidance, rejection with a reason (no scan consumed) |
| Phone camera variety | Inconsistent quality | Quality gate, live guidance, test on 2+ phones (including a low-end one) |
| Instructor finalizes without reviewing | Bad grades | Uncertain items block finalization; flagged items highlighted |
| Free-scan abuse across devices | Revenue loss | Single-device lease, server-side lifetime count |
| Play policy and Billing Library version changes | Store rejection | Re-check requirements at Phase 9; keep `in_app_purchase` current |
| Clock manipulation offline | Extended offline Premium | Trusted-time high-water mark, 30-day cap |
| Backend cost | Recurring cost | Supabase free tier is enough for licensing traffic. Student data is never stored there. |
| Lost phone without backup | Data loss | Backup reminders; encrypted local and opt-in cloud backups |
| APK size (OpenCV ≈ 25 MB per ABI) | Download size | App Bundle per-ABI splits; ship only arm64-v8a, armeabi-v7a, x86_64 |
| GitHub-hosted native binaries blocked in some build environments | Build failure | All native libraries come from Maven Central (OpenCV, SQLCipher) |
