import 'omr_reading.dart';

/// Why a photo did not become a scanned paper, in the instructor's words:
/// a short name for the problem, the reason, and what to do about it.
class ScanProblem {
  const ScanProblem({required this.title, required this.reason, this.tips = const []});

  /// From the engine's answer when it could not read the sheet.
  factory ScanProblem.fromFailure(OmrFailure f) {
    final (title, reason, tips) = switch (f.code) {
      'no_markers' => (
          'No answer sheet found',
          'The four black corner squares of an answer sheet were not found in the photo.',
          const [
            'Fit the whole sheet inside the frame, with all four black corner squares showing.',
            'Use an answer sheet printed from ACEkanner for this examination.',
          ],
        ),
      'partial_markers' => (
          'Corner squares not all visible',
          f.markersFound > 0 && f.markersFound < 4
              ? 'Only ${f.markersFound} of the 4 black corner squares were found.'
              : 'Not all of the 4 black corner squares were found.',
          const [
            'Move the phone back a little so the whole sheet fits.',
            'Keep fingers, clips and shadows off the four black corner squares.',
            'Do not cut or fold the corners of the sheet.',
          ],
        ),
      'too_blurry' => (
          'The photo is blurry',
          'The photo is not sharp enough to tell shaded circles from empty ones.',
          const [
            'Hold the phone steady, or rest your elbows on the table.',
            'Wait a moment for the camera to focus before the photo is taken.',
          ],
        ),
      'too_dark' => (
          'Too dark to read',
          'The photo is too dark or too grey to tell shaded circles from empty ones.',
          const [
            'Move to better light, or turn on the phone\'s light (button at the bottom right).',
            'Avoid your own shadow over the sheet.',
          ],
        ),
      'glare' => (
          'Glare on the sheet',
          'Light is reflecting on the sheet and hides some of the circles.',
          const [
            'Tilt the phone or the sheet a little away from the lamp or window.',
            'Turn the phone\'s light off if it is on.',
          ],
        ),
      'warped' => (
          'The sheet is bent or folded',
          'The sheet looks bent, folded or photographed at an angle, so the circles do not line up.',
          const [
            'Flatten the sheet on a table.',
            'Hold the phone straight above the sheet, not at an angle.',
          ],
        ),
      'wrong_template' => (
          'Wrong answer sheet',
          f.explanation,
          const [
            'Check that the sheet has the same number of questions as this examination.',
            'Print the right sheets from this examination\'s Answer sheets.',
          ],
        ),
      'too_small_sheet' => (
          'Answer sheet too short',
          f.explanation,
          const [
            'Use an answer sheet with at least as many questions as this examination.',
            'Print the right sheets from this examination\'s Answer sheets.',
          ],
        ),
      'old_sheet_design' => (
          'Old answer sheet design',
          f.explanation,
          const ['Print new sheets for this examination from Answer sheets.'],
        ),
      'unreadable_image' => (
          'The photo could not be read',
          'The photo file could not be opened.',
          const ['Take the photo again.'],
        ),
      _ => ('The sheet was not read', f.explanation, const ['Try again with the whole sheet inside the frame.']),
    };
    return ScanProblem(title: title, reason: reason, tips: tips);
  }

  /// The sheet was read but belongs elsewhere (another examination, or
  /// printed before the examination's settings changed).
  factory ScanProblem.mismatch(String reason) => ScanProblem(
        title: 'This sheet cannot be used here',
        reason: reason,
        tips: const ['Check which examination the sheet belongs to, or print new sheets from Answer sheets.'],
      );

  factory ScanProblem.camera(String detail) => ScanProblem(
        title: 'The photo could not be taken',
        reason: 'The camera reported a problem ($detail).',
        tips: const ['Try again. If it keeps happening, close ACEkanner and open it again.'],
      );

  static const ScanProblem unexpected = ScanProblem(
    title: 'The sheet was not read',
    reason: 'Something went wrong while reading the sheet. Nothing was saved.',
    tips: ['Try again.'],
  );

  final String title;
  final String reason;
  final List<String> tips;
}
