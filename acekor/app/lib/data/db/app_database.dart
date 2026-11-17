import 'package:drift/drift.dart';

import '../../domain/categories.dart';
import '../../domain/grading/default_scale.dart';

part 'app_database.g.dart';

/// The ACEKOR Calculator on-device database (SQLCipher-encrypted on Android).
///
/// The schema lives in `schema/acekor.drift` (plain SQL). Bump [schemaVersion]
/// for every schema change and add a migration step.
@DriftDatabase(include: {'schema/acekor.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seed(this);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      final fk = await customSelect('PRAGMA foreign_keys').getSingle();
      if (fk.data.values.first != 1) {
        throw StateError('SQLite foreign keys could not be enabled');
      }
    },
  );

  /// Built-in categories, the default grade scale and the empty profile.
  /// Idempotent, so a restore can call it again.
  static Future<void> seed(AppDatabase db) async {
    final now = DateTime.now();
    await db.batch((b) {
      for (final c in CategoryCatalog.builtIn) {
        b.insert(
          db.categories,
          CategoriesCompanion.insert(
            id: c.id,
            name: c.name,
            kind: c.kind.name,
            defaultMaxPoints: c.defaultMax,
            builtIn: const Value(true),
            sortOrder: Value(c.sortOrder),
            createdAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      b.insert(
        db.gradeScales,
        GradeScalesCompanion.insert(
          id: DefaultScale.id,
          name: DefaultScale.name,
          passingBp: const Value(DefaultScale.passingBp),
          builtIn: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
        mode: InsertMode.insertOrIgnore,
      );
      for (final item in DefaultScale.items) {
        b.insert(
          db.gradeScaleRows,
          GradeScaleRowsCompanion.insert(
            scaleId: DefaultScale.id,
            minBp: item.minBp,
            grade: item.grade,
            remark: Value(item.remark),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      b.insert(
        db.instructorProfile,
        InstructorProfileCompanion.insert(id: const Value(1), updatedAt: now),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  /// SQLCipher version string, or null when the database is not encrypted
  /// (host unit tests use plain SQLite).
  Future<String?> cipherVersion() async {
    final rows = await customSelect('PRAGMA cipher_version').get();
    if (rows.isEmpty) return null;
    final value = rows.first.data.values.first;
    return (value is String && value.isNotEmpty) ? value : null;
  }

  /// `PRAGMA integrity_check` + `foreign_key_check`; empty when healthy.
  Future<List<String>> integrityProblems() async {
    final problems = <String>[];
    final rows = await customSelect('PRAGMA integrity_check').get();
    for (final r in rows) {
      final v = r.data.values.first.toString();
      if (v != 'ok') problems.add(v);
    }
    final fk = await customSelect('PRAGMA foreign_key_check').get();
    for (final r in fk) {
      problems.add('Broken link in ${r.data['table']} (row ${r.data['rowid']})');
    }
    return problems;
  }
}
