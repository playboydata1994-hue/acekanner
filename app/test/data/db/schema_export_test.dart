import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../support/test_db.dart';

/// Keeps docs/sql/v3_schema.sql (the documented schema) and the upgrade scripts
/// (v2_from_v1.sql, v3_from_v2.sql) identical to the schema the app creates.
void main() {
  Future<List<String>> appSchemaNow() async {
    final db = openTestDatabase();
    final rows = await db
        .customSelect(
          "SELECT type, name, sql FROM sqlite_master "
          "WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name",
        )
        .get();
    await db.close();
    return [
      for (final r in rows)
        '${r.read<String>('type')} ${r.read<String>('name')}: '
            '${_normalize(r.readNullable<String>('sql'))}',
    ];
  }

  test('v1_schema.sql + upgrade scripts reach exactly the app schema, keeping rows', () async {
    final db = sqlite3.openInMemory()..execute(File('../docs/sql/v1_schema.sql').readAsStringSync());
    db.execute(
      "INSERT INTO instructor_profiles (id, full_name, school_name, created_at, updated_at) "
      "VALUES ('p1', 'Maria Santos', 'State University', 1, 1)",
    );
    db.execute(
      "INSERT INTO examinations (id, short_code, title, item_count, created_at, updated_at) VALUES ('e1', 'K7M2Q9XA', 'Finals', 50, 1, 1)",
    );
    db.execute("INSERT INTO examination_versions (id, examination_id, label, created_at) VALUES ('vA', 'e1', 'A', 1)");
    db.execute(File('../docs/sql/v2_from_v1.sql').readAsStringSync());
    expect(db.select('PRAGMA user_version').single.values.first, 2);
    db.execute(File('../docs/sql/v3_from_v2.sql').readAsStringSync());
    expect(_schema(db), await appSchemaNow());
    expect(db.select('SELECT full_name FROM instructor_profiles').single['full_name'], 'Maria Santos');
    expect(db.select('SELECT label FROM examination_versions').single['label'], 'A');
    expect(db.select('PRAGMA user_version').single.values.first, 3);
    db.execute("INSERT INTO examination_versions (id, examination_id, label, created_at) VALUES ('vE', 'e1', 'E', 1)");
    db.close();
  });

  test('docs/sql/v3_schema.sql creates exactly the app schema', () async {
    final script = File('../docs/sql/v3_schema.sql').readAsStringSync();

    final fromScript = sqlite3.openInMemory()..execute(script);
    final scriptSchema = _schema(fromScript);
    fromScript.close();

    final db = openTestDatabase();
    final rows = await db
        .customSelect(
          "SELECT type, name, sql FROM sqlite_master "
          "WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name",
        )
        .get();
    final appSchema = [
      for (final r in rows)
        '${r.read<String>('type')} ${r.read<String>('name')}: '
            '${_normalize(r.readNullable<String>('sql'))}',
    ];
    await db.close();

    expect(scriptSchema, appSchema);
    expect(appSchema.where((s) => s.startsWith('table ')), hasLength(21));
    expect(appSchema.where((s) => s.startsWith('trigger ')), hasLength(4));
  });
}

List<String> _schema(Database db) => [
      for (final r in db.select(
        "SELECT type, name, sql FROM sqlite_master "
        "WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name",
      ))
        '${r['type']} ${r['name']}: ${_normalize(r['sql'] as String?)}',
    ];

String _normalize(String? sql) =>
    (sql ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
