import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:acekanner/core/theme/app_theme.dart';
import 'package:acekanner/domain/omr_reading.dart';
import 'package:acekanner/domain/scan_problem.dart';
import 'package:acekanner/features/scanner/scan_problem_panel.dart';

void main() {
  test('every engine failure has a name, a reason and something to do', () {
    for (final code in [
      'no_markers', 'partial_markers', 'too_blurry', 'too_dark', 'glare', 'warped',
      'wrong_template', 'old_sheet_design', 'unreadable_image', 'something_new',
    ]) {
      final p = ScanProblem.fromFailure(OmrFailure(code: code, message: 'Engine says $code.'));
      expect(p.title, isNotEmpty, reason: code);
      expect(p.reason, isNotEmpty, reason: code);
      expect(p.tips, isNotEmpty, reason: code);
    }
    expect(
      ScanProblem.fromFailure(const OmrFailure(code: 'partial_markers', message: '', markersFound: 3)).reason,
      'Only 3 of the 4 black corner squares were found.',
    );
    expect(
      ScanProblem.fromFailure(const OmrFailure(code: 'wrong_template', message: '', detectedItemCount: 75)).reason,
      'This is a 75-item answer sheet, but this examination uses a different one.',
    );
    expect(ScanProblem.fromFailure(const OmrFailure(code: 'something_new', message: 'Engine text.')).reason, 'Engine text.');
  });

  testWidgets('the problem stays until "OK, scan again" is tapped', (tester) async {
    var acknowledged = 0;
    final problem = ScanProblem.fromFailure(const OmrFailure(code: 'glare', message: ''));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ScanProblemPanel(problem: problem, onAcknowledge: () => acknowledged++),
        ),
      ),
    ));
    expect(find.text('NOT SCANNED'), findsOneWidget);
    expect(find.text('Glare on the sheet'), findsOneWidget);
    expect(find.text('Light is reflecting on the sheet and hides some of the circles.'), findsOneWidget);
    expect(find.text('What to do'), findsOneWidget);
    expect(find.textContaining('Tilt the phone'), findsOneWidget);
    expect(find.text('Nothing was saved and no scan was counted.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Glare on the sheet'), findsOneWidget, reason: 'it does not go away by itself');
    await tester.tap(find.text('OK, scan again'));
    expect(acknowledged, 1);
  });
}
