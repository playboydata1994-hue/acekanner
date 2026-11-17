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
}
