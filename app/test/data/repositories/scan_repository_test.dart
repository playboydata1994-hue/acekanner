import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/audit/audit_logger.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/errors.dart';
import 'package:acekanner/data/repositories/classes_repository.dart';
import 'package:acekanner/data/repositories/exams_repository.dart';
import 'package:acekanner/data/repositories/scan_repository.dart';
import 'package:acekanner/data/repositories/students_repository.dart';
import 'package:acekanner/domain/omr_reading.dart';
import 'package:acekanner/domain/personal_sheet_code.dart';
import 'package:acekanner/domain/sheet_layout.dart';
import 'package:acekanner/domain/sheet_qr.dart';

import '../../support/omr_fixtures.dart';
import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late ScanRepository scans;
  late Directory tmp;
  late String examId;
  late StudentRow juan;
  late StudentRow outsider;

  setUp(() async {
    db = openTestDatabase();
    tmp = await Directory.systemTemp.createTemp('acek_scan_');
    final clock = FixedClock(t0);
    final audit = AuditLogger(db, clock: clock);
    scans = ScanRepository(db, audit, scansDirectory: () async => tmp, clock: clock);
    final classes = ClassesRepository(db, clock: clock);
    final students = StudentsRepository(db, audit, clock: clock);
    final section = await classes.createSection(const SectionInput(name: 'BSIT 2-A'));
    final other = await classes.createSection(const SectionInput(name: 'BSIT 2-B'));
    juan = (await students.addToSection(
      section,
      const StudentInput(studentNo: '2021-00123', lastName: 'Dela Cruz', firstName: 'Juan'),
    ))
        .student;
    outsider = (await students.addToSection(
      other,
      const StudentInput(studentNo: '2021-00999', lastName: 'Reyes', firstName: 'Ana'),
    ))
        .student;
    examId = await ExamsRepository(db, audit, clock: clock).create(
      ExamInput(title: 'Quiz', itemCount: 50, versionCount: 2, sectionIds: [section], studentIdDigits: 9),
    );
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('context describes the exam, its sets, layout and roster', () async {
    final ctx = await scans.context(examId);
    expect(ctx.versions.map((v) => v.label), ['A', 'B']);
    expect(ctx.layout.itemCount, 50);
    expect(ctx.layout.idDigits, 9);
    expect(ctx.layout.setCount, 2);
    expect(ctx.roster.map((s) => s.id), [juan.id]);
  });

  test('identifies by personalized QR, then by shaded number', () async {
    final ctx = await scans.context(examId);
    final code = personalSheetCode(examId, juan.id);
    final qr = SheetQr(examCode: ctx.exam.shortCode, itemCount: 50, idDigits: 9, setCount: 2, sheetCode: code).encode();

    final byQr = await scans.identify(ctx, reading(masks: List.filled(50, 1), qr: qr, studentNumber: '', clear: false));
    expect(byQr.by, IdentifiedBy.qrCode);
    expect(byQr.student!.id, juan.id);

    final byNumber = await scans.identify(ctx, reading(masks: List.filled(50, 1), studentNumber: '202100123'));
    expect(byNumber.by, IdentifiedBy.studentNumber);
    expect(byNumber.student!.id, juan.id);

    // Not in the exam's sections, but a saved student: still found.
    final elsewhere = await scans.identify(ctx, reading(masks: List.filled(50, 1), studentNumber: '202100999'));
    expect(elsewhere.student!.id, outsider.id);

    final unclear = await scans.identify(ctx, reading(masks: List.filled(50, 1), studentNumber: '2021?0123', clear: false));
    expect(unclear.by, IdentifiedBy.none);
    expect(unclear.detectedNumber, '2021?0123');
  });

  test('sheets from another examination or with other settings are accepted with a note', () async {
    final ctx = await scans.context(examId);
    final foreign = const SheetQr(examCode: 'ZZZZZZZZ', itemCount: 50, idDigits: 9, setCount: 2).encode();
    final r = reading(masks: List.filled(50, 1), qr: foreign);
    expect(scans.sheetMismatch(ctx, r), isNull, reason: 'any ACEkanner sheet with enough questions is read');
    expect(scans.sheetNote(ctx, r), contains('ZZZZZZZZ'));
    final mine = SheetQr(examCode: ctx.exam.shortCode, itemCount: 50, idDigits: 9, setCount: 2).encode();
    expect(scans.sheetNote(ctx, reading(masks: List.filled(50, 1), qr: mine)), isNull);
    final stale = SheetQr(examCode: ctx.exam.shortCode, itemCount: 50, idDigits: 10, setCount: 2).encode();
    expect(scans.sheetMismatch(ctx, reading(masks: List.filled(50, 1), qr: stale)), isNull);
    expect(scans.sheetMismatch(ctx, reading(masks: List.filled(50, 1))), isNull);
    final bigger = reading(masks: List.filled(100, 1), qr: mine);
    expect(scans.sheetNote(ctx, bigger), '100-item sheet: only questions 1–50 are checked.');
    final oldDesign = 'ACK1|${ctx.exam.shortCode}|50|9|2|G';
    expect(scans.sheetMismatch(ctx, reading(masks: List.filled(50, 1), qr: oldDesign)), contains('older ACEkanner'));
  });

  group('readSheet', () {
    late ScanContext ctx;
    setUp(() async => ctx = await scans.context(examId));

    test('the examination\'s own sheet is read once', () async {
      final layouts = <SheetLayout>[];
      final r = await readSheet(ctx, (l) async {
        layouts.add(l);
        return reading(masks: List.filled(50, 1));
      });
      expect(r, isA<OmrSheetReading>());
      expect(layouts.map((l) => l.itemCount), [50]);
    });

    test('a bigger sheet is read again with its own layout', () async {
      final layouts = <SheetLayout>[];
      final r = await readSheet(ctx, (l) async {
        layouts.add(l);
        return l.itemCount == 50
            ? const OmrFailure(code: 'wrong_template', message: 'x', detectedItemCount: 100)
            : reading(masks: List.filled(100, 1));
      });
      expect((r as OmrSheetReading).questions, hasLength(100));
      expect(layouts.map((l) => (l.itemCount, l.idDigits, l.setCount)), [(50, 9, 2), (100, 9, 2)]);
    });

    test('a sheet with fewer questions than the examination uses is refused', () async {
      await (db.update(db.examinations)..where((t) => t.id.equals(examId)))
          .write(const ExaminationsCompanion(itemCount: Value(100), questionsUsed: Value(90)));
      final big = await scans.context(examId);
      final r = await readSheet(big, (l) async => const OmrFailure(code: 'wrong_template', message: 'x', detectedItemCount: 75));
      expect((r as OmrFailure).code, 'too_small_sheet');
      expect(r.explanation, 'This is a 75-item answer sheet, but this examination uses 90 questions.');
    });

    test('a sheet printed with other settings is read with them (from its QR code)', () async {
      final layouts = <SheetLayout>[];
      final other = const SheetQr(examCode: 'ZZZZZZZZ', itemCount: 50, idDigits: 12, setCount: 3).encode();
      final r = await readSheet(ctx, (l) async {
        layouts.add(l);
        return reading(masks: List.filled(50, 1), qr: other);
      });
      expect(r, isA<OmrSheetReading>());
      expect(layouts.map((l) => (l.idDigits, l.setCount)), [(9, 2), (12, 3)]);
    });

    test('engine failures other than a different sheet are returned as they are', () async {
      final r = await readSheet(ctx, (l) async => const OmrFailure(code: 'glare', message: 'Glare.'));
      expect((r as OmrFailure).code, 'glare');
    });
  });

  test('saving stores answers, image, session counts and an audit entry; a re-scan replaces', () async {
    final ctx = await scans.context(examId);
    final session = await scans.startSession(examId, 'batch');
    await scans.recordCapture(session, rejected: true);
    await scans.recordCapture(session, rejected: false);
    final image = File('${tmp.path}/rect.jpg')..writeAsBytesSync(List.filled(1000, 7));
    final r = reading(masks: List.generate(50, (i) => 1 << (i % 5)), uncertain: {3});

    final firstId = await scans.save(ReviewedSheet(
      examId: examId,
      versionId: ctx.versions.first.id,
      reading: r,
      finalMasks: {for (var q = 1; q <= 50; q++) q: q == 3 ? 16 : 1 << ((q - 1) % 5)},
      overridden: {3},
      rectifiedImage: image,
      studentId: juan.id,
      sessionId: session,
    ));

    final sheet = await (db.select(db.answerSheets)..where((t) => t.id.equals(firstId))).getSingle();
    expect(sheet.status, 'needs_review');
    expect(sheet.flaggedCount, 1);
    expect(File(sheet.rectifiedImagePath!).existsSync(), isTrue);
    final answers = await (db.select(db.studentAnswers)..where((t) => t.answerSheetId.equals(firstId))).get();
    expect(answers, hasLength(50));
    final q3 = answers.firstWhere((a) => a.questionNo == 3);
    expect(q3.detectedState, MarkState.uncertain.name);
    expect(q3.finalMask, 16);
    expect(q3.resolvedBy, 'instructor');
    final s = await (db.select(db.scanSessions)..where((t) => t.id.equals(session))).getSingle();
    expect([s.capturesAttempted, s.capturesRejected, s.sheetsFinalized], [2, 1, 1]);

    expect((await scans.existingPaper(examId, juan.id))!.id, firstId);
    final secondId = await scans.save(ReviewedSheet(
      examId: examId,
      versionId: ctx.versions.first.id,
      reading: r,
      finalMasks: {for (var q = 1; q <= 50; q++) q: 1},
      overridden: const {},
      rectifiedImage: image,
      studentId: juan.id,
      replaceSheetId: firstId,
    ));
    final first = await (db.select(db.answerSheets)..where((t) => t.id.equals(firstId))).getSingle();
    expect(first.status, 'superseded');
    final papers = await scans.watchPapers(examId).first;
    expect(papers.map((p) => p.sheet.id), [secondId]);
    expect(papers.single.student!.lastName, 'Dela Cruz');
    expect(papers.single.versionLabel, 'A');

    final events = (await db.select(db.auditLogs).get()).map((a) => a.event);
    expect(events, containsAll(['answer_sheet.scanned', 'answer_sheet.rescanned']));
  });

  test('saving requires a final answer for every question', () async {
    final ctx = await scans.context(examId);
    final image = File('${tmp.path}/rect.jpg')..writeAsBytesSync([1, 2, 3]);
    await expectLater(
      scans.save(ReviewedSheet(
        examId: examId,
        versionId: ctx.versions.first.id,
        reading: reading(masks: List.filled(50, 1)),
        finalMasks: {1: 1},
        overridden: const {},
        rectifiedImage: image,
      )),
      throwsA(isA<DataException>()),
    );
  });

  test('engine failures parse into instructor-facing explanations', () {
    final f = OmrReading.parse('{"ok":false,"error":"wrong_template","message":"x","markersFound":0,"detectedItemCount":100}') as OmrFailure;
    expect(f.explanation, contains('100-item'));
    final g = OmrReading.parse('{"ok":false,"error":"glare","message":"There is glare on the sheet."}') as OmrFailure;
    expect(g.explanation, 'There is glare on the sheet.');
  });
}
