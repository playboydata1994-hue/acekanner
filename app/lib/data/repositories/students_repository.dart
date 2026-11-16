import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/text.dart';
import '../../domain/roster_csv.dart';
import '../../domain/student_number.dart';
import '../audit/audit_logger.dart';
import '../db/app_database.dart';
import '../errors.dart';

class StudentInput {
  const StudentInput({
    required this.studentNo,
    required this.lastName,
    required this.firstName,
    this.middleName,
    this.suffix,
    this.email,
  });

  final String studentNo;
  final String lastName;
  final String firstName;
  final String? middleName;
  final String? suffix;
  final String? email;
}

enum AddStudentOutcome {
  /// A new student record was created and enrolled.
  added,

  /// The number already belonged to a student, who was enrolled here as-is.
  linkedExisting,

  /// That student was already in this section.
  alreadyInSection,
}

class AddStudentResult {
  const AddStudentResult(this.outcome, this.student);

  final AddStudentOutcome outcome;
  final StudentRow student;
}

class ImportSummary {
  const ImportSummary({
    required this.added,
    required this.updated,
    required this.enrolled,
    required this.unchanged,
  });

  /// New student records.
  final int added;

  /// Existing students whose names/email were updated from the file.
  final int updated;

  /// Existing students newly enrolled in the section.
  final int enrolled;

  /// Already enrolled and nothing to change.
  final int unchanged;

  int get total => added + updated + enrolled + unchanged;
}

/// "DELA CRUZ, Juan P." style display name.
String studentDisplayName(StudentRow s) {
  final first = [s.firstName, s.middleName, s.suffix].whereType<String>().join(' ');
  return '${s.lastName}, $first';
}

/// Students and section rosters.
class StudentsRepository {
  StudentsRepository(this._db, this._audit, {this.clock = const Clock()});

  final AppDatabase _db;
  final AuditLogger _audit;
  final Clock clock;

  Stream<List<StudentRow>> watchRoster(String sectionId) =>
      _db.sectionRoster(sectionId: sectionId).watch();

  /// Active students whose name or number contains [query] (max 50).
  Future<List<StudentRow>> search(String query) {
    final q = '%${query.trim()}%';
    final key = '%${StudentNumber.normalize(query)}%';
    return (_db.select(_db.students)
          ..where((t) =>
              t.deletedAt.isNull() &
              (t.lastName.like(q) | t.firstName.like(q) | (key == '%%' ? const Constant(false) : t.studentNoKey.like(key))))
          ..orderBy([(t) => OrderingTerm.asc(t.lastName), (t) => OrderingTerm.asc(t.firstName)])
          ..limit(50))
        .get();
  }

  Future<StudentRow?> findByNumber(String studentNo) {
    final key = StudentNumber.normalize(studentNo);
    return (_db.select(_db.students)
          ..where((t) => t.studentNoKey.equals(key) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<AddStudentResult> addToSection(String sectionId, StudentInput input) {
    return _db.transaction(() async {
      final existing = await findByNumber(input.studentNo);
      if (existing != null) {
        final linked = await _enroll(sectionId, existing.id);
        return AddStudentResult(
          linked ? AddStudentOutcome.linkedExisting : AddStudentOutcome.alreadyInSection,
          existing,
        );
      }
      final now = clock.now();
      final id = newId();
      await _db.into(_db.students).insert(
            _companion(input, now).copyWith(id: Value(id), createdAt: Value(now)),
          );
      await _enroll(sectionId, id);
      final row = await (_db.select(_db.students)..where((t) => t.id.equals(id))).getSingle();
      return AddStudentResult(AddStudentOutcome.added, row);
    });
  }

  Future<void> updateStudent(String id, StudentInput input) {
    return _db.transaction(() async {
      final other = await findByNumber(input.studentNo);
      if (other != null && other.id != id) {
        throw DuplicateValueException(
          'Student number ${input.studentNo.trim()} already belongs to '
          '${studentDisplayName(other)}.',
        );
      }
      await (_db.update(_db.students)..where((t) => t.id.equals(id)))
          .write(_companion(input, clock.now()));
    });
  }

  /// Removes the student from this section only. Their record and any scanned
  /// papers are kept.
  Future<void> removeFromSection(String sectionId, String studentId) =>
      (_db.delete(_db.sectionStudents)
            ..where((t) => t.sectionId.equals(sectionId) & t.studentId.equals(studentId)))
          .go();

  /// Adds every row to the section in one transaction. Existing students
  /// (same normalized number) are enrolled; their names are replaced with the
  /// file's when [updateExistingNames] is true.
  Future<ImportSummary> importRoster(
    String sectionId,
    List<RosterRow> rows, {
    bool updateExistingNames = true,
  }) {
    return _db.transaction(() async {
      var added = 0, updated = 0, enrolled = 0, unchanged = 0;
      final now = clock.now();
      for (final row in rows) {
        final input = StudentInput(
          studentNo: row.studentNo,
          lastName: row.lastName,
          firstName: row.firstName,
          middleName: row.middleName,
          suffix: row.suffix,
          email: row.email,
        );
        final existing = await findByNumber(row.studentNo);
        if (existing == null) {
          final id = newId();
          await _db.into(_db.students).insert(
                _companion(input, now).copyWith(id: Value(id), createdAt: Value(now)),
              );
          await _enroll(sectionId, id);
          added++;
          continue;
        }
        // A file without an email column must not erase a stored email.
        final merged = StudentInput(
          studentNo: input.studentNo,
          lastName: input.lastName,
          firstName: input.firstName,
          middleName: input.middleName,
          suffix: input.suffix,
          email: input.email ?? existing.email,
        );
        final changed = updateExistingNames && _differs(existing, merged);
        if (changed) {
          await (_db.update(_db.students)..where((t) => t.id.equals(existing.id)))
              .write(_companion(merged, now));
        }
        final newlyEnrolled = await _enroll(sectionId, existing.id);
        if (changed) {
          updated++;
        } else if (newlyEnrolled) {
          enrolled++;
        } else {
          unchanged++;
        }
      }
      await _audit.record(
        event: 'roster.imported',
        entityType: 'section',
        entityId: sectionId,
        details: {'added': added, 'updated': updated, 'enrolled': enrolled, 'unchanged': unchanged},
      );
      return ImportSummary(added: added, updated: updated, enrolled: enrolled, unchanged: unchanged);
    });
  }

  /// Returns true when a new enrollment row was created.
  Future<bool> _enroll(String sectionId, String studentId) async {
    final existing = await (_db.select(_db.sectionStudents)
          ..where((t) => t.sectionId.equals(sectionId) & t.studentId.equals(studentId)))
        .getSingleOrNull();
    if (existing != null) return false;
    await _db.into(_db.sectionStudents).insert(
          SectionStudentsCompanion.insert(
            sectionId: sectionId,
            studentId: studentId,
            enrolledAt: clock.now(),
          ),
        );
    return true;
  }

  static StudentsCompanion _companion(StudentInput input, DateTime now) => StudentsCompanion(
        studentNo: Value(cleanSpaces(input.studentNo)),
        studentNoKey: Value(StudentNumber.normalize(input.studentNo)),
        lastName: Value(cleanSpaces(input.lastName)),
        firstName: Value(cleanSpaces(input.firstName)),
        middleName: Value(blankToNull(input.middleName)),
        suffix: Value(blankToNull(input.suffix)),
        email: Value(blankToNull(input.email)),
        updatedAt: Value(now),
      );

  static bool _differs(StudentRow s, StudentInput i) =>
      s.studentNo != cleanSpaces(i.studentNo) ||
      s.lastName != cleanSpaces(i.lastName) ||
      s.firstName != cleanSpaces(i.firstName) ||
      s.middleName != blankToNull(i.middleName) ||
      s.suffix != blankToNull(i.suffix) ||
      s.email != blankToNull(i.email);
}
