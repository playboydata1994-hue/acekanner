import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// A user-facing problem with the data that was entered.
class DataException implements Exception {
  const DataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The value must be unique (e.g. a subject code) and is already used.
class DuplicateValueException extends DataException {
  const DuplicateValueException(super.message);
}

/// The record can no longer be changed this way (e.g. sheets were printed).
class LockedException extends DataException {
  const LockedException(super.message);
}

Object _unwrap(Object e) => e is DriftRemoteException ? e.remoteCause : e;

/// True for SQLite UNIQUE / PRIMARY KEY violations.
bool isUniqueViolation(Object error) {
  final e = _unwrap(error);
  return e is SqliteException &&
      (e.extendedResultCode == 2067 || e.extendedResultCode == 1555);
}
