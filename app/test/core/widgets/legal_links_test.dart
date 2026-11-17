import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:acekanner/app/app_config.dart';
import 'package:acekanner/app/providers.dart';
import 'package:acekanner/core/widgets/legal_links.dart';

void main() {
  Future<void> pump(WidgetTester tester, LegalLinks links) => tester.pumpWidget(
        ProviderScope(
          overrides: [legalLinksProvider.overrideWithValue(links)],
          child: const MaterialApp(home: Scaffold(body: LegalLinksRow())),
        ),
      );

  testWidgets('shows nothing when no page address is set', (tester) async {
    await pump(tester, const LegalLinks());
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('shows only links with a valid https address', (tester) async {
    await pump(tester, const LegalLinks(privacyPolicy: 'https://example.org/privacy', terms: 'http://example.org/t'));
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Terms of use'), findsNothing);
  });

  test('parses addresses strictly', () {
    expect(const LegalLinks(privacyPolicy: ' https://a.b/p ').privacyPolicyUri.toString(), 'https://a.b/p');
    expect(const LegalLinks(privacyPolicy: 'not a url').privacyPolicyUri, isNull);
    expect(const LegalLinks(accountDeletion: 'https:///x').accountDeletionUri, isNull);
  });
}
