// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class InstructorProfile extends Table with TableInfo<InstructorProfile, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  InstructorProfile(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _instructorNameMeta = const VerificationMeta('instructorName');
  late final GeneratedColumn<String> instructorName = GeneratedColumn<String>(
    'instructor_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(instructor_name) <= 120)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _schoolNameMeta = const VerificationMeta('schoolName');
  late final GeneratedColumn<String> schoolName = GeneratedColumn<String>(
    'school_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(school_name) <= 160)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _schoolAddressMeta = const VerificationMeta('schoolAddress');
  late final GeneratedColumn<String> schoolAddress = GeneratedColumn<String>(
    'school_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(school_address) <= 240)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _departmentMeta = const VerificationMeta('department');
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
    'department',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(department) <= 160)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, instructorName, schoolName, schoolAddress, department, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instructor_profile';
  @override
  VerificationContext validateIntegrity(Insertable<ProfileRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('instructor_name')) {
      context.handle(
        _instructorNameMeta,
        instructorName.isAcceptableOrUnknown(data['instructor_name']!, _instructorNameMeta),
      );
    }
    if (data.containsKey('school_name')) {
      context.handle(_schoolNameMeta, schoolName.isAcceptableOrUnknown(data['school_name']!, _schoolNameMeta));
    }
    if (data.containsKey('school_address')) {
      context.handle(
        _schoolAddressMeta,
        schoolAddress.isAcceptableOrUnknown(data['school_address']!, _schoolAddressMeta),
      );
    }
    if (data.containsKey('department')) {
      context.handle(_departmentMeta, department.isAcceptableOrUnknown(data['department']!, _departmentMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      instructorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructor_name'],
      )!,
      schoolName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}school_name'])!,
      schoolAddress: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}school_address'])!,
      department: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}department'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  InstructorProfile createAlias(String alias) {
    return InstructorProfile(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final int id;
  final String instructorName;
  final String schoolName;
  final String schoolAddress;
  final String department;
  final DateTime updatedAt;
  const ProfileRow({
    required this.id,
    required this.instructorName,
    required this.schoolName,
    required this.schoolAddress,
    required this.department,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['instructor_name'] = Variable<String>(instructorName);
    map['school_name'] = Variable<String>(schoolName);
    map['school_address'] = Variable<String>(schoolAddress);
    map['department'] = Variable<String>(department);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InstructorProfileCompanion toCompanion(bool nullToAbsent) {
    return InstructorProfileCompanion(
      id: Value(id),
      instructorName: Value(instructorName),
      schoolName: Value(schoolName),
      schoolAddress: Value(schoolAddress),
      department: Value(department),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfileRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<int>(json['id']),
      instructorName: serializer.fromJson<String>(json['instructor_name']),
      schoolName: serializer.fromJson<String>(json['school_name']),
      schoolAddress: serializer.fromJson<String>(json['school_address']),
      department: serializer.fromJson<String>(json['department']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'instructor_name': serializer.toJson<String>(instructorName),
      'school_name': serializer.toJson<String>(schoolName),
      'school_address': serializer.toJson<String>(schoolAddress),
      'department': serializer.toJson<String>(department),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProfileRow copyWith({
    int? id,
    String? instructorName,
    String? schoolName,
    String? schoolAddress,
    String? department,
    DateTime? updatedAt,
  }) => ProfileRow(
    id: id ?? this.id,
    instructorName: instructorName ?? this.instructorName,
    schoolName: schoolName ?? this.schoolName,
    schoolAddress: schoolAddress ?? this.schoolAddress,
    department: department ?? this.department,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProfileRow copyWithCompanion(InstructorProfileCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      instructorName: data.instructorName.present ? data.instructorName.value : this.instructorName,
      schoolName: data.schoolName.present ? data.schoolName.value : this.schoolName,
      schoolAddress: data.schoolAddress.present ? data.schoolAddress.value : this.schoolAddress,
      department: data.department.present ? data.department.value : this.department,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('instructorName: $instructorName, ')
          ..write('schoolName: $schoolName, ')
          ..write('schoolAddress: $schoolAddress, ')
          ..write('department: $department, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, instructorName, schoolName, schoolAddress, department, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.instructorName == this.instructorName &&
          other.schoolName == this.schoolName &&
          other.schoolAddress == this.schoolAddress &&
          other.department == this.department &&
          other.updatedAt == this.updatedAt);
}

class InstructorProfileCompanion extends UpdateCompanion<ProfileRow> {
  final Value<int> id;
  final Value<String> instructorName;
  final Value<String> schoolName;
  final Value<String> schoolAddress;
  final Value<String> department;
  final Value<DateTime> updatedAt;
  const InstructorProfileCompanion({
    this.id = const Value.absent(),
    this.instructorName = const Value.absent(),
    this.schoolName = const Value.absent(),
    this.schoolAddress = const Value.absent(),
    this.department = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  InstructorProfileCompanion.insert({
    this.id = const Value.absent(),
    this.instructorName = const Value.absent(),
    this.schoolName = const Value.absent(),
    this.schoolAddress = const Value.absent(),
    this.department = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<ProfileRow> custom({
    Expression<int>? id,
    Expression<String>? instructorName,
    Expression<String>? schoolName,
    Expression<String>? schoolAddress,
    Expression<String>? department,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instructorName != null) 'instructor_name': instructorName,
      if (schoolName != null) 'school_name': schoolName,
      if (schoolAddress != null) 'school_address': schoolAddress,
      if (department != null) 'department': department,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  InstructorProfileCompanion copyWith({
    Value<int>? id,
    Value<String>? instructorName,
    Value<String>? schoolName,
    Value<String>? schoolAddress,
    Value<String>? department,
    Value<DateTime>? updatedAt,
  }) {
    return InstructorProfileCompanion(
      id: id ?? this.id,
      instructorName: instructorName ?? this.instructorName,
      schoolName: schoolName ?? this.schoolName,
      schoolAddress: schoolAddress ?? this.schoolAddress,
      department: department ?? this.department,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (instructorName.present) {
      map['instructor_name'] = Variable<String>(instructorName.value);
    }
    if (schoolName.present) {
      map['school_name'] = Variable<String>(schoolName.value);
    }
    if (schoolAddress.present) {
      map['school_address'] = Variable<String>(schoolAddress.value);
    }
    if (department.present) {
      map['department'] = Variable<String>(department.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstructorProfileCompanion(')
          ..write('id: $id, ')
          ..write('instructorName: $instructorName, ')
          ..write('schoolName: $schoolName, ')
          ..write('schoolAddress: $schoolAddress, ')
          ..write('department: $department, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class Sections extends Table with TableInfo<Sections, SectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Sections(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 60)',
  );
  static const VerificationMeta _programMeta = const VerificationMeta('program');
  late final GeneratedColumn<String> program = GeneratedColumn<String>(
    'program',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(program) <= 120)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _yearLevelMeta = const VerificationMeta('yearLevel');
  late final GeneratedColumn<int> yearLevel = GeneratedColumn<int>(
    'year_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (year_level IS NULL OR year_level BETWEEN 1 AND 6)',
  );
  static const VerificationMeta _academicYearMeta = const VerificationMeta('academicYear');
  late final GeneratedColumn<String> academicYear = GeneratedColumn<String>(
    'academic_year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(academic_year) <= 20)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta('semester');
  late final GeneratedColumn<String> semester = GeneratedColumn<String>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(semester) <= 40)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, program, yearLevel, academicYear, semester, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sections';
  @override
  VerificationContext validateIntegrity(Insertable<SectionRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('program')) {
      context.handle(_programMeta, program.isAcceptableOrUnknown(data['program']!, _programMeta));
    }
    if (data.containsKey('year_level')) {
      context.handle(_yearLevelMeta, yearLevel.isAcceptableOrUnknown(data['year_level']!, _yearLevelMeta));
    }
    if (data.containsKey('academic_year')) {
      context.handle(_academicYearMeta, academicYear.isAcceptableOrUnknown(data['academic_year']!, _academicYearMeta));
    }
    if (data.containsKey('semester')) {
      context.handle(_semesterMeta, semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectionRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      program: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}program'])!,
      yearLevel: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}year_level']),
      academicYear: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}academic_year'])!,
      semester: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}semester'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  Sections createAlias(String alias) {
    return Sections(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SectionRow extends DataClass implements Insertable<SectionRow> {
  final String id;
  final String name;
  final String program;
  final int? yearLevel;
  final String academicYear;
  final String semester;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SectionRow({
    required this.id,
    required this.name,
    required this.program,
    this.yearLevel,
    required this.academicYear,
    required this.semester,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['program'] = Variable<String>(program);
    if (!nullToAbsent || yearLevel != null) {
      map['year_level'] = Variable<int>(yearLevel);
    }
    map['academic_year'] = Variable<String>(academicYear);
    map['semester'] = Variable<String>(semester);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SectionsCompanion toCompanion(bool nullToAbsent) {
    return SectionsCompanion(
      id: Value(id),
      name: Value(name),
      program: Value(program),
      yearLevel: yearLevel == null && nullToAbsent ? const Value.absent() : Value(yearLevel),
      academicYear: Value(academicYear),
      semester: Value(semester),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SectionRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectionRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      program: serializer.fromJson<String>(json['program']),
      yearLevel: serializer.fromJson<int?>(json['year_level']),
      academicYear: serializer.fromJson<String>(json['academic_year']),
      semester: serializer.fromJson<String>(json['semester']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'program': serializer.toJson<String>(program),
      'year_level': serializer.toJson<int?>(yearLevel),
      'academic_year': serializer.toJson<String>(academicYear),
      'semester': serializer.toJson<String>(semester),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SectionRow copyWith({
    String? id,
    String? name,
    String? program,
    Value<int?> yearLevel = const Value.absent(),
    String? academicYear,
    String? semester,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SectionRow(
    id: id ?? this.id,
    name: name ?? this.name,
    program: program ?? this.program,
    yearLevel: yearLevel.present ? yearLevel.value : this.yearLevel,
    academicYear: academicYear ?? this.academicYear,
    semester: semester ?? this.semester,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SectionRow copyWithCompanion(SectionsCompanion data) {
    return SectionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      program: data.program.present ? data.program.value : this.program,
      yearLevel: data.yearLevel.present ? data.yearLevel.value : this.yearLevel,
      academicYear: data.academicYear.present ? data.academicYear.value : this.academicYear,
      semester: data.semester.present ? data.semester.value : this.semester,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('program: $program, ')
          ..write('yearLevel: $yearLevel, ')
          ..write('academicYear: $academicYear, ')
          ..write('semester: $semester, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, program, yearLevel, academicYear, semester, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.program == this.program &&
          other.yearLevel == this.yearLevel &&
          other.academicYear == this.academicYear &&
          other.semester == this.semester &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SectionsCompanion extends UpdateCompanion<SectionRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> program;
  final Value<int?> yearLevel;
  final Value<String> academicYear;
  final Value<String> semester;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.program = const Value.absent(),
    this.yearLevel = const Value.absent(),
    this.academicYear = const Value.absent(),
    this.semester = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SectionsCompanion.insert({
    required String id,
    required String name,
    this.program = const Value.absent(),
    this.yearLevel = const Value.absent(),
    this.academicYear = const Value.absent(),
    this.semester = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SectionRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? program,
    Expression<int>? yearLevel,
    Expression<String>? academicYear,
    Expression<String>? semester,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (program != null) 'program': program,
      if (yearLevel != null) 'year_level': yearLevel,
      if (academicYear != null) 'academic_year': academicYear,
      if (semester != null) 'semester': semester,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? program,
    Value<int?>? yearLevel,
    Value<String>? academicYear,
    Value<String>? semester,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      program: program ?? this.program,
      yearLevel: yearLevel ?? this.yearLevel,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (program.present) {
      map['program'] = Variable<String>(program.value);
    }
    if (yearLevel.present) {
      map['year_level'] = Variable<int>(yearLevel.value);
    }
    if (academicYear.present) {
      map['academic_year'] = Variable<String>(academicYear.value);
    }
    if (semester.present) {
      map['semester'] = Variable<String>(semester.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('program: $program, ')
          ..write('yearLevel: $yearLevel, ')
          ..write('academicYear: $academicYear, ')
          ..write('semester: $semester, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Students extends Table with TableInfo<Students, StudentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Students(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _studentNoMeta = const VerificationMeta('studentNo');
  late final GeneratedColumn<String> studentNo = GeneratedColumn<String>(
    'student_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (student_no IS NULL OR length(trim(student_no)) BETWEEN 1 AND 30)',
  );
  static const VerificationMeta _studentNoKeyMeta = const VerificationMeta('studentNoKey');
  late final GeneratedColumn<String> studentNoKey = GeneratedColumn<String>(
    'student_no_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (student_no_key IS NULL OR length(student_no_key) BETWEEN 1 AND 30)',
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta('firstName');
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(first_name)) BETWEEN 1 AND 80)',
  );
  static const VerificationMeta _middleNameMeta = const VerificationMeta('middleName');
  late final GeneratedColumn<String> middleName = GeneratedColumn<String>(
    'middle_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(middle_name) <= 80)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta('lastName');
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(last_name)) BETWEEN 1 AND 80)',
  );
  static const VerificationMeta _suffixMeta = const VerificationMeta('suffix');
  late final GeneratedColumn<String> suffix = GeneratedColumn<String>(
    'suffix',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(suffix) <= 10)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _programMeta = const VerificationMeta('program');
  late final GeneratedColumn<String> program = GeneratedColumn<String>(
    'program',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(program) <= 120)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _yearLevelMeta = const VerificationMeta('yearLevel');
  late final GeneratedColumn<int> yearLevel = GeneratedColumn<int>(
    'year_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (year_level IS NULL OR year_level BETWEEN 1 AND 6)',
  );
  static const VerificationMeta _sectionIdMeta = const VerificationMeta('sectionId');
  late final GeneratedColumn<String> sectionId = GeneratedColumn<String>(
    'section_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES sections(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _academicYearMeta = const VerificationMeta('academicYear');
  late final GeneratedColumn<String> academicYear = GeneratedColumn<String>(
    'academic_year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(academic_year) <= 20)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta('semester');
  late final GeneratedColumn<String> semester = GeneratedColumn<String>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(semester) <= 40)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentNo,
    studentNoKey,
    firstName,
    middleName,
    lastName,
    suffix,
    program,
    yearLevel,
    sectionId,
    academicYear,
    semester,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students';
  @override
  VerificationContext validateIntegrity(Insertable<StudentRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('student_no')) {
      context.handle(_studentNoMeta, studentNo.isAcceptableOrUnknown(data['student_no']!, _studentNoMeta));
    }
    if (data.containsKey('student_no_key')) {
      context.handle(_studentNoKeyMeta, studentNoKey.isAcceptableOrUnknown(data['student_no_key']!, _studentNoKeyMeta));
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta, firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('middle_name')) {
      context.handle(_middleNameMeta, middleName.isAcceptableOrUnknown(data['middle_name']!, _middleNameMeta));
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta, lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('suffix')) {
      context.handle(_suffixMeta, suffix.isAcceptableOrUnknown(data['suffix']!, _suffixMeta));
    }
    if (data.containsKey('program')) {
      context.handle(_programMeta, program.isAcceptableOrUnknown(data['program']!, _programMeta));
    }
    if (data.containsKey('year_level')) {
      context.handle(_yearLevelMeta, yearLevel.isAcceptableOrUnknown(data['year_level']!, _yearLevelMeta));
    }
    if (data.containsKey('section_id')) {
      context.handle(_sectionIdMeta, sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta));
    }
    if (data.containsKey('academic_year')) {
      context.handle(_academicYearMeta, academicYear.isAcceptableOrUnknown(data['academic_year']!, _academicYearMeta));
    }
    if (data.containsKey('semester')) {
      context.handle(_semesterMeta, semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      studentNo: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}student_no']),
      studentNoKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}student_no_key']),
      firstName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      middleName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}middle_name'])!,
      lastName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}last_name'])!,
      suffix: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}suffix'])!,
      program: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}program'])!,
      yearLevel: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}year_level']),
      sectionId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}section_id']),
      academicYear: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}academic_year'])!,
      semester: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}semester'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  Students createAlias(String alias) {
    return Students(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class StudentRow extends DataClass implements Insertable<StudentRow> {
  final String id;

  /// Official student ID as the school writes it, e.g. "2021-00123". Optional.
  final String? studentNo;

  /// Normalized for duplicate detection: upper-case letters and digits only.
  final String? studentNoKey;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String program;
  final int? yearLevel;

  /// Moving a student to another section keeps all scores (they belong to
  /// the student and the subject's activities, not to the section).
  final String? sectionId;
  final String academicYear;
  final String semester;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const StudentRow({
    required this.id,
    this.studentNo,
    this.studentNoKey,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.suffix,
    required this.program,
    this.yearLevel,
    this.sectionId,
    required this.academicYear,
    required this.semester,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || studentNo != null) {
      map['student_no'] = Variable<String>(studentNo);
    }
    if (!nullToAbsent || studentNoKey != null) {
      map['student_no_key'] = Variable<String>(studentNoKey);
    }
    map['first_name'] = Variable<String>(firstName);
    map['middle_name'] = Variable<String>(middleName);
    map['last_name'] = Variable<String>(lastName);
    map['suffix'] = Variable<String>(suffix);
    map['program'] = Variable<String>(program);
    if (!nullToAbsent || yearLevel != null) {
      map['year_level'] = Variable<int>(yearLevel);
    }
    if (!nullToAbsent || sectionId != null) {
      map['section_id'] = Variable<String>(sectionId);
    }
    map['academic_year'] = Variable<String>(academicYear);
    map['semester'] = Variable<String>(semester);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  StudentsCompanion toCompanion(bool nullToAbsent) {
    return StudentsCompanion(
      id: Value(id),
      studentNo: studentNo == null && nullToAbsent ? const Value.absent() : Value(studentNo),
      studentNoKey: studentNoKey == null && nullToAbsent ? const Value.absent() : Value(studentNoKey),
      firstName: Value(firstName),
      middleName: Value(middleName),
      lastName: Value(lastName),
      suffix: Value(suffix),
      program: Value(program),
      yearLevel: yearLevel == null && nullToAbsent ? const Value.absent() : Value(yearLevel),
      sectionId: sectionId == null && nullToAbsent ? const Value.absent() : Value(sectionId),
      academicYear: Value(academicYear),
      semester: Value(semester),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory StudentRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentRow(
      id: serializer.fromJson<String>(json['id']),
      studentNo: serializer.fromJson<String?>(json['student_no']),
      studentNoKey: serializer.fromJson<String?>(json['student_no_key']),
      firstName: serializer.fromJson<String>(json['first_name']),
      middleName: serializer.fromJson<String>(json['middle_name']),
      lastName: serializer.fromJson<String>(json['last_name']),
      suffix: serializer.fromJson<String>(json['suffix']),
      program: serializer.fromJson<String>(json['program']),
      yearLevel: serializer.fromJson<int?>(json['year_level']),
      sectionId: serializer.fromJson<String?>(json['section_id']),
      academicYear: serializer.fromJson<String>(json['academic_year']),
      semester: serializer.fromJson<String>(json['semester']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      deletedAt: serializer.fromJson<DateTime?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'student_no': serializer.toJson<String?>(studentNo),
      'student_no_key': serializer.toJson<String?>(studentNoKey),
      'first_name': serializer.toJson<String>(firstName),
      'middle_name': serializer.toJson<String>(middleName),
      'last_name': serializer.toJson<String>(lastName),
      'suffix': serializer.toJson<String>(suffix),
      'program': serializer.toJson<String>(program),
      'year_level': serializer.toJson<int?>(yearLevel),
      'section_id': serializer.toJson<String?>(sectionId),
      'academic_year': serializer.toJson<String>(academicYear),
      'semester': serializer.toJson<String>(semester),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'deleted_at': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  StudentRow copyWith({
    String? id,
    Value<String?> studentNo = const Value.absent(),
    Value<String?> studentNoKey = const Value.absent(),
    String? firstName,
    String? middleName,
    String? lastName,
    String? suffix,
    String? program,
    Value<int?> yearLevel = const Value.absent(),
    Value<String?> sectionId = const Value.absent(),
    String? academicYear,
    String? semester,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => StudentRow(
    id: id ?? this.id,
    studentNo: studentNo.present ? studentNo.value : this.studentNo,
    studentNoKey: studentNoKey.present ? studentNoKey.value : this.studentNoKey,
    firstName: firstName ?? this.firstName,
    middleName: middleName ?? this.middleName,
    lastName: lastName ?? this.lastName,
    suffix: suffix ?? this.suffix,
    program: program ?? this.program,
    yearLevel: yearLevel.present ? yearLevel.value : this.yearLevel,
    sectionId: sectionId.present ? sectionId.value : this.sectionId,
    academicYear: academicYear ?? this.academicYear,
    semester: semester ?? this.semester,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  StudentRow copyWithCompanion(StudentsCompanion data) {
    return StudentRow(
      id: data.id.present ? data.id.value : this.id,
      studentNo: data.studentNo.present ? data.studentNo.value : this.studentNo,
      studentNoKey: data.studentNoKey.present ? data.studentNoKey.value : this.studentNoKey,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      middleName: data.middleName.present ? data.middleName.value : this.middleName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      suffix: data.suffix.present ? data.suffix.value : this.suffix,
      program: data.program.present ? data.program.value : this.program,
      yearLevel: data.yearLevel.present ? data.yearLevel.value : this.yearLevel,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      academicYear: data.academicYear.present ? data.academicYear.value : this.academicYear,
      semester: data.semester.present ? data.semester.value : this.semester,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentRow(')
          ..write('id: $id, ')
          ..write('studentNo: $studentNo, ')
          ..write('studentNoKey: $studentNoKey, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('lastName: $lastName, ')
          ..write('suffix: $suffix, ')
          ..write('program: $program, ')
          ..write('yearLevel: $yearLevel, ')
          ..write('sectionId: $sectionId, ')
          ..write('academicYear: $academicYear, ')
          ..write('semester: $semester, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studentNo,
    studentNoKey,
    firstName,
    middleName,
    lastName,
    suffix,
    program,
    yearLevel,
    sectionId,
    academicYear,
    semester,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentRow &&
          other.id == this.id &&
          other.studentNo == this.studentNo &&
          other.studentNoKey == this.studentNoKey &&
          other.firstName == this.firstName &&
          other.middleName == this.middleName &&
          other.lastName == this.lastName &&
          other.suffix == this.suffix &&
          other.program == this.program &&
          other.yearLevel == this.yearLevel &&
          other.sectionId == this.sectionId &&
          other.academicYear == this.academicYear &&
          other.semester == this.semester &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class StudentsCompanion extends UpdateCompanion<StudentRow> {
  final Value<String> id;
  final Value<String?> studentNo;
  final Value<String?> studentNoKey;
  final Value<String> firstName;
  final Value<String> middleName;
  final Value<String> lastName;
  final Value<String> suffix;
  final Value<String> program;
  final Value<int?> yearLevel;
  final Value<String?> sectionId;
  final Value<String> academicYear;
  final Value<String> semester;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const StudentsCompanion({
    this.id = const Value.absent(),
    this.studentNo = const Value.absent(),
    this.studentNoKey = const Value.absent(),
    this.firstName = const Value.absent(),
    this.middleName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.suffix = const Value.absent(),
    this.program = const Value.absent(),
    this.yearLevel = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.academicYear = const Value.absent(),
    this.semester = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentsCompanion.insert({
    required String id,
    this.studentNo = const Value.absent(),
    this.studentNoKey = const Value.absent(),
    required String firstName,
    this.middleName = const Value.absent(),
    required String lastName,
    this.suffix = const Value.absent(),
    this.program = const Value.absent(),
    this.yearLevel = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.academicYear = const Value.absent(),
    this.semester = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       firstName = Value(firstName),
       lastName = Value(lastName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StudentRow> custom({
    Expression<String>? id,
    Expression<String>? studentNo,
    Expression<String>? studentNoKey,
    Expression<String>? firstName,
    Expression<String>? middleName,
    Expression<String>? lastName,
    Expression<String>? suffix,
    Expression<String>? program,
    Expression<int>? yearLevel,
    Expression<String>? sectionId,
    Expression<String>? academicYear,
    Expression<String>? semester,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentNo != null) 'student_no': studentNo,
      if (studentNoKey != null) 'student_no_key': studentNoKey,
      if (firstName != null) 'first_name': firstName,
      if (middleName != null) 'middle_name': middleName,
      if (lastName != null) 'last_name': lastName,
      if (suffix != null) 'suffix': suffix,
      if (program != null) 'program': program,
      if (yearLevel != null) 'year_level': yearLevel,
      if (sectionId != null) 'section_id': sectionId,
      if (academicYear != null) 'academic_year': academicYear,
      if (semester != null) 'semester': semester,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentsCompanion copyWith({
    Value<String>? id,
    Value<String?>? studentNo,
    Value<String?>? studentNoKey,
    Value<String>? firstName,
    Value<String>? middleName,
    Value<String>? lastName,
    Value<String>? suffix,
    Value<String>? program,
    Value<int?>? yearLevel,
    Value<String?>? sectionId,
    Value<String>? academicYear,
    Value<String>? semester,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return StudentsCompanion(
      id: id ?? this.id,
      studentNo: studentNo ?? this.studentNo,
      studentNoKey: studentNoKey ?? this.studentNoKey,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      suffix: suffix ?? this.suffix,
      program: program ?? this.program,
      yearLevel: yearLevel ?? this.yearLevel,
      sectionId: sectionId ?? this.sectionId,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (studentNo.present) {
      map['student_no'] = Variable<String>(studentNo.value);
    }
    if (studentNoKey.present) {
      map['student_no_key'] = Variable<String>(studentNoKey.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (middleName.present) {
      map['middle_name'] = Variable<String>(middleName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (suffix.present) {
      map['suffix'] = Variable<String>(suffix.value);
    }
    if (program.present) {
      map['program'] = Variable<String>(program.value);
    }
    if (yearLevel.present) {
      map['year_level'] = Variable<int>(yearLevel.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<String>(sectionId.value);
    }
    if (academicYear.present) {
      map['academic_year'] = Variable<String>(academicYear.value);
    }
    if (semester.present) {
      map['semester'] = Variable<String>(semester.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsCompanion(')
          ..write('id: $id, ')
          ..write('studentNo: $studentNo, ')
          ..write('studentNoKey: $studentNoKey, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('lastName: $lastName, ')
          ..write('suffix: $suffix, ')
          ..write('program: $program, ')
          ..write('yearLevel: $yearLevel, ')
          ..write('sectionId: $sectionId, ')
          ..write('academicYear: $academicYear, ')
          ..write('semester: $semester, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class GradeScales extends Table with TableInfo<GradeScales, GradeScaleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GradeScales(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 60)',
  );
  static const VerificationMeta _passingBpMeta = const VerificationMeta('passingBp');
  late final GeneratedColumn<int> passingBp = GeneratedColumn<int>(
    'passing_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 7500 CHECK (passing_bp BETWEEN 0 AND 10000)',
    defaultValue: const CustomExpression('7500'),
  );
  static const VerificationMeta _roundBeforeLookupMeta = const VerificationMeta('roundBeforeLookup');
  late final GeneratedColumn<bool> roundBeforeLookup = GeneratedColumn<bool>(
    'round_before_lookup',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _builtInMeta = const VerificationMeta('builtIn');
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, passingBp, roundBeforeLookup, builtIn, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grade_scales';
  @override
  VerificationContext validateIntegrity(Insertable<GradeScaleRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('passing_bp')) {
      context.handle(_passingBpMeta, passingBp.isAcceptableOrUnknown(data['passing_bp']!, _passingBpMeta));
    }
    if (data.containsKey('round_before_lookup')) {
      context.handle(
        _roundBeforeLookupMeta,
        roundBeforeLookup.isAcceptableOrUnknown(data['round_before_lookup']!, _roundBeforeLookupMeta),
      );
    }
    if (data.containsKey('built_in')) {
      context.handle(_builtInMeta, builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GradeScaleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GradeScaleRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      passingBp: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}passing_bp'])!,
      roundBeforeLookup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}round_before_lookup'],
      )!,
      builtIn: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}built_in'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  GradeScales createAlias(String alias) {
    return GradeScales(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class GradeScaleRow extends DataClass implements Insertable<GradeScaleRow> {
  final String id;
  final String name;
  final int passingBp;

  /// Round the final percentage to a whole number (half up) before lookup.
  final bool roundBeforeLookup;
  final bool builtIn;
  final DateTime createdAt;
  final DateTime updatedAt;
  const GradeScaleRow({
    required this.id,
    required this.name,
    required this.passingBp,
    required this.roundBeforeLookup,
    required this.builtIn,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['passing_bp'] = Variable<int>(passingBp);
    map['round_before_lookup'] = Variable<bool>(roundBeforeLookup);
    map['built_in'] = Variable<bool>(builtIn);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GradeScalesCompanion toCompanion(bool nullToAbsent) {
    return GradeScalesCompanion(
      id: Value(id),
      name: Value(name),
      passingBp: Value(passingBp),
      roundBeforeLookup: Value(roundBeforeLookup),
      builtIn: Value(builtIn),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GradeScaleRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GradeScaleRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      passingBp: serializer.fromJson<int>(json['passing_bp']),
      roundBeforeLookup: serializer.fromJson<bool>(json['round_before_lookup']),
      builtIn: serializer.fromJson<bool>(json['built_in']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'passing_bp': serializer.toJson<int>(passingBp),
      'round_before_lookup': serializer.toJson<bool>(roundBeforeLookup),
      'built_in': serializer.toJson<bool>(builtIn),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GradeScaleRow copyWith({
    String? id,
    String? name,
    int? passingBp,
    bool? roundBeforeLookup,
    bool? builtIn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => GradeScaleRow(
    id: id ?? this.id,
    name: name ?? this.name,
    passingBp: passingBp ?? this.passingBp,
    roundBeforeLookup: roundBeforeLookup ?? this.roundBeforeLookup,
    builtIn: builtIn ?? this.builtIn,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GradeScaleRow copyWithCompanion(GradeScalesCompanion data) {
    return GradeScaleRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      passingBp: data.passingBp.present ? data.passingBp.value : this.passingBp,
      roundBeforeLookup: data.roundBeforeLookup.present ? data.roundBeforeLookup.value : this.roundBeforeLookup,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GradeScaleRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('passingBp: $passingBp, ')
          ..write('roundBeforeLookup: $roundBeforeLookup, ')
          ..write('builtIn: $builtIn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, passingBp, roundBeforeLookup, builtIn, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GradeScaleRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.passingBp == this.passingBp &&
          other.roundBeforeLookup == this.roundBeforeLookup &&
          other.builtIn == this.builtIn &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GradeScalesCompanion extends UpdateCompanion<GradeScaleRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> passingBp;
  final Value<bool> roundBeforeLookup;
  final Value<bool> builtIn;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GradeScalesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.passingBp = const Value.absent(),
    this.roundBeforeLookup = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GradeScalesCompanion.insert({
    required String id,
    required String name,
    this.passingBp = const Value.absent(),
    this.roundBeforeLookup = const Value.absent(),
    this.builtIn = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GradeScaleRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? passingBp,
    Expression<bool>? roundBeforeLookup,
    Expression<bool>? builtIn,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (passingBp != null) 'passing_bp': passingBp,
      if (roundBeforeLookup != null) 'round_before_lookup': roundBeforeLookup,
      if (builtIn != null) 'built_in': builtIn,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GradeScalesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? passingBp,
    Value<bool>? roundBeforeLookup,
    Value<bool>? builtIn,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return GradeScalesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      passingBp: passingBp ?? this.passingBp,
      roundBeforeLookup: roundBeforeLookup ?? this.roundBeforeLookup,
      builtIn: builtIn ?? this.builtIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (passingBp.present) {
      map['passing_bp'] = Variable<int>(passingBp.value);
    }
    if (roundBeforeLookup.present) {
      map['round_before_lookup'] = Variable<bool>(roundBeforeLookup.value);
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradeScalesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('passingBp: $passingBp, ')
          ..write('roundBeforeLookup: $roundBeforeLookup, ')
          ..write('builtIn: $builtIn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class GradeScaleRows extends Table with TableInfo<GradeScaleRows, GradeScaleItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GradeScaleRows(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scaleIdMeta = const VerificationMeta('scaleId');
  late final GeneratedColumn<String> scaleId = GeneratedColumn<String>(
    'scale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES grade_scales(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _minBpMeta = const VerificationMeta('minBp');
  late final GeneratedColumn<int> minBp = GeneratedColumn<int>(
    'min_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (min_bp BETWEEN 0 AND 10000)',
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(grade)) BETWEEN 1 AND 10)',
  );
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
    'remark',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(remark) <= 40)',
    defaultValue: const CustomExpression('\'\''),
  );
  @override
  List<GeneratedColumn> get $columns => [scaleId, minBp, grade, remark];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grade_scale_rows';
  @override
  VerificationContext validateIntegrity(Insertable<GradeScaleItemRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scale_id')) {
      context.handle(_scaleIdMeta, scaleId.isAcceptableOrUnknown(data['scale_id']!, _scaleIdMeta));
    } else if (isInserting) {
      context.missing(_scaleIdMeta);
    }
    if (data.containsKey('min_bp')) {
      context.handle(_minBpMeta, minBp.isAcceptableOrUnknown(data['min_bp']!, _minBpMeta));
    } else if (isInserting) {
      context.missing(_minBpMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(_gradeMeta, grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta));
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('remark')) {
      context.handle(_remarkMeta, remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scaleId, minBp};
  @override
  GradeScaleItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GradeScaleItemRow(
      scaleId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}scale_id'])!,
      minBp: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}min_bp'])!,
      grade: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}grade'])!,
      remark: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}remark'])!,
    );
  }

  @override
  GradeScaleRows createAlias(String alias) {
    return GradeScaleRows(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(scale_id, min_bp)'];
  @override
  bool get dontWriteConstraints => true;
}

class GradeScaleItemRow extends DataClass implements Insertable<GradeScaleItemRow> {
  final String scaleId;

  /// Lowest percentage (inclusive) that earns this grade, in basis points.
  final int minBp;
  final String grade;
  final String remark;
  const GradeScaleItemRow({required this.scaleId, required this.minBp, required this.grade, required this.remark});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scale_id'] = Variable<String>(scaleId);
    map['min_bp'] = Variable<int>(minBp);
    map['grade'] = Variable<String>(grade);
    map['remark'] = Variable<String>(remark);
    return map;
  }

  GradeScaleRowsCompanion toCompanion(bool nullToAbsent) {
    return GradeScaleRowsCompanion(
      scaleId: Value(scaleId),
      minBp: Value(minBp),
      grade: Value(grade),
      remark: Value(remark),
    );
  }

  factory GradeScaleItemRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GradeScaleItemRow(
      scaleId: serializer.fromJson<String>(json['scale_id']),
      minBp: serializer.fromJson<int>(json['min_bp']),
      grade: serializer.fromJson<String>(json['grade']),
      remark: serializer.fromJson<String>(json['remark']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scale_id': serializer.toJson<String>(scaleId),
      'min_bp': serializer.toJson<int>(minBp),
      'grade': serializer.toJson<String>(grade),
      'remark': serializer.toJson<String>(remark),
    };
  }

  GradeScaleItemRow copyWith({String? scaleId, int? minBp, String? grade, String? remark}) => GradeScaleItemRow(
    scaleId: scaleId ?? this.scaleId,
    minBp: minBp ?? this.minBp,
    grade: grade ?? this.grade,
    remark: remark ?? this.remark,
  );
  GradeScaleItemRow copyWithCompanion(GradeScaleRowsCompanion data) {
    return GradeScaleItemRow(
      scaleId: data.scaleId.present ? data.scaleId.value : this.scaleId,
      minBp: data.minBp.present ? data.minBp.value : this.minBp,
      grade: data.grade.present ? data.grade.value : this.grade,
      remark: data.remark.present ? data.remark.value : this.remark,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GradeScaleItemRow(')
          ..write('scaleId: $scaleId, ')
          ..write('minBp: $minBp, ')
          ..write('grade: $grade, ')
          ..write('remark: $remark')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scaleId, minBp, grade, remark);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GradeScaleItemRow &&
          other.scaleId == this.scaleId &&
          other.minBp == this.minBp &&
          other.grade == this.grade &&
          other.remark == this.remark);
}

class GradeScaleRowsCompanion extends UpdateCompanion<GradeScaleItemRow> {
  final Value<String> scaleId;
  final Value<int> minBp;
  final Value<String> grade;
  final Value<String> remark;
  final Value<int> rowid;
  const GradeScaleRowsCompanion({
    this.scaleId = const Value.absent(),
    this.minBp = const Value.absent(),
    this.grade = const Value.absent(),
    this.remark = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GradeScaleRowsCompanion.insert({
    required String scaleId,
    required int minBp,
    required String grade,
    this.remark = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scaleId = Value(scaleId),
       minBp = Value(minBp),
       grade = Value(grade);
  static Insertable<GradeScaleItemRow> custom({
    Expression<String>? scaleId,
    Expression<int>? minBp,
    Expression<String>? grade,
    Expression<String>? remark,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scaleId != null) 'scale_id': scaleId,
      if (minBp != null) 'min_bp': minBp,
      if (grade != null) 'grade': grade,
      if (remark != null) 'remark': remark,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GradeScaleRowsCompanion copyWith({
    Value<String>? scaleId,
    Value<int>? minBp,
    Value<String>? grade,
    Value<String>? remark,
    Value<int>? rowid,
  }) {
    return GradeScaleRowsCompanion(
      scaleId: scaleId ?? this.scaleId,
      minBp: minBp ?? this.minBp,
      grade: grade ?? this.grade,
      remark: remark ?? this.remark,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scaleId.present) {
      map['scale_id'] = Variable<String>(scaleId.value);
    }
    if (minBp.present) {
      map['min_bp'] = Variable<int>(minBp.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradeScaleRowsCompanion(')
          ..write('scaleId: $scaleId, ')
          ..write('minBp: $minBp, ')
          ..write('grade: $grade, ')
          ..write('remark: $remark, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Subjects extends Table with TableInfo<Subjects, SubjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Subjects(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(code)) BETWEEN 1 AND 30)',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(title) <= 160)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _academicYearMeta = const VerificationMeta('academicYear');
  late final GeneratedColumn<String> academicYear = GeneratedColumn<String>(
    'academic_year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(academic_year) <= 20)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta('semester');
  late final GeneratedColumn<String> semester = GeneratedColumn<String>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(semester) <= 40)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _combineMethodMeta = const VerificationMeta('combineMethod');
  late final GeneratedColumn<String> combineMethod = GeneratedColumn<String>(
    'combine_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'total_points\' CHECK (combine_method IN (\'total_points\', \'average_percent\'))',
    defaultValue: const CustomExpression('\'total_points\''),
  );
  static const VerificationMeta _gradeScaleIdMeta = const VerificationMeta('gradeScaleId');
  late final GeneratedColumn<String> gradeScaleId = GeneratedColumn<String>(
    'grade_scale_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES grade_scales(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _gradingActiveMeta = const VerificationMeta('gradingActive');
  late final GeneratedColumn<bool> gradingActive = GeneratedColumn<bool>(
    'grading_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    title,
    academicYear,
    semester,
    combineMethod,
    gradeScaleId,
    gradingActive,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(Insertable<SubjectRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(_codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('academic_year')) {
      context.handle(_academicYearMeta, academicYear.isAcceptableOrUnknown(data['academic_year']!, _academicYearMeta));
    }
    if (data.containsKey('semester')) {
      context.handle(_semesterMeta, semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta));
    }
    if (data.containsKey('combine_method')) {
      context.handle(
        _combineMethodMeta,
        combineMethod.isAcceptableOrUnknown(data['combine_method']!, _combineMethodMeta),
      );
    }
    if (data.containsKey('grade_scale_id')) {
      context.handle(_gradeScaleIdMeta, gradeScaleId.isAcceptableOrUnknown(data['grade_scale_id']!, _gradeScaleIdMeta));
    }
    if (data.containsKey('grading_active')) {
      context.handle(
        _gradingActiveMeta,
        gradingActive.isAcceptableOrUnknown(data['grading_active']!, _gradingActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      academicYear: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}academic_year'])!,
      semester: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}semester'])!,
      combineMethod: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}combine_method'])!,
      gradeScaleId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}grade_scale_id']),
      gradingActive: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}grading_active'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  Subjects createAlias(String alias) {
    return Subjects(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SubjectRow extends DataClass implements Insertable<SubjectRow> {
  final String id;
  final String code;
  final String title;
  final String academicYear;
  final String semester;

  /// How several activities of one category combine:
  /// total_points = sum(scores) / sum(maximum points); average_percent = mean of percentages.
  final String combineMethod;
  final String? gradeScaleId;

  /// Set only when the weights total exactly 100 %.
  final bool gradingActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const SubjectRow({
    required this.id,
    required this.code,
    required this.title,
    required this.academicYear,
    required this.semester,
    required this.combineMethod,
    this.gradeScaleId,
    required this.gradingActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['title'] = Variable<String>(title);
    map['academic_year'] = Variable<String>(academicYear);
    map['semester'] = Variable<String>(semester);
    map['combine_method'] = Variable<String>(combineMethod);
    if (!nullToAbsent || gradeScaleId != null) {
      map['grade_scale_id'] = Variable<String>(gradeScaleId);
    }
    map['grading_active'] = Variable<bool>(gradingActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      code: Value(code),
      title: Value(title),
      academicYear: Value(academicYear),
      semester: Value(semester),
      combineMethod: Value(combineMethod),
      gradeScaleId: gradeScaleId == null && nullToAbsent ? const Value.absent() : Value(gradeScaleId),
      gradingActive: Value(gradingActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory SubjectRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      title: serializer.fromJson<String>(json['title']),
      academicYear: serializer.fromJson<String>(json['academic_year']),
      semester: serializer.fromJson<String>(json['semester']),
      combineMethod: serializer.fromJson<String>(json['combine_method']),
      gradeScaleId: serializer.fromJson<String?>(json['grade_scale_id']),
      gradingActive: serializer.fromJson<bool>(json['grading_active']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      deletedAt: serializer.fromJson<DateTime?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'title': serializer.toJson<String>(title),
      'academic_year': serializer.toJson<String>(academicYear),
      'semester': serializer.toJson<String>(semester),
      'combine_method': serializer.toJson<String>(combineMethod),
      'grade_scale_id': serializer.toJson<String?>(gradeScaleId),
      'grading_active': serializer.toJson<bool>(gradingActive),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'deleted_at': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SubjectRow copyWith({
    String? id,
    String? code,
    String? title,
    String? academicYear,
    String? semester,
    String? combineMethod,
    Value<String?> gradeScaleId = const Value.absent(),
    bool? gradingActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SubjectRow(
    id: id ?? this.id,
    code: code ?? this.code,
    title: title ?? this.title,
    academicYear: academicYear ?? this.academicYear,
    semester: semester ?? this.semester,
    combineMethod: combineMethod ?? this.combineMethod,
    gradeScaleId: gradeScaleId.present ? gradeScaleId.value : this.gradeScaleId,
    gradingActive: gradingActive ?? this.gradingActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SubjectRow copyWithCompanion(SubjectsCompanion data) {
    return SubjectRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      title: data.title.present ? data.title.value : this.title,
      academicYear: data.academicYear.present ? data.academicYear.value : this.academicYear,
      semester: data.semester.present ? data.semester.value : this.semester,
      combineMethod: data.combineMethod.present ? data.combineMethod.value : this.combineMethod,
      gradeScaleId: data.gradeScaleId.present ? data.gradeScaleId.value : this.gradeScaleId,
      gradingActive: data.gradingActive.present ? data.gradingActive.value : this.gradingActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('title: $title, ')
          ..write('academicYear: $academicYear, ')
          ..write('semester: $semester, ')
          ..write('combineMethod: $combineMethod, ')
          ..write('gradeScaleId: $gradeScaleId, ')
          ..write('gradingActive: $gradingActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    title,
    academicYear,
    semester,
    combineMethod,
    gradeScaleId,
    gradingActive,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.title == this.title &&
          other.academicYear == this.academicYear &&
          other.semester == this.semester &&
          other.combineMethod == this.combineMethod &&
          other.gradeScaleId == this.gradeScaleId &&
          other.gradingActive == this.gradingActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SubjectsCompanion extends UpdateCompanion<SubjectRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> title;
  final Value<String> academicYear;
  final Value<String> semester;
  final Value<String> combineMethod;
  final Value<String?> gradeScaleId;
  final Value<bool> gradingActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.title = const Value.absent(),
    this.academicYear = const Value.absent(),
    this.semester = const Value.absent(),
    this.combineMethod = const Value.absent(),
    this.gradeScaleId = const Value.absent(),
    this.gradingActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String id,
    required String code,
    this.title = const Value.absent(),
    this.academicYear = const Value.absent(),
    this.semester = const Value.absent(),
    this.combineMethod = const Value.absent(),
    this.gradeScaleId = const Value.absent(),
    this.gradingActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SubjectRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? title,
    Expression<String>? academicYear,
    Expression<String>? semester,
    Expression<String>? combineMethod,
    Expression<String>? gradeScaleId,
    Expression<bool>? gradingActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (title != null) 'title': title,
      if (academicYear != null) 'academic_year': academicYear,
      if (semester != null) 'semester': semester,
      if (combineMethod != null) 'combine_method': combineMethod,
      if (gradeScaleId != null) 'grade_scale_id': gradeScaleId,
      if (gradingActive != null) 'grading_active': gradingActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? title,
    Value<String>? academicYear,
    Value<String>? semester,
    Value<String>? combineMethod,
    Value<String?>? gradeScaleId,
    Value<bool>? gradingActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SubjectsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      combineMethod: combineMethod ?? this.combineMethod,
      gradeScaleId: gradeScaleId ?? this.gradeScaleId,
      gradingActive: gradingActive ?? this.gradingActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (academicYear.present) {
      map['academic_year'] = Variable<String>(academicYear.value);
    }
    if (semester.present) {
      map['semester'] = Variable<String>(semester.value);
    }
    if (combineMethod.present) {
      map['combine_method'] = Variable<String>(combineMethod.value);
    }
    if (gradeScaleId.present) {
      map['grade_scale_id'] = Variable<String>(gradeScaleId.value);
    }
    if (gradingActive.present) {
      map['grading_active'] = Variable<bool>(gradingActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('title: $title, ')
          ..write('academicYear: $academicYear, ')
          ..write('semester: $semester, ')
          ..write('combineMethod: $combineMethod, ')
          ..write('gradeScaleId: $gradeScaleId, ')
          ..write('gradingActive: $gradingActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SubjectStudents extends Table with TableInfo<SubjectStudents, EnrolmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SubjectStudents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectIdMeta = const VerificationMeta('subjectId');
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES subjects(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta('studentId');
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES students(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _enrolledAtMeta = const VerificationMeta('enrolledAt');
  late final GeneratedColumn<DateTime> enrolledAt = GeneratedColumn<DateTime>(
    'enrolled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [subjectId, studentId, enrolledAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subject_students';
  @override
  VerificationContext validateIntegrity(Insertable<EnrolmentRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta, subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta, studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('enrolled_at')) {
      context.handle(_enrolledAtMeta, enrolledAt.isAcceptableOrUnknown(data['enrolled_at']!, _enrolledAtMeta));
    } else if (isInserting) {
      context.missing(_enrolledAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subjectId, studentId};
  @override
  EnrolmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnrolmentRow(
      subjectId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      studentId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      enrolledAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}enrolled_at'])!,
    );
  }

  @override
  SubjectStudents createAlias(String alias) {
    return SubjectStudents(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(subject_id, student_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class EnrolmentRow extends DataClass implements Insertable<EnrolmentRow> {
  final String subjectId;
  final String studentId;
  final DateTime enrolledAt;
  const EnrolmentRow({required this.subjectId, required this.studentId, required this.enrolledAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject_id'] = Variable<String>(subjectId);
    map['student_id'] = Variable<String>(studentId);
    map['enrolled_at'] = Variable<DateTime>(enrolledAt);
    return map;
  }

  SubjectStudentsCompanion toCompanion(bool nullToAbsent) {
    return SubjectStudentsCompanion(
      subjectId: Value(subjectId),
      studentId: Value(studentId),
      enrolledAt: Value(enrolledAt),
    );
  }

  factory EnrolmentRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnrolmentRow(
      subjectId: serializer.fromJson<String>(json['subject_id']),
      studentId: serializer.fromJson<String>(json['student_id']),
      enrolledAt: serializer.fromJson<DateTime>(json['enrolled_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subject_id': serializer.toJson<String>(subjectId),
      'student_id': serializer.toJson<String>(studentId),
      'enrolled_at': serializer.toJson<DateTime>(enrolledAt),
    };
  }

  EnrolmentRow copyWith({String? subjectId, String? studentId, DateTime? enrolledAt}) => EnrolmentRow(
    subjectId: subjectId ?? this.subjectId,
    studentId: studentId ?? this.studentId,
    enrolledAt: enrolledAt ?? this.enrolledAt,
  );
  EnrolmentRow copyWithCompanion(SubjectStudentsCompanion data) {
    return EnrolmentRow(
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      enrolledAt: data.enrolledAt.present ? data.enrolledAt.value : this.enrolledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnrolmentRow(')
          ..write('subjectId: $subjectId, ')
          ..write('studentId: $studentId, ')
          ..write('enrolledAt: $enrolledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(subjectId, studentId, enrolledAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnrolmentRow &&
          other.subjectId == this.subjectId &&
          other.studentId == this.studentId &&
          other.enrolledAt == this.enrolledAt);
}

class SubjectStudentsCompanion extends UpdateCompanion<EnrolmentRow> {
  final Value<String> subjectId;
  final Value<String> studentId;
  final Value<DateTime> enrolledAt;
  final Value<int> rowid;
  const SubjectStudentsCompanion({
    this.subjectId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.enrolledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectStudentsCompanion.insert({
    required String subjectId,
    required String studentId,
    required DateTime enrolledAt,
    this.rowid = const Value.absent(),
  }) : subjectId = Value(subjectId),
       studentId = Value(studentId),
       enrolledAt = Value(enrolledAt);
  static Insertable<EnrolmentRow> custom({
    Expression<String>? subjectId,
    Expression<String>? studentId,
    Expression<DateTime>? enrolledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subjectId != null) 'subject_id': subjectId,
      if (studentId != null) 'student_id': studentId,
      if (enrolledAt != null) 'enrolled_at': enrolledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectStudentsCompanion copyWith({
    Value<String>? subjectId,
    Value<String>? studentId,
    Value<DateTime>? enrolledAt,
    Value<int>? rowid,
  }) {
    return SubjectStudentsCompanion(
      subjectId: subjectId ?? this.subjectId,
      studentId: studentId ?? this.studentId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (enrolledAt.present) {
      map['enrolled_at'] = Variable<DateTime>(enrolledAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectStudentsCompanion(')
          ..write('subjectId: $subjectId, ')
          ..write('studentId: $studentId, ')
          ..write('enrolledAt: $enrolledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Categories extends Table with TableInfo<Categories, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Categories(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 40)',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'quiz\', \'recitation\', \'exam\'))',
  );
  static const VerificationMeta _defaultMaxPointsMeta = const VerificationMeta('defaultMaxPoints');
  late final GeneratedColumn<int> defaultMaxPoints = GeneratedColumn<int>(
    'default_max_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (default_max_points BETWEEN 1 AND 1000)',
  );
  static const VerificationMeta _builtInMeta = const VerificationMeta('builtIn');
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 100',
    defaultValue: const CustomExpression('100'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, kind, defaultMaxPoints, builtIn, sortOrder, createdAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('default_max_points')) {
      context.handle(
        _defaultMaxPointsMeta,
        defaultMaxPoints.isAcceptableOrUnknown(data['default_max_points']!, _defaultMaxPointsMeta),
      );
    } else if (isInserting) {
      context.missing(_defaultMaxPointsMeta);
    }
    if (data.containsKey('built_in')) {
      context.handle(_builtInMeta, builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      defaultMaxPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_max_points'],
      )!,
      builtIn: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}built_in'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  Categories createAlias(String alias) {
    return Categories(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final String kind;
  final int defaultMaxPoints;
  final bool builtIn;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? deletedAt;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.defaultMaxPoints,
    required this.builtIn,
    required this.sortOrder,
    required this.createdAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['default_max_points'] = Variable<int>(defaultMaxPoints);
    map['built_in'] = Variable<bool>(builtIn);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      defaultMaxPoints: Value(defaultMaxPoints),
      builtIn: Value(builtIn),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory CategoryRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      defaultMaxPoints: serializer.fromJson<int>(json['default_max_points']),
      builtIn: serializer.fromJson<bool>(json['built_in']),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      deletedAt: serializer.fromJson<DateTime?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'default_max_points': serializer.toJson<int>(defaultMaxPoints),
      'built_in': serializer.toJson<bool>(builtIn),
      'sort_order': serializer.toJson<int>(sortOrder),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'deleted_at': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    String? kind,
    int? defaultMaxPoints,
    bool? builtIn,
    int? sortOrder,
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    defaultMaxPoints: defaultMaxPoints ?? this.defaultMaxPoints,
    builtIn: builtIn ?? this.builtIn,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      defaultMaxPoints: data.defaultMaxPoints.present ? data.defaultMaxPoints.value : this.defaultMaxPoints,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('defaultMaxPoints: $defaultMaxPoints, ')
          ..write('builtIn: $builtIn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, kind, defaultMaxPoints, builtIn, sortOrder, createdAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.defaultMaxPoints == this.defaultMaxPoints &&
          other.builtIn == this.builtIn &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<int> defaultMaxPoints;
  final Value<bool> builtIn;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.defaultMaxPoints = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required String kind,
    required int defaultMaxPoints,
    this.builtIn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       defaultMaxPoints = Value(defaultMaxPoints),
       createdAt = Value(createdAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? defaultMaxPoints,
    Expression<bool>? builtIn,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (defaultMaxPoints != null) 'default_max_points': defaultMaxPoints,
      if (builtIn != null) 'built_in': builtIn,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<int>? defaultMaxPoints,
    Value<bool>? builtIn,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      defaultMaxPoints: defaultMaxPoints ?? this.defaultMaxPoints,
      builtIn: builtIn ?? this.builtIn,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (defaultMaxPoints.present) {
      map['default_max_points'] = Variable<int>(defaultMaxPoints.value);
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('defaultMaxPoints: $defaultMaxPoints, ')
          ..write('builtIn: $builtIn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SubjectWeights extends Table with TableInfo<SubjectWeights, WeightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SubjectWeights(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectIdMeta = const VerificationMeta('subjectId');
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES subjects(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES categories(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _weightBpMeta = const VerificationMeta('weightBp');
  late final GeneratedColumn<int> weightBp = GeneratedColumn<int>(
    'weight_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (weight_bp BETWEEN 0 AND 10000)',
  );
  @override
  List<GeneratedColumn> get $columns => [subjectId, categoryId, weightBp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subject_weights';
  @override
  VerificationContext validateIntegrity(Insertable<WeightRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta, subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('weight_bp')) {
      context.handle(_weightBpMeta, weightBp.isAcceptableOrUnknown(data['weight_bp']!, _weightBpMeta));
    } else if (isInserting) {
      context.missing(_weightBpMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subjectId, categoryId};
  @override
  WeightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightRow(
      subjectId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      weightBp: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}weight_bp'])!,
    );
  }

  @override
  SubjectWeights createAlias(String alias) {
    return SubjectWeights(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(subject_id, category_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class WeightRow extends DataClass implements Insertable<WeightRow> {
  final String subjectId;
  final String categoryId;
  final int weightBp;
  const WeightRow({required this.subjectId, required this.categoryId, required this.weightBp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject_id'] = Variable<String>(subjectId);
    map['category_id'] = Variable<String>(categoryId);
    map['weight_bp'] = Variable<int>(weightBp);
    return map;
  }

  SubjectWeightsCompanion toCompanion(bool nullToAbsent) {
    return SubjectWeightsCompanion(
      subjectId: Value(subjectId),
      categoryId: Value(categoryId),
      weightBp: Value(weightBp),
    );
  }

  factory WeightRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightRow(
      subjectId: serializer.fromJson<String>(json['subject_id']),
      categoryId: serializer.fromJson<String>(json['category_id']),
      weightBp: serializer.fromJson<int>(json['weight_bp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subject_id': serializer.toJson<String>(subjectId),
      'category_id': serializer.toJson<String>(categoryId),
      'weight_bp': serializer.toJson<int>(weightBp),
    };
  }

  WeightRow copyWith({String? subjectId, String? categoryId, int? weightBp}) => WeightRow(
    subjectId: subjectId ?? this.subjectId,
    categoryId: categoryId ?? this.categoryId,
    weightBp: weightBp ?? this.weightBp,
  );
  WeightRow copyWithCompanion(SubjectWeightsCompanion data) {
    return WeightRow(
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      weightBp: data.weightBp.present ? data.weightBp.value : this.weightBp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightRow(')
          ..write('subjectId: $subjectId, ')
          ..write('categoryId: $categoryId, ')
          ..write('weightBp: $weightBp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(subjectId, categoryId, weightBp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightRow &&
          other.subjectId == this.subjectId &&
          other.categoryId == this.categoryId &&
          other.weightBp == this.weightBp);
}

class SubjectWeightsCompanion extends UpdateCompanion<WeightRow> {
  final Value<String> subjectId;
  final Value<String> categoryId;
  final Value<int> weightBp;
  final Value<int> rowid;
  const SubjectWeightsCompanion({
    this.subjectId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.weightBp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectWeightsCompanion.insert({
    required String subjectId,
    required String categoryId,
    required int weightBp,
    this.rowid = const Value.absent(),
  }) : subjectId = Value(subjectId),
       categoryId = Value(categoryId),
       weightBp = Value(weightBp);
  static Insertable<WeightRow> custom({
    Expression<String>? subjectId,
    Expression<String>? categoryId,
    Expression<int>? weightBp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subjectId != null) 'subject_id': subjectId,
      if (categoryId != null) 'category_id': categoryId,
      if (weightBp != null) 'weight_bp': weightBp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectWeightsCompanion copyWith({
    Value<String>? subjectId,
    Value<String>? categoryId,
    Value<int>? weightBp,
    Value<int>? rowid,
  }) {
    return SubjectWeightsCompanion(
      subjectId: subjectId ?? this.subjectId,
      categoryId: categoryId ?? this.categoryId,
      weightBp: weightBp ?? this.weightBp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (weightBp.present) {
      map['weight_bp'] = Variable<int>(weightBp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectWeightsCompanion(')
          ..write('subjectId: $subjectId, ')
          ..write('categoryId: $categoryId, ')
          ..write('weightBp: $weightBp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Activities extends Table with TableInfo<Activities, ActivityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Activities(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta('subjectId');
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES subjects(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES categories(id)',
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (number IS NULL OR number BETWEEN 1 AND 999)',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(title) <= 80)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _maxPointsMeta = const VerificationMeta('maxPoints');
  late final GeneratedColumn<int> maxPoints = GeneratedColumn<int>(
    'max_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (max_points BETWEEN 1 AND 1000)',
  );
  static const VerificationMeta _activityDateMeta = const VerificationMeta('activityDate');
  late final GeneratedColumn<String> activityDate = GeneratedColumn<String>(
    'activity_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (activity_date IS NULL OR activity_date GLOB \'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\')',
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'\' CHECK (period IN (\'\', \'prelim\', \'midterm\', \'prefinal\', \'final\'))',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta('remarks');
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(remarks) <= 500)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subjectId,
    categoryId,
    number,
    title,
    maxPoints,
    activityDate,
    period,
    remarks,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(Insertable<ActivityRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta, subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta, number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('max_points')) {
      context.handle(_maxPointsMeta, maxPoints.isAcceptableOrUnknown(data['max_points']!, _maxPointsMeta));
    } else if (isInserting) {
      context.missing(_maxPointsMeta);
    }
    if (data.containsKey('activity_date')) {
      context.handle(_activityDateMeta, activityDate.isAcceptableOrUnknown(data['activity_date']!, _activityDateMeta));
    }
    if (data.containsKey('period')) {
      context.handle(_periodMeta, period.isAcceptableOrUnknown(data['period']!, _periodMeta));
    }
    if (data.containsKey('remarks')) {
      context.handle(_remarksMeta, remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subjectId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      number: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}number']),
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      maxPoints: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}max_points'])!,
      activityDate: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}activity_date']),
      period: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}period'])!,
      remarks: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}remarks'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  Activities createAlias(String alias) {
    return Activities(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ActivityRow extends DataClass implements Insertable<ActivityRow> {
  final String id;
  final String subjectId;
  final String categoryId;
  final int? number;
  final String title;
  final int maxPoints;
  final String? activityDate;

  /// Optional grading-period tag, used for filters and reports only.
  final String period;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const ActivityRow({
    required this.id,
    required this.subjectId,
    required this.categoryId,
    this.number,
    required this.title,
    required this.maxPoints,
    this.activityDate,
    required this.period,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject_id'] = Variable<String>(subjectId);
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<int>(number);
    }
    map['title'] = Variable<String>(title);
    map['max_points'] = Variable<int>(maxPoints);
    if (!nullToAbsent || activityDate != null) {
      map['activity_date'] = Variable<String>(activityDate);
    }
    map['period'] = Variable<String>(period);
    map['remarks'] = Variable<String>(remarks);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      categoryId: Value(categoryId),
      number: number == null && nullToAbsent ? const Value.absent() : Value(number),
      title: Value(title),
      maxPoints: Value(maxPoints),
      activityDate: activityDate == null && nullToAbsent ? const Value.absent() : Value(activityDate),
      period: Value(period),
      remarks: Value(remarks),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory ActivityRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityRow(
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subject_id']),
      categoryId: serializer.fromJson<String>(json['category_id']),
      number: serializer.fromJson<int?>(json['number']),
      title: serializer.fromJson<String>(json['title']),
      maxPoints: serializer.fromJson<int>(json['max_points']),
      activityDate: serializer.fromJson<String?>(json['activity_date']),
      period: serializer.fromJson<String>(json['period']),
      remarks: serializer.fromJson<String>(json['remarks']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      deletedAt: serializer.fromJson<DateTime?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subject_id': serializer.toJson<String>(subjectId),
      'category_id': serializer.toJson<String>(categoryId),
      'number': serializer.toJson<int?>(number),
      'title': serializer.toJson<String>(title),
      'max_points': serializer.toJson<int>(maxPoints),
      'activity_date': serializer.toJson<String?>(activityDate),
      'period': serializer.toJson<String>(period),
      'remarks': serializer.toJson<String>(remarks),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'deleted_at': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ActivityRow copyWith({
    String? id,
    String? subjectId,
    String? categoryId,
    Value<int?> number = const Value.absent(),
    String? title,
    int? maxPoints,
    Value<String?> activityDate = const Value.absent(),
    String? period,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ActivityRow(
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    categoryId: categoryId ?? this.categoryId,
    number: number.present ? number.value : this.number,
    title: title ?? this.title,
    maxPoints: maxPoints ?? this.maxPoints,
    activityDate: activityDate.present ? activityDate.value : this.activityDate,
    period: period ?? this.period,
    remarks: remarks ?? this.remarks,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ActivityRow copyWithCompanion(ActivitiesCompanion data) {
    return ActivityRow(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      number: data.number.present ? data.number.value : this.number,
      title: data.title.present ? data.title.value : this.title,
      maxPoints: data.maxPoints.present ? data.maxPoints.value : this.maxPoints,
      activityDate: data.activityDate.present ? data.activityDate.value : this.activityDate,
      period: data.period.present ? data.period.value : this.period,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityRow(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('categoryId: $categoryId, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('maxPoints: $maxPoints, ')
          ..write('activityDate: $activityDate, ')
          ..write('period: $period, ')
          ..write('remarks: $remarks, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subjectId,
    categoryId,
    number,
    title,
    maxPoints,
    activityDate,
    period,
    remarks,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityRow &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.categoryId == this.categoryId &&
          other.number == this.number &&
          other.title == this.title &&
          other.maxPoints == this.maxPoints &&
          other.activityDate == this.activityDate &&
          other.period == this.period &&
          other.remarks == this.remarks &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ActivitiesCompanion extends UpdateCompanion<ActivityRow> {
  final Value<String> id;
  final Value<String> subjectId;
  final Value<String> categoryId;
  final Value<int?> number;
  final Value<String> title;
  final Value<int> maxPoints;
  final Value<String?> activityDate;
  final Value<String> period;
  final Value<String> remarks;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    this.maxPoints = const Value.absent(),
    this.activityDate = const Value.absent(),
    this.period = const Value.absent(),
    this.remarks = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    required String id,
    required String subjectId,
    required String categoryId,
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    required int maxPoints,
    this.activityDate = const Value.absent(),
    this.period = const Value.absent(),
    this.remarks = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       subjectId = Value(subjectId),
       categoryId = Value(categoryId),
       maxPoints = Value(maxPoints),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ActivityRow> custom({
    Expression<String>? id,
    Expression<String>? subjectId,
    Expression<String>? categoryId,
    Expression<int>? number,
    Expression<String>? title,
    Expression<int>? maxPoints,
    Expression<String>? activityDate,
    Expression<String>? period,
    Expression<String>? remarks,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (categoryId != null) 'category_id': categoryId,
      if (number != null) 'number': number,
      if (title != null) 'title': title,
      if (maxPoints != null) 'max_points': maxPoints,
      if (activityDate != null) 'activity_date': activityDate,
      if (period != null) 'period': period,
      if (remarks != null) 'remarks': remarks,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? subjectId,
    Value<String>? categoryId,
    Value<int?>? number,
    Value<String>? title,
    Value<int>? maxPoints,
    Value<String?>? activityDate,
    Value<String>? period,
    Value<String>? remarks,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      categoryId: categoryId ?? this.categoryId,
      number: number ?? this.number,
      title: title ?? this.title,
      maxPoints: maxPoints ?? this.maxPoints,
      activityDate: activityDate ?? this.activityDate,
      period: period ?? this.period,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (maxPoints.present) {
      map['max_points'] = Variable<int>(maxPoints.value);
    }
    if (activityDate.present) {
      map['activity_date'] = Variable<String>(activityDate.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('categoryId: $categoryId, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('maxPoints: $maxPoints, ')
          ..write('activityDate: $activityDate, ')
          ..write('period: $period, ')
          ..write('remarks: $remarks, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Scores extends Table with TableInfo<Scores, ScoreRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Scores(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta('activityId');
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES activities(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta('studentId');
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES students(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (points >= 0)',
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta('remarks');
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' CHECK (length(remarks) <= 500)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, activityId, studentId, points, remarks, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scores';
  @override
  VerificationContext validateIntegrity(Insertable<ScoreRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(_activityIdMeta, activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta));
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta, studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('points')) {
      context.handle(_pointsMeta, points.isAcceptableOrUnknown(data['points']!, _pointsMeta));
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    if (data.containsKey('remarks')) {
      context.handle(_remarksMeta, remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScoreRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoreRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      activityId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}activity_id'])!,
      studentId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      points: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}points'])!,
      remarks: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}remarks'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  Scores createAlias(String alias) {
    return Scores(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ScoreRow extends DataClass implements Insertable<ScoreRow> {
  final String id;
  final String activityId;
  final String studentId;
  final int points;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ScoreRow({
    required this.id,
    required this.activityId,
    required this.studentId,
    required this.points,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['activity_id'] = Variable<String>(activityId);
    map['student_id'] = Variable<String>(studentId);
    map['points'] = Variable<int>(points);
    map['remarks'] = Variable<String>(remarks);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ScoresCompanion toCompanion(bool nullToAbsent) {
    return ScoresCompanion(
      id: Value(id),
      activityId: Value(activityId),
      studentId: Value(studentId),
      points: Value(points),
      remarks: Value(remarks),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScoreRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoreRow(
      id: serializer.fromJson<String>(json['id']),
      activityId: serializer.fromJson<String>(json['activity_id']),
      studentId: serializer.fromJson<String>(json['student_id']),
      points: serializer.fromJson<int>(json['points']),
      remarks: serializer.fromJson<String>(json['remarks']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activity_id': serializer.toJson<String>(activityId),
      'student_id': serializer.toJson<String>(studentId),
      'points': serializer.toJson<int>(points),
      'remarks': serializer.toJson<String>(remarks),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ScoreRow copyWith({
    String? id,
    String? activityId,
    String? studentId,
    int? points,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ScoreRow(
    id: id ?? this.id,
    activityId: activityId ?? this.activityId,
    studentId: studentId ?? this.studentId,
    points: points ?? this.points,
    remarks: remarks ?? this.remarks,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ScoreRow copyWithCompanion(ScoresCompanion data) {
    return ScoreRow(
      id: data.id.present ? data.id.value : this.id,
      activityId: data.activityId.present ? data.activityId.value : this.activityId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      points: data.points.present ? data.points.value : this.points,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoreRow(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('studentId: $studentId, ')
          ..write('points: $points, ')
          ..write('remarks: $remarks, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, activityId, studentId, points, remarks, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoreRow &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.studentId == this.studentId &&
          other.points == this.points &&
          other.remarks == this.remarks &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScoresCompanion extends UpdateCompanion<ScoreRow> {
  final Value<String> id;
  final Value<String> activityId;
  final Value<String> studentId;
  final Value<int> points;
  final Value<String> remarks;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ScoresCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.points = const Value.absent(),
    this.remarks = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoresCompanion.insert({
    required String id,
    required String activityId,
    required String studentId,
    required int points,
    this.remarks = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       activityId = Value(activityId),
       studentId = Value(studentId),
       points = Value(points),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ScoreRow> custom({
    Expression<String>? id,
    Expression<String>? activityId,
    Expression<String>? studentId,
    Expression<int>? points,
    Expression<String>? remarks,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (studentId != null) 'student_id': studentId,
      if (points != null) 'points': points,
      if (remarks != null) 'remarks': remarks,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoresCompanion copyWith({
    Value<String>? id,
    Value<String>? activityId,
    Value<String>? studentId,
    Value<int>? points,
    Value<String>? remarks,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ScoresCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      studentId: studentId ?? this.studentId,
      points: points ?? this.points,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoresCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('studentId: $studentId, ')
          ..write('points: $points, ')
          ..write('remarks: $remarks, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ScoreHistory extends Table with TableInfo<ScoreHistory, ScoreHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ScoreHistory(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _scoreIdMeta = const VerificationMeta('scoreId');
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta('activityId');
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta('studentId');
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _changeMeta = const VerificationMeta('change');
  late final GeneratedColumn<String> change = GeneratedColumn<String>(
    'change',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (change IN (\'create\', \'update\', \'delete\'))',
  );
  static const VerificationMeta _oldPointsMeta = const VerificationMeta('oldPoints');
  late final GeneratedColumn<int> oldPoints = GeneratedColumn<int>(
    'old_points',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _newPointsMeta = const VerificationMeta('newPoints');
  late final GeneratedColumn<int> newPoints = GeneratedColumn<int>(
    'new_points',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _maxPointsMeta = const VerificationMeta('maxPoints');
  late final GeneratedColumn<int> maxPoints = GeneratedColumn<int>(
    'max_points',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scoreId,
    activityId,
    studentId,
    change,
    oldPoints,
    newPoints,
    maxPoints,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'score_history';
  @override
  VerificationContext validateIntegrity(Insertable<ScoreHistoryRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('score_id')) {
      context.handle(_scoreIdMeta, scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta));
    } else if (isInserting) {
      context.missing(_scoreIdMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(_activityIdMeta, activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta));
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta, studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('change')) {
      context.handle(_changeMeta, change.isAcceptableOrUnknown(data['change']!, _changeMeta));
    } else if (isInserting) {
      context.missing(_changeMeta);
    }
    if (data.containsKey('old_points')) {
      context.handle(_oldPointsMeta, oldPoints.isAcceptableOrUnknown(data['old_points']!, _oldPointsMeta));
    }
    if (data.containsKey('new_points')) {
      context.handle(_newPointsMeta, newPoints.isAcceptableOrUnknown(data['new_points']!, _newPointsMeta));
    }
    if (data.containsKey('max_points')) {
      context.handle(_maxPointsMeta, maxPoints.isAcceptableOrUnknown(data['max_points']!, _maxPointsMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScoreHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoreHistoryRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      scoreId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}score_id'])!,
      activityId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}activity_id'])!,
      studentId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      change: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}change'])!,
      oldPoints: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}old_points']),
      newPoints: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}new_points']),
      maxPoints: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}max_points']),
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
    );
  }

  @override
  ScoreHistory createAlias(String alias) {
    return ScoreHistory(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ScoreHistoryRow extends DataClass implements Insertable<ScoreHistoryRow> {
  final int id;
  final String scoreId;
  final String activityId;
  final String studentId;
  final String change;
  final int? oldPoints;
  final int? newPoints;
  final int? maxPoints;
  final DateTime at;
  const ScoreHistoryRow({
    required this.id,
    required this.scoreId,
    required this.activityId,
    required this.studentId,
    required this.change,
    this.oldPoints,
    this.newPoints,
    this.maxPoints,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['score_id'] = Variable<String>(scoreId);
    map['activity_id'] = Variable<String>(activityId);
    map['student_id'] = Variable<String>(studentId);
    map['change'] = Variable<String>(change);
    if (!nullToAbsent || oldPoints != null) {
      map['old_points'] = Variable<int>(oldPoints);
    }
    if (!nullToAbsent || newPoints != null) {
      map['new_points'] = Variable<int>(newPoints);
    }
    if (!nullToAbsent || maxPoints != null) {
      map['max_points'] = Variable<int>(maxPoints);
    }
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  ScoreHistoryCompanion toCompanion(bool nullToAbsent) {
    return ScoreHistoryCompanion(
      id: Value(id),
      scoreId: Value(scoreId),
      activityId: Value(activityId),
      studentId: Value(studentId),
      change: Value(change),
      oldPoints: oldPoints == null && nullToAbsent ? const Value.absent() : Value(oldPoints),
      newPoints: newPoints == null && nullToAbsent ? const Value.absent() : Value(newPoints),
      maxPoints: maxPoints == null && nullToAbsent ? const Value.absent() : Value(maxPoints),
      at: Value(at),
    );
  }

  factory ScoreHistoryRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoreHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      scoreId: serializer.fromJson<String>(json['score_id']),
      activityId: serializer.fromJson<String>(json['activity_id']),
      studentId: serializer.fromJson<String>(json['student_id']),
      change: serializer.fromJson<String>(json['change']),
      oldPoints: serializer.fromJson<int?>(json['old_points']),
      newPoints: serializer.fromJson<int?>(json['new_points']),
      maxPoints: serializer.fromJson<int?>(json['max_points']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'score_id': serializer.toJson<String>(scoreId),
      'activity_id': serializer.toJson<String>(activityId),
      'student_id': serializer.toJson<String>(studentId),
      'change': serializer.toJson<String>(change),
      'old_points': serializer.toJson<int?>(oldPoints),
      'new_points': serializer.toJson<int?>(newPoints),
      'max_points': serializer.toJson<int?>(maxPoints),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  ScoreHistoryRow copyWith({
    int? id,
    String? scoreId,
    String? activityId,
    String? studentId,
    String? change,
    Value<int?> oldPoints = const Value.absent(),
    Value<int?> newPoints = const Value.absent(),
    Value<int?> maxPoints = const Value.absent(),
    DateTime? at,
  }) => ScoreHistoryRow(
    id: id ?? this.id,
    scoreId: scoreId ?? this.scoreId,
    activityId: activityId ?? this.activityId,
    studentId: studentId ?? this.studentId,
    change: change ?? this.change,
    oldPoints: oldPoints.present ? oldPoints.value : this.oldPoints,
    newPoints: newPoints.present ? newPoints.value : this.newPoints,
    maxPoints: maxPoints.present ? maxPoints.value : this.maxPoints,
    at: at ?? this.at,
  );
  ScoreHistoryRow copyWithCompanion(ScoreHistoryCompanion data) {
    return ScoreHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      activityId: data.activityId.present ? data.activityId.value : this.activityId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      change: data.change.present ? data.change.value : this.change,
      oldPoints: data.oldPoints.present ? data.oldPoints.value : this.oldPoints,
      newPoints: data.newPoints.present ? data.newPoints.value : this.newPoints,
      maxPoints: data.maxPoints.present ? data.maxPoints.value : this.maxPoints,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoreHistoryRow(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('activityId: $activityId, ')
          ..write('studentId: $studentId, ')
          ..write('change: $change, ')
          ..write('oldPoints: $oldPoints, ')
          ..write('newPoints: $newPoints, ')
          ..write('maxPoints: $maxPoints, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scoreId, activityId, studentId, change, oldPoints, newPoints, maxPoints, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoreHistoryRow &&
          other.id == this.id &&
          other.scoreId == this.scoreId &&
          other.activityId == this.activityId &&
          other.studentId == this.studentId &&
          other.change == this.change &&
          other.oldPoints == this.oldPoints &&
          other.newPoints == this.newPoints &&
          other.maxPoints == this.maxPoints &&
          other.at == this.at);
}

class ScoreHistoryCompanion extends UpdateCompanion<ScoreHistoryRow> {
  final Value<int> id;
  final Value<String> scoreId;
  final Value<String> activityId;
  final Value<String> studentId;
  final Value<String> change;
  final Value<int?> oldPoints;
  final Value<int?> newPoints;
  final Value<int?> maxPoints;
  final Value<DateTime> at;
  const ScoreHistoryCompanion({
    this.id = const Value.absent(),
    this.scoreId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.change = const Value.absent(),
    this.oldPoints = const Value.absent(),
    this.newPoints = const Value.absent(),
    this.maxPoints = const Value.absent(),
    this.at = const Value.absent(),
  });
  ScoreHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String scoreId,
    required String activityId,
    required String studentId,
    required String change,
    this.oldPoints = const Value.absent(),
    this.newPoints = const Value.absent(),
    this.maxPoints = const Value.absent(),
    required DateTime at,
  }) : scoreId = Value(scoreId),
       activityId = Value(activityId),
       studentId = Value(studentId),
       change = Value(change),
       at = Value(at);
  static Insertable<ScoreHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? scoreId,
    Expression<String>? activityId,
    Expression<String>? studentId,
    Expression<String>? change,
    Expression<int>? oldPoints,
    Expression<int>? newPoints,
    Expression<int>? maxPoints,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scoreId != null) 'score_id': scoreId,
      if (activityId != null) 'activity_id': activityId,
      if (studentId != null) 'student_id': studentId,
      if (change != null) 'change': change,
      if (oldPoints != null) 'old_points': oldPoints,
      if (newPoints != null) 'new_points': newPoints,
      if (maxPoints != null) 'max_points': maxPoints,
      if (at != null) 'at': at,
    });
  }

  ScoreHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? scoreId,
    Value<String>? activityId,
    Value<String>? studentId,
    Value<String>? change,
    Value<int?>? oldPoints,
    Value<int?>? newPoints,
    Value<int?>? maxPoints,
    Value<DateTime>? at,
  }) {
    return ScoreHistoryCompanion(
      id: id ?? this.id,
      scoreId: scoreId ?? this.scoreId,
      activityId: activityId ?? this.activityId,
      studentId: studentId ?? this.studentId,
      change: change ?? this.change,
      oldPoints: oldPoints ?? this.oldPoints,
      newPoints: newPoints ?? this.newPoints,
      maxPoints: maxPoints ?? this.maxPoints,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (change.present) {
      map['change'] = Variable<String>(change.value);
    }
    if (oldPoints.present) {
      map['old_points'] = Variable<int>(oldPoints.value);
    }
    if (newPoints.present) {
      map['new_points'] = Variable<int>(newPoints.value);
    }
    if (maxPoints.present) {
      map['max_points'] = Variable<int>(maxPoints.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoreHistoryCompanion(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('activityId: $activityId, ')
          ..write('studentId: $studentId, ')
          ..write('change: $change, ')
          ..write('oldPoints: $oldPoints, ')
          ..write('newPoints: $newPoints, ')
          ..write('maxPoints: $maxPoints, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class CalcHistory extends Table with TableInfo<CalcHistory, CalcHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CalcHistory(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _expressionMeta = const VerificationMeta('expression');
  late final GeneratedColumn<String> expression = GeneratedColumn<String>(
    'expression',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(expression) <= 400)',
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(result) <= 80)',
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, expression, result, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calc_history';
  @override
  VerificationContext validateIntegrity(Insertable<CalcHistoryRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('expression')) {
      context.handle(_expressionMeta, expression.isAcceptableOrUnknown(data['expression']!, _expressionMeta));
    } else if (isInserting) {
      context.missing(_expressionMeta);
    }
    if (data.containsKey('result')) {
      context.handle(_resultMeta, result.isAcceptableOrUnknown(data['result']!, _resultMeta));
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalcHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalcHistoryRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      expression: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}expression'])!,
      result: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}result'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
    );
  }

  @override
  CalcHistory createAlias(String alias) {
    return CalcHistory(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CalcHistoryRow extends DataClass implements Insertable<CalcHistoryRow> {
  final int id;
  final String expression;
  final String result;
  final DateTime at;
  const CalcHistoryRow({required this.id, required this.expression, required this.result, required this.at});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['expression'] = Variable<String>(expression);
    map['result'] = Variable<String>(result);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  CalcHistoryCompanion toCompanion(bool nullToAbsent) {
    return CalcHistoryCompanion(id: Value(id), expression: Value(expression), result: Value(result), at: Value(at));
  }

  factory CalcHistoryRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalcHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      expression: serializer.fromJson<String>(json['expression']),
      result: serializer.fromJson<String>(json['result']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'expression': serializer.toJson<String>(expression),
      'result': serializer.toJson<String>(result),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  CalcHistoryRow copyWith({int? id, String? expression, String? result, DateTime? at}) => CalcHistoryRow(
    id: id ?? this.id,
    expression: expression ?? this.expression,
    result: result ?? this.result,
    at: at ?? this.at,
  );
  CalcHistoryRow copyWithCompanion(CalcHistoryCompanion data) {
    return CalcHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      expression: data.expression.present ? data.expression.value : this.expression,
      result: data.result.present ? data.result.value : this.result,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalcHistoryRow(')
          ..write('id: $id, ')
          ..write('expression: $expression, ')
          ..write('result: $result, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, expression, result, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalcHistoryRow &&
          other.id == this.id &&
          other.expression == this.expression &&
          other.result == this.result &&
          other.at == this.at);
}

class CalcHistoryCompanion extends UpdateCompanion<CalcHistoryRow> {
  final Value<int> id;
  final Value<String> expression;
  final Value<String> result;
  final Value<DateTime> at;
  const CalcHistoryCompanion({
    this.id = const Value.absent(),
    this.expression = const Value.absent(),
    this.result = const Value.absent(),
    this.at = const Value.absent(),
  });
  CalcHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String expression,
    required String result,
    required DateTime at,
  }) : expression = Value(expression),
       result = Value(result),
       at = Value(at);
  static Insertable<CalcHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? expression,
    Expression<String>? result,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expression != null) 'expression': expression,
      if (result != null) 'result': result,
      if (at != null) 'at': at,
    });
  }

  CalcHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? expression,
    Value<String>? result,
    Value<DateTime>? at,
  }) {
    return CalcHistoryCompanion(
      id: id ?? this.id,
      expression: expression ?? this.expression,
      result: result ?? this.result,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (expression.present) {
      map['expression'] = Variable<String>(expression.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalcHistoryCompanion(')
          ..write('id: $id, ')
          ..write('expression: $expression, ')
          ..write('result: $result, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class AppSettings extends Table with TableInfo<AppSettings, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AppSettings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingKeyMeta = const VerificationMeta('settingKey');
  late final GeneratedColumn<String> settingKey = GeneratedColumn<String>(
    'setting_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [settingKey, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setting_key')) {
      context.handle(_settingKeyMeta, settingKey.isAcceptableOrUnknown(data['setting_key']!, _settingKeyMeta));
    } else if (isInserting) {
      context.missing(_settingKeyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingKey};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      settingKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}setting_key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  AppSettings createAlias(String alias) {
    return AppSettings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String settingKey;
  final String value;
  final DateTime updatedAt;
  const SettingRow({required this.settingKey, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setting_key'] = Variable<String>(settingKey);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(settingKey: Value(settingKey), value: Value(value), updatedAt: Value(updatedAt));
  }

  factory SettingRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      settingKey: serializer.fromJson<String>(json['setting_key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setting_key': serializer.toJson<String>(settingKey),
      'value': serializer.toJson<String>(value),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SettingRow copyWith({String? settingKey, String? value, DateTime? updatedAt}) => SettingRow(
    settingKey: settingKey ?? this.settingKey,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SettingRow copyWithCompanion(AppSettingsCompanion data) {
    return SettingRow(
      settingKey: data.settingKey.present ? data.settingKey.value : this.settingKey,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('settingKey: $settingKey, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingKey, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.settingKey == this.settingKey &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> settingKey;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.settingKey = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String settingKey,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : settingKey = Value(settingKey),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<SettingRow> custom({
    Expression<String>? settingKey,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingKey != null) 'setting_key': settingKey,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? settingKey,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      settingKey: settingKey ?? this.settingKey,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingKey.present) {
      map['setting_key'] = Variable<String>(settingKey.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('settingKey: $settingKey, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LicenseCache extends Table with TableInfo<LicenseCache, LicenseCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LicenseCache(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _storedAtMeta = const VerificationMeta('storedAt');
  late final GeneratedColumn<DateTime> storedAt = GeneratedColumn<DateTime>(
    'stored_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, token, storedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'license_cache';
  @override
  VerificationContext validateIntegrity(Insertable<LicenseCacheRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('token')) {
      context.handle(_tokenMeta, token.isAcceptableOrUnknown(data['token']!, _tokenMeta));
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('stored_at')) {
      context.handle(_storedAtMeta, storedAt.isAcceptableOrUnknown(data['stored_at']!, _storedAtMeta));
    } else if (isInserting) {
      context.missing(_storedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LicenseCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LicenseCacheRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      token: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}token'])!,
      storedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}stored_at'])!,
    );
  }

  @override
  LicenseCache createAlias(String alias) {
    return LicenseCache(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class LicenseCacheRow extends DataClass implements Insertable<LicenseCacheRow> {
  final int id;
  final String token;
  final DateTime storedAt;
  const LicenseCacheRow({required this.id, required this.token, required this.storedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['token'] = Variable<String>(token);
    map['stored_at'] = Variable<DateTime>(storedAt);
    return map;
  }

  LicenseCacheCompanion toCompanion(bool nullToAbsent) {
    return LicenseCacheCompanion(id: Value(id), token: Value(token), storedAt: Value(storedAt));
  }

  factory LicenseCacheRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LicenseCacheRow(
      id: serializer.fromJson<int>(json['id']),
      token: serializer.fromJson<String>(json['token']),
      storedAt: serializer.fromJson<DateTime>(json['stored_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'token': serializer.toJson<String>(token),
      'stored_at': serializer.toJson<DateTime>(storedAt),
    };
  }

  LicenseCacheRow copyWith({int? id, String? token, DateTime? storedAt}) =>
      LicenseCacheRow(id: id ?? this.id, token: token ?? this.token, storedAt: storedAt ?? this.storedAt);
  LicenseCacheRow copyWithCompanion(LicenseCacheCompanion data) {
    return LicenseCacheRow(
      id: data.id.present ? data.id.value : this.id,
      token: data.token.present ? data.token.value : this.token,
      storedAt: data.storedAt.present ? data.storedAt.value : this.storedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LicenseCacheRow(')
          ..write('id: $id, ')
          ..write('token: $token, ')
          ..write('storedAt: $storedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, token, storedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LicenseCacheRow && other.id == this.id && other.token == this.token && other.storedAt == this.storedAt);
}

class LicenseCacheCompanion extends UpdateCompanion<LicenseCacheRow> {
  final Value<int> id;
  final Value<String> token;
  final Value<DateTime> storedAt;
  const LicenseCacheCompanion({
    this.id = const Value.absent(),
    this.token = const Value.absent(),
    this.storedAt = const Value.absent(),
  });
  LicenseCacheCompanion.insert({this.id = const Value.absent(), required String token, required DateTime storedAt})
    : token = Value(token),
      storedAt = Value(storedAt);
  static Insertable<LicenseCacheRow> custom({
    Expression<int>? id,
    Expression<String>? token,
    Expression<DateTime>? storedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (token != null) 'token': token,
      if (storedAt != null) 'stored_at': storedAt,
    });
  }

  LicenseCacheCompanion copyWith({Value<int>? id, Value<String>? token, Value<DateTime>? storedAt}) {
    return LicenseCacheCompanion(id: id ?? this.id, token: token ?? this.token, storedAt: storedAt ?? this.storedAt);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (storedAt.present) {
      map['stored_at'] = Variable<DateTime>(storedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LicenseCacheCompanion(')
          ..write('id: $id, ')
          ..write('token: $token, ')
          ..write('storedAt: $storedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final InstructorProfile instructorProfile = InstructorProfile(this);
  late final Sections sections = Sections(this);
  late final Index sectionsNameTerm = Index(
    'sections_name_term',
    'CREATE UNIQUE INDEX sections_name_term ON sections (name COLLATE NOCASE, academic_year, semester)',
  );
  late final Students students = Students(this);
  late final Index studentsNoActive = Index(
    'students_no_active',
    'CREATE UNIQUE INDEX students_no_active ON students (student_no_key) WHERE deleted_at IS NULL AND student_no_key IS NOT NULL',
  );
  late final Index studentsName = Index(
    'students_name',
    'CREATE INDEX students_name ON students (last_name COLLATE NOCASE, first_name COLLATE NOCASE)',
  );
  late final Index studentsSection = Index(
    'students_section',
    'CREATE INDEX students_section ON students (section_id)',
  );
  late final GradeScales gradeScales = GradeScales(this);
  late final GradeScaleRows gradeScaleRows = GradeScaleRows(this);
  late final Subjects subjects = Subjects(this);
  late final Index subjectsCodeTerm = Index(
    'subjects_code_term',
    'CREATE UNIQUE INDEX subjects_code_term ON subjects (code COLLATE NOCASE, academic_year, semester) WHERE deleted_at IS NULL',
  );
  late final SubjectStudents subjectStudents = SubjectStudents(this);
  late final Index subjectStudentsStudent = Index(
    'subject_students_student',
    'CREATE INDEX subject_students_student ON subject_students (student_id)',
  );
  late final Categories categories = Categories(this);
  late final Index categoriesNameActive = Index(
    'categories_name_active',
    'CREATE UNIQUE INDEX categories_name_active ON categories (name COLLATE NOCASE) WHERE deleted_at IS NULL',
  );
  late final SubjectWeights subjectWeights = SubjectWeights(this);
  late final Activities activities = Activities(this);
  late final Index activitiesSubject = Index(
    'activities_subject',
    'CREATE INDEX activities_subject ON activities (subject_id, category_id)',
  );
  late final Index activitiesNumberActive = Index(
    'activities_number_active',
    'CREATE UNIQUE INDEX activities_number_active ON activities (subject_id, category_id, number) WHERE deleted_at IS NULL AND number IS NOT NULL',
  );
  late final Scores scores = Scores(this);
  late final Trigger activitiesMaxPointsGuard = Trigger(
    'CREATE TRIGGER activities_max_points_guard BEFORE UPDATE OF max_points ON activities WHEN NEW.max_points < (SELECT ifnull(max(points), 0) FROM scores WHERE activity_id = NEW.id) BEGIN SELECT RAISE (ABORT, \'ACEKOR: maximum points below a recorded score\');END',
    'activities_max_points_guard',
  );
  late final Index scoresActivityStudent = Index(
    'scores_activity_student',
    'CREATE UNIQUE INDEX scores_activity_student ON scores (activity_id, student_id)',
  );
  late final Index scoresStudent = Index('scores_student', 'CREATE INDEX scores_student ON scores (student_id)');
  late final Trigger scoresMaxInsert = Trigger(
    'CREATE TRIGGER scores_max_insert BEFORE INSERT ON scores WHEN NEW.points > (SELECT max_points FROM activities WHERE id = NEW.activity_id) BEGIN SELECT RAISE (ABORT, \'ACEKOR: score above maximum points\');END',
    'scores_max_insert',
  );
  late final Trigger scoresMaxUpdate = Trigger(
    'CREATE TRIGGER scores_max_update BEFORE UPDATE OF points ON scores WHEN NEW.points > (SELECT max_points FROM activities WHERE id = NEW.activity_id) BEGIN SELECT RAISE (ABORT, \'ACEKOR: score above maximum points\');END',
    'scores_max_update',
  );
  late final ScoreHistory scoreHistory = ScoreHistory(this);
  late final Index scoreHistoryActivity = Index(
    'score_history_activity',
    'CREATE INDEX score_history_activity ON score_history (activity_id, at)',
  );
  late final Index scoreHistoryStudent = Index(
    'score_history_student',
    'CREATE INDEX score_history_student ON score_history (student_id, at)',
  );
  late final Trigger scoresHistoryInsert = Trigger(
    'CREATE TRIGGER scores_history_insert AFTER INSERT ON scores BEGIN INSERT INTO score_history (score_id, activity_id, student_id, change, old_points, new_points, max_points, at) VALUES (NEW.id, NEW.activity_id, NEW.student_id, \'create\', NULL, NEW.points, (SELECT max_points FROM activities WHERE id = NEW.activity_id), NEW.updated_at);END',
    'scores_history_insert',
  );
  late final Trigger scoresHistoryUpdate = Trigger(
    'CREATE TRIGGER scores_history_update AFTER UPDATE OF points ON scores WHEN NEW.points <> OLD.points BEGIN INSERT INTO score_history (score_id, activity_id, student_id, change, old_points, new_points, max_points, at) VALUES (NEW.id, NEW.activity_id, NEW.student_id, \'update\', OLD.points, NEW.points, (SELECT max_points FROM activities WHERE id = NEW.activity_id), NEW.updated_at);END',
    'scores_history_update',
  );
  late final Trigger scoresHistoryDelete = Trigger(
    'CREATE TRIGGER scores_history_delete AFTER DELETE ON scores BEGIN INSERT INTO score_history (score_id, activity_id, student_id, change, old_points, new_points, max_points, at) VALUES (OLD.id, OLD.activity_id, OLD.student_id, \'delete\', OLD.points, NULL, (SELECT max_points FROM activities WHERE id = OLD.activity_id), CAST(strftime(\'%s\', \'now\') AS INTEGER));END',
    'scores_history_delete',
  );
  late final CalcHistory calcHistory = CalcHistory(this);
  late final AppSettings appSettings = AppSettings(this);
  late final LicenseCache licenseCache = LicenseCache(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    instructorProfile,
    sections,
    sectionsNameTerm,
    students,
    studentsNoActive,
    studentsName,
    studentsSection,
    gradeScales,
    gradeScaleRows,
    subjects,
    subjectsCodeTerm,
    subjectStudents,
    subjectStudentsStudent,
    categories,
    categoriesNameActive,
    subjectWeights,
    activities,
    activitiesSubject,
    activitiesNumberActive,
    scores,
    activitiesMaxPointsGuard,
    scoresActivityStudent,
    scoresStudent,
    scoresMaxInsert,
    scoresMaxUpdate,
    scoreHistory,
    scoreHistoryActivity,
    scoreHistoryStudent,
    scoresHistoryInsert,
    scoresHistoryUpdate,
    scoresHistoryDelete,
    calcHistory,
    appSettings,
    licenseCache,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('sections', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('students', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('grade_scales', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('grade_scale_rows', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('grade_scales', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('subjects', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('subjects', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('subject_students', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('students', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('subject_students', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('subjects', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('subject_weights', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('categories', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('subject_weights', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('subjects', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('activities', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('activities', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('scores', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('students', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('scores', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('activities', limitUpdateKind: UpdateKind.update),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('scores', limitUpdateKind: UpdateKind.insert),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('scores', limitUpdateKind: UpdateKind.update),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('scores', limitUpdateKind: UpdateKind.insert),
      result: [TableUpdate('score_history', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('scores', limitUpdateKind: UpdateKind.update),
      result: [TableUpdate('score_history', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('scores', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('score_history', kind: UpdateKind.insert)],
    ),
  ]);
}
