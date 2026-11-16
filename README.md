# ACEkanner

Offline-first Android app for college instructors: print answer sheets, scan students'
shaded papers with the phone camera, grade automatically against an answer key, and
export reports. Student data stays encrypted on the phone.

- **Free:** 100 lifetime scans · **Premium:** PHP 399/year, unlimited scans
- Answer sheets: 50, 75 or 100 items, choices A–E; A4, Letter or 8.5×13 in

## Repository layout

| Path | Contents |
|---|---|
| `app/` | Flutter application (Dart UI and logic, Kotlin OMR engine in `android/`) |
| `docs/` | Architecture, database reference, SQL scripts, development log |
| `tools/brand/` | Icon generator |
| `store/` | Google Play listing assets |

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). Progress, test results and
known issues are in [`docs/DEVELOPMENT_LOG.md`](docs/DEVELOPMENT_LOG.md).

## Build

Requirements: Flutter 3.50+, Android SDK 36, JDK 17+.

```bash
cd app
flutter pub get
dart run build_runner build          # regenerate Drift code after schema changes
flutter analyze
flutter test
flutter build apk --release --split-per-abi   # sideload test builds
flutter build appbundle --release            # Google Play upload
```

Release signing reads `app/android/key.properties`, which is never committed. See the
comment at the top of `app/android/app/build.gradle.kts`.

## Status

Phases 1–3 of 9 are complete: architecture, project setup, encrypted database, design
system, navigation, onboarding, dashboard, and examination management (profile, classes
and rosters with CSV import, examinations with sets A–D, answer-key editor). See the
development log for what's next.
