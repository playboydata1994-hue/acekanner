# ACEkanner — Development Log

Newest entries first. Every entry lists what was built, how it was verified, open issues,
and the next step.

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
