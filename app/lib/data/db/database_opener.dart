import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

/// The SQLite library that was loaded has no SQLCipher support.
class DatabaseEncryptionUnavailableException implements Exception {
  const DatabaseEncryptionUnavailableException();

  @override
  String toString() =>
      'Database encryption (SQLCipher) is not available in this build.';
}

final RegExp _hexKey = RegExp(r'^[0-9a-f]{64}$');

/// Opens [file] as an SQLCipher database keyed with the 256-bit [hexKey].
///
/// SQLite runs in a background isolate so database work never blocks the UI.
/// If [requireCipher] is true (always on Android), opening fails instead of
/// silently creating an unencrypted database. A wrong key surfaces as a
/// [SqliteException] with result code 26 (SQLITE_NOTADB) on first use.
///
/// WAL journaling with `synchronous = FULL` keeps every committed transaction
/// on disk even if the app is killed or the phone loses power.
QueryExecutor openEncryptedDatabase(
  File file, {
  required String hexKey,
  bool requireCipher = true,
}) {
  if (!_hexKey.hasMatch(hexKey)) {
    throw ArgumentError('Database key must be 64 lower-case hex characters');
  }
  return NativeDatabase.createInBackground(
    file,
    setup: (Database db) {
      final rows = db.select('PRAGMA cipher_version');
      final version = rows.isEmpty ? null : rows.first.columnAt(0);
      final hasCipher = version is String && version.isNotEmpty;
      if (hasCipher) {
        db.execute('PRAGMA key = "x\'$hexKey\'"');
      } else if (requireCipher) {
        throw const DatabaseEncryptionUnavailableException();
      }
      // Touches the file: throws SQLITE_NOTADB here if the key is wrong.
      db.select('SELECT count(*) FROM sqlite_master');
      db.execute('PRAGMA journal_mode = WAL');
      db.execute('PRAGMA synchronous = FULL');
    },
  );
}
