import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../db/app_database.dart';

/// Mini-calculator history (kept on the phone, never part of any record).
class CalcHistoryRepository {
  CalcHistoryRepository(this._db, {this.clock = const Clock()});

  static const int keep = 100;
  final AppDatabase _db;
  final Clock clock;

  Stream<List<CalcHistoryRow>> watch() =>
      (_db.select(_db.calcHistory)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(keep))
          .watch();

  Future<void> add(String expression, String result) async {
    await _db
        .into(_db.calcHistory)
        .insert(CalcHistoryCompanion.insert(expression: expression, result: result, at: clock.now()));
    await _db.customStatement(
      'DELETE FROM calc_history WHERE id NOT IN (SELECT id FROM calc_history ORDER BY id DESC LIMIT $keep)',
    );
  }

  Future<void> clear() => _db.delete(_db.calcHistory).go();
}
