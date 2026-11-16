import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:acekanner/data/db/app_database.dart';

import '../../support/test_db.dart';

Matcher get throwsSqlite => throwsA(isA<SqliteException>());

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('creates every table and enforces foreign keys', () async {
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .map((r) => r.read<String>('name'))
        .get();
    expect(tables, [
      'answer_key_items',
      'answer_keys',
      'answer_sheets',
      'application_settings',
      'audit_logs',
      'backup_records',
      'courses',
      'examination_results',
      'examination_sections',
      'examination_versions',
      'examinations',
      'instructor_profiles',
      'printed_sheets',
      'scan_ledger',
      'scan_sessions',
      'section_students',
      'sections',
      'student_answers',
      'students',
      'subjects',
      'subscription_entitlements',
    ]);
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.data.values.first, 1);
  });

  test('examinations accept only 50, 75 or 100 items', () async {
    await insertExam(db, id: 'exam50', itemCount: 50);
    await insertExam(db, id: 'exam75', itemCount: 75);
    await insertExam(db, id: 'exam100', itemCount: 100);
    expect(() => insertExam(db, id: 'exam60', itemCount: 60), throwsSqlite);
  });

  test('answer sheet must reference an existing examination', () async {
    expect(() => insertSheet(db, id: 's1', examId: 'missing'), throwsSqlite);
  });

  test('a finalized sheet needs a submission key', () async {
    await insertExam(db, id: 'e1');
    expect(
      () => db.into(db.answerSheets).insert(
            AnswerSheetsCompanion.insert(
              id: 's1',
              examinationId: 'e1',
              status: 'finalized',
              capturedAt: t0,
              finalizedAt: Value(t0),
              updatedAt: t0,
            ),
          ),
      throwsSqlite,
    );
  });

  test('only one finalized sheet per submission key; drafts may repeat', () async {
    await insertExam(db, id: 'e1');
    final key = hex64(42);
    await insertSheet(db, id: 's1', examId: 'e1', submissionKey: key);
    expect(
      () => insertSheet(db, id: 's2', examId: 'e1', submissionKey: key),
      throwsSqlite,
    );
    await insertSheet(db, id: 's3', examId: 'e1', status: 'needs_review', submissionKey: key);
    await insertSheet(db, id: 's4', examId: 'e1', status: 'superseded', submissionKey: key);
  });

  test('only one current answer key per examination version', () async {
    final (_, versionId, _) = await insertExam(db, id: 'e1');
    expect(
      () => db.into(db.answerKeys).insert(
            AnswerKeysCompanion.insert(
              id: 'k2',
              examinationVersionId: versionId,
              revision: 2,
              createdAt: t0,
            ),
          ),
      throwsSqlite,
    );
    await (db.update(db.answerKeys)..where((k) => k.id.equals('e1-k1')))
        .write(const AnswerKeysCompanion(isCurrent: Value(false)));
    await db.into(db.answerKeys).insert(
          AnswerKeysCompanion.insert(
            id: 'k2',
            examinationVersionId: versionId,
            revision: 2,
            createdAt: t0,
          ),
        );
  });

  test('answer key masks are limited to A-E', () async {
    await insertExam(db, id: 'e1');
    await db.into(db.answerKeyItems).insert(
          AnswerKeyItemsCompanion.insert(
            answerKeyId: 'e1-k1',
            questionNo: 1,
            correctMask: const Value(16),
          ),
        );
    expect(
      () => db.into(db.answerKeyItems).insert(
            AnswerKeyItemsCompanion.insert(
              answerKeyId: 'e1-k1',
              questionNo: 2,
              correctMask: const Value(32),
            ),
          ),
      throwsSqlite,
    );
  });

  test('subject codes are unique among active subjects, case-insensitively', () async {
    Future<void> add(String id, String code) => db.into(db.subjects).insert(
          SubjectsCompanion.insert(
            id: id,
            code: code,
            title: 'Programming 1',
            createdAt: t0,
            updatedAt: t0,
          ),
        );
    await add('sub1', 'CS101');
    expect(() => add('sub2', 'cs101'), throwsSqlite);
    await (db.update(db.subjects)..where((s) => s.id.equals('sub1')))
        .write(SubjectsCompanion(deletedAt: Value(t0)));
    await add('sub3', 'CS101');
  });

  group('scan ledger', () {
    setUp(() async {
      await insertExam(db, id: 'e1');
      await insertSheet(db, id: 's1', examId: 'e1', submissionKey: hex64(7));
      await insertLedger(db, id: 'L1', submissionKey: hex64(7), answerSheetId: 's1');
    });

    test('rejects a second charge for the same submission', () async {
      expect(
        () => insertLedger(db, id: 'L2', submissionKey: hex64(7), seed: 2),
        throwsSqlite,
      );
    });

    test('rows cannot be deleted', () async {
      expect(() => db.delete(db.scanLedger).go(), throwsSqlite);
      expect(await db.select(db.scanLedger).get(), hasLength(1));
    });

    test('charged fields cannot be edited', () async {
      expect(
        () => db.update(db.scanLedger).write(const ScanLedgerCompanion(tier: Value('premium'))),
        throwsSqlite,
      );
      expect(
        () => db.customStatement("UPDATE scan_ledger SET submission_key = '${hex64(8)}'"),
        throwsSqlite,
      );
    });

    test('sync bookkeeping can be recorded once', () async {
      await db.update(db.scanLedger).write(
            ScanLedgerCompanion(syncedAt: Value(t0), serverReceipt: const Value('r1')),
          );
      expect(
        () => db.update(db.scanLedger).write(
              ScanLedgerCompanion(syncedAt: Value(t0.add(const Duration(days: 1)))),
            ),
        throwsSqlite,
      );
    });

    test('purging an examination keeps the charge but unlinks the sheet', () async {
      await (db.delete(db.examinations)..where((e) => e.id.equals('e1'))).go();
      final rows = await db.select(db.scanLedger).get();
      expect(rows, hasLength(1));
      expect(rows.single.answerSheetId, isNull);
      expect(await db.select(db.answerSheets).get(), isEmpty);
    });
  });

  test('audit log is append-only', () async {
    await db.into(db.auditLogs).insert(
          AuditLogsCompanion.insert(
            id: 'a1',
            occurredAt: t0,
            actor: 'instructor',
            event: 'answer_key.revised',
            entityType: 'answer_key',
            prevHash: hex64(0),
            entryHash: hex64(1),
          ),
        );
    expect(
      () => db.update(db.auditLogs).write(const AuditLogsCompanion(event: Value('x'))),
      throwsSqlite,
    );
    expect(() => db.delete(db.auditLogs).go(), throwsSqlite);
  });

  test('deleting an examination removes all of its scan data', () async {
    final (examId, _, keyId) = await insertExam(db, id: 'e1');
    await db.into(db.answerKeyItems).insert(
          AnswerKeyItemsCompanion.insert(answerKeyId: keyId, questionNo: 1),
        );
    await insertSheet(db, id: 's1', examId: examId);
    await db.into(db.studentAnswers).insert(
          StudentAnswersCompanion.insert(
            answerSheetId: 's1',
            questionNo: 1,
            detectedState: 'answered',
            bubbleScores: '[0.9,0,0,0,0]',
            confidence: 0.98,
          ),
        );
    await db.into(db.examinationResults).insert(
          ExaminationResultsCompanion.insert(
            id: 'r1',
            answerSheetId: 's1',
            answerKeyId: keyId,
            correctCount: 1,
            incorrectCount: 0,
            blankCount: 0,
            multipleCount: 0,
            earnedPoints: 1,
            possiblePoints: 1,
            percentage: 100,
            passed: true,
            gradedAt: t0,
          ),
        );

    await (db.delete(db.examinations)..where((e) => e.id.equals(examId))).go();

    for (final table in [
      'examination_versions',
      'answer_keys',
      'answer_key_items',
      'answer_sheets',
      'student_answers',
      'examination_results',
    ]) {
      final count = await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
      expect(count.read<int>('c'), 0, reason: table);
    }
  });

  group('dashboard queries', () {
    test('count active exams, saved papers (reviewed or graded) and free charges', () async {
      await insertExam(db, id: 'e1');
      await insertExam(db, id: 'e2', deletedAt: t0);
      await insertSheet(db, id: 's1', examId: 'e1');
      await insertSheet(db, id: 's2', examId: 'e1', status: 'needs_review');
      await insertSheet(db, id: 's2b', examId: 'e1', status: 'superseded', submissionKey: hex64(77));
      await insertSheet(db, id: 's3', examId: 'e2');
      await insertLedger(db, id: 'L1', submissionKey: hex64(1), seed: 1);
      await insertLedger(db, id: 'L2', submissionKey: hex64(2), seed: 2, tier: 'premium');

      final stats = await db.dashboardStats().getSingle();
      expect(stats.examCount, 1);
      expect(stats.papersScanned, 2, reason: 'superseded papers and deleted exams are not counted');
      expect(stats.freeScansUsedLocal, 1);
    });

    test('recent examinations are newest first with paper counts', () async {
      await insertExam(db, id: 'old', title: 'Prelim', updatedAt: t0);
      await insertExam(
        db,
        id: 'new',
        title: 'Midterm',
        updatedAt: t0.add(const Duration(days: 3)),
      );
      await insertSheet(db, id: 's1', examId: 'new');
      await insertSheet(db, id: 's2', examId: 'new');

      final rows = await db.recentExaminations(limit: 5).get();
      expect(rows.map((r) => r.title), ['Midterm', 'Prelim']);
      expect(rows.first.finalizedCount, 2);
      expect(rows.last.finalizedCount, 0);
    });
  });
}
