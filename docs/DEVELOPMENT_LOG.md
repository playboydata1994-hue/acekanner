# ACEkanner — Development Log

Newest entries first. Every entry lists what was built, how it was verified, open issues,
and the next step.

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
