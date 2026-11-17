import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/audit/audit_logger.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/errors.dart';
import 'package:acekanner/data/repositories/answer_key_repository.dart';
import 'package:acekanner/data/repositories/classes_repository.dart';
import 'package:acekanner/data/repositories/exams_repository.dart';
import 'package:acekanner/domain/short_code.dart';

import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late ExamsRepository exams;
  late AnswerKeyRepository keys;
  late ClassesRepository classes;
  late AuditLogger audit;

  setUp(() {
    db = openTestDatabase();
    final clock = FixedClock(t0);
    audit = AuditLogger(db, clock: clock);
    exams = ExamsRepository(db, audit, clock: clock);
    keys = AnswerKeyRepository(db, audit, exams, clock: clock);
    classes = ClassesRepository(db, clock: clock);
  });
  tearDown(() => db.close());

  Future<String> createExam({int items = 50, int sets = 1, double points = 1}) => exams.create(
        ExamInput(title: ' Midterm  Exam ', itemCount: items, versionCount: sets, pointsPerItem: points),
      );

  test('creating an exam builds its sets, keys and items', () async {
    final section = await classes.createSection(const SectionInput(name: 'BSIT 2-A'));
    final id = await exams.create(
      ExamInput(
        title: 'Midterm',
        itemCount: 75,
        versionCount: 3,
        sectionIds: [section],
        pointsPerItem: 2,
        negativePoints: 0.25,
      ),
    );
    final detail = (await exams.loadDetail(id))!;
    expect(detail.exam.status, ExamStatus.draft);
    expect(ShortCode.isValid(detail.exam.shortCode), isTrue);
    expect(detail.versions.map((v) => v.version.label), ['A', 'B', 'C']);
    expect(detail.versions.every((v) => v.itemTotal == 75 && v.completeCount == 0), isTrue);
    expect(detail.sections.single.name, 'BSIT 2-A');
    expect(detail.structureLocked, isFalse);

    final key = await keys.load(detail.versions.first.version.id);
    expect(key.items.first.points, 2);
    expect(key.items.first.negativePoints, 0.25);
    expect((await exams.watchActive().first).single.versionCount, 3);
  });

  test('invalid input is rejected before touching the database', () async {
    expect(() => exams.create(const ExamInput(title: ' ', itemCount: 50)), throwsA(isA<DataException>()));
    expect(() => exams.create(const ExamInput(title: 'X', itemCount: 60)), throwsA(isA<DataException>()));
    expect(
      () => exams.create(const ExamInput(title: 'X', itemCount: 50, versionCount: 6)),
      throwsA(isA<DataException>()),
    );
  });

  test('an examination can have five sets, A to E', () async {
    final id = await exams.create(const ExamInput(title: 'Finals', itemCount: 100, versionCount: 5));
    final detail = (await exams.loadDetail(id))!;
    expect(detail.versions.map((v) => v.version.label), ['A', 'B', 'C', 'D', 'E']);
    // Growing from 2 sets to 5 adds C, D and E.
    final other = await createExam(items: 50, sets: 2);
    await exams.update(other, const ExamInput(title: 'Midterm', itemCount: 50, versionCount: 5));
    expect((await exams.loadDetail(other))!.versions.map((v) => v.version.label), ['A', 'B', 'C', 'D', 'E']);
  });

  test('item count and sets can change until sheets exist, then they lock', () async {
    final id = await createExam(items: 50, sets: 2);
    await exams.update(id, const ExamInput(title: 'Midterm', itemCount: 100, versionCount: 1));
    var detail = (await exams.loadDetail(id))!;
    expect(detail.versions, hasLength(1));
    expect(detail.versions.single.itemTotal, 100);

    await exams.update(id, const ExamInput(title: 'Midterm', itemCount: 75, versionCount: 2));
    detail = (await exams.loadDetail(id))!;
    expect(detail.versions.map((v) => v.itemTotal), [75, 75]);

    await insertSheet(db, id: 's1', examId: id, status: 'needs_review');
    expect(await exams.isStructureLocked(id), isTrue);
    await expectLater(
      exams.update(id, const ExamInput(title: 'Midterm', itemCount: 50, versionCount: 2)),
      throwsA(isA<LockedException>()),
    );
    // Other details can still change.
    await exams.update(id, const ExamInput(title: 'Final', itemCount: 75, versionCount: 2));
    expect((await exams.loadDetail(id))!.exam.title, 'Final');
  });

  test('saving a complete key makes the exam ready; clearing one item reverts', () async {
    final id = await createExam(items: 50);
    final versionId = (await exams.loadDetail(id))!.versions.single.version.id;
    var data = await keys.load(versionId);
    final full = [for (final i in data.items) i.copyWith(mask: 1 << (i.questionNo % 5))];

    final result = await keys.save(versionId, full);
    expect(result.newRevision, isFalse);
    expect(result.changed, hasLength(50));
    expect((await exams.loadDetail(id))!.exam.status, ExamStatus.ready);

    final cleared = [...full]..[9] = full[9].copyWith(mask: 0);
    await keys.save(versionId, cleared);
    expect((await exams.loadDetail(id))!.exam.status, ExamStatus.draft);

    // A dropped question needs no answer.
    final dropped = [...cleared]..[9] = cleared[9].copyWith(mode: KeyItemMode.dropped);
    await keys.save(versionId, dropped);
    expect((await exams.loadDetail(id))!.exam.status, ExamStatus.ready);

    data = await keys.load(versionId);
    expect(data.key.revision, 1);
    expect(data.items[9].mode, KeyItemMode.dropped);
  });

  test('saving an unchanged key writes nothing', () async {
    final id = await createExam();
    final versionId = (await exams.loadDetail(id))!.versions.single.version.id;
    final before = (await db.select(db.auditLogs).get()).length;
    final result = await keys.save(versionId, (await keys.load(versionId)).items);
    expect(result.changed, isEmpty);
    expect((await db.select(db.auditLogs).get()).length, before);
  });

  test('after a paper is finalized, edits create a new revision with a reason', () async {
    final id = await createExam(items: 50);
    final versionId = (await exams.loadDetail(id))!.versions.single.version.id;
    final items = [for (final i in (await keys.load(versionId)).items) i.copyWith(mask: 1)];
    await keys.save(versionId, items);
    await insertSheet(db, id: 's1', examId: id);

    final corrected = [...items]..[4] = items[4].copyWith(mask: 3); // accept A or B
    await expectLater(keys.save(versionId, corrected), throwsA(isA<DataException>()));

    final result = await keys.save(versionId, corrected, changeNote: 'Item 5 had two correct answers');
    expect(result.newRevision, isTrue);
    expect(result.revision, 2);
    expect(result.changed, [5]);

    final allKeys = await (db.select(db.answerKeys)..orderBy([(t) => OrderingTerm.asc(t.revision)])).get();
    expect(allKeys.map((k) => (k.revision, k.isCurrent)), [(1, false), (2, true)]);
    expect((await keys.load(versionId)).items[4].mask, 3);

    final revised = (await db.select(db.auditLogs).get()).where((a) => a.event == 'answer_key.revised');
    expect(revised.single.details, contains('"questions":[5]'));
    expect(await audit.findBrokenEntry(), isNull);
  });

  test('key validation', () async {
    final id = await createExam(items: 50);
    final versionId = (await exams.loadDetail(id))!.versions.single.version.id;
    final items = (await keys.load(versionId)).items;
    await expectLater(keys.save(versionId, items.sublist(1)), throwsA(isA<DataException>()));
    await expectLater(
      keys.save(versionId, [...items]..[0] = items[0].copyWith(mask: 32)),
      throwsA(isA<DataException>()),
    );
    await expectLater(
      keys.save(versionId, [...items]..[0] = items[0].copyWith(points: -1)),
      throwsA(isA<DataException>()),
    );
  });

  test('trash, restore and permanent deletion', () async {
    final id = await createExam();
    await expectLater(exams.deletePermanently(id), throwsA(isA<DataException>()));

    await exams.moveToTrash(id);
    expect(await exams.watchActive().first, isEmpty);
    expect((await exams.watchDeleted().first).single.exam.id, id);

    await exams.restore(id);
    expect(await exams.watchActive().first, hasLength(1));

    await exams.moveToTrash(id);
    await exams.deletePermanently(id);
    expect(await exams.watchDeleted().first, isEmpty);
    expect(await db.select(db.answerKeyItems).get(), isEmpty);
    final events = (await db.select(db.auditLogs).get()).map((a) => a.event).toList();
    expect(events, containsAllInOrder([
      'examination.created',
      'examination.trashed',
      'examination.restored',
      'examination.trashed',
      'examination.purged',
    ]));
  });

  test('watchDetail re-emits when the key changes', () async {
    final id = await createExam(items: 50);
    final versionId = (await exams.loadDetail(id))!.versions.single.version.id;
    final stream = exams.watchDetail(id);
    final seen = <int>[];
    final sub = stream.listen((d) => seen.add(d!.versions.single.completeCount));
    await pumpEventQueue();
    final items = (await keys.load(versionId)).items;
    await keys.save(versionId, [...items]..[0] = items[0].copyWith(mask: 1));
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen.last, 1);
  });
}
