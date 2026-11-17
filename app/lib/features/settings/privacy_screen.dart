import 'package:material_ui/material_ui.dart';

import '../../core/constants.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/legal_links.dart';
import '../../core/widgets/section_header.dart';

/// Plain-language explanation of how ACEkanner handles data (RA 10173).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const List<(String, List<String>)> _sections = [
    (
      'Stored only on this phone',
      [
        'Examinations, answer keys, class lists, student names and numbers, '
            'scanned answer sheets and scores.',
        'Everything is kept in ACEkanner’s private storage and the database is '
            'encrypted with a key held in this phone’s secure hardware.',
        'Android’s automatic cloud backup is turned off for ACEkanner, so this '
            'data is never copied to Google Drive without you.',
      ],
    ),
    (
      'What goes online, and when',
      [
        'Your Google account email, name and ID, when you sign in.',
        'Your Google Play purchase details, to verify Premium.',
        'Scan counts for your free allowance, as anonymous codes — never '
            'student names, answers or scores.',
      ],
    ),
    (
      'Your control',
      [
        'Reports and exports are created only when you ask, and you choose '
            'where to share them.',
        'Deleting an examination deletes its scanned papers and results from '
            'this phone.',
      ],
    ),
    (
      'Your responsibility as a personal information controller',
      [
        'Student information you record is covered by the Data Privacy Act of '
            '2012 (Republic Act No. 10173). Use it only for grading, keep your '
            'phone locked, and share reports only with authorized people.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and your data')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          children: [
            const SizedBox(height: Space.s),
            Text(
              '${AppConstants.appName} is built to keep student information on '
              'your phone.',
              style: theme.textTheme.bodyLarge,
            ),
            for (final (title, points) in _sections) ...[
              SectionHeader(title),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Space.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final point in points)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Space.s),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 7, right: Space.m),
                                child: Icon(Icons.circle, size: 6),
                              ),
                              Expanded(
                                child: Text(point, style: theme.textTheme.bodyMedium),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: Space.s),
            const LegalLinksRow(),
            const SizedBox(height: Space.xxl),
          ],
        ),
      ),
    );
  }
}
