# ACEkanner — OMR Accuracy: Results So Far and Physical Test Protocol

ACEkanner never claims 100 % accuracy. This document records what has been
**measured** (with the date and engine version) and describes the **physical
tests** that must pass before release (Phase 8). Unmeasured conditions are
listed as such.

Engine version: **3.0.0** (sheet design 3, circles) · Thresholds preset: **standard**

---

## 1. Automated results (desktop harness, `omr_engine/`)

The recognition code that ships in the app
(`app/android/app/src/main/kotlin/com/acekanner/app/omr/core`) is compiled
unchanged against desktop OpenCV 4.9 and run on:

- **Synthetic sheets.** These are drawn from the app's own layout JSON, with realistic marks:
  - No. 2 pencil with graphite texture
  - Black pen
  - Light pencil pressure
  - About half-filled circles
  - Incomplete erasures (grey residue next to the final answer)
  - Check marks
  - Shading well beyond the circle
  - Two clear answers
- **Real answer-sheet PDFs** from the app, rasterized with poppler (`pdftoppm`) at
  12 px/mm on A4, Letter and 8.5×13 in, then marked.

Each sheet then goes through a **simulated phone photo**:
- perspective tilt and in-plane rotation, including 90°, 180° and 270°
- page size in the frame of 60–92 %
- a lighting gradient down to 55 %, and soft shadows
- Gaussian blur and sensor noise
- warm colour cast
- JPEG quality 70–92
- at 3000×4000 (12 MP) and 1080×1920 (the app's capture resolution)

Run: `cd omr_engine && ./gradlew test`. All random inputs use fixed seeds.

### 1.1 Accuracy (16 Nov 2026 run, circle design 3)

| Scenario | Sheets | Questions | Read correctly | Flagged for review | **Misread** | Student no. | QR | Set |
|---|---|---|---|---|---|---|---|---|
| Clean photos (±3°) | 9 | 675 | 675 | 0 | **0** | 9/9 | 9/9 | 6/6 |
| Hand-held phone (12 MP, all distortions above) | 18 | 1,350 | 1,350 | 0 | **0** | 18/18 | 18/18 | 12/12 |
| 1080p capture (app setting) | 12 | 900 | 900 | 0 | **0** | 12/12 | 12/12 | 8/8 |
| Difficult marks (35 % of items light / half / erased / check / overfilled / double) | 12 | 900 | 770 | 130 (14.4 %) | **0** | 12/12 | 12/12 | 8/8 |
| Real PDFs: A4 50, Letter 75 + logo, 8.5×13 100 + logo | 3 | 225 | 225 | 0 | **0** | 3/3 | 3/3 | 2/2 |
| **Total** | **54** | **4,050** | | | **0** | | | |

"Misread" means an answer that was **not** flagged and does not match what the
student marked. In the difficult-marks scenario the flagged items are the
light, half-filled and check marks. That's the intended behaviour: the
instructor decides those. Erased residue next to a clear answer is accepted
(standard preset) or flagged (strict preset). It is never counted as a second
answer.

During the oval design (0.5.1), 2 check marks were read as blank. The standard
"empty" threshold was lowered from 0.20 to 0.15, so they are now flagged; it stays
at 0.15 for circles, and clean and phone photos still need no review.

Speed: up to 140 ms per photo on a desktop CPU. Not yet measured on phones (Phase 8).

### 1.2 Rejections (no scan is counted)

| Situation | Reported as |
|---|---|
| Photo without a sheet | "No answer sheet found…" |
| One corner square covered | "Not all four corner squares are visible…" (3 found) |
| Sheet for another item count | "This is a 100-item answer sheet, but this examination uses a different one." |
| Far too dark | "The photo is too dark or low in contrast…" |
| Badly blurred | "The photo is blurry…" |
| Glare over the answers | "There is glare on the sheet…" |
| Corner folded ~7 mm | "The sheet looks bent or folded…" |
| Corner folded ~4 mm | Corrected by local alignment and read correctly (never misread) |
| QR code of another examination | "This answer sheet was printed for another examination (code …)" |
| Sheet of an older test design (0.4–0.5 circles, 0.5.1 ovals) | "This is an older ACEkanner answer sheet design. Print new sheets…" |

### 1.3 Thresholds and how they were set

| Threshold | Value | Basis |
|---|---|---|
| Filled ≥ / empty ≤ (normalized) | 0.55 / 0.15 | Empty bubbles score 0.00 ± 0.02 and full shading about 1.0. Check marks score about 0.19–0.25, so "empty" must stay below that so they're flagged, not read as blank. That was found and fixed during testing (0.20 → 0.15). |
| Erasure auto-accept | Dominance ≥ 0.40 and residue ≤ 0.35 | Residue of a clean erasure is 0.05–0.15 |
| Focus (marker edge width) | ≤ 0.9 mm | Blur sweep: answers still read correctly up to about 1.0 mm. The 0.9 mm limit leaves margin for real hand-shake blur. |
| Local alignment shift | ≤ 2.0 mm | Flat sheets need 0.1–0.2 mm. Below 2.5 mm a misplaced sample can't reach a neighbouring bubble's ink. |
| Contrast | ≥ 60 grey levels | Normal photos measure 170–240 |
| Glare | ≤ 1 % of answer area | |

**These values are provisional.** They come from simulation and must be confirmed
or re-tuned with the physical tests below. Instructors can choose
*Lenient / Standard / Strict* per examination.

---

## 2. Physical test protocol (to run before release)

### 2.1 Materials
- Phones: at least **two Android phones**, one low-end (≤ ₱8,000 class) and one mid-range.
- Printers: one laser printer and one inkjet. One set of photocopies made from the laser prints.
- Paper: A4 and 8.5×13 bond paper.
- Marking tools: No. 2 pencil, HB pencil, black ballpoint, blue ballpoint.
- Answer sheets: 50, 75 and 100 items, generic and personalized.

### 2.2 Sheet sets (30 sheets per condition minimum)
1. Normal dark pencil, one answer per item, about 5 % blanks.
2. Light pencil (HB, light pressure).
3. Ballpoint pen (black, and blue).
4. Erasures: change 10 answers per sheet with a normal eraser.
5. Double answers on 5 items per sheet.
6. Partial shading and check marks on 5 items per sheet.
7. Folded once in the middle, then flattened.
8. Crumpled lightly, then flattened.

For each sheet, write the intended answers on a separate answer list (ground truth).

### 2.3 Capture conditions
- Classroom fluorescent light, daylight near a window, a dim room, and a desk lamp
  (with glare).
- Sheet on a desk, hand-held at 25–45 cm, straight and tilted up to about 20°.
- Auto-capture on and off.

### 2.4 Record for every scan
Phone, condition, accepted or rejected (and reason), questions read
correctly, flagged, **misread**, student number correct, time to result.

### 2.5 Release criteria
| Metric | Target |
|---|---|
| Misread unflagged answers, normal conditions (sets 1, 3) | **≤ 0.1 %**, and investigate every one |
| Misread unflagged answers, difficult sets (2, 4–8) | ≤ 0.5 % |
| Flagged on normal sheets | ≤ 2 % |
| Wrong student identified | **0** |
| Usable photos rejected in normal light | ≤ 5 % |
| Capture → result on the low-end phone | ≤ 3 s |

If a criterion fails, adjust thresholds or the layout, re-run the automated
suite, and repeat that physical set. Results go in a new section of this document.
