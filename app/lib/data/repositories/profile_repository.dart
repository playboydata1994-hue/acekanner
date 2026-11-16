import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/text.dart';
import '../db/app_database.dart';
import '../settings/settings_repository.dart';

class ProfileInput {
  const ProfileInput({
    required this.fullName,
    this.honorific,
    this.email,
    this.employeeNo,
    this.schoolName,
    this.schoolAddress,
    this.department,
  });

  final String fullName;
  final String? honorific;
  final String? email;
  final String? employeeNo;
  final String? schoolName;
  final String? schoolAddress;
  final String? department;
}

/// The instructor's profile and school details (one active row).
class ProfileRepository {
  ProfileRepository(this._db, this._settings, {this.clock = const Clock()});

  static const String defaultStudentNoFormat = '##########';

  final AppDatabase _db;
  final SettingsRepository _settings;
  final Clock clock;

  SimpleSelectStatement<InstructorProfiles, InstructorProfileRow> _active() =>
      _db.select(_db.instructorProfiles)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
        ..limit(1);

  Stream<InstructorProfileRow?> watch() => _active().watchSingleOrNull();

  Future<InstructorProfileRow?> get() => _active().getSingleOrNull();

  Future<String> save(ProfileInput input) {
    return _db.transaction(() async {
      final now = clock.now();
      final existing = await get();
      final companion = InstructorProfilesCompanion(
        fullName: Value(cleanSpaces(input.fullName)),
        honorific: Value(blankToNull(input.honorific)),
        email: Value(blankToNull(input.email)),
        employeeNo: Value(blankToNull(input.employeeNo)),
        schoolName: Value(blankToNull(input.schoolName)),
        schoolAddress: Value(blankToNull(input.schoolAddress)),
        department: Value(blankToNull(input.department)),
        updatedAt: Value(now),
      );
      if (existing == null) {
        final id = newId();
        await _db.into(_db.instructorProfiles).insert(
              companion.copyWith(id: Value(id), createdAt: Value(now)),
            );
        return id;
      }
      await (_db.update(_db.instructorProfiles)
            ..where((t) => t.id.equals(existing.id)))
          .write(companion);
      return existing.id;
    });
  }

  /// Sets or clears the stored school logo (a file written by BrandingStore).
  /// Returns the previous path so the caller can delete the old file.
  Future<String?> setLogoPath(String? path) {
    return _db.transaction(() async {
      final existing = await get();
      if (existing == null) throw StateError('Save the profile before adding a logo.');
      await (_db.update(_db.instructorProfiles)..where((t) => t.id.equals(existing.id))).write(
        InstructorProfilesCompanion(logoPath: Value(path), updatedAt: Value(clock.now())),
      );
      return existing.logoPath;
    });
  }

  /// The school's student-number format, e.g. "####-#####" ('#' = digit).
  Stream<String> watchStudentNoFormat() => _settings
      .watchString(SettingKeys.studentNoFormat)
      .map((v) => v ?? defaultStudentNoFormat);

  Future<String> studentNoFormat() async =>
      await _settings.getString(SettingKeys.studentNoFormat) ??
      defaultStudentNoFormat;

  Future<void> setStudentNoFormat(String format) =>
      _settings.setString(SettingKeys.studentNoFormat, format.trim());
}
