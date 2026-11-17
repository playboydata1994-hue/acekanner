# ACEKOR Calculator

Offline academic score calculator and student performance recorder for college instructors.

**Open the app → search student → enter score → save.** The score shows as **42/50** with
**84%** underneath.

- **Plans:** 7-day free trial (everything); PRO ₱399/year (quizzes, recitations, roster, weighted
  grades, PDF/Excel); MAX ₱499/year (PRO plus examinations, custom categories and analytics).
- **Storage:** student records stay on the phone, encrypted (SQLCipher, key in the Android
  Keystore). Everything works offline.
- **Package:** `com.acekor.calculator`.

## Layout

| Path | Contents |
|---|---|
| `app/` | Flutter app (Dart): `lib/domain` pure logic, `lib/data` database and repositories, `lib/services` reports and reminders, `lib/features` screens |
| `app/test/` | Unit, repository, report and full-flow widget tests |
| `app/tool/screenshots/` | Real-font screenshots (`flutter test tool/screenshots/screenshots_test.dart --update-goldens`) |
| `docs/` | Architecture, database, development log, Play release checklist |
| `store/` | Play icon, feature graphic, listing text and data-safety answers |
| `tools/generate_brand.py` | Icon and store graphic generator |
| `../supabase/functions/acekor-license`, `../supabase/migrations/20261119000000_acekor_licensing.sql` | Licensing server (shared Supabase project) |
| `../docs/acekor/` | Public privacy policy, terms and account-deletion pages (GitHub Pages) |

## Build

Requirements: Flutter 3.50+, Android SDK 36, JDK 17+.

```bash
cd acekor/app
flutter pub get
dart run build_runner build      # after schema changes
flutter analyze
flutter test
flutter build apk --release --split-per-abi --dart-define-from-file=config/acekor.json   # test install
flutter build appbundle --release --dart-define-from-file=config/acekor.json             # Google Play
```

Server tests: `cd supabase && deno task test`. SQL tests: `supabase/tests/run_sql_tests.sh`.

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). Status and open items are in
[`docs/DEVELOPMENT_LOG.md`](docs/DEVELOPMENT_LOG.md); release steps are in
[`docs/PLAY_RELEASE.md`](docs/PLAY_RELEASE.md).
