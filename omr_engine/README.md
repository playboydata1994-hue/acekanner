# OMR engine test harness

Desktop (JVM) tests for the ACEkanner recognition engine. The engine source is
**not** copied here: Gradle compiles
`app/android/app/src/main/kotlin/com/acekanner/app/omr/core` directly, against
desktop OpenCV 4.9 (`org.openpnp:opencv`). The app uses the official OpenCV
4.14 Android build; the engine only uses API that is identical in both.

```bash
cd omr_engine
./gradlew test                       # all tests (~4 min)
./gradlew test --tests '*Accuracy*'  # accuracy scenarios only
./gradlew test -Pcalibrate --tests '*BlurCalibration*'   # print the blur sweep
```

| Test | What it checks |
|---|---|
| `EngineAccuracyTest` | Synthetic sheets through simulated phone photos: clean, hand-held 12 MP, 1080p, difficult marks. **No misread answers allowed.** |
| `PrintedSheetTest` | The app's real PDFs (A4/Letter/8.5×13) rasterized, marked, photographed, read |
| `RejectionTest` | No sheet, covered corner, wrong template, dark, blurred, glare, folded corners |
| `ConsistencyTest` | Marker bits in the Dart PDF code = OpenCV dictionary; layout parsing; decision rules |
| `BlurCalibrationTest`, `DiagnosticTest` | Measurements used to choose thresholds (run with `-Pcalibrate`) |

Fixtures in `src/test/resources` are generated from the app's code:

```bash
tool/render_fixtures.sh   # layouts + PDFs (Flutter tests) and PNGs (pdftoppm)
```

The Dart test `test/domain/sheet_layout_test.dart` fails if the layout fixtures
are stale. Results and the physical test protocol: `docs/OMR_TEST_PROTOCOL.md`.
