import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../data/db/app_database.dart';

/// Headline numbers for the home dashboard.
class DashboardStats {
  const DashboardStats({
    required this.examCount,
    required this.papersScanned,
    required this.freeScansUsed,
  });

  final int examCount;
  final int papersScanned;

  /// Free-plan scans recorded in this phone's scan ledger.
  final int freeScansUsed;

  int get freeScansRemaining =>
      (AppConstants.freeScanLimit - freeScansUsed).clamp(0, AppConstants.freeScanLimit);
}

/// Live dashboard numbers (re-emits whenever the underlying tables change).
final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final db = ref.watch(databaseProvider);
  return db.dashboardStats().watchSingle().map(
        (row) => DashboardStats(
          examCount: row.examCount,
          papersScanned: row.papersScanned,
          freeScansUsed: row.freeScansUsedLocal,
        ),
      );
});

/// The five most recently updated examinations.
final recentExaminationsProvider =
    StreamProvider<List<RecentExaminationsResult>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.recentExaminations(limit: 5).watch();
});
