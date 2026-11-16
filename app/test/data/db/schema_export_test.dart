import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../support/test_db.dart';

/// Keeps docs/sql/v1_schema.sql (the documented migration script) identical to
/// the schema the app actually creates.
void main() {
  test('docs/sql/v1_schema.sql creates exactly the app schema', () async {
    final script = File('../docs/sql/v1_schema.sql').readAsStringSync();

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
