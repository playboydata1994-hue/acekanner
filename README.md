# ACEkanner

Offline-first Android app for college instructors: print answer sheets, scan students'
shaded papers with the phone camera, grade automatically against an answer key, and
export reports. Student data stays encrypted on the phone.

- **Free:** 100 lifetime scans · **Premium:** PHP 399/year, unlimited scans
- Answer sheets: 50, 75 or 100 items, choices A–E; A4, Letter or 8.5×13 in

This repository also holds a second app, **ACEkor Grading Sheet** (`acekor/`): an offline academic
score calculator for instructors (search student → enter score → save). See
[`acekor/README.md`](acekor/README.md). It shares only the Supabase licensing project.

## Repository layout

| Path | Contents |
|---|---|
| `app/` | Flutter application (Dart UI and logic, Kotlin OMR engine in `android/`) |
| `docs/` | Architecture, database reference, SQL scripts, development log |
| `omr_engine/` | Desktop test harness for the OMR engine (runs the app's Kotlin engine against desktop OpenCV) |
| `tools/brand/` | Icon generator |
| `store/` | Google Play listing assets |
| `acekor/` | ACEkor Grading Sheet (separate app, package `com.acekor.calculator`) |

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

OMR engine tests (desktop, no phone needed): `cd omr_engine && ./gradlew test`.

Release signing reads `app/android/key.properties`, which is never committed. See the
comment at the top of `app/android/app/build.gradle.kts`.

## Status

Phases 1–5 of 9 are complete: architecture, setup, encrypted database, examination
management, printable answer sheets, the OMR engine (0 misread answers in 4,050
simulated questions; physical tests pending), the camera scanner and review screen,
grading with key revisions, and class analytics.
See the development log for what's next.
