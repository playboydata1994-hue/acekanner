import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:acekanner/data/db/app_database.dart';

/// Fresh in-memory database with the production schema and FK enforcement.
AppDatabase openTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

final DateTime t0 = DateTime.utc(2026, 11, 16, 8);

/// 64-char lower-case hex string derived from [seed] (for hash/key columns).
String hex64(int seed) => seed.toRadixString(16).padLeft(64, '0');

/// Inserts an examination with one version (A) and a current answer key.
/// Returns (examId, versionId, keyId).
Future<(String, String, String)> insertExam(
  AppDatabase db, {
  required String id,
  String title = 'Midterm Examination',
  int itemCount = 50,
  DateTime? updatedAt,
  DateTime? deletedAt,
}) async {
  final at = updatedAt ?? t0;
  await db.into(db.examinations).insert(
        ExaminationsCompanion.insert(
          id: id,
          shortCode: id.padRight(8, 'X').substring(0, 8).toUpperCase(),
          title: title,
          itemCount: itemCount,
          createdAt: at,
          updatedAt: at,
          deletedAt: Value(deletedAt),
        ),
      );
  final versionId = '$id-vA';
  await db.into(db.examinationVersions).insert(
        ExaminationVersionsCompanion.insert(
          id: versionId,
          examinationId: id,
          label: 'A',
          createdAt: at,
        ),
      );
  final keyId = '$id-k1';
  await db.into(db.answerKeys).insert(
        AnswerKeysCompanion.insert(
          id: keyId,
          examinationVersionId: versionId,
          revision: 1,
          createdAt: at,
        ),
      );
  return (id, versionId, keyId);
}

/// Inserts an answer sheet; finalized sheets get a submission key.
Future<String> insertSheet(
  AppDatabase db, {
  required String id,
  required String examId,
  String status = 'finalized',
  String? submissionKey,
}) async {
  final finalized = status == 'finalized';
  await db.into(db.answerSheets).insert(
        AnswerSheetsCompanion.insert(
          id: id,
          examinationId: examId,
          status: status,
          submissionKey: Value(submissionKey ?? (finalized ? hex64(id.hashCode.abs()) : null)),
          capturedAt: t0,
          finalizedAt: Value(finalized ? t0 : null),
          updatedAt: t0,
        ),
      );
  return id;
}

Future<void> insertLedger(
  AppDatabase db, {
  required String id,
  required String submissionKey,
  String tier = 'free',
  String? answerSheetId,
  int seed = 1,
}) {
  return db.into(db.scanLedger).insert(
        ScanLedgerCompanion.insert(
          id: id,
          submissionKey: submissionKey,
          answerSheetId: Value(answerSheetId),
          tier: tier,
          consumedAt: t0,
          prevHash: hex64(0),
          entryHash: hex64(1000 + seed),
          mac: hex64(2000 + seed),
        ),
      );
}
