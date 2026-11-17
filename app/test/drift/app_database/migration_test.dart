// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('v1 -> v2 keeps the profile and lets the full name be empty', () async {
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase.execute(
      "INSERT INTO instructor_profiles (id, full_name, honorific, school_name, logo_path, created_at, updated_at) "
      "VALUES ('p1', 'Maria Santos', 'Prof.', 'State University', '/branding/logo.png', 1763337600, 1763337600)",
    );
    // A v1 database refuses a missing name.
    expect(
      () => schema.rawDatabase.execute(
        "INSERT INTO instructor_profiles (id, full_name, created_at, updated_at) VALUES ('p2', NULL, 1, 1)",
      ),
      throwsA(anything),
    );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);

    final row = await (db.select(db.instructorProfiles)..where((t) => t.id.equals('p1'))).getSingle();
    expect(row.fullName, 'Maria Santos');
    expect(row.honorific, 'Prof.');
    expect(row.schoolName, 'State University');
    expect(row.logoPath, '/branding/logo.png');

    // v2: no name is fine; a blank or over-long name is still refused.
    await db.customStatement(
      "INSERT INTO instructor_profiles (id, full_name, created_at, updated_at) VALUES ('p2', NULL, 1, 1)",
    );
    await expectLater(
      db.customStatement("INSERT INTO instructor_profiles (id, full_name, created_at, updated_at) VALUES ('p3', '  ', 1, 1)"),
      throwsA(anything),
    );
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.data.values.first, 1, reason: 'foreign keys back on after migrating');
    await db.close();
  });

  test('v2 -> v3 keeps sets, keys and references, and allows set E', () async {
    final schema = await verifier.schemaAt(2);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO examinations (id, short_code, title, item_count, created_at, updated_at) "
      "VALUES ('e1', 'K7M2Q9XA', 'Finals', 50, 1, 1)",
    );
    for (final l in ['A', 'B', 'C', 'D']) {
      raw.execute("INSERT INTO examination_versions (id, examination_id, label, created_at) VALUES ('v$l', 'e1', '$l', 1)");
    }
    raw.execute(
      "INSERT INTO answer_keys (id, examination_version_id, revision, created_at) VALUES ('k1', 'vC', 1, 1)",
    );
    expect(
      () => raw.execute("INSERT INTO examination_versions (id, examination_id, label, created_at) VALUES ('vE', 'e1', 'E', 1)"),
      throwsA(anything),
      reason: 'v2 allows only A-D',
    );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);

    final labels = await db.customSelect('SELECT label FROM examination_versions ORDER BY label').get();
    expect(labels.map((r) => r.read<String>('label')), ['A', 'B', 'C', 'D']);
    final key = await db.customSelect("SELECT examination_version_id v FROM answer_keys WHERE id = 'k1'").getSingle();
    expect(key.read<String>('v'), 'vC');
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty, reason: 'references intact');

    await db.customStatement(
      "INSERT INTO examination_versions (id, examination_id, label, created_at) VALUES ('vE', 'e1', 'E', 1)",
    );
    await expectLater(
      db.customStatement("INSERT INTO examination_versions (id, examination_id, label, created_at) VALUES ('vF', 'e1', 'F', 1)"),
      throwsA(anything),
    );
    // Deleting the examination still cascades to its sets after the rebuild.
    await db.customStatement("DELETE FROM answer_keys");
    await db.customStatement("DELETE FROM examinations WHERE id = 'e1'");
    expect(await db.customSelect('SELECT id FROM examination_versions').get(), isEmpty);
    await db.close();
  });

  test('v3 -> v4 keeps saved answers and allows "counted wrong" (32)', () async {
    final schema = await verifier.schemaAt(3);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO examinations (id, short_code, title, item_count, created_at, updated_at) "
      "VALUES ('e1', 'K7M2Q9XA', 'Finals', 50, 1, 1)",
    );
    raw.execute(
      "INSERT INTO answer_sheets (id, examination_id, status, captured_at, updated_at) "
      "VALUES ('s1', 'e1', 'needs_review', 1, 1)",
    );
    raw.execute(
      "INSERT INTO student_answers (answer_sheet_id, question_no, detected_state, detected_mask, bubble_scores, confidence, final_mask, resolved_by) "
      "VALUES ('s1', 1, 'multiple', 5, '[0.9,0,0.9,0,0]', 0.9, 5, 'engine'), "
      "('s1', 2, 'uncertain', 2, '[0,0.4,0,0,0]', 0.5, NULL, NULL)",
    );
    expect(
      () => raw.execute("UPDATE student_answers SET final_mask = 32 WHERE question_no = 2"),
      throwsA(anything),
      reason: 'v3 allows only 0-31',
    );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);

    final rows = await db.customSelect('SELECT question_no, final_mask, resolved_by FROM student_answers ORDER BY question_no').get();
    expect(rows.map((r) => (r.read<int>('question_no'), r.readNullable<int>('final_mask'), r.readNullable<String>('resolved_by'))),
        [(1, 5, 'engine'), (2, null, null)]);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty, reason: 'references intact');

    await db.customStatement("UPDATE student_answers SET final_mask = 32 WHERE question_no = 2");
    await expectLater(
      db.customStatement("UPDATE student_answers SET final_mask = 33 WHERE question_no = 2"),
      throwsA(anything),
    );
    // Deleting the paper still cascades to its answers after the rebuild.
    await db.customStatement("DELETE FROM answer_sheets WHERE id = 's1'");
    expect(await db.customSelect('SELECT 1 FROM student_answers').get(), isEmpty);
    await db.close();
  });
}
