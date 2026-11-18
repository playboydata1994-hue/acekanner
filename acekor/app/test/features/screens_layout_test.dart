import 'package:acekor/app/router.dart';
import 'package:acekor/app/routes.dart';
import 'package:acekor/data/settings/settings_repository.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';

/// Texts squeezed into a narrow column (one letter per line), like the
/// "Default subject and class" row that a wide trailing widget crushed.
List<String> squeezedTexts(WidgetTester tester) {
  final out = <String>[];
  for (final p in tester.allRenderObjects.whereType<RenderParagraph>()) {
    final text = p.text.toPlainText().trim();
    if (text.length < 6 || !p.hasSize) continue;
    if (p.size.width < 48 && p.size.height > 80) out.add('"$text" (${p.size.width.toStringAsFixed(0)} px wide)');
  }
  return out;
}

Future<void> checkAllScreens(WidgetTester tester, {required String textSize}) async {
  final h = AppHarness();
  await h.pump(tester, size: const Size(360, 780)); // a small phone
  await tester.scrollUntilVisible(find.text('Try with a sample class'), 200);
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
  await AppHarness.settle(tester, 4);
  await tester.tap(find.text('Try with a sample class'));
  await AppHarness.settle(tester, 30);
  await tester.runAsync(() => SettingsRepository(h.db).setString(SettingKeys.textSize, textSize));
  await AppHarness.settle(tester, 6);

  final ids = await tester.runAsync(() async {
    final subject = (await h.db.select(h.db.subjects).get()).first.id;
    final student = (await h.db.select(h.db.students).get()).first.id;
    final activity = (await h.db.select(h.db.activities).get()).first.id;
    return (subject: subject, student: student, activity: activity);
  });
  final routes = [
    Routes.home,
    Routes.menu,
    Routes.miniCalculator,
    Routes.students,
    Routes.newStudent,
    Routes.importStudents,
    Routes.deletedStudents,
    Routes.student(ids!.student),
    Routes.editStudent(ids.student),
    Routes.sections,
    Routes.subjects,
    Routes.newSubject,
    Routes.deletedSubjects,
    Routes.subject(ids.subject),
    Routes.editSubject(ids.subject),
    Routes.grading(ids.subject),
    Routes.enrol(ids.subject),
    Routes.newActivity(ids.subject),
    Routes.activity(ids.activity),
    Routes.editActivity(ids.activity),
    Routes.records,
    Routes.gradebook(ids.subject),
    Routes.history(),
    Routes.reports,
    Routes.plan,
    Routes.settings,
    Routes.calculatorSettings,
    Routes.profile,
    Routes.scales,
    Routes.newScale,
    Routes.categories,
    Routes.backup,
    Routes.lock,
    Routes.privacy,
    Routes.about,
  ];
  final router = h.container.read(routerProvider);
  final problems = <String>[];
  for (final r in routes) {
    router.go(r);
    await AppHarness.settle(tester, 8);
    final error = tester.takeException();
    if (error != null) problems.add('$r: $error');
    // Long pages: also check what is further down.
    for (var i = 0; i < 6; i++) {
      for (final s in squeezedTexts(tester)) {
        problems.add('$r: squeezed $s');
      }
      final lists = find.byType(Scrollable);
      if (lists.evaluate().isEmpty) break;
      await tester.drag(lists.first, const Offset(0, -500), warnIfMissed: false);
      await AppHarness.settle(tester, 2);
      final e = tester.takeException();
      if (e != null) problems.add('$r (scrolled): $e');
    }
  }
  // Pop-up panels on the calculator.
  router.go(Routes.home);
  await AppHarness.settle(tester, 8);
  for (final open in <Finder>[find.byKey(const ValueKey('class-chip')), find.byKey(const ValueKey('activity-line'))]) {
    await tester.tap(open);
    await AppHarness.settle(tester, 8);
    final e = tester.takeException();
    if (e != null) problems.add('sheet ${open.describeMatch(Plurality.one)}: $e');
    for (final sq in squeezedTexts(tester)) {
      problems.add('sheet: squeezed $sq');
    }
    await tester.tapAt(const Offset(180, 40)); // close the sheet
    await AppHarness.settle(tester, 6);
  }
  expect(problems.toSet().toList(), isEmpty);
  await h.dispose(tester);
}

/// Real Roboto, so text is measured as on a phone (the default test font is wider).
Future<void> loadRoboto() async {
  final loader = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  await loader.load();
}

void main() {
  setUpAll(loadRoboto);
  testWidgets('every screen lays out on a small phone (normal text)', (tester) async {
    await checkAllScreens(tester, textSize: 'normal');
  });
  testWidgets('every screen lays out on a small phone (extra large text)', (tester) async {
    await checkAllScreens(tester, textSize: 'xlarge');
  });
}
