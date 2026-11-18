// Renders store-style screenshots of the real app with real fonts.
//   flutter test tool/screenshots/screenshots_test.dart --update-goldens
// PNGs are written to tool/screenshots/out/ (not part of the normal test run).
import 'dart:io';

import 'package:acekor/app/router.dart';
import 'package:acekor/app/routes.dart';
import 'package:acekor/data/repositories/activities_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../test/support/app_harness.dart';

Future<void> loadFonts() async {
  final roboto = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  await roboto.load();
  final icons = File('/opt/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
  await loader.load();
}

Future<void> shot(WidgetTester tester, String name) async {
  await AppHarness.settle(tester, 6);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/$name.png'));
}

Future<void> key(WidgetTester tester, String k) async {
  await tester.tap(find.byKey(ValueKey('key-$k')));
  await AppHarness.settle(tester, 3);
}

void main() {
  testWidgets('screenshots', (tester) async {
    await tester.runAsync(loadFonts);
    final h = AppHarness();
    // 405 × 720 dp at 8/3 → 1080 × 1920 px, the 9:16 size Play recommends.
    await h.pump(tester, size: const Size(405, 720), pixelRatio: 8 / 3);
    await shot(tester, '01_welcome');
    await tester.scrollUntilVisible(find.text('Try with a sample class'), 200);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await AppHarness.settle(tester, 4);
    await tester.tap(find.text('Try with a sample class'));
    await AppHarness.settle(tester, 30);

    // Trial on, so saving works.
    await tester.tap(find.byKey(const ValueKey('student-search')));
    await AppHarness.settle(tester, 3);
    await tester.enterText(find.byKey(const ValueKey('student-search')), 'JUAN');
    await shot(tester, '03_search');
    await tester.tap(find.text('Juan Dela Cruz'));
    await AppHarness.settle(tester, 8);
    await key(tester, 'd4');
    await key(tester, 'd2');
    await shot(tester, '02_calculator_42_of_50');

    await key(tester, 'save');
    await AppHarness.settle(tester, 6);
    await tester.tap(find.text('Start free trial'));
    await AppHarness.settle(tester, 20);
    await key(tester, 'save');
    await AppHarness.settle(tester, 6);
    await shot(tester, '04_saved_next_student');

    // Mini calculator.
    await tester.tap(find.byTooltip('Calculator'));
    await AppHarness.settle(tester, 10);
    for (final k in ['3', '5', '÷', '4', '0', '×', '1', '0', '0']) {
      await tester.tap(find.byKey(ValueKey('mini-$k')));
      await AppHarness.settle(tester, 1);
    }
    await shot(tester, '05_mini_calculator');
    await tester.tap(find.byTooltip('Back to the academic calculator'));
    await AppHarness.settle(tester, 8);

    // A few more scores, then the records.
    final acts = await tester.runAsync(() => h.db.select(h.db.activities).get());
    final students = await tester.runAsync(() => h.db.select(h.db.students).get());
    await tester.runAsync(() async {
      final scores = h.container.read(scoresRepoForShots);
      for (var i = 0; i < students!.length; i++) {
        await scores.save(acts!.first.id, students[i].id, 50 - i * 4);
      }
      final repo = ActivitiesRepository(h.db);
      final r1 = await repo.createActivity(
        ActivityInput(subjectId: acts!.first.subjectId, categoryId: 'recitation', number: 1, maxPoints: 10),
      );
      for (var i = 0; i < students.length; i++) {
        await scores.save(r1, students[i].id, 10 - i);
      }
    });
    await tester.tap(find.byTooltip('Menu'));
    await AppHarness.settle(tester, 10);
    await shot(tester, '06_menu');
    await tester.tap(find.text('Records'));
    await AppHarness.settle(tester, 10);
    await tester.tap(find.textContaining('SAMPLE 101'));
    await AppHarness.settle(tester, 15);
    await shot(tester, '07_records');
    h.container.read(routerProvider).go(Routes.calculatorSettings);
    await AppHarness.settle(tester, 10);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2400));
    await AppHarness.settle(tester, 6);
    await shot(tester, '08_calculator_settings_general');
    await h.dispose(tester);
  });
}
