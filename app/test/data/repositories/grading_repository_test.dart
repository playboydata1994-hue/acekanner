import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/audit/audit_logger.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/errors.dart';
import 'package:acekanner/data/repositories/answer_key_repository.dart';
import 'package:acekanner/data/repositories/classes_repository.dart';
import 'package:acekanner/data/repositories/exams_repository.dart';
import 'package:acekanner/data/repositories/grading_repository.dart';
import 'package:acekanner/data/repositories/scan_repository.dart';
import 'package:acekanner/data/repositories/students_repository.dart';
import 'package:acekanner/domain/grading.dart';

import '../../support/omr_fixtures.dart';
import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late Directory tmp;
  late GradingRepository grading;
  late ExamsRepository exams;
  late AnswerKeyRepository keys;
  late ScanRepository scans;
  late StudentsRepository students;
  late String sectionId;
  late List<StudentRow> roster;

  /// Correct answers: question q -> choice (q - 1) % 5.
  int keyMask(int q) => 1 << ((q - 1) % 5);

  setUp(() async {
    db = openTestDatabase();
    tmp = await Directory.systemTemp.createTemp('acek_grade_');
    final clock = FixedClock(t0);
    final audit = AuditLogger(db, clock: clock);
    grading = GradingRepository(db, audit, clock: clock);
    exams = ExamsRepository(db, audit, grading: grading, clock: clock);
    keys = AnswerKeyRepository(db, audit, exams, grading: grading, clock: clock);
    scans = ScanRepository(db, audit, scansDirectory: () async => tmp, grading: grading, clock: clock);
    students = StudentsRepository(db, audit, clock: clock);
    sectionId = await ClassesRepository(db, clock: clock).createSection(const SectionInput(name: 'BSIT 2-A'));
    roster = [
      for (var i = 0; i < 4; i++)
        (await students.addToSection(
          sectionId,
          StudentInput(studentNo: '202100$i', lastName: 'Student$i', firstName: 'S'),
        ))
            .student,
    ];
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  Future<(String, String)> examWithKey({bool complete = true, int sets = 1}) async {
    final id = await exams.create(ExamInput(title: 'Midterm', itemCount: 50, versionCount: sets, sectionIds: [sectionId]));
    final versionId = (await exams.loadDetail(id))!.versions.first.version.id;
    if (complete) {
      for (final v in (await exams.loadDetail(id))!.versions) {
        final items = (await keys.load(v.version.id)).items;
        await keys.save(v.version.id, [for (final i in items) i.copyWith(mask: keyMask(i.questionNo))]);
      }
    }
    return (id, versionId);
  }

  /// Saves a reviewed paper whose first [correct] answers match the key.
  Future<String> scan(String examId, String versionId, StudentRow student, int correct, {String? replace}) {
    final masks = [for (var q = 1; q <= 50; q++) q <= correct ? keyMask(q) : (keyMask(q) << 1) % 31];
    final image = File('${tmp.path}/rect-${student.id}.jpg')..writeAsBytesSync([1, 2, 3]);
    return scans.save(ReviewedSheet(
      examId: examId,
      versionId: versionId,
      reading: reading(masks: masks),
      finalMasks: {for (var q = 1; q <= 50; q++) q: masks[q - 1]},
      overridden: const {},
      rectifiedImage: image,
      studentId: student.id,
      replaceSheetId: replace,
    ));
  }

  Future<ExaminationResultRow> current(String sheetId) => (db.select(db.examinationResults)
        ..where((t) => t.answerSheetId.equals(sheetId) & t.isCurrent.equals(true)))
      .getSingle();

  test('a paper saved when the key is complete is graded immediately', () async {
    final (examId, versionId) = await examWithKey();
    final sheetId = await scan(examId, versionId, roster[0], 40);

    final sheet = await (db.select(db.answerSheets)..where((t) => t.id.equals(sheetId))).getSingle();
    expect(sheet.status, 'finalized');
    expect(sheet.submissionKey, GradingRepository.submissionKey(examId, roster[0].id));
    final r = await current(sheetId);
    expect([r.correctCount, r.incorrectCount, r.blankCount], [40, 10, 0]);
    expect(r.percentage, 80);
    expect(r.passed, isTrue);

    // Finalizing again changes nothing.
    final again = await grading.finalize(sheetId);
    expect(again.id, r.id);
    expect(await db.select(db.examinationResults).get(), hasLength(1));
  });

  test('papers saved before the key was complete are graded when it is completed', () async {
    final (examId, versionId) = await examWithKey(complete: false);
    final sheetId = await scan(examId, versionId, roster[0], 30);
    expect((await (db.select(db.answerSheets)..where((t) => t.id.equals(sheetId))).getSingle()).status, 'needs_review');
    await expectLater(grading.finalize(sheetId), throwsA(isA<DataException>()));

    final items = (await keys.load(versionId)).items;
    await keys.save(versionId, [for (final i in items) i.copyWith(mask: keyMask(i.questionNo))]);
    expect((await current(sheetId)).percentage, 60);
  });

  test('a key revision re-grades every paper and keeps the old results as history', () async {
    final (examId, versionId) = await examWithKey();
    final a = await scan(examId, versionId, roster[0], 50);
    final b = await scan(examId, versionId, roster[1], 45);
    final before = await current(b);
    expect(before.percentage, 90);

    // Question 50: accept the answer student B gave as well (B answered wrong on 46-50).
    final items = (await keys.load(versionId)).items;
    final bAnswer50 = (keyMask(50) << 1) % 31;
    final revised = [...items]..[49] = items[49].copyWith(mask: keyMask(50) | bAnswer50);
    final result = await keys.save(versionId, revised, changeNote: 'Q50 has two correct answers');
    expect(result.newRevision, isTrue);

    final after = await current(b);
    expect(after.id, isNot(before.id));
    expect(after.percentage, 92);
    expect((await current(a)).percentage, 100);
    final history = await (db.select(db.examinationResults)..where((t) => t.answerSheetId.equals(b))).get();
    expect(history, hasLength(2));
    expect(history.where((h) => h.isCurrent), hasLength(1));

    final regrades = (await db.select(db.auditLogs).get()).where((l) => l.event == 'results.regraded');
    expect(regrades.single.details, contains('"changed":1'));
  });

  test('changing the pass mark or multiple-mark policy updates current results', () async {
    final (examId, versionId) = await examWithKey();
    final sheetId = await scan(examId, versionId, roster[0], 35); // 70 %
    expect((await current(sheetId)).passed, isFalse);

    await exams.update(examId, const ExamInput(title: 'Midterm', itemCount: 50, passingPercentage: 60));
    final r = await current(sheetId);
    expect(r.passed, isTrue);
    expect(await (db.select(db.examinationResults)..where((t) => t.answerSheetId.equals(sheetId))).get(), hasLength(1));
  });

  test('correcting a reading re-scores the paper and is audited', () async {
    final (examId, versionId) = await examWithKey();
    final sheetId = await scan(examId, versionId, roster[0], 49);
    await grading.correctAnswers(sheetId, {50: keyMask(50)});
    expect((await current(sheetId)).percentage, 100);
    final answer = await (db.select(db.studentAnswers)
          ..where((t) => t.answerSheetId.equals(sheetId) & t.questionNo.equals(50)))
        .getSingle();
    expect(answer.resolvedBy, 'instructor');
    expect((await db.select(db.auditLogs).get()).map((l) => l.event), contains('answer.corrected'));
  });

  test('re-scanning a student replaces the earlier graded paper (one submission)', () async {
    final (examId, versionId) = await examWithKey();
    final first = await scan(examId, versionId, roster[0], 30);
    final second = await scan(examId, versionId, roster[0], 32, replace: first);
    final sheets = await db.select(db.answerSheets).get();
    expect(sheets.firstWhere((s) => s.id == first).status, 'superseded');
    expect(sheets.firstWhere((s) => s.id == second).status, 'finalized');
    expect(sheets.where((s) => s.status == 'finalized'), hasLength(1));
    expect((await scans.watchPapers(examId).first).single.result!.percentage, 64);
  });

  test('a paper without a student cannot be graded', () async {
    final (examId, versionId) = await examWithKey();
    final image = File('${tmp.path}/x.jpg')..writeAsBytesSync([1]);
    final id = await scans.save(ReviewedSheet(
      examId: examId,
      versionId: versionId,
      reading: reading(masks: List.filled(50, 1)),
      finalMasks: {for (var q = 1; q <= 50; q++) q: 1},
      overridden: const {},
      rectifiedImage: image,
    ));
    await expectLater(grading.finalize(id), throwsA(isA<DataException>()));
  });

  test('paper detail and class analytics', () async {
    final (examId, versionId) = await examWithKey();
    final scores = [50, 45, 40, 20];
    final ids = [for (var i = 0; i < 4; i++) await scan(examId, versionId, roster[i], scores[i])];

    final detail = (await grading.paperDetail(ids[1]))!;
    expect(detail.student!.id, roster[1].id);
    expect(detail.keyRevision, 1);
    expect(detail.grade!.questions[45].outcome, ItemOutcome.incorrect);
    expect(detail.grade!.questions[0].outcome, ItemOutcome.correct);

    final a = await grading.analytics(examId);
    final stats = a.stats();
    expect(stats.count, 4);
    expect(stats.highest, 100);
    expect(stats.lowest, 40);
    expect(stats.mean, closeTo(77.5, 1e-9));
    expect(stats.passed, 3);
    expect(a.stats(sectionId: sectionId).count, 4);
    expect(a.stats(sectionId: 'other').count, 0);

    final items = a.items(versionId);
    expect(items, hasLength(50));
    expect(items[0].difficulty, 1.0);
    expect(items[49].difficulty, 0.25); // only the perfect paper
  });
}
