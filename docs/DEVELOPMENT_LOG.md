# ACEkanner — Development Log

Newest entries first. Every entry lists what was built, how it was verified, open issues,
and the next step.

---

## 2026-11-17 · Revisions round 3 (0.6.3)

- **Exam sets A–E:** a fifth set. Database schema v3 (`examination_versions.label` allows
  E); existing data migrates automatically (table rebuild, references kept).
- **Answer sheet:** a 5-set SET row starts further left so it fits under the QR code;
  sheets with 2–4 sets are unchanged, so sheets already printed still scan.
- Verification: migration tests (v2→v3 with sets, keys and references; all paths), SQL
  upgrade chain test, geometry with 5 sets × 12 digits, engine suite on the 5-set
  layout (0 misread; every set read) plus an explicit A–E set test; 211/211 app tests.

## 2026-11-17 · Revisions round 2 (0.6.2)

- **Examination date optional:** a new examination starts with no date ("Examination
  date (optional) · Not set · tap to choose"); sheets simply omit the date.
- **Class-list upload box** on the examination form: pick an Excel (.xlsx) or CSV list of
  names and student numbers → preview (students found, skipped rows with reasons) →
  section name (suggested from the file name) → students are saved to that section
  (an existing section with the same name is reused) and it is selected for the exam.
- **Excel support** for class lists everywhere (also Classes → Import): first sheet with
  a recognizable header; student numbers typed as numbers in Excel are read without ".0";
  old .xls files get a "save as .xlsx" message.
- Verification: real .xlsx files built in tests (title row, numeric IDs, ñ, bad rows,
  single "Name" column), import into new/existing section, form test; 198/198 pass.

## 2026-11-17 · Revisions round 1 (0.6.1)

The owner is testing the app and sending revisions before the Google/Play setup resumes.

- **Instructor title and full name are optional** in Profile and school. Database schema
  v2 (`full_name` may be empty); existing installs migrate automatically, keeping their
  data (Drift step-by-step migration, table rebuild). Sheets leave the instructor line
  off when there is no name; Settings and Home cope with no name.
- Verification: migration test (v1 database with a profile → v2, data identical, FK on),
  SQL upgrade script test, new repository and screen tests; `flutter test` 193/193.

---

## 2026-11-17 · Phase 6: licensing, Google sign-in and Play billing (code complete; awaiting accounts)

### What was built
**Server** (`supabase/`, no student data)
- SQL migration: accounts, phones, hashed scan charges, Play subscriptions, deletion
  tombstones. Row Level Security on with no client access; only the service role may
  call the `license_*` functions.
- Free allowance of 100 lifetime scans, leased to one phone at a time. Charges are
  idempotent per paper. A forged "premium" charge is counted as free. Deleting and
  re-creating an account never restores free scans (hashed tombstone).
- `license` Edge Function: check-in (upload scan hashes, refresh the plan, Ed25519-signed
  token), purchase verification with Google (`subscriptionsv2`, acknowledgement,
  account binding, replay protection), account deletion.
- `play-rtdn` Edge Function: renewals, cancellations, holds, refunds and revocations from
  Google, accepted only with a Google-signed OIDC token for this endpoint.

**App**
- Build-time configuration (public values only). Builds without it are test builds:
  100 scans counted on the phone, no sign-in, never Premium.
- Google sign-in → Supabase session, stored in the Android Keystore-backed store.
- Entitlement verification (Ed25519, bound to account and phone), 30-day offline window
  with a 7-day warning, clock-rollback detection.
- Scan charging inside the paper-save transaction: one charge per student per exam
  (re-scans free); refused charges save nothing. Hash-chained, HMAC-signed ledger.
- Play Billing: purchase tied to the account, pending payments, server verification
  before Premium, `completePurchase` only after the server confirms, restore, manage
  subscription, delete account.
- Screens: Plan and account (sign-in, plan, check now, Premium, restore, manage, delete
  account), plan card on Home, Settings entry, "why can't I scan" dialog before scanning
  and on save.
- Release signing with an upload key (kept outside the repository).

### Verification
| Check | Result |
|---|---|
| SQL tests (PostgreSQL 16) | **34 / 34 checks passed** (lease, idempotency, forged premium, ownership, refunds, tombstone, no client access) |
| Deno tests | **32 / 32 passed** (tokens, Google auth, Play rules, OIDC, both handlers, SQL signature consistency, app test vectors); `deno check` and `deno lint` clean |
| `flutter analyze` | No issues |
| `flutter test` | **188 / 188 passed** (43 new: verifier with server vectors, plan rules, charging and rollback, ledger tamper checks, check-in batching, purchase flow incl. "Play success alone never unlocks Premium", Plan screen flows) |

### Bug found by the new tests
- The purchase listener started before the database opened and would have crashed
  configured builds at launch. It now starts after startup.

### Not verified yet (needs the owner's accounts)
- Deployment to Supabase, real Google sign-in, real Play purchases (license testers),
  real RTDN delivery. See `docs/PHASE6_SETUP.md`.

### Deployment (2026-11-17)
- Supabase project `acekanner` (Singapore) created by the owner; migration applied,
  `license` and `play-rtdn` deployed, signing key generated straight into Supabase secrets
  (public key in `app/config/acekanner.json`).
- Live end-to-end check passed (sign-in required, signed and bound token, lease counting,
  idempotent upload, forged premium counted as free, account deletion). Test data removed.
- Waiting for: Google Web client ID (Part 2), Play Console app and subscription (Parts 3–4),
  Play service account and notifications (Part 5).

### Next step
Owner completes Part 2 (Google sign-in) → configured build → internal testing purchase
test → Phase 7.

---

## 2026-11-16 · Answer sheet design 3: back to circles

Requested: "make it circle". The ovals of 0.5.1 were replaced by circles. Everything
else from the redesign stays: optional logo and instructor name, the correct / wrong
shading example and the darker outlines.

### What was built
- **Design 3** (format 3): answer circles 4.6 mm across with the letter inside,
  6.4 mm pitch; student-number circles 3.5 mm (rows 4.6 mm apart so neighbouring
  circles stay ≥ 1 mm apart); QR prefix `ACK3`; corner markers 50 = IDs 24–27,
  75 = 28–31, 100 = 32–35.
- The engine (3.0.0) knows all three designs. Sheets of design 1 (0.4–0.5) and
  design 2 (ovals, 0.5.1) are rejected as "older sheet design, print new sheets",
  in the camera guide and after capture.
- Drafts: 50, 75 and 100 items on A4 with a sample logo, 100 items on 8.5×13 without.

### Verification
| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | **145 / 145 passed** |
| Engine `./gradlew test` | **22 / 22 passed**. 4,050 simulated questions on circles, **0 misread**; clean, phone and 1080p photos 0 flagged; difficult marks 130 / 900 flagged. Real app PDFs (two with a logo) read end to end. Design 1 and design 2 sheets → `old_sheet_design`. |

### Not verified yet
- Printing and scanning on paper with a real phone (Phase 8 protocol).

### Next step: Phase 6, licensing and billing

---

## 2026-11-16 · Answer sheet redesign: board-exam ovals, optional logo and instructor

Requested before Phase 6: make the instructor name optional, add an optional school
logo, make the bubbles look like a board-exam answer sheet, and show drafts of the
75- and 100-item sheets.

### What was built
- **Sheet design 2** (`lib/domain/sheet_layout.dart`, format 2):
  - Answer ovals 5.0 × 3.2 mm with the letter inside, 6.8 mm pitch; student-number
    ovals 4.2 × 2.8 mm; dark-grey 0.3 mm outlines.
  - A "correct / wrong" shading example (filled vs. check, cross, half, dot).
  - New corner-marker IDs (50 = 12–15, 75 = 16–19, 100 = 20–23) and QR prefix `ACK2`.
- **Optional school logo.** Added in Profile (any picture; reduced to at most
  600 px and stored as PNG in app-private storage, `branding/`). Printed 11 × 11 mm
  beside the top-left marker. The school name moved to the top of the header.
- **Optional instructor name**, now in the footer. Answer sheets screen: chips
  "Instructor name" and "School logo" switch each on or off; the choice is saved
  (`sheets.show_instructor`, `sheets.show_logo`). A shortcut opens Profile when no
  name or logo is set yet.
- **Engine 2.0.0** reads ovals (elliptical sampling and elliptical outline alignment).
  It recognises all 24 marker IDs, so a sheet printed by test builds 0.4–0.5
  (circles) is rejected with "older sheet design, print new sheets" instead of
  being read with the wrong geometry. The live camera guide says the same.
- Review screen highlights answers with ovals.

### Verification
| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | **145 / 145 passed** (new: logo storage and resizing, logo path, PDF with/without/broken logo, old-design QR and camera guide, oval geometry: every oval inside the frame, clear of markers and QR, ≥ 1 mm apart) |
| Engine `./gradlew test` | **22 / 22 passed**. 4,050 simulated questions on ovals, **0 misread**; clean, phone and 1080p photos 0 flagged. Real app PDFs read end to end, two of them with a logo. Old circle sheet → `old_sheet_design`. |
| Drafts | 75 and 100 items (A4, with sample logo) and 100 items on 8.5×13 without logo, rendered and checked visually |

### Changed during testing
- Check marks inside the smaller oval scored 0.19–0.20 (just under the old 0.20
  "empty" limit) and were read as blank in 2 of 900 difficult marks. The standard
  empty limit is now 0.15 (strict 0.12), so they are flagged for review.

### Not verified yet
- Printing and scanning the new design on paper with a real phone (Phase 8 protocol).
- Logo picking from the phone gallery (system picker; tested only through the
  storage code).

### Next step: Phase 6, licensing and billing
See the Phase 6 setup list (Supabase project, Google OAuth client, Play Console
subscription, internal test upload, service-account key into Supabase only).

---

## 2026-11-16 · Phase 5: grading, results and class analytics

### What was built
**Grading engine** (`lib/domain/grading.dart`, pure and deterministic)
- Each question is one of: correct, wrong, no answer, more than one, bonus
  (everyone earns it), or dropped (excluded from the total).
- Accepted alternatives (any one is correct), points per item and negative
  marking.
- The exam's rules: more than one mark counts as wrong (deduction applies) or as
  zero; whether totals may go below zero; the pass mark (inclusive).
- Percentage = earned points ÷ total possible points × 100, with sums rounded to 4
  decimals so 0.1 + 0.2 adds up exactly.

**Grading workflow** (`lib/data/repositories/grading_repository.dart`)
- **Finalize.** A paper is graded with the current key of its set as soon as it is
  saved, if the key is complete. Otherwise it waits and is graded automatically
  the moment the key is finished.
- **One submission per student per exam** (submission key = exam + student). A
  re-scan replaces the earlier paper, which is kept as `superseded`. Phase 6 will
  charge scans on this key, so a re-scan is never charged twice.
- **Key revision.** In the same transaction as the key change, every paper of that
  set is re-graded. The new result becomes current, and the old result is kept as
  history. Audited with a count of changed scores.
- **Rule change** (pass mark, multiple-mark policy, negative totals): current
  results are recomputed in place and audited.
- **Correct a reading** after grading: the score updates immediately; audited
  (`answer.corrected`).

**Class analytics** (`lib/domain/analytics.dart`)
- Papers, mean, median, standard deviation, highest, lowest, pass count and pass
  rate, and a score distribution in 10-point bands.
- **Item analysis per exam set:**
  - % correct (Easy / Moderate / Difficult)
  - discrimination (top 27 % minus bottom 27 %; shown with 10+ papers)
  - how many chose each option, blank and multiple counts
  - the most-chosen wrong answer
  - a "Review this question" flag when discrimination is under 0.2

**Screens**
- **Exam:** each paper shows its score and PASSED/FAILED (icon and label, never
  colour alone). The "Class results and question analysis" button appears once
  papers exist.
- **Paper result:**
  - Percentage, points, pass/fail, and counts of correct / wrong / no answer / more
    than one.
  - Which key revision graded it.
  - The scanned sheet (zoomable).
  - Question by question (answer, key, outcome), filtered by All / Not correct /
    Changed by you. Tap a question to correct it.
- **Class results:**
  - Filters for section and set.
  - Summary tiles and the score distribution (tap a column for its count; table
    view; pass mark marked).
  - Most-missed questions with % correct bars; all questions on request.
  - A ranked list of papers.
- **Charts** follow the dataviz checks: one series, no legend; thin columns with a
  4 px cap, 2 px gaps and a hairline grid; text in text colours; a table
  alternative. Chart colours were validated: light `#1D4ED8`. The dark theme's
  primary `#B7C4FF` failed the lightness and chroma checks, so dark charts use
  `#3B82F6`, which passes.

### Verification
| Check | Result |
|---|---|
| `flutter test` | **139 / 139 passed**. New: 10 grading/analytics rule tests (including the specification's example), 8 repository workflow tests, 2 end-to-end results flows. |
| `flutter analyze` | No issues |
| Release APK | Builds |

### Known limitations
- Item analysis is per exam set, because each set has its own key. "All sets" shows
  score statistics only.
- Discrimination needs at least 10 graded papers.
- PDF/Excel/CSV reports of these results come in Phase 7.

### Next step: Phase 6, licensing and Google Play Billing
- Supabase backend: Google sign-in, signed entitlement tokens, lifetime free-scan
  ledger, purchase verification, Real-time Developer Notifications.
- In the app: scan ledger consumption at finalization (using the submission key
  above), the 100 lifetime free scans, Premium PHP 399/year, the 30-day offline
  window, restore purchases, and the subscription screen.

---

## 2026-11-16 · Phase 4: answer sheets, OMR engine, scanner and review

### What was built
**Answer sheets** (`lib/domain/sheet_layout.dart`, `lib/services/answer_sheet_pdf.dart`)
- One geometry source for 50/75/100 items, sets A–D and 4–12 student-number digits.
  It drives both the PDF and the engine (as JSON).
- A paper-size-independent 190×250 mm frame, centred on A4, Letter or 8.5×13 in.
- Four ArUco corner markers (their IDs encode the template), a QR code with the exam
  code and an optional personalized sheet code, a student-number grid, the set row,
  instructions, and an embedded Roboto font (so ñ prints).
- Sheets screen: live PDF preview, print (Android print service), share/save,
  generic sheets with a copy count, or personalized sheets per section.
  Printing records `printed_sheets`, which locks item count and sets.

**OMR engine** (Kotlin + OpenCV 4.14, `android/.../omr/core`)
- Pipeline and decision rules in ARCHITECTURE §5.2–5.3. Platform channel:
  `analyzeSheet`, `detectMarkers`.
- **Desktop harness** (`omr_engine/`): the same Kotlin code against desktop OpenCV,
  with synthetic sheets, simulated phone photos, and the app's real PDFs rasterized
  with poppler.

**Scanner and review** (`lib/features/scanner`, `lib/data/repositories/scan_repository.dart`)
- Camera screen (1080p):
  - Live corner guidance ("3 of 4 corners found — move back a little",
    "different sheet type").
  - Auto-capture when steady; a manual shutter; a light toggle.
  - Batch scanning with a saved counter.
- Every rejection says why, and no scan is counted. The photo is deleted right after
  reading; only the corrected sheet image is kept, privately.
- Sheets printed for another examination, or before its settings changed, are
  refused (QR check).
- Review screen:
  - The corrected sheet with what was read circled (pinch to zoom).
  - The student, identified by personalized QR, then by shaded number (exam
    sections first), or chosen by hand.
  - The set, and a grid of all answers.
  - Flagged answers must be decided, with darkness bars and the engine's suggestion.
  - Re-scanning a student replaces the earlier paper (kept as `superseded`).
- Saving writes `answer_sheets`, per-question `student_answers` (detected state,
  scores, final answer, engine or instructor), session counters, and an audit
  entry, in one transaction.
- Exam screen: "Answer sheets" and "Scan papers" buttons, and a list of saved papers.

### Engine problems found by the tests and fixed
| Found | Fix |
|---|---|
| Check marks (✓) scored about 0.25 and were read as **blank**: a silent error | "Empty" threshold lowered 0.30 → 0.20, so they are flagged |
| Laplacian sharpness stayed high on blurred photos (sensor noise) | Focus measured as marker edge width in mm |
| Too-dark photos reported as "blurry" | Contrast checked before focus |
| A blank desk reported "blurry", a blurred sheet "no sheet" | Blur reported only when paper is visible |
| A 4 mm folded corner was accepted, and the corner-extrapolation check gave false "folded" results at 1080p | **Local alignment on the bubble rings**: corrects small distortions, rejects real folds; the corner check is now only for gross errors |

### Verification
| Check | Result |
|---|---|
| Engine accuracy, 4,050 questions across 54 photos | **0 misread**. Flagged only where marks were deliberately unclear. Details in `docs/OMR_TEST_PROTOCOL.md`. |
| Engine rejections | 9 situations, each with the right reason |
| `omr_engine` tests | 18 passed |
| `flutter test` | **119 / 119 passed**. New: layout geometry for 18 configurations, fixtures in sync, PDF generation, scan repository, capture guide, review-screen flows. |
| `flutter analyze` | No issues |
| Android build | Debug and release build. The engine compiles against OpenCV 4.14 Android. |

### Not verified yet (needs your phone and printer)
- The camera, live guidance and auto-capture on a real device.
- Printing through the Android print service.
- **Physical accuracy.** All results so far are from simulation and from
  rasterized PDFs. Follow `docs/OMR_TEST_PROTOCOL.md` §2. Start simple: print one
  50-item sheet at 100 % scale, shade it with a pencil, and scan it.

### Known limitations
- Papers are saved as "Awaiting grading". Scores, finalization and scan counting
  come in Phase 5 (grading) and Phase 6 (licensing).
- Scanning happens at 1080p. If physical tests show a need, switch to
  `ResolutionPreset.ultraHigh` (heavier live preview).
- Live guidance shows a count of corners found, not their positions on screen.

### Next step: Phase 5, grading
Finalize papers: compute scores from the current answer-key revision, store
`examination_results`, regrade on key revisions with audit, and add individual
results and class analytics (average, highest and lowest, pass rate, item
difficulty, most-missed questions, score distribution).

---

## 2026-11-16 · Phase 3: examination management

### What was built
**Data layer** (`app/lib/data/repositories/`, `app/lib/domain/`)
- `ProfileRepository`: one instructor profile (name, title, email, employee no., school,
  department, address) plus the school's **student-number format**, e.g. `####-#####`.
  The format sets the number of digit columns on new sheets.
- `ClassesRepository`: subjects, courses, sections.
  - Codes are upper-cased and unique among active records, case-insensitively.
  - Section names are unique per school year and term.
  - Delete is soft: existing examinations keep their references.
- `StudentsRepository`:
  - Adding a number that already exists enrolls the existing student instead of
    creating a duplicate.
  - CSV roster import runs in one transaction and returns counts: added, updated,
    already saved, unchanged.
  - Existing emails are never erased by a file without an email column.
- `ExamsRepository`:
  - Creates an examination with its sets A–D, a current key per set, and an item per
    question, using the default points and deduction.
  - Item count and number of sets can change until any sheet is printed or scanned,
    then they lock (`LockedException`).
  - Deleting moves an exam to the trash. It can then be restored or deleted
    permanently, which erases its papers and results but keeps scan charges.
  - The live detail stream coalesces bursts of database changes.
- `AnswerKeyRepository`:
  - Validates every item: answers A–E (more than one allowed), points and deduction
    0–100, modes normal/bonus/dropped.
  - Before any paper is finalized, edits update the key in place. Afterwards they
    create revision N+1 with a required reason.
  - The exam status becomes `ready` when every item of every set is complete.
- `AuditLogger`: hash-chained entries for exam create/update/trash/restore/purge,
  key updates and revisions (with the questions changed), and roster imports.
  Tamper detection is tested.
- Roster CSV parser:
  - Finds the header row even under a title line, and accepts many header spellings.
  - Handles comma, semicolon and tab separators, BOM, and Windows-1252 files from
    Excel's plain "CSV" export.
  - Accepts a single "Last, First M." column.
  - Keeps leading zeros, reports problems per line, and skips duplicates.
- Quick answer-key entry: `ABCDA…` (`-` skips a question) or `1A 2B 10AC`.

**Screens**
- Bottom navigation: Home · Exams · Classes · Settings.
- Dashboard:
  - "Create examination" button.
  - Greeting by name.
  - "Add your name and school" prompt until the profile exists.
  - Recent examinations open their detail.
- Exams:
  - List with status ("Key incomplete" / "Key complete").
  - Create/edit form: title, subject (with inline "New subject"), date, 50/75/100
    items, sets A–D, student-number digits, sections, passing %, points, deduction,
    multiple-mark policy, negative totals.
  - Detail screen with per-set key progress.
  - Recently deleted, with Restore and Delete permanently.
- Answer-key editor:
  - Five 46 dp A–E bubbles per question.
  - Per-question menu: more than one answer, bonus, drop, points.
  - Quick entry, and points for all questions at once.
  - A revision reason is required once papers exist.
  - Unsaved-changes guard.
- Classes: sections, subjects and courses with forms.
  - Section roster with add, edit, and remove from section.
  - Students whose number can't be shaded (letters, or too many digits) are flagged
    "needs a personalized (QR) sheet".
  - CSV import screen with instructions, preview, skipped-line list, and an
    "update names" switch.
- Settings: Profile and school, Student number format.

### Bugs found and fixed during this phase
- Layout overflows at realistic phone widths (415 dp and 320 dp), which also hit large
  system fonts:
  - dashboard plan header
  - exam-detail status row
  - answer-key row (bubbles now scale down below ~330 dp)
- Confirmation messages covered the floating "Add" buttons for about four seconds.
  - Cause: the tab container was a Scaffold sharing one message area with every tab.
  - Fix: each tab and each full-screen editor now has its own message area, and
    results are shown by the screen that opened the editor.
- Duplicate-hero crash when leaving the key editor while a message was showing, caused
  by the same shared message area. Fixed by the same change, and hidden tabs no longer
  take part in hero transitions.
- Live exam-detail stream could hang on cancel. Rewritten with an explicit controller.

### Verification
| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | **81 / 81 passed**. 46 are new: domain helpers, audit chain, repositories (duplicates, roster import merge, structure lock, revisions, trash), and widget flows at 415 dp and 320 dp. |
| Release APK | Builds: arm64 49.3 MB, armv7 37.1 MB. Permissions unchanged. |

### Not verified yet (needs your phone)
- Picking a CSV with the Android file picker (all parsing is tested; the system picker
  itself can't run here).
- Look and feel on a real screen and with the system font enlarged.

### Known limitations
- Regrading after a key revision is Phase 5. Until then no paper can be finalized
  (scanning arrives in Phase 4), so the revision path is tested but not reachable in
  the app yet.
- Section and student deletion is soft. A "delete student permanently" option for
  privacy requests comes with data retention tools in Phase 7/8.

### Next step: Phase 4, OMR
- Answer-sheet layout and PDF generator (A4 / Letter / 8.5×13, ArUco corners, QR,
  student-number grid, set row).
- Kotlin OpenCV engine with a synthetic-image test suite.
- Camera screen with live guidance, and the verification screen.

---

## 2026-11-16 · Phases 1 and 2: architecture, project setup, encrypted database, UI foundation

### Decisions confirmed with the owner
- Package `com.acekanner.app`; sheets of 50 / 75 / 100 items; choices A–E; English.
- Student identification: shaded student-number grid on every sheet, plus optional
  personalized sheets with a per-student QR.
- Free-scan protection through a one-time Google sign-in, backed by Supabase.
- New private GitHub repository `acekanner`.

### Phase 1: architecture (done)
- `docs/ARCHITECTURE.md`: system architecture, stack, structure, OMR algorithm, grading,
  licensing, security, privacy, roadmap, complexity, risks.
- `docs/DATABASE.md`: table-by-table reference. `docs/sql/v1_schema.sql`: SQL migration script.

### Phase 2: project setup (done)
- **Toolchain:** Flutter 3.50.0 / Dart 3.14, Android SDK 36, NDK r28c, AGP 9.3,
  Gradle 9.5, Kotlin 2.4.
- **Android:**
  - Application ID `com.acekanner.app`, minSdk 24, targetSdk 36.
  - Release builds minified with R8, signing read from `android/key.properties` (not committed).
  - Adaptive and themed launcher icon, plus Android 12+ splash.
  - `allowBackup=false` and data-extraction rules that exclude everything.
  - Removed the microphone and shared-storage permissions that plugins declared.
- **Native libraries from Maven Central:**
  - OpenCV 4.14.0 (`org.opencv:opencv`).
  - SQLCipher 4.20.0 (`net.zetetic:sqlcipher-android`).
  - Both are 16 KB page-aligned; the release APK passes `zipalign -P 16`.
- **Dart `sqlite3` package:** loads `libsqlcipher.so` on Android (verified in the APK's
  `NativeAssetsManifest.json`). Host tests use the OS SQLite.
- **Encrypted database:**
  - Drift schema in SQL with 21 tables, 4 triggers and 24 indexes.
  - 256-bit key generated on first run and stored in the Android Keystore.
  - Never auto-reset: a lost key leads to a recovery screen that keeps the locked file.
  - WAL with `synchronous=FULL`.
  - Opening fails closed if SQLCipher is missing, so an unencrypted database is never created.
- **Design system:**
  - Material 3 theme in brand blue, light and dark.
  - Status colors for correct, incorrect, uncertain and blank.
  - Spacing and radius tokens.
  - Logo painter and wordmark, `StatCard`, `SectionHeader`, `EmptyState`, `StatusPill`, `InfoRow`.
- **Screens:**
  - Splash, which opens the database and offers a retry on error.
  - Recovery.
  - Four-page onboarding: how it works, preparing sheets, plans, offline and privacy.
  - Dashboard with live counts from the database.
  - Settings, About (live encryption and OpenCV status), Privacy.
- **Navigation:** `go_router`. Every route waits for the database. Onboarding is shown
  only once and can be replayed from Settings.
- **Native channel:** `com.acekanner.app/omr` with `engineInfo`, which loads OpenCV on a
  worker thread and reports its version.
- **Dependencies for later phases** (camera, pdf, printing, excel_plus, csv, share_plus,
  file_picker, in_app_purchase, google_sign_in, supabase_flutter) are installed and
  build-verified but not yet used.

### Verification
| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | **35 / 35 passed** (schema constraints and triggers, SQL export parity, key manager, settings, bootstrap and recovery, fail-closed encryption, 4 widget flows) |
| Debug APK | Builds |
| Release APK (R8) | Builds. Per-ABI sizes: arm64 48.0 MB, armv7 35.5 MB, x86_64 85.2 MB. |
| App Bundle (`.aab`) | Builds, 101.5 MB (Play delivers only the phone's ABI) |
| 16 KB page alignment | `zipalign -c -P 16` passes |
| Merged permissions | CAMERA, INTERNET, ACCESS_NETWORK_STATE, BILLING, USE_BIOMETRIC, USE_FINGERPRINT |

### Not verified yet (needs a real phone, since this build machine has no Android emulator)
- That SQLCipher actually encrypts on-device. Check: Settings → About ACEkanner →
  *Data storage* must read **Encrypted (SQLCipher 4.x)**.
- That OpenCV loads on-device. Check: Settings → About ACEkanner → *Scanner engine* must
  read **Ready (OpenCV 4.14.0)**.

### Known issues and limitations
- The build machine's network proxy rate-limits Maven downloads (HTTP 429). Gradle builds
  sometimes need 2–4 retries. This doesn't affect normal build machines.
- The release build is signed with the debug key until an upload keystore is created
  (Phase 9). Google Play will refuse that build, which is expected.
- The dashboard's free-scan count reads only this phone's ledger. In Phase 6 it changes to
  the server-signed entitlement.
- `READ_EXTERNAL_STORAGE` was removed. CSV roster import (Phase 3) must be checked on
  Android 7–9 devices with the system file picker.

### Next step: Phase 3, examination management
Instructor profile and school info; subjects, courses, sections; students with CSV roster
import; examination creation (50/75/100 items, versions A–D); answer-key entry and
validation; dashboard actions for "Create examination". All of it with validation and
tests.
