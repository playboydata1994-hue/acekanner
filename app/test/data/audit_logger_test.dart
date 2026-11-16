import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/audit/audit_logger.dart';
import 'package:acekanner/data/db/app_database.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late AuditLogger audit;

  setUp(() {
    db = openTestDatabase();
    audit = AuditLogger(db, clock: FixedClock(t0));
  });
  tearDown(() => db.close());

  test('entries chain from the genesis hash and verify', () async {
    await audit.record(event: 'examination.created', entityType: 'examination', entityId: 'e1');
    await audit.record(
      event: 'answer_key.updated',
      entityType: 'answer_key',
      entityId: 'k1',
      examinationId: 'e1',
      details: {'changed': 3},
    );
    final rows = await (db.select(db.auditLogs)..orderBy([(t) => OrderingTerm.asc(t.seq)])).get();
    expect(rows, hasLength(2));
    expect(rows[0].prevHash, AuditLogger.genesisHash);
    expect(rows[1].prevHash, rows[0].entryHash);
    expect(rows[1].details, '{"changed":3}');
    expect(await audit.findBrokenEntry(), isNull);
  });

  test('an entry rolls back with its transaction', () async {
    await expectLater(
      db.transaction(() async {
        await audit.record(event: 'x.y', entityType: 'x');
        throw StateError('change failed');
      }),
      throwsStateError,
    );
    expect(await db.select(db.auditLogs).get(), isEmpty);
  });

  test('tampering is detected', () async {
    await audit.record(event: 'a.b', entityType: 'x');
    await audit.record(event: 'c.d', entityType: 'x');
    // Simulate an attacker who bypasses the triggers (e.g. edits the file).
    await db.customStatement('DROP TRIGGER audit_logs_no_update');
    await db.customStatement("UPDATE audit_logs SET event = 'z.z' WHERE seq = 1");
    expect(await audit.findBrokenEntry(), 1);
  });
}
