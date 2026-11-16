#!/usr/bin/env bash
# Regenerates the engine test fixtures from the app's real code:
#  1. layout JSON + sheet PDFs (Dart tests with ACEK_EXPORT_FIXTURES=1)
#  2. PNGs at 12 px/mm (304.8 dpi) with poppler's pdftoppm
set -euo pipefail
cd "$(dirname "$0")/../../app"
ACEK_EXPORT_FIXTURES=1 flutter test test/domain/sheet_layout_test.dart test/services/answer_sheet_pdf_test.dart
cd ../omr_engine/src/test/resources/sheets
for f in *.pdf; do pdftoppm -r 304.8 -gray -png -singlefile "$f" "${f%.pdf}"; done
echo "Fixtures updated."
