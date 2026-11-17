import 'dart:io';

import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/audit/audit_logger.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/licensing/license_repository.dart';
import 'package:acekanner/data/licensing/scan_ledger.dart';
import 'package:acekanner/data/repositories/classes_repository.dart';
import 'package:acekanner/data/repositories/exams_repository.dart';
import 'package:acekanner/data/repositories/scan_repository.dart';
import 'package:acekanner/data/repositories/students_repository.dart';
import 'package:acekanner/data/secure/secret_store.dart';
import 'package:acekanner/data/settings/settings_repository.dart';
import 'package:acekanner/domain/licensing/entitlement.dart';
import 'package:acekanner/domain/licensing/license_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/licensing_fakes.dart';
import '../../support/omr_fixtures.dart';
import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late Directory tmp;
  late File image;
  late TestIssuer issuer;
  late String examId;
  late String versionId;
  late List<String> students;
  late ScanLedgerStore ledger;
  final clock = FixedClock(t0);

  setUp(() async {
    db = openTestDatabase();
    tmp = await Directory.systemTemp.createTemp('acek_charge_');
    image = File('${tmp.path}/r.jpg')..writeAsBytesSync(List.filled(64, 1));
    issuer = await TestIssuer.create();
    final audit = AuditLogger(db, clock: clock);
    final classes = ClassesRepository(db, clock: clock);
    final roster = StudentsRepository(db, audit, clock: clock);
    final section = await classes.createSection(const SectionInput(name: 'BSIT 2-A'));
    students = [
      for (var i = 0; i < 3; i++)
        (await roster.addToSection(section, StudentInput(studentNo: '2021-0000$i', lastName: 'S$i', firstName: 'F')))
            .student
            .id,
    ];
    examId = await ExamsRepository(db, audit, clock: clock)
        .create(ExamInput(title: 'Quiz', itemCount: 50, versionCount: 1, sectionIds: [section], studentIdDigits: 9));
    versionId = (await (db.select(db.examinationVersions)..where((t) => t.examinationId.equals(examId))).getSingle()).id;
    ledger = ScanLedgerStore(db, MemorySecretStore(), clock: clock);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  LicenseRepository repo({bool configured = true}) => LicenseRepository(
        db,
        ledger,
        SettingsRepository(db, clock: clock),
        configured: configured,
        verifier: EntitlementVerifier(issuer.config.entitlementKeys),
        clock: clock,
      );

  Future<String> save(LicenseRepository r, {String? student, String? replace}) {
    final scans = ScanRepository(db, AuditLogger(db, clock: clock), scansDirectory: () async => tmp, charger: r, clock: clock);
    return scans.save(ReviewedSheet(
      examId: examId,
      versionId: versionId,
      reading: reading(masks: List.filled(50, 1)),
      finalMasks: {for (var q = 1; q <= 50; q++) q: 1},
      overridden: const {},
      rectifiedImage: image,
      studentId: student,
      replaceSheetId: replace,
    ));
  }

  Future<int> sheets() async => (await db.select(db.answerSheets).get()).length;

  Future<void> grant(LicenseRepository r, {int used = 0, int? lease, DateTime? premiumUntil}) async {
    final token = await issuer.token(freeUsed: used, lease: lease, premiumUntil: premiumUntil, now: t0);
    await r.store(await EntitlementVerifier(issuer.config.entitlementKeys).verify(token));
  }

  test('one charge per student per exam: re-scans are free', () async {
    final r = repo();
    await grant(r);
    final first = await save(r, student: students[0]);
    await save(r, student: students[0], replace: first);
    await save(r, student: students[1]);
    final rows = await db.select(db.scanLedger).get();
    expect(rows, hasLength(2));
    expect(rows.every((x) => x.tier == 'free'), isTrue);
    expect((await r.status()).freeRemaining, 98);
  });

  test('papers without an identified student are charged per paper', () async {
    final r = repo();
    await grant(r);
    await save(r);
    await save(r);
    expect(await ledger.countFree(), 2);
  });

  test('when the allowance is used up nothing is saved', () async {
    final r = repo();
    await grant(r, used: 99);
    await save(r, student: students[0]);
    await expectLater(save(r, student: students[1]), throwsA(isA<ScanLimitException>()));
    expect(await sheets(), 1, reason: 'the refused paper was rolled back');
    expect(tmp.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.jpg') && f.path != image.path), hasLength(1),
        reason: 'its image was removed');
    // Re-scanning the already charged student still works.
    final again = await save(r, student: students[0]);
    expect(again, isNotEmpty);
  });

  test('signed out (configured build): scanning needs sign-in', () async {
    await expectLater(save(repo(), student: students[0]),
        throwsA(isA<ScanLimitException>().having((e) => e.block, 'block', ScanBlock.signInRequired)));
    expect(await sheets(), 0);
  });

  test('premium scans are recorded as premium and do not use free scans', () async {
    final r = repo();
    await grant(r, used: 100, lease: 0, premiumUntil: t0.add(const Duration(days: 365)));
    await save(r, student: students[0]);
    await save(r, student: students[1]);
    final rows = await db.select(db.scanLedger).get();
    expect(rows.map((x) => x.tier), ['premium', 'premium']);
    expect(rows.first.accountId, testAccount);
  });

  test('test build without licensing: 100 scans counted locally', () async {
    final r = repo(configured: false);
    for (var i = 0; i < 100; i++) {
      await ledger.append(submissionKey: hex64(i + 1), tier: 'free');
    }
    await expectLater(save(r, student: students[0]), throwsA(isA<ScanLimitException>()));
    expect((await r.status()).freeRemaining, 0);
  });

  test('an entitlement edited on the phone is ignored', () async {
    final r = repo();
    await grant(r, used: 99);
    await db.customStatement("UPDATE subscription_entitlements SET token = replace(token, 'a', 'b')");
    expect(await repo().current(), isNull);
  });

  test('the ledger is hash-chained, MAC-signed and append-only', () async {
    final r = repo();
    await grant(r);
    await save(r, student: students[0]);
    await save(r, student: students[1]);
    expect(await ledger.verifyChain(), isTrue);
    await expectLater(db.customStatement('DELETE FROM scan_ledger'), throwsA(anything));
    await expectLater(db.customStatement("UPDATE scan_ledger SET tier = 'premium'"), throwsA(anything));
    // A copy of the database moved to another install (different MAC key) does not verify.
    final other = ScanLedgerStore(db, MemorySecretStore(), clock: clock);
    expect(await other.verifyChain(), isFalse);
  });

  test('clock turned back past trusted time pauses scanning until a check-in', () async {
    final r = repo();
    await grant(r, premiumUntil: t0.add(const Duration(days: 365)));
    final earlier = LicenseRepository(
      db,
      ledger,
      SettingsRepository(db, clock: clock),
      configured: true,
      verifier: EntitlementVerifier(issuer.config.entitlementKeys),
      clock: FixedClock(t0.subtract(const Duration(days: 2))),
    );
    final s = await earlier.status();
    expect(s.clockTampered, isTrue);
    expect(s.block, ScanBlock.checkInRequired);
    expect((await r.status()).premiumActive, isTrue, reason: 'correct clock is fine');
  });

  test('sign-out forgets the plan but keeps papers and ledger', () async {
    final r = repo();
    await grant(r);
    await save(r, student: students[0]);
    await r.clear();
    expect(await r.current(), isNull);
    expect(await sheets(), 1);
    expect(await ledger.countFree(), 1);
    final unsynced = await (db.select(db.scanLedger)..where((t) => t.syncedAt.isNull())).get();
    expect(unsynced, hasLength(1));
  });
}
