import 'package:acekor/data/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// A fresh in-memory database (plain SQLite on the host).
AppDatabase newTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
