import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../domain/personal_sheet_code.dart';
import '../../domain/short_code.dart';
import '../audit/audit_logger.dart';
import '../db/app_database.dart';

/// Records which answer sheets were printed or shared. Once a row exists the
/// examination's item count and sets are locked (sheets already exist).
class PrintedSheetsRepository {
  PrintedSheetsRepository(this._db, this._audit, {this.clock = const Clock()});

  final AppDatabase _db;
  final AuditLogger _audit;
  final Clock clock;

  Future<void> recordGeneric(String examId, {required String paper, required int copies}) {
    return _db.transaction(() async {
      await _db.into(_db.printedSheets).insert(
            PrintedSheetsCompanion.insert(
              id: newId(),
              examinationId: examId,
              sheetCode: 'G${ShortCode.generate(length: 11)}',
              paperSize: paper,
              copies: Value(copies.clamp(1, 1000)),
              generatedAt: clock.now(),
            ),
          );
      await _audit.record(
        event: 'sheets.generated',
        entityType: 'examination',
        entityId: examId,
        examinationId: examId,
        details: {'kind': 'generic', 'copies': copies, 'paper': paper},
      );
    });
  }

  Future<void> recordPersonalized(String examId, {required String paper, required List<String> studentIds}) {
    return _db.transaction(() async {
      final now = clock.now();
      for (final studentId in studentIds) {
        await _db.into(_db.printedSheets).insert(
              PrintedSheetsCompanion.insert(
                id: newId(),
                examinationId: examId,
                studentId: Value(studentId),
                sheetCode: personalSheetCode(examId, studentId),
                paperSize: paper,
                generatedAt: now,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      await _audit.record(
        event: 'sheets.generated',
        entityType: 'examination',
        entityId: examId,
        examinationId: examId,
        details: {'kind': 'personalized', 'students': studentIds.length, 'paper': paper},
      );
    });
  }
}
