import 'package:drift/drift.dart';

import 'app_database.steps.dart';

part 'app_database.g.dart';

/// The ACEkanner on-device database.
///
/// The schema lives in `schema/acekanner.drift` (plain SQL). Bump
/// [schemaVersion] for every schema change, add the step to [migration], run
/// `dart run drift_dev make-migrations` to snapshot the schema and generate
/// migration tests, and export the SQL to `docs/sql/`.
@DriftDatabase(include: {'schema/acekanner.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  static const int currentSchemaVersion = 2;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Foreign keys are switched on only in beforeOpen, after migrating,
          // so tables can be rebuilt here.
          await transaction(() => _steps(m, from, to));
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          final fk = await customSelect('PRAGMA foreign_keys').getSingle();
          if (fk.data.values.first != 1) {
            throw StateError('SQLite foreign keys could not be enabled');
          }
        },
      );

  /// One step per schema version (see drift_schemas/ and test/drift/).
  static final OnUpgrade _steps = stepByStep(
    // v2: the instructor's full name became optional (CHECK allows NULL).
    // SQLite cannot change a CHECK constraint, so the table is rebuilt with
    // its rows copied unchanged.
    from1To2: (m, schema) async {
      await m.alterTable(TableMigration(schema.instructorProfiles));
    },
  );

  /// SQLCipher version string, or null when the database is not encrypted
  /// (host unit tests use plain SQLite).
  Future<String?> cipherVersion() async {
    final rows = await customSelect('PRAGMA cipher_version').get();
    if (rows.isEmpty) return null;
    final value = rows.first.data.values.first;
    return (value is String && value.isNotEmpty) ? value : null;
  }
}
