import 'package:acekor/data/settings/settings_repository.dart';
import 'package:acekor/features/calculator/calculator_screen.dart';
import 'package:acekor/features/welcome/welcome_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';

Future<void> tapKey(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(ValueKey('key-$name')));
  await AppHarness.settle(tester, 4);
}

String displayText(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('score-display'))).data!;
String percentText(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('percent-display'))).data!;

void main() {
  testWidgets('home calculator: layout, display, search, trial gate, save, continuous entry', (tester) async {
    final h = AppHarness();
    await h.pump(tester);

    // First start: welcome, then a sample class.
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Try with a sample class'), 200);
    await tester.tap(find.text('Try with a sample class'));
    await AppHarness.settle(tester, 30);
    expect(find.byType(CalculatorScreen), findsOneWidget);
    expect(find.text('SAMPLE 101'), findsOneWidget);
    expect(find.text('QUIZ 1'), findsOneWidget);

    // Keypad: exactly the 12 keys, three columns, ⌫ under 1, 0 under 2, ✓ under 3.
    Offset at(String k) => tester.getCenter(find.byKey(ValueKey('key-$k')));
    for (final row in [
      ['d7', 'd8', 'd9'],
      ['d4', 'd5', 'd6'],
      ['d1', 'd2', 'd3'],
      ['backspace', 'd0', 'save'],
    ]) {
      expect(at(row[0]).dy, moreOrLessEquals(at(row[1]).dy));
      expect(at(row[1]).dy, moreOrLessEquals(at(row[2]).dy));
      expect(at(row[0]).dx < at(row[1]).dx && at(row[1]).dx < at(row[2]).dx, isTrue);
    }
    expect(at('backspace').dx, moreOrLessEquals(at('d1').dx));
    expect(at('backspace').dy > at('d1').dy, isTrue);
    expect(at('d0').dx, moreOrLessEquals(at('d2').dx));
    expect(at('save').dx, moreOrLessEquals(at('d3').dx));
    expect(
      find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key as ValueKey).value}'.startsWith('key-')),
      findsNWidgets(12),
    );
    for (final op in ['+', '−', '×', '÷', '%', '.', 'C', '(', ')']) {
      expect(find.descendant(of: find.byType(CalculatorScreen), matching: find.text(op)), findsNothing);
    }

    // Score display: 42/50 then 84% underneath, nothing else.
    expect(displayText(tester), '0/50');
    await tapKey(tester, 'd4');
    await tapKey(tester, 'd2');
    expect(displayText(tester), '42/50');
    expect(percentText(tester), '84%');
    expect(
      tester.getCenter(find.byKey(const ValueKey('percent-display'))).dy >
          tester.getCenter(find.byKey(const ValueKey('score-display'))).dy,
      isTrue,
    );
    expect(find.text('42'), findsNothing); // the raw score is not repeated

    // Above the maximum: refused, value kept.
    await tapKey(tester, 'd0');
    expect(displayText(tester), '42/50');
    expect(find.text('The maximum is 50 points.'), findsOneWidget);

    // Backspace.
    await tapKey(tester, 'backspace');
    expect(displayText(tester), '4/50');
    await tapKey(tester, 'd2');

    // Save without a student.
    await tapKey(tester, 'save');
    expect(find.text('Search and select a student first.'), findsOneWidget);

    // Search: JUAN.
    await tester.tap(find.byKey(const ValueKey('student-search')));
    await AppHarness.settle(tester, 4);
    await tester.enterText(find.byKey(const ValueKey('student-search')), 'JUAN');
    await AppHarness.settle(tester, 6);
    final results = find.descendant(of: find.byKey(const ValueKey('search-results')), matching: find.byType(Text));
    final names = tester.widgetList<Text>(results).map((t) => t.data ?? '').toList();
    final order = [
      'Juan Dela Cruz',
      'Juan Miguel Santos',
      'Juan Carlo Reyes',
      'Mark Juan Garcia',
    ].map(names.indexOf).toList();
    expect(order.every((i) => i >= 0), isTrue, reason: '$names');
    expect(order[3] > order[0] && order[3] > order[1] && order[3] > order[2], isTrue);
    await tester.tap(find.text('Juan Dela Cruz'));
    await AppHarness.settle(tester, 8);
    expect(find.textContaining('JUAN DELA CRUZ'), findsOneWidget);

    // No plan yet: SAVE offers the free trial.
    await tapKey(tester, 'd4');
    await tapKey(tester, 'd2');
    await tapKey(tester, 'save');
    await AppHarness.settle(tester, 8);
    expect(find.text('Start your free 7-day trial'), findsOneWidget);
    await tester.tap(find.text('Start free trial'));
    await AppHarness.settle(tester, 20);

    // Now it saves; continuous entry moves to the next student without a score.
    await tapKey(tester, 'save');
    await AppHarness.settle(tester, 10);
    expect(find.textContaining('Saved 42/50 (84%) · Juan Dela Cruz'), findsOneWidget);
    expect(find.textContaining('MARK JUAN GARCIA'), findsOneWidget);
    expect(displayText(tester), '0/50');

    final rows = await tester.runAsync(() => h.db.customSelect('SELECT points FROM scores').get());
    expect(rows!.single.read<int>('points'), 42);
    final trial = await tester.runAsync(() => SettingsRepository(h.db).getString(SettingKeys.localTrialStarted));
    expect(trial, isNotNull);

    await h.dispose(tester);
  });
}
