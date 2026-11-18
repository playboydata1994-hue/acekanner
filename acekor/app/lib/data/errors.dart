import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// A problem the instructor can understand and fix (shown as-is).
class DataError implements Exception {
  const DataError(this.message);
  final String message;

  /// Translates a database failure: UNIQUE violations become [unique], the
  /// app's own trigger messages ("ACEKOR: …") become readable sentences.
  factory DataError.fromDatabase(Object error, {String? unique}) {
    final cause = error is DriftRemoteException ? error.remoteCause : error;
    if (cause is SqliteException) {
      final text = cause.message;
      if (text.contains('UNIQUE') && unique != null) return DataError(unique);
      if (text.contains('ACEKOR: score above maximum points')) {
        return const DataError('The score is above the maximum points.');
      }
      if (text.contains('ACEKOR: maximum points below a recorded score')) {
        return const DataError('A student already has a higher score. Lower or delete that score first.');
      }
    }
    if (cause is DataError) return cause;
    return DataError('The change could not be saved ($cause).');
  }

  @override
  String toString() => message;
}

class DuplicateStudentNoError extends DataError {
  const DuplicateStudentNoError(super.message, {required this.existingId});
  final String existingId;
}
