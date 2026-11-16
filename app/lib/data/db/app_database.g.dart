// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class InstructorProfiles extends Table
    with TableInfo<InstructorProfiles, InstructorProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  InstructorProfiles(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(full_name)) BETWEEN 1 AND 120)',
  );
  static const VerificationMeta _honorificMeta = const VerificationMeta(
    'honorific',
  );
  late final GeneratedColumn<String> honorific = GeneratedColumn<String>(
    'honorific',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (honorific IS NULL OR length(honorific) <= 20)',
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (email IS NULL OR length(email) <= 254)',
  );
  static const VerificationMeta _employeeNoMeta = const VerificationMeta(
    'employeeNo',
  );
  late final GeneratedColumn<String> employeeNo = GeneratedColumn<String>(
    'employee_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (employee_no IS NULL OR length(employee_no) <= 40)',
  );
  static const VerificationMeta _schoolNameMeta = const VerificationMeta(
    'schoolName',
  );
  late final GeneratedColumn<String> schoolName = GeneratedColumn<String>(
    'school_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (school_name IS NULL OR length(school_name) <= 160)',
  );
  static const VerificationMeta _schoolAddressMeta = const VerificationMeta(
    'schoolAddress',
  );
  late final GeneratedColumn<String> schoolAddress = GeneratedColumn<String>(
    'school_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (school_address IS NULL OR length(school_address) <= 240)',
  );
  static const VerificationMeta _departmentMeta = const VerificationMeta(
    'department',
  );
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
    'department',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (department IS NULL OR length(department) <= 160)',
  );
  static const VerificationMeta _logoPathMeta = const VerificationMeta(
    'logoPath',
  );
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
    'logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
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
    fullName,
    honorific,
    email,
    employeeNo,
    schoolName,
    schoolAddress,
    department,
    logoPath,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instructor_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstructorProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('honorific')) {
      context.handle(
        _honorificMeta,
        honorific.isAcceptableOrUnknown(data['honorific']!, _honorificMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('employee_no')) {
      context.handle(
        _employeeNoMeta,
        employeeNo.isAcceptableOrUnknown(data['employee_no']!, _employeeNoMeta),
      );
    }
    if (data.containsKey('school_name')) {
      context.handle(
        _schoolNameMeta,
        schoolName.isAcceptableOrUnknown(data['school_name']!, _schoolNameMeta),
      );
    }
    if (data.containsKey('school_address')) {
      context.handle(
        _schoolAddressMeta,
        schoolAddress.isAcceptableOrUnknown(
          data['school_address']!,
          _schoolAddressMeta,
        ),
      );
    }
    if (data.containsKey('department')) {
      context.handle(
        _departmentMeta,
        department.isAcceptableOrUnknown(data['department']!, _departmentMeta),
      );
    }
    if (data.containsKey('logo_path')) {
      context.handle(
        _logoPathMeta,
        logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstructorProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstructorProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      honorific: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}honorific'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      employeeNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_no'],
      ),
      schoolName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school_name'],
      ),
      schoolAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school_address'],
      ),
      department: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department'],
      ),
      logoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  InstructorProfiles createAlias(String alias) {
    return InstructorProfiles(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class InstructorProfileRow extends DataClass
    implements Insertable<InstructorProfileRow> {
  final String id;
  final String fullName;
  final String? honorific;
  final String? email;
  final String? employeeNo;
  final String? schoolName;
  final String? schoolAddress;
  final String? department;
  final String? logoPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const InstructorProfileRow({
    required this.id,
    required this.fullName,
    this.honorific,
    this.email,
    this.employeeNo,
    this.schoolName,
    this.schoolAddress,
    this.department,
    this.logoPath,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || honorific != null) {
      map['honorific'] = Variable<String>(honorific);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || employeeNo != null) {
      map['employee_no'] = Variable<String>(employeeNo);
    }
    if (!nullToAbsent || schoolName != null) {
      map['school_name'] = Variable<String>(schoolName);
    }
    if (!nullToAbsent || schoolAddress != null) {
      map['school_address'] = Variable<String>(schoolAddress);
    }
    if (!nullToAbsent || department != null) {
      map['department'] = Variable<String>(department);
    }
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  InstructorProfilesCompanion toCompanion(bool nullToAbsent) {
    return InstructorProfilesCompanion(
      id: Value(id),
      fullName: Value(fullName),
      honorific: honorific == null && nullToAbsent
          ? const Value.absent()
          : Value(honorific),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      employeeNo: employeeNo == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeNo),
      schoolName: schoolName == null && nullToAbsent
          ? const Value.absent()
          : Value(schoolName),
      schoolAddress: schoolAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(schoolAddress),
      department: department == null && nullToAbsent
          ? const Value.absent()
          : Value(department),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory InstructorProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstructorProfileRow(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['full_name']),
      honorific: serializer.fromJson<String?>(json['honorific']),
      email: serializer.fromJson<String?>(json['email']),
      employeeNo: serializer.fromJson<String?>(json['employee_no']),
      schoolName: serializer.fromJson<String?>(json['school_name']),
      schoolAddress: serializer.fromJson<String?>(json['school_address']),
      department: serializer.fromJson<String?>(json['department']),
      logoPath: serializer.fromJson<String?>(json['logo_path']),
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
      'full_name': serializer.toJson<String>(fullName),
      'honorific': serializer.toJson<String?>(honorific),
      'email': serializer.toJson<String?>(email),
      'employee_no': serializer.toJson<String?>(employeeNo),
      'school_name': serializer.toJson<String?>(schoolName),
      'school_address': serializer.toJson<String?>(schoolAddress),
      'department': serializer.toJson<String?>(department),
      'logo_path': serializer.toJson<String?>(logoPath),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'deleted_at': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  InstructorProfileRow copyWith({
    String? id,
    String? fullName,
    Value<String?> honorific = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> employeeNo = const Value.absent(),
    Value<String?> schoolName = const Value.absent(),
    Value<String?> schoolAddress = const Value.absent(),
    Value<String?> department = const Value.absent(),
    Value<String?> logoPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => InstructorProfileRow(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    honorific: honorific.present ? honorific.value : this.honorific,
    email: email.present ? email.value : this.email,
    employeeNo: employeeNo.present ? employeeNo.value : this.employeeNo,
    schoolName: schoolName.present ? schoolName.value : this.schoolName,
    schoolAddress: schoolAddress.present
        ? schoolAddress.value
        : this.schoolAddress,
    department: department.present ? department.value : this.department,
    logoPath: logoPath.present ? logoPath.value : this.logoPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  InstructorProfileRow copyWithCompanion(InstructorProfilesCompanion data) {
    return InstructorProfileRow(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      honorific: data.honorific.present ? data.honorific.value : this.honorific,
      email: data.email.present ? data.email.value : this.email,
      employeeNo: data.employeeNo.present
          ? data.employeeNo.value
          : this.employeeNo,
      schoolName: data.schoolName.present
          ? data.schoolName.value
          : this.schoolName,
      schoolAddress: data.schoolAddress.present
          ? data.schoolAddress.value
          : this.schoolAddress,
      department: data.department.present
          ? data.department.value
          : this.department,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstructorProfileRow(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('honorific: $honorific, ')
          ..write('email: $email, ')
          ..write('employeeNo: $employeeNo, ')
          ..write('schoolName: $schoolName, ')
          ..write('schoolAddress: $schoolAddress, ')
          ..write('department: $department, ')
          ..write('logoPath: $logoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fullName,
    honorific,
    email,
    employeeNo,
    schoolName,
    schoolAddress,
    department,
    logoPath,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstructorProfileRow &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.honorific == this.honorific &&
          other.email == this.email &&
          other.employeeNo == this.employeeNo &&
          other.schoolName == this.schoolName &&
          other.schoolAddress == this.schoolAddress &&
          other.department == this.department &&
          other.logoPath == this.logoPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class InstructorProfilesCompanion
    extends UpdateCompanion<InstructorProfileRow> {
  final Value<String> id;
  final Value<String> fullName;
  final Value<String?> honorific;
  final Value<String?> email;
  final Value<String?> employeeNo;
  final Value<String?> schoolName;
  final Value<String?> schoolAddress;
  final Value<String?> department;
  final Value<String?> logoPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const InstructorProfilesCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.honorific = const Value.absent(),
    this.email = const Value.absent(),
    this.employeeNo = const Value.absent(),
    this.schoolName = const Value.absent(),
    this.schoolAddress = const Value.absent(),
    this.department = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstructorProfilesCompanion.insert({
    required String id,
    required String fullName,
    this.honorific = const Value.absent(),
    this.email = const Value.absent(),
    this.employeeNo = const Value.absent(),
    this.schoolName = const Value.absent(),
    this.schoolAddress = const Value.absent(),
    this.department = const Value.absent(),
    this.logoPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fullName = Value(fullName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InstructorProfileRow> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? honorific,
    Expression<String>? email,
    Expression<String>? employeeNo,
    Expression<String>? schoolName,
    Expression<String>? schoolAddress,
    Expression<String>? department,
    Expression<String>? logoPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (honorific != null) 'honorific': honorific,
      if (email != null) 'email': email,
      if (employeeNo != null) 'employee_no': employeeNo,
      if (schoolName != null) 'school_name': schoolName,
      if (schoolAddress != null) 'school_address': schoolAddress,
      if (department != null) 'department': department,
      if (logoPath != null) 'logo_path': logoPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstructorProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? fullName,
    Value<String?>? honorific,
    Value<String?>? email,
    Value<String?>? employeeNo,
    Value<String?>? schoolName,
    Value<String?>? schoolAddress,
    Value<String?>? department,
    Value<String?>? logoPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return InstructorProfilesCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      honorific: honorific ?? this.honorific,
      email: email ?? this.email,
      employeeNo: employeeNo ?? this.employeeNo,
      schoolName: schoolName ?? this.schoolName,
      schoolAddress: schoolAddress ?? this.schoolAddress,
      department: department ?? this.department,
      logoPath: logoPath ?? this.logoPath,
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
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (honorific.present) {
      map['honorific'] = Variable<String>(honorific.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (employeeNo.present) {
      map['employee_no'] = Variable<String>(employeeNo.value);
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
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
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
    return (StringBuffer('InstructorProfilesCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('honorific: $honorific, ')
          ..write('email: $email, ')
          ..write('employeeNo: $employeeNo, ')
          ..write('schoolName: $schoolName, ')
          ..write('schoolAddress: $schoolAddress, ')
          ..write('department: $department, ')
          ..write('logoPath: $logoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
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
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 160)',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (description IS NULL OR length(description) <= 1000)',
  );
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  late final GeneratedColumn<double> units = GeneratedColumn<double>(
    'units',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (units IS NULL OR units BETWEEN 0 AND 12)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
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
    description,
    units,
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
  VerificationContext validateIntegrity(
    Insertable<SubjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('units')) {
      context.handle(
        _unitsMeta,
        units.isAcceptableOrUnknown(data['units']!, _unitsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      units: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}units'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
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
  final String? description;
  final double? units;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const SubjectRow({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    this.units,
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
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || units != null) {
      map['units'] = Variable<double>(units);
    }
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
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      units: units == null && nullToAbsent
          ? const Value.absent()
          : Value(units),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SubjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      units: serializer.fromJson<double?>(json['units']),
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
      'description': serializer.toJson<String?>(description),
      'units': serializer.toJson<double?>(units),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'deleted_at': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SubjectRow copyWith({
    String? id,
    String? code,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<double?> units = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SubjectRow(
    id: id ?? this.id,
    code: code ?? this.code,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    units: units.present ? units.value : this.units,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SubjectRow copyWithCompanion(SubjectsCompanion data) {
    return SubjectRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      units: data.units.present ? data.units.value : this.units,
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
          ..write('description: $description, ')
          ..write('units: $units, ')
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
    description,
    units,
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
          other.description == this.description &&
          other.units == this.units &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SubjectsCompanion extends UpdateCompanion<SubjectRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> title;
  final Value<String?> description;
  final Value<double?> units;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.units = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String id,
    required String code,
    required String title,
    this.description = const Value.absent(),
    this.units = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SubjectRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? title,
    Expression<String>? description,
    Expression<double>? units,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (units != null) 'units': units,
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
    Value<String?>? description,
    Value<double?>? units,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SubjectsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      units: units ?? this.units,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (units.present) {
      map['units'] = Variable<double>(units.value);
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
          ..write('description: $description, ')
          ..write('units: $units, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Courses extends Table with TableInfo<Courses, CourseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Courses(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 160)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
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
    name,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Courses createAlias(String alias) {
    return Courses(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CourseRow extends DataClass implements Insertable<CourseRow> {
  final String id;
  final String code;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const CourseRow({
    required this.id,
    required this.code,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CourseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
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
      'name': serializer.toJson<String>(name),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'deleted_at': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CourseRow copyWith({
    String? id,
    String? code,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => CourseRow(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CourseRow copyWithCompanion(CoursesCompanion data) {
    return CourseRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, name, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CoursesCompanion extends UpdateCompanion<CourseRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoursesCompanion.insert({
    required String id,
    required String code,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CourseRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoursesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
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
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
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
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES courses(id)',
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
  static const VerificationMeta _yearLevelMeta = const VerificationMeta(
    'yearLevel',
  );
  late final GeneratedColumn<int> yearLevel = GeneratedColumn<int>(
    'year_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (year_level IS NULL OR year_level BETWEEN 1 AND 6)',
  );
  static const VerificationMeta _schoolYearMeta = const VerificationMeta(
    'schoolYear',
  );
  late final GeneratedColumn<String> schoolYear = GeneratedColumn<String>(
    'school_year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (school_year IS NULL OR length(school_year) <= 20)',
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (term IS NULL OR length(term) <= 40)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
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
    courseId,
    name,
    yearLevel,
    schoolYear,
    term,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sections';
  @override
  VerificationContext validateIntegrity(
    Insertable<SectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('year_level')) {
      context.handle(
        _yearLevelMeta,
        yearLevel.isAcceptableOrUnknown(data['year_level']!, _yearLevelMeta),
      );
    }
    if (data.containsKey('school_year')) {
      context.handle(
        _schoolYearMeta,
        schoolYear.isAcceptableOrUnknown(data['school_year']!, _schoolYearMeta),
      );
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      yearLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year_level'],
      ),
      schoolYear: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school_year'],
      ),
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
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
  final String? courseId;
  final String name;
  final int? yearLevel;
  final String? schoolYear;
  final String? term;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const SectionRow({
    required this.id,
    this.courseId,
    required this.name,
    this.yearLevel,
    this.schoolYear,
    this.term,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || courseId != null) {
      map['course_id'] = Variable<String>(courseId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || yearLevel != null) {
      map['year_level'] = Variable<int>(yearLevel);
    }
    if (!nullToAbsent || schoolYear != null) {
      map['school_year'] = Variable<String>(schoolYear);
    }
    if (!nullToAbsent || term != null) {
      map['term'] = Variable<String>(term);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SectionsCompanion toCompanion(bool nullToAbsent) {
    return SectionsCompanion(
      id: Value(id),
      courseId: courseId == null && nullToAbsent
          ? const Value.absent()
          : Value(courseId),
      name: Value(name),
      yearLevel: yearLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(yearLevel),
      schoolYear: schoolYear == null && nullToAbsent
          ? const Value.absent()
          : Value(schoolYear),
      term: term == null && nullToAbsent ? const Value.absent() : Value(term),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectionRow(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String?>(json['course_id']),
      name: serializer.fromJson<String>(json['name']),
      yearLevel: serializer.fromJson<int?>(json['year_level']),
      schoolYear: serializer.fromJson<String?>(json['school_year']),
      term: serializer.fromJson<String?>(json['term']),
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
      'course_id': serializer.toJson<String?>(courseId),
      'name': serializer.toJson<String>(name),
      'year_level': serializer.toJson<int?>(yearLevel),
      'school_year': serializer.toJson<String?>(schoolYear),
      'term': serializer.toJson<String?>(term),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'deleted_at': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SectionRow copyWith({
    String? id,
    Value<String?> courseId = const Value.absent(),
    String? name,
    Value<int?> yearLevel = const Value.absent(),
    Value<String?> schoolYear = const Value.absent(),
    Value<String?> term = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SectionRow(
    id: id ?? this.id,
    courseId: courseId.present ? courseId.value : this.courseId,
    name: name ?? this.name,
    yearLevel: yearLevel.present ? yearLevel.value : this.yearLevel,
    schoolYear: schoolYear.present ? schoolYear.value : this.schoolYear,
    term: term.present ? term.value : this.term,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SectionRow copyWithCompanion(SectionsCompanion data) {
    return SectionRow(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      name: data.name.present ? data.name.value : this.name,
      yearLevel: data.yearLevel.present ? data.yearLevel.value : this.yearLevel,
      schoolYear: data.schoolYear.present
          ? data.schoolYear.value
          : this.schoolYear,
      term: data.term.present ? data.term.value : this.term,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectionRow(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('name: $name, ')
          ..write('yearLevel: $yearLevel, ')
          ..write('schoolYear: $schoolYear, ')
          ..write('term: $term, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    name,
    yearLevel,
    schoolYear,
    term,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectionRow &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.name == this.name &&
          other.yearLevel == this.yearLevel &&
          other.schoolYear == this.schoolYear &&
          other.term == this.term &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SectionsCompanion extends UpdateCompanion<SectionRow> {
  final Value<String> id;
  final Value<String?> courseId;
  final Value<String> name;
  final Value<int?> yearLevel;
  final Value<String?> schoolYear;
  final Value<String?> term;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SectionsCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.name = const Value.absent(),
    this.yearLevel = const Value.absent(),
    this.schoolYear = const Value.absent(),
    this.term = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SectionsCompanion.insert({
    required String id,
    this.courseId = const Value.absent(),
    required String name,
    this.yearLevel = const Value.absent(),
    this.schoolYear = const Value.absent(),
    this.term = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SectionRow> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<String>? name,
    Expression<int>? yearLevel,
    Expression<String>? schoolYear,
    Expression<String>? term,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (name != null) 'name': name,
      if (yearLevel != null) 'year_level': yearLevel,
      if (schoolYear != null) 'school_year': schoolYear,
      if (term != null) 'term': term,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SectionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? courseId,
    Value<String>? name,
    Value<int?>? yearLevel,
    Value<String?>? schoolYear,
    Value<String?>? term,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SectionsCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      yearLevel: yearLevel ?? this.yearLevel,
      schoolYear: schoolYear ?? this.schoolYear,
      term: term ?? this.term,
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
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (yearLevel.present) {
      map['year_level'] = Variable<int>(yearLevel.value);
    }
    if (schoolYear.present) {
      map['school_year'] = Variable<String>(schoolYear.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
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
    return (StringBuffer('SectionsCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('name: $name, ')
          ..write('yearLevel: $yearLevel, ')
          ..write('schoolYear: $schoolYear, ')
          ..write('term: $term, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
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
  static const VerificationMeta _studentNoMeta = const VerificationMeta(
    'studentNo',
  );
  late final GeneratedColumn<String> studentNo = GeneratedColumn<String>(
    'student_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(student_no)) BETWEEN 1 AND 30)',
  );
  static const VerificationMeta _studentNoKeyMeta = const VerificationMeta(
    'studentNoKey',
  );
  late final GeneratedColumn<String> studentNoKey = GeneratedColumn<String>(
    'student_no_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(student_no_key) BETWEEN 1 AND 30)',
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(last_name)) BETWEEN 1 AND 80)',
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(first_name)) BETWEEN 1 AND 80)',
  );
  static const VerificationMeta _middleNameMeta = const VerificationMeta(
    'middleName',
  );
  late final GeneratedColumn<String> middleName = GeneratedColumn<String>(
    'middle_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (middle_name IS NULL OR length(middle_name) <= 80)',
  );
  static const VerificationMeta _suffixMeta = const VerificationMeta('suffix');
  late final GeneratedColumn<String> suffix = GeneratedColumn<String>(
    'suffix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (suffix IS NULL OR length(suffix) <= 10)',
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (email IS NULL OR length(email) <= 254)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
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
    lastName,
    firstName,
    middleName,
    suffix,
    email,
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
  VerificationContext validateIntegrity(
    Insertable<StudentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('student_no')) {
      context.handle(
        _studentNoMeta,
        studentNo.isAcceptableOrUnknown(data['student_no']!, _studentNoMeta),
      );
    } else if (isInserting) {
      context.missing(_studentNoMeta);
    }
    if (data.containsKey('student_no_key')) {
      context.handle(
        _studentNoKeyMeta,
        studentNoKey.isAcceptableOrUnknown(
          data['student_no_key']!,
          _studentNoKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentNoKeyMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('middle_name')) {
      context.handle(
        _middleNameMeta,
        middleName.isAcceptableOrUnknown(data['middle_name']!, _middleNameMeta),
      );
    }
    if (data.containsKey('suffix')) {
      context.handle(
        _suffixMeta,
        suffix.isAcceptableOrUnknown(data['suffix']!, _suffixMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      studentNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_no'],
      )!,
      studentNoKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_no_key'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      middleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}middle_name'],
      ),
      suffix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suffix'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
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

  /// Official number exactly as the school writes it, e.g. "2021-00123".
  final String studentNo;

  /// Normalized for matching: upper-case letters and digits only, e.g. "202100123".
  /// The shaded grid on the answer sheet is matched against this value.
  final String studentNoKey;
  final String lastName;
  final String firstName;
  final String? middleName;
  final String? suffix;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const StudentRow({
    required this.id,
    required this.studentNo,
    required this.studentNoKey,
    required this.lastName,
    required this.firstName,
    this.middleName,
    this.suffix,
    this.email,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['student_no'] = Variable<String>(studentNo);
    map['student_no_key'] = Variable<String>(studentNoKey);
    map['last_name'] = Variable<String>(lastName);
    map['first_name'] = Variable<String>(firstName);
    if (!nullToAbsent || middleName != null) {
      map['middle_name'] = Variable<String>(middleName);
    }
    if (!nullToAbsent || suffix != null) {
      map['suffix'] = Variable<String>(suffix);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
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
      studentNo: Value(studentNo),
      studentNoKey: Value(studentNoKey),
      lastName: Value(lastName),
      firstName: Value(firstName),
      middleName: middleName == null && nullToAbsent
          ? const Value.absent()
          : Value(middleName),
      suffix: suffix == null && nullToAbsent
          ? const Value.absent()
          : Value(suffix),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory StudentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentRow(
      id: serializer.fromJson<String>(json['id']),
      studentNo: serializer.fromJson<String>(json['student_no']),
      studentNoKey: serializer.fromJson<String>(json['student_no_key']),
      lastName: serializer.fromJson<String>(json['last_name']),
      firstName: serializer.fromJson<String>(json['first_name']),
      middleName: serializer.fromJson<String?>(json['middle_name']),
      suffix: serializer.fromJson<String?>(json['suffix']),
      email: serializer.fromJson<String?>(json['email']),
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
      'student_no': serializer.toJson<String>(studentNo),
      'student_no_key': serializer.toJson<String>(studentNoKey),
      'last_name': serializer.toJson<String>(lastName),
      'first_name': serializer.toJson<String>(firstName),
      'middle_name': serializer.toJson<String?>(middleName),
      'suffix': serializer.toJson<String?>(suffix),
      'email': serializer.toJson<String?>(email),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'deleted_at': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  StudentRow copyWith({
    String? id,
    String? studentNo,
    String? studentNoKey,
    String? lastName,
    String? firstName,
    Value<String?> middleName = const Value.absent(),
    Value<String?> suffix = const Value.absent(),
    Value<String?> email = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => StudentRow(
    id: id ?? this.id,
    studentNo: studentNo ?? this.studentNo,
    studentNoKey: studentNoKey ?? this.studentNoKey,
    lastName: lastName ?? this.lastName,
    firstName: firstName ?? this.firstName,
    middleName: middleName.present ? middleName.value : this.middleName,
    suffix: suffix.present ? suffix.value : this.suffix,
    email: email.present ? email.value : this.email,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  StudentRow copyWithCompanion(StudentsCompanion data) {
    return StudentRow(
      id: data.id.present ? data.id.value : this.id,
      studentNo: data.studentNo.present ? data.studentNo.value : this.studentNo,
      studentNoKey: data.studentNoKey.present
          ? data.studentNoKey.value
          : this.studentNoKey,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      middleName: data.middleName.present
          ? data.middleName.value
          : this.middleName,
      suffix: data.suffix.present ? data.suffix.value : this.suffix,
      email: data.email.present ? data.email.value : this.email,
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
          ..write('lastName: $lastName, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('suffix: $suffix, ')
          ..write('email: $email, ')
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
    lastName,
    firstName,
    middleName,
    suffix,
    email,
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
          other.lastName == this.lastName &&
          other.firstName == this.firstName &&
          other.middleName == this.middleName &&
          other.suffix == this.suffix &&
          other.email == this.email &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class StudentsCompanion extends UpdateCompanion<StudentRow> {
  final Value<String> id;
  final Value<String> studentNo;
  final Value<String> studentNoKey;
  final Value<String> lastName;
  final Value<String> firstName;
  final Value<String?> middleName;
  final Value<String?> suffix;
  final Value<String?> email;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const StudentsCompanion({
    this.id = const Value.absent(),
    this.studentNo = const Value.absent(),
    this.studentNoKey = const Value.absent(),
    this.lastName = const Value.absent(),
    this.firstName = const Value.absent(),
    this.middleName = const Value.absent(),
    this.suffix = const Value.absent(),
    this.email = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentsCompanion.insert({
    required String id,
    required String studentNo,
    required String studentNoKey,
    required String lastName,
    required String firstName,
    this.middleName = const Value.absent(),
    this.suffix = const Value.absent(),
    this.email = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       studentNo = Value(studentNo),
       studentNoKey = Value(studentNoKey),
       lastName = Value(lastName),
       firstName = Value(firstName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StudentRow> custom({
    Expression<String>? id,
    Expression<String>? studentNo,
    Expression<String>? studentNoKey,
    Expression<String>? lastName,
    Expression<String>? firstName,
    Expression<String>? middleName,
    Expression<String>? suffix,
    Expression<String>? email,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentNo != null) 'student_no': studentNo,
      if (studentNoKey != null) 'student_no_key': studentNoKey,
      if (lastName != null) 'last_name': lastName,
      if (firstName != null) 'first_name': firstName,
      if (middleName != null) 'middle_name': middleName,
      if (suffix != null) 'suffix': suffix,
      if (email != null) 'email': email,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentsCompanion copyWith({
    Value<String>? id,
    Value<String>? studentNo,
    Value<String>? studentNoKey,
    Value<String>? lastName,
    Value<String>? firstName,
    Value<String?>? middleName,
    Value<String?>? suffix,
    Value<String?>? email,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return StudentsCompanion(
      id: id ?? this.id,
      studentNo: studentNo ?? this.studentNo,
      studentNoKey: studentNoKey ?? this.studentNoKey,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      suffix: suffix ?? this.suffix,
      email: email ?? this.email,
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
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (middleName.present) {
      map['middle_name'] = Variable<String>(middleName.value);
    }
    if (suffix.present) {
      map['suffix'] = Variable<String>(suffix.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
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
          ..write('lastName: $lastName, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('suffix: $suffix, ')
          ..write('email: $email, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SectionStudents extends Table
    with TableInfo<SectionStudents, SectionStudentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SectionStudents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sectionIdMeta = const VerificationMeta(
    'sectionId',
  );
  late final GeneratedColumn<String> sectionId = GeneratedColumn<String>(
    'section_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES sections(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES students(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _enrolledAtMeta = const VerificationMeta(
    'enrolledAt',
  );
  late final GeneratedColumn<DateTime> enrolledAt = GeneratedColumn<DateTime>(
    'enrolled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [sectionId, studentId, enrolledAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'section_students';
  @override
  VerificationContext validateIntegrity(
    Insertable<SectionStudentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('section_id')) {
      context.handle(
        _sectionIdMeta,
        sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('enrolled_at')) {
      context.handle(
        _enrolledAtMeta,
        enrolledAt.isAcceptableOrUnknown(data['enrolled_at']!, _enrolledAtMeta),
      );
    } else if (isInserting) {
      context.missing(_enrolledAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sectionId, studentId};
  @override
  SectionStudentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectionStudentRow(
      sectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      enrolledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}enrolled_at'],
      )!,
    );
  }

  @override
  SectionStudents createAlias(String alias) {
    return SectionStudents(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(section_id, student_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SectionStudentRow extends DataClass
    implements Insertable<SectionStudentRow> {
  final String sectionId;
  final String studentId;
  final DateTime enrolledAt;
  const SectionStudentRow({
    required this.sectionId,
    required this.studentId,
    required this.enrolledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['section_id'] = Variable<String>(sectionId);
    map['student_id'] = Variable<String>(studentId);
    map['enrolled_at'] = Variable<DateTime>(enrolledAt);
    return map;
  }

  SectionStudentsCompanion toCompanion(bool nullToAbsent) {
    return SectionStudentsCompanion(
      sectionId: Value(sectionId),
      studentId: Value(studentId),
      enrolledAt: Value(enrolledAt),
    );
  }

  factory SectionStudentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectionStudentRow(
      sectionId: serializer.fromJson<String>(json['section_id']),
      studentId: serializer.fromJson<String>(json['student_id']),
      enrolledAt: serializer.fromJson<DateTime>(json['enrolled_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'section_id': serializer.toJson<String>(sectionId),
      'student_id': serializer.toJson<String>(studentId),
      'enrolled_at': serializer.toJson<DateTime>(enrolledAt),
    };
  }

  SectionStudentRow copyWith({
    String? sectionId,
    String? studentId,
    DateTime? enrolledAt,
  }) => SectionStudentRow(
    sectionId: sectionId ?? this.sectionId,
    studentId: studentId ?? this.studentId,
    enrolledAt: enrolledAt ?? this.enrolledAt,
  );
  SectionStudentRow copyWithCompanion(SectionStudentsCompanion data) {
    return SectionStudentRow(
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      enrolledAt: data.enrolledAt.present
          ? data.enrolledAt.value
          : this.enrolledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectionStudentRow(')
          ..write('sectionId: $sectionId, ')
          ..write('studentId: $studentId, ')
          ..write('enrolledAt: $enrolledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sectionId, studentId, enrolledAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectionStudentRow &&
          other.sectionId == this.sectionId &&
          other.studentId == this.studentId &&
          other.enrolledAt == this.enrolledAt);
}

class SectionStudentsCompanion extends UpdateCompanion<SectionStudentRow> {
  final Value<String> sectionId;
  final Value<String> studentId;
  final Value<DateTime> enrolledAt;
  final Value<int> rowid;
  const SectionStudentsCompanion({
    this.sectionId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.enrolledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SectionStudentsCompanion.insert({
    required String sectionId,
    required String studentId,
    required DateTime enrolledAt,
    this.rowid = const Value.absent(),
  }) : sectionId = Value(sectionId),
       studentId = Value(studentId),
       enrolledAt = Value(enrolledAt);
  static Insertable<SectionStudentRow> custom({
    Expression<String>? sectionId,
    Expression<String>? studentId,
    Expression<DateTime>? enrolledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sectionId != null) 'section_id': sectionId,
      if (studentId != null) 'student_id': studentId,
      if (enrolledAt != null) 'enrolled_at': enrolledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SectionStudentsCompanion copyWith({
    Value<String>? sectionId,
    Value<String>? studentId,
    Value<DateTime>? enrolledAt,
    Value<int>? rowid,
  }) {
    return SectionStudentsCompanion(
      sectionId: sectionId ?? this.sectionId,
      studentId: studentId ?? this.studentId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sectionId.present) {
      map['section_id'] = Variable<String>(sectionId.value);
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
    return (StringBuffer('SectionStudentsCompanion(')
          ..write('sectionId: $sectionId, ')
          ..write('studentId: $studentId, ')
          ..write('enrolledAt: $enrolledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Examinations extends Table with TableInfo<Examinations, ExaminationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Examinations(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _shortCodeMeta = const VerificationMeta(
    'shortCode',
  );
  late final GeneratedColumn<String> shortCode = GeneratedColumn<String>(
    'short_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE CHECK (length(short_code) = 8)',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 160)',
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES subjects(id)',
  );
  static const VerificationMeta _instructorIdMeta = const VerificationMeta(
    'instructorId',
  );
  late final GeneratedColumn<String> instructorId = GeneratedColumn<String>(
    'instructor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES instructor_profiles(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _examDateMeta = const VerificationMeta(
    'examDate',
  );
  late final GeneratedColumn<DateTime> examDate = GeneratedColumn<DateTime>(
    'exam_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (item_count IN (50, 75, 100))',
  );
  static const VerificationMeta _choiceCountMeta = const VerificationMeta(
    'choiceCount',
  );
  late final GeneratedColumn<int> choiceCount = GeneratedColumn<int>(
    'choice_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 5 CHECK (choice_count BETWEEN 2 AND 5)',
    defaultValue: const CustomExpression('5'),
  );
  static const VerificationMeta _passingPercentageMeta = const VerificationMeta(
    'passingPercentage',
  );
  late final GeneratedColumn<double> passingPercentage =
      GeneratedColumn<double>(
        'passing_percentage',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        $customConstraints:
            'NOT NULL DEFAULT 75 CHECK (passing_percentage BETWEEN 0 AND 100)',
        defaultValue: const CustomExpression('75'),
      );
  static const VerificationMeta _multipleMarkPolicyMeta =
      const VerificationMeta('multipleMarkPolicy');
  late final GeneratedColumn<String> multipleMarkPolicy =
      GeneratedColumn<String>(
        'multiple_mark_policy',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT \'incorrect\' CHECK (multiple_mark_policy IN (\'incorrect\', \'zero\'))',
        defaultValue: const CustomExpression('\'incorrect\''),
      );
  static const VerificationMeta _allowNegativeTotalMeta =
      const VerificationMeta('allowNegativeTotal');
  late final GeneratedColumn<bool> allowNegativeTotal = GeneratedColumn<bool>(
    'allow_negative_total',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _omrPresetMeta = const VerificationMeta(
    'omrPreset',
  );
  late final GeneratedColumn<String> omrPreset = GeneratedColumn<String>(
    'omr_preset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'standard\' CHECK (omr_preset IN (\'lenient\', \'standard\', \'strict\', \'custom\'))',
    defaultValue: const CustomExpression('\'standard\''),
  );
  static const VerificationMeta _omrThresholdsMeta = const VerificationMeta(
    'omrThresholds',
  );
  late final GeneratedColumn<String> omrThresholds = GeneratedColumn<String>(
    'omr_thresholds',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _studentIdDigitsMeta = const VerificationMeta(
    'studentIdDigits',
  );
  late final GeneratedColumn<int> studentIdDigits = GeneratedColumn<int>(
    'student_id_digits',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 10 CHECK (student_id_digits BETWEEN 4 AND 12)',
    defaultValue: const CustomExpression('10'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'draft\' CHECK (status IN (\'draft\', \'ready\', \'closed\'))',
    defaultValue: const CustomExpression('\'draft\''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
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
    shortCode,
    title,
    subjectId,
    instructorId,
    examDate,
    itemCount,
    choiceCount,
    passingPercentage,
    multipleMarkPolicy,
    allowNegativeTotal,
    omrPreset,
    omrThresholds,
    studentIdDigits,
    status,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'examinations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExaminationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('short_code')) {
      context.handle(
        _shortCodeMeta,
        shortCode.isAcceptableOrUnknown(data['short_code']!, _shortCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_shortCodeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('instructor_id')) {
      context.handle(
        _instructorIdMeta,
        instructorId.isAcceptableOrUnknown(
          data['instructor_id']!,
          _instructorIdMeta,
        ),
      );
    }
    if (data.containsKey('exam_date')) {
      context.handle(
        _examDateMeta,
        examDate.isAcceptableOrUnknown(data['exam_date']!, _examDateMeta),
      );
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCountMeta);
    }
    if (data.containsKey('choice_count')) {
      context.handle(
        _choiceCountMeta,
        choiceCount.isAcceptableOrUnknown(
          data['choice_count']!,
          _choiceCountMeta,
        ),
      );
    }
    if (data.containsKey('passing_percentage')) {
      context.handle(
        _passingPercentageMeta,
        passingPercentage.isAcceptableOrUnknown(
          data['passing_percentage']!,
          _passingPercentageMeta,
        ),
      );
    }
    if (data.containsKey('multiple_mark_policy')) {
      context.handle(
        _multipleMarkPolicyMeta,
        multipleMarkPolicy.isAcceptableOrUnknown(
          data['multiple_mark_policy']!,
          _multipleMarkPolicyMeta,
        ),
      );
    }
    if (data.containsKey('allow_negative_total')) {
      context.handle(
        _allowNegativeTotalMeta,
        allowNegativeTotal.isAcceptableOrUnknown(
          data['allow_negative_total']!,
          _allowNegativeTotalMeta,
        ),
      );
    }
    if (data.containsKey('omr_preset')) {
      context.handle(
        _omrPresetMeta,
        omrPreset.isAcceptableOrUnknown(data['omr_preset']!, _omrPresetMeta),
      );
    }
    if (data.containsKey('omr_thresholds')) {
      context.handle(
        _omrThresholdsMeta,
        omrThresholds.isAcceptableOrUnknown(
          data['omr_thresholds']!,
          _omrThresholdsMeta,
        ),
      );
    }
    if (data.containsKey('student_id_digits')) {
      context.handle(
        _studentIdDigitsMeta,
        studentIdDigits.isAcceptableOrUnknown(
          data['student_id_digits']!,
          _studentIdDigitsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExaminationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExaminationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shortCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_code'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      ),
      instructorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructor_id'],
      ),
      examDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}exam_date'],
      ),
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      choiceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}choice_count'],
      )!,
      passingPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}passing_percentage'],
      )!,
      multipleMarkPolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}multiple_mark_policy'],
      )!,
      allowNegativeTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_negative_total'],
      )!,
      omrPreset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}omr_preset'],
      )!,
      omrThresholds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}omr_thresholds'],
      ),
      studentIdDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_id_digits'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Examinations createAlias(String alias) {
    return Examinations(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ExaminationRow extends DataClass implements Insertable<ExaminationRow> {
  final String id;

  /// Short code printed on the sheet and inside the QR code (8 chars, Crockford base32).
  final String shortCode;
  final String title;
  final String? subjectId;
  final String? instructorId;
  final DateTime? examDate;
  final int itemCount;
  final int choiceCount;
  final double passingPercentage;

  /// How a question with two or more shaded bubbles is scored.
  final String multipleMarkPolicy;
  final bool allowNegativeTotal;

  /// Recognition sensitivity preset; omr_thresholds holds JSON when 'custom'.
  final String omrPreset;
  final String? omrThresholds;

  /// Number of digit columns in the student-number grid on this exam's sheets.
  final int studentIdDigits;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const ExaminationRow({
    required this.id,
    required this.shortCode,
    required this.title,
    this.subjectId,
    this.instructorId,
    this.examDate,
    required this.itemCount,
    required this.choiceCount,
    required this.passingPercentage,
    required this.multipleMarkPolicy,
    required this.allowNegativeTotal,
    required this.omrPreset,
    this.omrThresholds,
    required this.studentIdDigits,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['short_code'] = Variable<String>(shortCode);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || instructorId != null) {
      map['instructor_id'] = Variable<String>(instructorId);
    }
    if (!nullToAbsent || examDate != null) {
      map['exam_date'] = Variable<DateTime>(examDate);
    }
    map['item_count'] = Variable<int>(itemCount);
    map['choice_count'] = Variable<int>(choiceCount);
    map['passing_percentage'] = Variable<double>(passingPercentage);
    map['multiple_mark_policy'] = Variable<String>(multipleMarkPolicy);
    map['allow_negative_total'] = Variable<bool>(allowNegativeTotal);
    map['omr_preset'] = Variable<String>(omrPreset);
    if (!nullToAbsent || omrThresholds != null) {
      map['omr_thresholds'] = Variable<String>(omrThresholds);
    }
    map['student_id_digits'] = Variable<int>(studentIdDigits);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ExaminationsCompanion toCompanion(bool nullToAbsent) {
    return ExaminationsCompanion(
      id: Value(id),
      shortCode: Value(shortCode),
      title: Value(title),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      instructorId: instructorId == null && nullToAbsent
          ? const Value.absent()
          : Value(instructorId),
      examDate: examDate == null && nullToAbsent
          ? const Value.absent()
          : Value(examDate),
      itemCount: Value(itemCount),
      choiceCount: Value(choiceCount),
      passingPercentage: Value(passingPercentage),
      multipleMarkPolicy: Value(multipleMarkPolicy),
      allowNegativeTotal: Value(allowNegativeTotal),
      omrPreset: Value(omrPreset),
      omrThresholds: omrThresholds == null && nullToAbsent
          ? const Value.absent()
          : Value(omrThresholds),
      studentIdDigits: Value(studentIdDigits),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ExaminationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExaminationRow(
      id: serializer.fromJson<String>(json['id']),
      shortCode: serializer.fromJson<String>(json['short_code']),
      title: serializer.fromJson<String>(json['title']),
      subjectId: serializer.fromJson<String?>(json['subject_id']),
      instructorId: serializer.fromJson<String?>(json['instructor_id']),
      examDate: serializer.fromJson<DateTime?>(json['exam_date']),
      itemCount: serializer.fromJson<int>(json['item_count']),
      choiceCount: serializer.fromJson<int>(json['choice_count']),
      passingPercentage: serializer.fromJson<double>(
        json['passing_percentage'],
      ),
      multipleMarkPolicy: serializer.fromJson<String>(
        json['multiple_mark_policy'],
      ),
      allowNegativeTotal: serializer.fromJson<bool>(
        json['allow_negative_total'],
      ),
      omrPreset: serializer.fromJson<String>(json['omr_preset']),
      omrThresholds: serializer.fromJson<String?>(json['omr_thresholds']),
      studentIdDigits: serializer.fromJson<int>(json['student_id_digits']),
      status: serializer.fromJson<String>(json['status']),
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
      'short_code': serializer.toJson<String>(shortCode),
      'title': serializer.toJson<String>(title),
      'subject_id': serializer.toJson<String?>(subjectId),
      'instructor_id': serializer.toJson<String?>(instructorId),
      'exam_date': serializer.toJson<DateTime?>(examDate),
      'item_count': serializer.toJson<int>(itemCount),
      'choice_count': serializer.toJson<int>(choiceCount),
      'passing_percentage': serializer.toJson<double>(passingPercentage),
      'multiple_mark_policy': serializer.toJson<String>(multipleMarkPolicy),
      'allow_negative_total': serializer.toJson<bool>(allowNegativeTotal),
      'omr_preset': serializer.toJson<String>(omrPreset),
      'omr_thresholds': serializer.toJson<String?>(omrThresholds),
      'student_id_digits': serializer.toJson<int>(studentIdDigits),
      'status': serializer.toJson<String>(status),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'deleted_at': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ExaminationRow copyWith({
    String? id,
    String? shortCode,
    String? title,
    Value<String?> subjectId = const Value.absent(),
    Value<String?> instructorId = const Value.absent(),
    Value<DateTime?> examDate = const Value.absent(),
    int? itemCount,
    int? choiceCount,
    double? passingPercentage,
    String? multipleMarkPolicy,
    bool? allowNegativeTotal,
    String? omrPreset,
    Value<String?> omrThresholds = const Value.absent(),
    int? studentIdDigits,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ExaminationRow(
    id: id ?? this.id,
    shortCode: shortCode ?? this.shortCode,
    title: title ?? this.title,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    instructorId: instructorId.present ? instructorId.value : this.instructorId,
    examDate: examDate.present ? examDate.value : this.examDate,
    itemCount: itemCount ?? this.itemCount,
    choiceCount: choiceCount ?? this.choiceCount,
    passingPercentage: passingPercentage ?? this.passingPercentage,
    multipleMarkPolicy: multipleMarkPolicy ?? this.multipleMarkPolicy,
    allowNegativeTotal: allowNegativeTotal ?? this.allowNegativeTotal,
    omrPreset: omrPreset ?? this.omrPreset,
    omrThresholds: omrThresholds.present
        ? omrThresholds.value
        : this.omrThresholds,
    studentIdDigits: studentIdDigits ?? this.studentIdDigits,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ExaminationRow copyWithCompanion(ExaminationsCompanion data) {
    return ExaminationRow(
      id: data.id.present ? data.id.value : this.id,
      shortCode: data.shortCode.present ? data.shortCode.value : this.shortCode,
      title: data.title.present ? data.title.value : this.title,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      instructorId: data.instructorId.present
          ? data.instructorId.value
          : this.instructorId,
      examDate: data.examDate.present ? data.examDate.value : this.examDate,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      choiceCount: data.choiceCount.present
          ? data.choiceCount.value
          : this.choiceCount,
      passingPercentage: data.passingPercentage.present
          ? data.passingPercentage.value
          : this.passingPercentage,
      multipleMarkPolicy: data.multipleMarkPolicy.present
          ? data.multipleMarkPolicy.value
          : this.multipleMarkPolicy,
      allowNegativeTotal: data.allowNegativeTotal.present
          ? data.allowNegativeTotal.value
          : this.allowNegativeTotal,
      omrPreset: data.omrPreset.present ? data.omrPreset.value : this.omrPreset,
      omrThresholds: data.omrThresholds.present
          ? data.omrThresholds.value
          : this.omrThresholds,
      studentIdDigits: data.studentIdDigits.present
          ? data.studentIdDigits.value
          : this.studentIdDigits,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExaminationRow(')
          ..write('id: $id, ')
          ..write('shortCode: $shortCode, ')
          ..write('title: $title, ')
          ..write('subjectId: $subjectId, ')
          ..write('instructorId: $instructorId, ')
          ..write('examDate: $examDate, ')
          ..write('itemCount: $itemCount, ')
          ..write('choiceCount: $choiceCount, ')
          ..write('passingPercentage: $passingPercentage, ')
          ..write('multipleMarkPolicy: $multipleMarkPolicy, ')
          ..write('allowNegativeTotal: $allowNegativeTotal, ')
          ..write('omrPreset: $omrPreset, ')
          ..write('omrThresholds: $omrThresholds, ')
          ..write('studentIdDigits: $studentIdDigits, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shortCode,
    title,
    subjectId,
    instructorId,
    examDate,
    itemCount,
    choiceCount,
    passingPercentage,
    multipleMarkPolicy,
    allowNegativeTotal,
    omrPreset,
    omrThresholds,
    studentIdDigits,
    status,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExaminationRow &&
          other.id == this.id &&
          other.shortCode == this.shortCode &&
          other.title == this.title &&
          other.subjectId == this.subjectId &&
          other.instructorId == this.instructorId &&
          other.examDate == this.examDate &&
          other.itemCount == this.itemCount &&
          other.choiceCount == this.choiceCount &&
          other.passingPercentage == this.passingPercentage &&
          other.multipleMarkPolicy == this.multipleMarkPolicy &&
          other.allowNegativeTotal == this.allowNegativeTotal &&
          other.omrPreset == this.omrPreset &&
          other.omrThresholds == this.omrThresholds &&
          other.studentIdDigits == this.studentIdDigits &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ExaminationsCompanion extends UpdateCompanion<ExaminationRow> {
  final Value<String> id;
  final Value<String> shortCode;
  final Value<String> title;
  final Value<String?> subjectId;
  final Value<String?> instructorId;
  final Value<DateTime?> examDate;
  final Value<int> itemCount;
  final Value<int> choiceCount;
  final Value<double> passingPercentage;
  final Value<String> multipleMarkPolicy;
  final Value<bool> allowNegativeTotal;
  final Value<String> omrPreset;
  final Value<String?> omrThresholds;
  final Value<int> studentIdDigits;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ExaminationsCompanion({
    this.id = const Value.absent(),
    this.shortCode = const Value.absent(),
    this.title = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.instructorId = const Value.absent(),
    this.examDate = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.choiceCount = const Value.absent(),
    this.passingPercentage = const Value.absent(),
    this.multipleMarkPolicy = const Value.absent(),
    this.allowNegativeTotal = const Value.absent(),
    this.omrPreset = const Value.absent(),
    this.omrThresholds = const Value.absent(),
    this.studentIdDigits = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExaminationsCompanion.insert({
    required String id,
    required String shortCode,
    required String title,
    this.subjectId = const Value.absent(),
    this.instructorId = const Value.absent(),
    this.examDate = const Value.absent(),
    required int itemCount,
    this.choiceCount = const Value.absent(),
    this.passingPercentage = const Value.absent(),
    this.multipleMarkPolicy = const Value.absent(),
    this.allowNegativeTotal = const Value.absent(),
    this.omrPreset = const Value.absent(),
    this.omrThresholds = const Value.absent(),
    this.studentIdDigits = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shortCode = Value(shortCode),
       title = Value(title),
       itemCount = Value(itemCount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExaminationRow> custom({
    Expression<String>? id,
    Expression<String>? shortCode,
    Expression<String>? title,
    Expression<String>? subjectId,
    Expression<String>? instructorId,
    Expression<DateTime>? examDate,
    Expression<int>? itemCount,
    Expression<int>? choiceCount,
    Expression<double>? passingPercentage,
    Expression<String>? multipleMarkPolicy,
    Expression<bool>? allowNegativeTotal,
    Expression<String>? omrPreset,
    Expression<String>? omrThresholds,
    Expression<int>? studentIdDigits,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shortCode != null) 'short_code': shortCode,
      if (title != null) 'title': title,
      if (subjectId != null) 'subject_id': subjectId,
      if (instructorId != null) 'instructor_id': instructorId,
      if (examDate != null) 'exam_date': examDate,
      if (itemCount != null) 'item_count': itemCount,
      if (choiceCount != null) 'choice_count': choiceCount,
      if (passingPercentage != null) 'passing_percentage': passingPercentage,
      if (multipleMarkPolicy != null)
        'multiple_mark_policy': multipleMarkPolicy,
      if (allowNegativeTotal != null)
        'allow_negative_total': allowNegativeTotal,
      if (omrPreset != null) 'omr_preset': omrPreset,
      if (omrThresholds != null) 'omr_thresholds': omrThresholds,
      if (studentIdDigits != null) 'student_id_digits': studentIdDigits,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExaminationsCompanion copyWith({
    Value<String>? id,
    Value<String>? shortCode,
    Value<String>? title,
    Value<String?>? subjectId,
    Value<String?>? instructorId,
    Value<DateTime?>? examDate,
    Value<int>? itemCount,
    Value<int>? choiceCount,
    Value<double>? passingPercentage,
    Value<String>? multipleMarkPolicy,
    Value<bool>? allowNegativeTotal,
    Value<String>? omrPreset,
    Value<String?>? omrThresholds,
    Value<int>? studentIdDigits,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ExaminationsCompanion(
      id: id ?? this.id,
      shortCode: shortCode ?? this.shortCode,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      instructorId: instructorId ?? this.instructorId,
      examDate: examDate ?? this.examDate,
      itemCount: itemCount ?? this.itemCount,
      choiceCount: choiceCount ?? this.choiceCount,
      passingPercentage: passingPercentage ?? this.passingPercentage,
      multipleMarkPolicy: multipleMarkPolicy ?? this.multipleMarkPolicy,
      allowNegativeTotal: allowNegativeTotal ?? this.allowNegativeTotal,
      omrPreset: omrPreset ?? this.omrPreset,
      omrThresholds: omrThresholds ?? this.omrThresholds,
      studentIdDigits: studentIdDigits ?? this.studentIdDigits,
      status: status ?? this.status,
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
    if (shortCode.present) {
      map['short_code'] = Variable<String>(shortCode.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (instructorId.present) {
      map['instructor_id'] = Variable<String>(instructorId.value);
    }
    if (examDate.present) {
      map['exam_date'] = Variable<DateTime>(examDate.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (choiceCount.present) {
      map['choice_count'] = Variable<int>(choiceCount.value);
    }
    if (passingPercentage.present) {
      map['passing_percentage'] = Variable<double>(passingPercentage.value);
    }
    if (multipleMarkPolicy.present) {
      map['multiple_mark_policy'] = Variable<String>(multipleMarkPolicy.value);
    }
    if (allowNegativeTotal.present) {
      map['allow_negative_total'] = Variable<bool>(allowNegativeTotal.value);
    }
    if (omrPreset.present) {
      map['omr_preset'] = Variable<String>(omrPreset.value);
    }
    if (omrThresholds.present) {
      map['omr_thresholds'] = Variable<String>(omrThresholds.value);
    }
    if (studentIdDigits.present) {
      map['student_id_digits'] = Variable<int>(studentIdDigits.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
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
    return (StringBuffer('ExaminationsCompanion(')
          ..write('id: $id, ')
          ..write('shortCode: $shortCode, ')
          ..write('title: $title, ')
          ..write('subjectId: $subjectId, ')
          ..write('instructorId: $instructorId, ')
          ..write('examDate: $examDate, ')
          ..write('itemCount: $itemCount, ')
          ..write('choiceCount: $choiceCount, ')
          ..write('passingPercentage: $passingPercentage, ')
          ..write('multipleMarkPolicy: $multipleMarkPolicy, ')
          ..write('allowNegativeTotal: $allowNegativeTotal, ')
          ..write('omrPreset: $omrPreset, ')
          ..write('omrThresholds: $omrThresholds, ')
          ..write('studentIdDigits: $studentIdDigits, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExaminationSections extends Table
    with TableInfo<ExaminationSections, ExaminationSectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExaminationSections(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _examinationIdMeta = const VerificationMeta(
    'examinationId',
  );
  late final GeneratedColumn<String> examinationId = GeneratedColumn<String>(
    'examination_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES examinations(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _sectionIdMeta = const VerificationMeta(
    'sectionId',
  );
  late final GeneratedColumn<String> sectionId = GeneratedColumn<String>(
    'section_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES sections(id)',
  );
  @override
  List<GeneratedColumn> get $columns => [examinationId, sectionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'examination_sections';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExaminationSectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('examination_id')) {
      context.handle(
        _examinationIdMeta,
        examinationId.isAcceptableOrUnknown(
          data['examination_id']!,
          _examinationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_examinationIdMeta);
    }
    if (data.containsKey('section_id')) {
      context.handle(
        _sectionIdMeta,
        sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {examinationId, sectionId};
  @override
  ExaminationSectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExaminationSectionRow(
      examinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examination_id'],
      )!,
      sectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_id'],
      )!,
    );
  }

  @override
  ExaminationSections createAlias(String alias) {
    return ExaminationSections(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(examination_id, section_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ExaminationSectionRow extends DataClass
    implements Insertable<ExaminationSectionRow> {
  final String examinationId;
  final String sectionId;
  const ExaminationSectionRow({
    required this.examinationId,
    required this.sectionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['examination_id'] = Variable<String>(examinationId);
    map['section_id'] = Variable<String>(sectionId);
    return map;
  }

  ExaminationSectionsCompanion toCompanion(bool nullToAbsent) {
    return ExaminationSectionsCompanion(
      examinationId: Value(examinationId),
      sectionId: Value(sectionId),
    );
  }

  factory ExaminationSectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExaminationSectionRow(
      examinationId: serializer.fromJson<String>(json['examination_id']),
      sectionId: serializer.fromJson<String>(json['section_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'examination_id': serializer.toJson<String>(examinationId),
      'section_id': serializer.toJson<String>(sectionId),
    };
  }

  ExaminationSectionRow copyWith({String? examinationId, String? sectionId}) =>
      ExaminationSectionRow(
        examinationId: examinationId ?? this.examinationId,
        sectionId: sectionId ?? this.sectionId,
      );
  ExaminationSectionRow copyWithCompanion(ExaminationSectionsCompanion data) {
    return ExaminationSectionRow(
      examinationId: data.examinationId.present
          ? data.examinationId.value
          : this.examinationId,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExaminationSectionRow(')
          ..write('examinationId: $examinationId, ')
          ..write('sectionId: $sectionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(examinationId, sectionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExaminationSectionRow &&
          other.examinationId == this.examinationId &&
          other.sectionId == this.sectionId);
}

class ExaminationSectionsCompanion
    extends UpdateCompanion<ExaminationSectionRow> {
  final Value<String> examinationId;
  final Value<String> sectionId;
  final Value<int> rowid;
  const ExaminationSectionsCompanion({
    this.examinationId = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExaminationSectionsCompanion.insert({
    required String examinationId,
    required String sectionId,
    this.rowid = const Value.absent(),
  }) : examinationId = Value(examinationId),
       sectionId = Value(sectionId);
  static Insertable<ExaminationSectionRow> custom({
    Expression<String>? examinationId,
    Expression<String>? sectionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (examinationId != null) 'examination_id': examinationId,
      if (sectionId != null) 'section_id': sectionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExaminationSectionsCompanion copyWith({
    Value<String>? examinationId,
    Value<String>? sectionId,
    Value<int>? rowid,
  }) {
    return ExaminationSectionsCompanion(
      examinationId: examinationId ?? this.examinationId,
      sectionId: sectionId ?? this.sectionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (examinationId.present) {
      map['examination_id'] = Variable<String>(examinationId.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<String>(sectionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExaminationSectionsCompanion(')
          ..write('examinationId: $examinationId, ')
          ..write('sectionId: $sectionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExaminationVersions extends Table
    with TableInfo<ExaminationVersions, ExaminationVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExaminationVersions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _examinationIdMeta = const VerificationMeta(
    'examinationId',
  );
  late final GeneratedColumn<String> examinationId = GeneratedColumn<String>(
    'examination_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES examinations(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (label IN (\'A\', \'B\', \'C\', \'D\'))',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, examinationId, label, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'examination_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExaminationVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('examination_id')) {
      context.handle(
        _examinationIdMeta,
        examinationId.isAcceptableOrUnknown(
          data['examination_id']!,
          _examinationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_examinationIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {examinationId, label},
  ];
  @override
  ExaminationVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExaminationVersionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      examinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examination_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  ExaminationVersions createAlias(String alias) {
    return ExaminationVersions(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(examination_id, label)'];
  @override
  bool get dontWriteConstraints => true;
}

class ExaminationVersionRow extends DataClass
    implements Insertable<ExaminationVersionRow> {
  final String id;
  final String examinationId;
  final String label;
  final DateTime createdAt;
  const ExaminationVersionRow({
    required this.id,
    required this.examinationId,
    required this.label,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['examination_id'] = Variable<String>(examinationId);
    map['label'] = Variable<String>(label);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExaminationVersionsCompanion toCompanion(bool nullToAbsent) {
    return ExaminationVersionsCompanion(
      id: Value(id),
      examinationId: Value(examinationId),
      label: Value(label),
      createdAt: Value(createdAt),
    );
  }

  factory ExaminationVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExaminationVersionRow(
      id: serializer.fromJson<String>(json['id']),
      examinationId: serializer.fromJson<String>(json['examination_id']),
      label: serializer.fromJson<String>(json['label']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'examination_id': serializer.toJson<String>(examinationId),
      'label': serializer.toJson<String>(label),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExaminationVersionRow copyWith({
    String? id,
    String? examinationId,
    String? label,
    DateTime? createdAt,
  }) => ExaminationVersionRow(
    id: id ?? this.id,
    examinationId: examinationId ?? this.examinationId,
    label: label ?? this.label,
    createdAt: createdAt ?? this.createdAt,
  );
  ExaminationVersionRow copyWithCompanion(ExaminationVersionsCompanion data) {
    return ExaminationVersionRow(
      id: data.id.present ? data.id.value : this.id,
      examinationId: data.examinationId.present
          ? data.examinationId.value
          : this.examinationId,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExaminationVersionRow(')
          ..write('id: $id, ')
          ..write('examinationId: $examinationId, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, examinationId, label, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExaminationVersionRow &&
          other.id == this.id &&
          other.examinationId == this.examinationId &&
          other.label == this.label &&
          other.createdAt == this.createdAt);
}

class ExaminationVersionsCompanion
    extends UpdateCompanion<ExaminationVersionRow> {
  final Value<String> id;
  final Value<String> examinationId;
  final Value<String> label;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ExaminationVersionsCompanion({
    this.id = const Value.absent(),
    this.examinationId = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExaminationVersionsCompanion.insert({
    required String id,
    required String examinationId,
    required String label,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       examinationId = Value(examinationId),
       label = Value(label),
       createdAt = Value(createdAt);
  static Insertable<ExaminationVersionRow> custom({
    Expression<String>? id,
    Expression<String>? examinationId,
    Expression<String>? label,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (examinationId != null) 'examination_id': examinationId,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExaminationVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? examinationId,
    Value<String>? label,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ExaminationVersionsCompanion(
      id: id ?? this.id,
      examinationId: examinationId ?? this.examinationId,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (examinationId.present) {
      map['examination_id'] = Variable<String>(examinationId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExaminationVersionsCompanion(')
          ..write('id: $id, ')
          ..write('examinationId: $examinationId, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AnswerKeys extends Table with TableInfo<AnswerKeys, AnswerKeyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AnswerKeys(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _examinationVersionIdMeta =
      const VerificationMeta('examinationVersionId');
  late final GeneratedColumn<String> examinationVersionId =
      GeneratedColumn<String>(
        'examination_version_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL REFERENCES examination_versions(id)ON DELETE CASCADE',
      );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (revision >= 1)',
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT TRUE',
    defaultValue: const CustomExpression('TRUE'),
  );
  static const VerificationMeta _changeNoteMeta = const VerificationMeta(
    'changeNote',
  );
  late final GeneratedColumn<String> changeNote = GeneratedColumn<String>(
    'change_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (change_note IS NULL OR length(change_note) <= 500)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    examinationVersionId,
    revision,
    isCurrent,
    changeNote,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'answer_keys';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnswerKeyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('examination_version_id')) {
      context.handle(
        _examinationVersionIdMeta,
        examinationVersionId.isAcceptableOrUnknown(
          data['examination_version_id']!,
          _examinationVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_examinationVersionIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    if (data.containsKey('change_note')) {
      context.handle(
        _changeNoteMeta,
        changeNote.isAcceptableOrUnknown(data['change_note']!, _changeNoteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {examinationVersionId, revision},
  ];
  @override
  AnswerKeyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnswerKeyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      examinationVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examination_version_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
      changeNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  AnswerKeys createAlias(String alias) {
    return AnswerKeys(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(examination_version_id, revision)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class AnswerKeyRow extends DataClass implements Insertable<AnswerKeyRow> {
  final String id;
  final String examinationVersionId;

  /// Every edit after scanning starts creates a new revision; old revisions are
  /// kept so earlier results remain explainable (see audit_logs).
  final int revision;
  final bool isCurrent;
  final String? changeNote;
  final DateTime createdAt;
  const AnswerKeyRow({
    required this.id,
    required this.examinationVersionId,
    required this.revision,
    required this.isCurrent,
    this.changeNote,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['examination_version_id'] = Variable<String>(examinationVersionId);
    map['revision'] = Variable<int>(revision);
    map['is_current'] = Variable<bool>(isCurrent);
    if (!nullToAbsent || changeNote != null) {
      map['change_note'] = Variable<String>(changeNote);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnswerKeysCompanion toCompanion(bool nullToAbsent) {
    return AnswerKeysCompanion(
      id: Value(id),
      examinationVersionId: Value(examinationVersionId),
      revision: Value(revision),
      isCurrent: Value(isCurrent),
      changeNote: changeNote == null && nullToAbsent
          ? const Value.absent()
          : Value(changeNote),
      createdAt: Value(createdAt),
    );
  }

  factory AnswerKeyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnswerKeyRow(
      id: serializer.fromJson<String>(json['id']),
      examinationVersionId: serializer.fromJson<String>(
        json['examination_version_id'],
      ),
      revision: serializer.fromJson<int>(json['revision']),
      isCurrent: serializer.fromJson<bool>(json['is_current']),
      changeNote: serializer.fromJson<String?>(json['change_note']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'examination_version_id': serializer.toJson<String>(examinationVersionId),
      'revision': serializer.toJson<int>(revision),
      'is_current': serializer.toJson<bool>(isCurrent),
      'change_note': serializer.toJson<String?>(changeNote),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  AnswerKeyRow copyWith({
    String? id,
    String? examinationVersionId,
    int? revision,
    bool? isCurrent,
    Value<String?> changeNote = const Value.absent(),
    DateTime? createdAt,
  }) => AnswerKeyRow(
    id: id ?? this.id,
    examinationVersionId: examinationVersionId ?? this.examinationVersionId,
    revision: revision ?? this.revision,
    isCurrent: isCurrent ?? this.isCurrent,
    changeNote: changeNote.present ? changeNote.value : this.changeNote,
    createdAt: createdAt ?? this.createdAt,
  );
  AnswerKeyRow copyWithCompanion(AnswerKeysCompanion data) {
    return AnswerKeyRow(
      id: data.id.present ? data.id.value : this.id,
      examinationVersionId: data.examinationVersionId.present
          ? data.examinationVersionId.value
          : this.examinationVersionId,
      revision: data.revision.present ? data.revision.value : this.revision,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
      changeNote: data.changeNote.present
          ? data.changeNote.value
          : this.changeNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnswerKeyRow(')
          ..write('id: $id, ')
          ..write('examinationVersionId: $examinationVersionId, ')
          ..write('revision: $revision, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('changeNote: $changeNote, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    examinationVersionId,
    revision,
    isCurrent,
    changeNote,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnswerKeyRow &&
          other.id == this.id &&
          other.examinationVersionId == this.examinationVersionId &&
          other.revision == this.revision &&
          other.isCurrent == this.isCurrent &&
          other.changeNote == this.changeNote &&
          other.createdAt == this.createdAt);
}

class AnswerKeysCompanion extends UpdateCompanion<AnswerKeyRow> {
  final Value<String> id;
  final Value<String> examinationVersionId;
  final Value<int> revision;
  final Value<bool> isCurrent;
  final Value<String?> changeNote;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AnswerKeysCompanion({
    this.id = const Value.absent(),
    this.examinationVersionId = const Value.absent(),
    this.revision = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.changeNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnswerKeysCompanion.insert({
    required String id,
    required String examinationVersionId,
    required int revision,
    this.isCurrent = const Value.absent(),
    this.changeNote = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       examinationVersionId = Value(examinationVersionId),
       revision = Value(revision),
       createdAt = Value(createdAt);
  static Insertable<AnswerKeyRow> custom({
    Expression<String>? id,
    Expression<String>? examinationVersionId,
    Expression<int>? revision,
    Expression<bool>? isCurrent,
    Expression<String>? changeNote,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (examinationVersionId != null)
        'examination_version_id': examinationVersionId,
      if (revision != null) 'revision': revision,
      if (isCurrent != null) 'is_current': isCurrent,
      if (changeNote != null) 'change_note': changeNote,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnswerKeysCompanion copyWith({
    Value<String>? id,
    Value<String>? examinationVersionId,
    Value<int>? revision,
    Value<bool>? isCurrent,
    Value<String?>? changeNote,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AnswerKeysCompanion(
      id: id ?? this.id,
      examinationVersionId: examinationVersionId ?? this.examinationVersionId,
      revision: revision ?? this.revision,
      isCurrent: isCurrent ?? this.isCurrent,
      changeNote: changeNote ?? this.changeNote,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (examinationVersionId.present) {
      map['examination_version_id'] = Variable<String>(
        examinationVersionId.value,
      );
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (changeNote.present) {
      map['change_note'] = Variable<String>(changeNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnswerKeysCompanion(')
          ..write('id: $id, ')
          ..write('examinationVersionId: $examinationVersionId, ')
          ..write('revision: $revision, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('changeNote: $changeNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AnswerKeyItems extends Table
    with TableInfo<AnswerKeyItems, AnswerKeyItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AnswerKeyItems(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _answerKeyIdMeta = const VerificationMeta(
    'answerKeyId',
  );
  late final GeneratedColumn<String> answerKeyId = GeneratedColumn<String>(
    'answer_key_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES answer_keys(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _questionNoMeta = const VerificationMeta(
    'questionNo',
  );
  late final GeneratedColumn<int> questionNo = GeneratedColumn<int>(
    'question_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (question_no BETWEEN 1 AND 100)',
  );
  static const VerificationMeta _correctMaskMeta = const VerificationMeta(
    'correctMask',
  );
  late final GeneratedColumn<int> correctMask = GeneratedColumn<int>(
    'correct_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (correct_mask BETWEEN 0 AND 31)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  late final GeneratedColumn<double> points = GeneratedColumn<double>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (points BETWEEN 0 AND 100)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _negativePointsMeta = const VerificationMeta(
    'negativePoints',
  );
  late final GeneratedColumn<double> negativePoints = GeneratedColumn<double>(
    'negative_points',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (negative_points BETWEEN 0 AND 100)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'normal\' CHECK (mode IN (\'normal\', \'bonus\', \'dropped\'))',
    defaultValue: const CustomExpression('\'normal\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    answerKeyId,
    questionNo,
    correctMask,
    points,
    negativePoints,
    mode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'answer_key_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnswerKeyItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('answer_key_id')) {
      context.handle(
        _answerKeyIdMeta,
        answerKeyId.isAcceptableOrUnknown(
          data['answer_key_id']!,
          _answerKeyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_answerKeyIdMeta);
    }
    if (data.containsKey('question_no')) {
      context.handle(
        _questionNoMeta,
        questionNo.isAcceptableOrUnknown(data['question_no']!, _questionNoMeta),
      );
    } else if (isInserting) {
      context.missing(_questionNoMeta);
    }
    if (data.containsKey('correct_mask')) {
      context.handle(
        _correctMaskMeta,
        correctMask.isAcceptableOrUnknown(
          data['correct_mask']!,
          _correctMaskMeta,
        ),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    if (data.containsKey('negative_points')) {
      context.handle(
        _negativePointsMeta,
        negativePoints.isAcceptableOrUnknown(
          data['negative_points']!,
          _negativePointsMeta,
        ),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {answerKeyId, questionNo};
  @override
  AnswerKeyItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnswerKeyItemRow(
      answerKeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_key_id'],
      )!,
      questionNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_no'],
      )!,
      correctMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_mask'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}points'],
      )!,
      negativePoints: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}negative_points'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
    );
  }

  @override
  AnswerKeyItems createAlias(String alias) {
    return AnswerKeyItems(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(answer_key_id, question_no)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class AnswerKeyItemRow extends DataClass
    implements Insertable<AnswerKeyItemRow> {
  final String answerKeyId;
  final int questionNo;

  /// Accepted answer(s) as a bitmask. 0 = not yet set (draft key).
  final int correctMask;
  final double points;
  final double negativePoints;

  /// normal: graded; bonus: everyone earns the points; dropped: excluded from totals.
  final String mode;
  const AnswerKeyItemRow({
    required this.answerKeyId,
    required this.questionNo,
    required this.correctMask,
    required this.points,
    required this.negativePoints,
    required this.mode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['answer_key_id'] = Variable<String>(answerKeyId);
    map['question_no'] = Variable<int>(questionNo);
    map['correct_mask'] = Variable<int>(correctMask);
    map['points'] = Variable<double>(points);
    map['negative_points'] = Variable<double>(negativePoints);
    map['mode'] = Variable<String>(mode);
    return map;
  }

  AnswerKeyItemsCompanion toCompanion(bool nullToAbsent) {
    return AnswerKeyItemsCompanion(
      answerKeyId: Value(answerKeyId),
      questionNo: Value(questionNo),
      correctMask: Value(correctMask),
      points: Value(points),
      negativePoints: Value(negativePoints),
      mode: Value(mode),
    );
  }

  factory AnswerKeyItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnswerKeyItemRow(
      answerKeyId: serializer.fromJson<String>(json['answer_key_id']),
      questionNo: serializer.fromJson<int>(json['question_no']),
      correctMask: serializer.fromJson<int>(json['correct_mask']),
      points: serializer.fromJson<double>(json['points']),
      negativePoints: serializer.fromJson<double>(json['negative_points']),
      mode: serializer.fromJson<String>(json['mode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'answer_key_id': serializer.toJson<String>(answerKeyId),
      'question_no': serializer.toJson<int>(questionNo),
      'correct_mask': serializer.toJson<int>(correctMask),
      'points': serializer.toJson<double>(points),
      'negative_points': serializer.toJson<double>(negativePoints),
      'mode': serializer.toJson<String>(mode),
    };
  }

  AnswerKeyItemRow copyWith({
    String? answerKeyId,
    int? questionNo,
    int? correctMask,
    double? points,
    double? negativePoints,
    String? mode,
  }) => AnswerKeyItemRow(
    answerKeyId: answerKeyId ?? this.answerKeyId,
    questionNo: questionNo ?? this.questionNo,
    correctMask: correctMask ?? this.correctMask,
    points: points ?? this.points,
    negativePoints: negativePoints ?? this.negativePoints,
    mode: mode ?? this.mode,
  );
  AnswerKeyItemRow copyWithCompanion(AnswerKeyItemsCompanion data) {
    return AnswerKeyItemRow(
      answerKeyId: data.answerKeyId.present
          ? data.answerKeyId.value
          : this.answerKeyId,
      questionNo: data.questionNo.present
          ? data.questionNo.value
          : this.questionNo,
      correctMask: data.correctMask.present
          ? data.correctMask.value
          : this.correctMask,
      points: data.points.present ? data.points.value : this.points,
      negativePoints: data.negativePoints.present
          ? data.negativePoints.value
          : this.negativePoints,
      mode: data.mode.present ? data.mode.value : this.mode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnswerKeyItemRow(')
          ..write('answerKeyId: $answerKeyId, ')
          ..write('questionNo: $questionNo, ')
          ..write('correctMask: $correctMask, ')
          ..write('points: $points, ')
          ..write('negativePoints: $negativePoints, ')
          ..write('mode: $mode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    answerKeyId,
    questionNo,
    correctMask,
    points,
    negativePoints,
    mode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnswerKeyItemRow &&
          other.answerKeyId == this.answerKeyId &&
          other.questionNo == this.questionNo &&
          other.correctMask == this.correctMask &&
          other.points == this.points &&
          other.negativePoints == this.negativePoints &&
          other.mode == this.mode);
}

class AnswerKeyItemsCompanion extends UpdateCompanion<AnswerKeyItemRow> {
  final Value<String> answerKeyId;
  final Value<int> questionNo;
  final Value<int> correctMask;
  final Value<double> points;
  final Value<double> negativePoints;
  final Value<String> mode;
  final Value<int> rowid;
  const AnswerKeyItemsCompanion({
    this.answerKeyId = const Value.absent(),
    this.questionNo = const Value.absent(),
    this.correctMask = const Value.absent(),
    this.points = const Value.absent(),
    this.negativePoints = const Value.absent(),
    this.mode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnswerKeyItemsCompanion.insert({
    required String answerKeyId,
    required int questionNo,
    this.correctMask = const Value.absent(),
    this.points = const Value.absent(),
    this.negativePoints = const Value.absent(),
    this.mode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : answerKeyId = Value(answerKeyId),
       questionNo = Value(questionNo);
  static Insertable<AnswerKeyItemRow> custom({
    Expression<String>? answerKeyId,
    Expression<int>? questionNo,
    Expression<int>? correctMask,
    Expression<double>? points,
    Expression<double>? negativePoints,
    Expression<String>? mode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (answerKeyId != null) 'answer_key_id': answerKeyId,
      if (questionNo != null) 'question_no': questionNo,
      if (correctMask != null) 'correct_mask': correctMask,
      if (points != null) 'points': points,
      if (negativePoints != null) 'negative_points': negativePoints,
      if (mode != null) 'mode': mode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnswerKeyItemsCompanion copyWith({
    Value<String>? answerKeyId,
    Value<int>? questionNo,
    Value<int>? correctMask,
    Value<double>? points,
    Value<double>? negativePoints,
    Value<String>? mode,
    Value<int>? rowid,
  }) {
    return AnswerKeyItemsCompanion(
      answerKeyId: answerKeyId ?? this.answerKeyId,
      questionNo: questionNo ?? this.questionNo,
      correctMask: correctMask ?? this.correctMask,
      points: points ?? this.points,
      negativePoints: negativePoints ?? this.negativePoints,
      mode: mode ?? this.mode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (answerKeyId.present) {
      map['answer_key_id'] = Variable<String>(answerKeyId.value);
    }
    if (questionNo.present) {
      map['question_no'] = Variable<int>(questionNo.value);
    }
    if (correctMask.present) {
      map['correct_mask'] = Variable<int>(correctMask.value);
    }
    if (points.present) {
      map['points'] = Variable<double>(points.value);
    }
    if (negativePoints.present) {
      map['negative_points'] = Variable<double>(negativePoints.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnswerKeyItemsCompanion(')
          ..write('answerKeyId: $answerKeyId, ')
          ..write('questionNo: $questionNo, ')
          ..write('correctMask: $correctMask, ')
          ..write('points: $points, ')
          ..write('negativePoints: $negativePoints, ')
          ..write('mode: $mode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PrintedSheets extends Table
    with TableInfo<PrintedSheets, PrintedSheetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PrintedSheets(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _examinationIdMeta = const VerificationMeta(
    'examinationId',
  );
  late final GeneratedColumn<String> examinationId = GeneratedColumn<String>(
    'examination_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES examinations(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _examinationVersionIdMeta =
      const VerificationMeta('examinationVersionId');
  late final GeneratedColumn<String> examinationVersionId =
      GeneratedColumn<String>(
        'examination_version_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES examination_versions(id)',
      );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES students(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _sheetCodeMeta = const VerificationMeta(
    'sheetCode',
  );
  late final GeneratedColumn<String> sheetCode = GeneratedColumn<String>(
    'sheet_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL UNIQUE CHECK (length(sheet_code) BETWEEN 6 AND 32)',
  );
  static const VerificationMeta _paperSizeMeta = const VerificationMeta(
    'paperSize',
  );
  late final GeneratedColumn<String> paperSize = GeneratedColumn<String>(
    'paper_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (paper_size IN (\'a4\', \'letter\', \'long\'))',
  );
  static const VerificationMeta _copiesMeta = const VerificationMeta('copies');
  late final GeneratedColumn<int> copies = GeneratedColumn<int>(
    'copies',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (copies BETWEEN 1 AND 1000)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    examinationId,
    examinationVersionId,
    studentId,
    sheetCode,
    paperSize,
    copies,
    generatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'printed_sheets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrintedSheetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('examination_id')) {
      context.handle(
        _examinationIdMeta,
        examinationId.isAcceptableOrUnknown(
          data['examination_id']!,
          _examinationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_examinationIdMeta);
    }
    if (data.containsKey('examination_version_id')) {
      context.handle(
        _examinationVersionIdMeta,
        examinationVersionId.isAcceptableOrUnknown(
          data['examination_version_id']!,
          _examinationVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    }
    if (data.containsKey('sheet_code')) {
      context.handle(
        _sheetCodeMeta,
        sheetCode.isAcceptableOrUnknown(data['sheet_code']!, _sheetCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_sheetCodeMeta);
    }
    if (data.containsKey('paper_size')) {
      context.handle(
        _paperSizeMeta,
        paperSize.isAcceptableOrUnknown(data['paper_size']!, _paperSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_paperSizeMeta);
    }
    if (data.containsKey('copies')) {
      context.handle(
        _copiesMeta,
        copies.isAcceptableOrUnknown(data['copies']!, _copiesMeta),
      );
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrintedSheetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrintedSheetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      examinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examination_id'],
      )!,
      examinationVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examination_version_id'],
      ),
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      ),
      sheetCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sheet_code'],
      )!,
      paperSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paper_size'],
      )!,
      copies: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}copies'],
      )!,
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generated_at'],
      )!,
    );
  }

  @override
  PrintedSheets createAlias(String alias) {
    return PrintedSheets(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PrintedSheetRow extends DataClass implements Insertable<PrintedSheetRow> {
  final String id;
  final String examinationId;
  final String? examinationVersionId;
  final String? studentId;

  /// Unique code inside the sheet's QR; identifies a personalized paper.
  final String sheetCode;
  final String paperSize;
  final int copies;
  final DateTime generatedAt;
  const PrintedSheetRow({
    required this.id,
    required this.examinationId,
    this.examinationVersionId,
    this.studentId,
    required this.sheetCode,
    required this.paperSize,
    required this.copies,
    required this.generatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['examination_id'] = Variable<String>(examinationId);
    if (!nullToAbsent || examinationVersionId != null) {
      map['examination_version_id'] = Variable<String>(examinationVersionId);
    }
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<String>(studentId);
    }
    map['sheet_code'] = Variable<String>(sheetCode);
    map['paper_size'] = Variable<String>(paperSize);
    map['copies'] = Variable<int>(copies);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    return map;
  }

  PrintedSheetsCompanion toCompanion(bool nullToAbsent) {
    return PrintedSheetsCompanion(
      id: Value(id),
      examinationId: Value(examinationId),
      examinationVersionId: examinationVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(examinationVersionId),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      sheetCode: Value(sheetCode),
      paperSize: Value(paperSize),
      copies: Value(copies),
      generatedAt: Value(generatedAt),
    );
  }

  factory PrintedSheetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrintedSheetRow(
      id: serializer.fromJson<String>(json['id']),
      examinationId: serializer.fromJson<String>(json['examination_id']),
      examinationVersionId: serializer.fromJson<String?>(
        json['examination_version_id'],
      ),
      studentId: serializer.fromJson<String?>(json['student_id']),
      sheetCode: serializer.fromJson<String>(json['sheet_code']),
      paperSize: serializer.fromJson<String>(json['paper_size']),
      copies: serializer.fromJson<int>(json['copies']),
      generatedAt: serializer.fromJson<DateTime>(json['generated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'examination_id': serializer.toJson<String>(examinationId),
      'examination_version_id': serializer.toJson<String?>(
        examinationVersionId,
      ),
      'student_id': serializer.toJson<String?>(studentId),
      'sheet_code': serializer.toJson<String>(sheetCode),
      'paper_size': serializer.toJson<String>(paperSize),
      'copies': serializer.toJson<int>(copies),
      'generated_at': serializer.toJson<DateTime>(generatedAt),
    };
  }

  PrintedSheetRow copyWith({
    String? id,
    String? examinationId,
    Value<String?> examinationVersionId = const Value.absent(),
    Value<String?> studentId = const Value.absent(),
    String? sheetCode,
    String? paperSize,
    int? copies,
    DateTime? generatedAt,
  }) => PrintedSheetRow(
    id: id ?? this.id,
    examinationId: examinationId ?? this.examinationId,
    examinationVersionId: examinationVersionId.present
        ? examinationVersionId.value
        : this.examinationVersionId,
    studentId: studentId.present ? studentId.value : this.studentId,
    sheetCode: sheetCode ?? this.sheetCode,
    paperSize: paperSize ?? this.paperSize,
    copies: copies ?? this.copies,
    generatedAt: generatedAt ?? this.generatedAt,
  );
  PrintedSheetRow copyWithCompanion(PrintedSheetsCompanion data) {
    return PrintedSheetRow(
      id: data.id.present ? data.id.value : this.id,
      examinationId: data.examinationId.present
          ? data.examinationId.value
          : this.examinationId,
      examinationVersionId: data.examinationVersionId.present
          ? data.examinationVersionId.value
          : this.examinationVersionId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      sheetCode: data.sheetCode.present ? data.sheetCode.value : this.sheetCode,
      paperSize: data.paperSize.present ? data.paperSize.value : this.paperSize,
      copies: data.copies.present ? data.copies.value : this.copies,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrintedSheetRow(')
          ..write('id: $id, ')
          ..write('examinationId: $examinationId, ')
          ..write('examinationVersionId: $examinationVersionId, ')
          ..write('studentId: $studentId, ')
          ..write('sheetCode: $sheetCode, ')
          ..write('paperSize: $paperSize, ')
          ..write('copies: $copies, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    examinationId,
    examinationVersionId,
    studentId,
    sheetCode,
    paperSize,
    copies,
    generatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrintedSheetRow &&
          other.id == this.id &&
          other.examinationId == this.examinationId &&
          other.examinationVersionId == this.examinationVersionId &&
          other.studentId == this.studentId &&
          other.sheetCode == this.sheetCode &&
          other.paperSize == this.paperSize &&
          other.copies == this.copies &&
          other.generatedAt == this.generatedAt);
}

class PrintedSheetsCompanion extends UpdateCompanion<PrintedSheetRow> {
  final Value<String> id;
  final Value<String> examinationId;
  final Value<String?> examinationVersionId;
  final Value<String?> studentId;
  final Value<String> sheetCode;
  final Value<String> paperSize;
  final Value<int> copies;
  final Value<DateTime> generatedAt;
  final Value<int> rowid;
  const PrintedSheetsCompanion({
    this.id = const Value.absent(),
    this.examinationId = const Value.absent(),
    this.examinationVersionId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.sheetCode = const Value.absent(),
    this.paperSize = const Value.absent(),
    this.copies = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrintedSheetsCompanion.insert({
    required String id,
    required String examinationId,
    this.examinationVersionId = const Value.absent(),
    this.studentId = const Value.absent(),
    required String sheetCode,
    required String paperSize,
    this.copies = const Value.absent(),
    required DateTime generatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       examinationId = Value(examinationId),
       sheetCode = Value(sheetCode),
       paperSize = Value(paperSize),
       generatedAt = Value(generatedAt);
  static Insertable<PrintedSheetRow> custom({
    Expression<String>? id,
    Expression<String>? examinationId,
    Expression<String>? examinationVersionId,
    Expression<String>? studentId,
    Expression<String>? sheetCode,
    Expression<String>? paperSize,
    Expression<int>? copies,
    Expression<DateTime>? generatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (examinationId != null) 'examination_id': examinationId,
      if (examinationVersionId != null)
        'examination_version_id': examinationVersionId,
      if (studentId != null) 'student_id': studentId,
      if (sheetCode != null) 'sheet_code': sheetCode,
      if (paperSize != null) 'paper_size': paperSize,
      if (copies != null) 'copies': copies,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrintedSheetsCompanion copyWith({
    Value<String>? id,
    Value<String>? examinationId,
    Value<String?>? examinationVersionId,
    Value<String?>? studentId,
    Value<String>? sheetCode,
    Value<String>? paperSize,
    Value<int>? copies,
    Value<DateTime>? generatedAt,
    Value<int>? rowid,
  }) {
    return PrintedSheetsCompanion(
      id: id ?? this.id,
      examinationId: examinationId ?? this.examinationId,
      examinationVersionId: examinationVersionId ?? this.examinationVersionId,
      studentId: studentId ?? this.studentId,
      sheetCode: sheetCode ?? this.sheetCode,
      paperSize: paperSize ?? this.paperSize,
      copies: copies ?? this.copies,
      generatedAt: generatedAt ?? this.generatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (examinationId.present) {
      map['examination_id'] = Variable<String>(examinationId.value);
    }
    if (examinationVersionId.present) {
      map['examination_version_id'] = Variable<String>(
        examinationVersionId.value,
      );
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (sheetCode.present) {
      map['sheet_code'] = Variable<String>(sheetCode.value);
    }
    if (paperSize.present) {
      map['paper_size'] = Variable<String>(paperSize.value);
    }
    if (copies.present) {
      map['copies'] = Variable<int>(copies.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrintedSheetsCompanion(')
          ..write('id: $id, ')
          ..write('examinationId: $examinationId, ')
          ..write('examinationVersionId: $examinationVersionId, ')
          ..write('studentId: $studentId, ')
          ..write('sheetCode: $sheetCode, ')
          ..write('paperSize: $paperSize, ')
          ..write('copies: $copies, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ScanSessions extends Table with TableInfo<ScanSessions, ScanSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ScanSessions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _examinationIdMeta = const VerificationMeta(
    'examinationId',
  );
  late final GeneratedColumn<String> examinationId = GeneratedColumn<String>(
    'examination_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES examinations(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (mode IN (\'single\', \'batch\'))',
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _capturesAttemptedMeta = const VerificationMeta(
    'capturesAttempted',
  );
  late final GeneratedColumn<int> capturesAttempted = GeneratedColumn<int>(
    'captures_attempted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (captures_attempted >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _capturesRejectedMeta = const VerificationMeta(
    'capturesRejected',
  );
  late final GeneratedColumn<int> capturesRejected = GeneratedColumn<int>(
    'captures_rejected',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (captures_rejected >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _sheetsFinalizedMeta = const VerificationMeta(
    'sheetsFinalized',
  );
  late final GeneratedColumn<int> sheetsFinalized = GeneratedColumn<int>(
    'sheets_finalized',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (sheets_finalized >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _deviceModelMeta = const VerificationMeta(
    'deviceModel',
  );
  late final GeneratedColumn<String> deviceModel = GeneratedColumn<String>(
    'device_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    examinationId,
    mode,
    startedAt,
    endedAt,
    capturesAttempted,
    capturesRejected,
    sheetsFinalized,
    deviceModel,
    appVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('examination_id')) {
      context.handle(
        _examinationIdMeta,
        examinationId.isAcceptableOrUnknown(
          data['examination_id']!,
          _examinationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_examinationIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('captures_attempted')) {
      context.handle(
        _capturesAttemptedMeta,
        capturesAttempted.isAcceptableOrUnknown(
          data['captures_attempted']!,
          _capturesAttemptedMeta,
        ),
      );
    }
    if (data.containsKey('captures_rejected')) {
      context.handle(
        _capturesRejectedMeta,
        capturesRejected.isAcceptableOrUnknown(
          data['captures_rejected']!,
          _capturesRejectedMeta,
        ),
      );
    }
    if (data.containsKey('sheets_finalized')) {
      context.handle(
        _sheetsFinalizedMeta,
        sheetsFinalized.isAcceptableOrUnknown(
          data['sheets_finalized']!,
          _sheetsFinalizedMeta,
        ),
      );
    }
    if (data.containsKey('device_model')) {
      context.handle(
        _deviceModelMeta,
        deviceModel.isAcceptableOrUnknown(
          data['device_model']!,
          _deviceModelMeta,
        ),
      );
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      examinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examination_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      capturesAttempted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}captures_attempted'],
      )!,
      capturesRejected: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}captures_rejected'],
      )!,
      sheetsFinalized: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sheets_finalized'],
      )!,
      deviceModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_model'],
      ),
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      ),
    );
  }

  @override
  ScanSessions createAlias(String alias) {
    return ScanSessions(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ScanSessionRow extends DataClass implements Insertable<ScanSessionRow> {
  final String id;
  final String examinationId;
  final String mode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int capturesAttempted;
  final int capturesRejected;
  final int sheetsFinalized;
  final String? deviceModel;
  final String? appVersion;
  const ScanSessionRow({
    required this.id,
    required this.examinationId,
    required this.mode,
    required this.startedAt,
    this.endedAt,
    required this.capturesAttempted,
    required this.capturesRejected,
    required this.sheetsFinalized,
    this.deviceModel,
    this.appVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['examination_id'] = Variable<String>(examinationId);
    map['mode'] = Variable<String>(mode);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['captures_attempted'] = Variable<int>(capturesAttempted);
    map['captures_rejected'] = Variable<int>(capturesRejected);
    map['sheets_finalized'] = Variable<int>(sheetsFinalized);
    if (!nullToAbsent || deviceModel != null) {
      map['device_model'] = Variable<String>(deviceModel);
    }
    if (!nullToAbsent || appVersion != null) {
      map['app_version'] = Variable<String>(appVersion);
    }
    return map;
  }

  ScanSessionsCompanion toCompanion(bool nullToAbsent) {
    return ScanSessionsCompanion(
      id: Value(id),
      examinationId: Value(examinationId),
      mode: Value(mode),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      capturesAttempted: Value(capturesAttempted),
      capturesRejected: Value(capturesRejected),
      sheetsFinalized: Value(sheetsFinalized),
      deviceModel: deviceModel == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceModel),
      appVersion: appVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(appVersion),
    );
  }

  factory ScanSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanSessionRow(
      id: serializer.fromJson<String>(json['id']),
      examinationId: serializer.fromJson<String>(json['examination_id']),
      mode: serializer.fromJson<String>(json['mode']),
      startedAt: serializer.fromJson<DateTime>(json['started_at']),
      endedAt: serializer.fromJson<DateTime?>(json['ended_at']),
      capturesAttempted: serializer.fromJson<int>(json['captures_attempted']),
      capturesRejected: serializer.fromJson<int>(json['captures_rejected']),
      sheetsFinalized: serializer.fromJson<int>(json['sheets_finalized']),
      deviceModel: serializer.fromJson<String?>(json['device_model']),
      appVersion: serializer.fromJson<String?>(json['app_version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'examination_id': serializer.toJson<String>(examinationId),
      'mode': serializer.toJson<String>(mode),
      'started_at': serializer.toJson<DateTime>(startedAt),
      'ended_at': serializer.toJson<DateTime?>(endedAt),
      'captures_attempted': serializer.toJson<int>(capturesAttempted),
      'captures_rejected': serializer.toJson<int>(capturesRejected),
      'sheets_finalized': serializer.toJson<int>(sheetsFinalized),
      'device_model': serializer.toJson<String?>(deviceModel),
      'app_version': serializer.toJson<String?>(appVersion),
    };
  }

  ScanSessionRow copyWith({
    String? id,
    String? examinationId,
    String? mode,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? capturesAttempted,
    int? capturesRejected,
    int? sheetsFinalized,
    Value<String?> deviceModel = const Value.absent(),
    Value<String?> appVersion = const Value.absent(),
  }) => ScanSessionRow(
    id: id ?? this.id,
    examinationId: examinationId ?? this.examinationId,
    mode: mode ?? this.mode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    capturesAttempted: capturesAttempted ?? this.capturesAttempted,
    capturesRejected: capturesRejected ?? this.capturesRejected,
    sheetsFinalized: sheetsFinalized ?? this.sheetsFinalized,
    deviceModel: deviceModel.present ? deviceModel.value : this.deviceModel,
    appVersion: appVersion.present ? appVersion.value : this.appVersion,
  );
  ScanSessionRow copyWithCompanion(ScanSessionsCompanion data) {
    return ScanSessionRow(
      id: data.id.present ? data.id.value : this.id,
      examinationId: data.examinationId.present
          ? data.examinationId.value
          : this.examinationId,
      mode: data.mode.present ? data.mode.value : this.mode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      capturesAttempted: data.capturesAttempted.present
          ? data.capturesAttempted.value
          : this.capturesAttempted,
      capturesRejected: data.capturesRejected.present
          ? data.capturesRejected.value
          : this.capturesRejected,
      sheetsFinalized: data.sheetsFinalized.present
          ? data.sheetsFinalized.value
          : this.sheetsFinalized,
      deviceModel: data.deviceModel.present
          ? data.deviceModel.value
          : this.deviceModel,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanSessionRow(')
          ..write('id: $id, ')
          ..write('examinationId: $examinationId, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('capturesAttempted: $capturesAttempted, ')
          ..write('capturesRejected: $capturesRejected, ')
          ..write('sheetsFinalized: $sheetsFinalized, ')
          ..write('deviceModel: $deviceModel, ')
          ..write('appVersion: $appVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    examinationId,
    mode,
    startedAt,
    endedAt,
    capturesAttempted,
    capturesRejected,
    sheetsFinalized,
    deviceModel,
    appVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanSessionRow &&
          other.id == this.id &&
          other.examinationId == this.examinationId &&
          other.mode == this.mode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.capturesAttempted == this.capturesAttempted &&
          other.capturesRejected == this.capturesRejected &&
          other.sheetsFinalized == this.sheetsFinalized &&
          other.deviceModel == this.deviceModel &&
          other.appVersion == this.appVersion);
}

class ScanSessionsCompanion extends UpdateCompanion<ScanSessionRow> {
  final Value<String> id;
  final Value<String> examinationId;
  final Value<String> mode;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> capturesAttempted;
  final Value<int> capturesRejected;
  final Value<int> sheetsFinalized;
  final Value<String?> deviceModel;
  final Value<String?> appVersion;
  final Value<int> rowid;
  const ScanSessionsCompanion({
    this.id = const Value.absent(),
    this.examinationId = const Value.absent(),
    this.mode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.capturesAttempted = const Value.absent(),
    this.capturesRejected = const Value.absent(),
    this.sheetsFinalized = const Value.absent(),
    this.deviceModel = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScanSessionsCompanion.insert({
    required String id,
    required String examinationId,
    required String mode,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.capturesAttempted = const Value.absent(),
    this.capturesRejected = const Value.absent(),
    this.sheetsFinalized = const Value.absent(),
    this.deviceModel = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       examinationId = Value(examinationId),
       mode = Value(mode),
       startedAt = Value(startedAt);
  static Insertable<ScanSessionRow> custom({
    Expression<String>? id,
    Expression<String>? examinationId,
    Expression<String>? mode,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? capturesAttempted,
    Expression<int>? capturesRejected,
    Expression<int>? sheetsFinalized,
    Expression<String>? deviceModel,
    Expression<String>? appVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (examinationId != null) 'examination_id': examinationId,
      if (mode != null) 'mode': mode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (capturesAttempted != null) 'captures_attempted': capturesAttempted,
      if (capturesRejected != null) 'captures_rejected': capturesRejected,
      if (sheetsFinalized != null) 'sheets_finalized': sheetsFinalized,
      if (deviceModel != null) 'device_model': deviceModel,
      if (appVersion != null) 'app_version': appVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScanSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? examinationId,
    Value<String>? mode,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? capturesAttempted,
    Value<int>? capturesRejected,
    Value<int>? sheetsFinalized,
    Value<String?>? deviceModel,
    Value<String?>? appVersion,
    Value<int>? rowid,
  }) {
    return ScanSessionsCompanion(
      id: id ?? this.id,
      examinationId: examinationId ?? this.examinationId,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      capturesAttempted: capturesAttempted ?? this.capturesAttempted,
      capturesRejected: capturesRejected ?? this.capturesRejected,
      sheetsFinalized: sheetsFinalized ?? this.sheetsFinalized,
      deviceModel: deviceModel ?? this.deviceModel,
      appVersion: appVersion ?? this.appVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (examinationId.present) {
      map['examination_id'] = Variable<String>(examinationId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (capturesAttempted.present) {
      map['captures_attempted'] = Variable<int>(capturesAttempted.value);
    }
    if (capturesRejected.present) {
      map['captures_rejected'] = Variable<int>(capturesRejected.value);
    }
    if (sheetsFinalized.present) {
      map['sheets_finalized'] = Variable<int>(sheetsFinalized.value);
    }
    if (deviceModel.present) {
      map['device_model'] = Variable<String>(deviceModel.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanSessionsCompanion(')
          ..write('id: $id, ')
          ..write('examinationId: $examinationId, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('capturesAttempted: $capturesAttempted, ')
          ..write('capturesRejected: $capturesRejected, ')
          ..write('sheetsFinalized: $sheetsFinalized, ')
          ..write('deviceModel: $deviceModel, ')
          ..write('appVersion: $appVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AnswerSheets extends Table with TableInfo<AnswerSheets, AnswerSheetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AnswerSheets(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _examinationIdMeta = const VerificationMeta(
    'examinationId',
  );
  late final GeneratedColumn<String> examinationId = GeneratedColumn<String>(
    'examination_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES examinations(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _examinationVersionIdMeta =
      const VerificationMeta('examinationVersionId');
  late final GeneratedColumn<String> examinationVersionId =
      GeneratedColumn<String>(
        'examination_version_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES examination_versions(id)',
      );
  static const VerificationMeta _scanSessionIdMeta = const VerificationMeta(
    'scanSessionId',
  );
  late final GeneratedColumn<String> scanSessionId = GeneratedColumn<String>(
    'scan_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES scan_sessions(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _printedSheetIdMeta = const VerificationMeta(
    'printedSheetId',
  );
  late final GeneratedColumn<String> printedSheetId = GeneratedColumn<String>(
    'printed_sheet_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES printed_sheets(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES students(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _detectedStudentNoMeta = const VerificationMeta(
    'detectedStudentNo',
  );
  late final GeneratedColumn<String> detectedStudentNo =
      GeneratedColumn<String>(
        'detected_student_no',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'CHECK (detected_student_no IS NULL OR length(detected_student_no) <= 30)',
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'needs_review\', \'finalized\', \'rejected\', \'superseded\'))',
  );
  static const VerificationMeta _submissionKeyMeta = const VerificationMeta(
    'submissionKey',
  );
  late final GeneratedColumn<String> submissionKey = GeneratedColumn<String>(
    'submission_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (submission_key IS NULL OR length(submission_key) = 64)',
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _rectifiedImagePathMeta =
      const VerificationMeta('rectifiedImagePath');
  late final GeneratedColumn<String> rectifiedImagePath =
      GeneratedColumn<String>(
        'rectified_image_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _omrEngineVersionMeta = const VerificationMeta(
    'omrEngineVersion',
  );
  late final GeneratedColumn<String> omrEngineVersion = GeneratedColumn<String>(
    'omr_engine_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _omrPayloadMeta = const VerificationMeta(
    'omrPayload',
  );
  late final GeneratedColumn<String> omrPayload = GeneratedColumn<String>(
    'omr_payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _qualityScoreMeta = const VerificationMeta(
    'qualityScore',
  );
  late final GeneratedColumn<double> qualityScore = GeneratedColumn<double>(
    'quality_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (quality_score IS NULL OR quality_score BETWEEN 0 AND 1)',
  );
  static const VerificationMeta _flaggedCountMeta = const VerificationMeta(
    'flaggedCount',
  );
  late final GeneratedColumn<int> flaggedCount = GeneratedColumn<int>(
    'flagged_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (flagged_count >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _finalizedAtMeta = const VerificationMeta(
    'finalizedAt',
  );
  late final GeneratedColumn<DateTime> finalizedAt = GeneratedColumn<DateTime>(
    'finalized_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    examinationId,
    examinationVersionId,
    scanSessionId,
    printedSheetId,
    studentId,
    detectedStudentNo,
    status,
    submissionKey,
    imagePath,
    rectifiedImagePath,
    omrEngineVersion,
    omrPayload,
    qualityScore,
    flaggedCount,
    capturedAt,
    finalizedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'answer_sheets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnswerSheetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('examination_id')) {
      context.handle(
        _examinationIdMeta,
        examinationId.isAcceptableOrUnknown(
          data['examination_id']!,
          _examinationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_examinationIdMeta);
    }
    if (data.containsKey('examination_version_id')) {
      context.handle(
        _examinationVersionIdMeta,
        examinationVersionId.isAcceptableOrUnknown(
          data['examination_version_id']!,
          _examinationVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('scan_session_id')) {
      context.handle(
        _scanSessionIdMeta,
        scanSessionId.isAcceptableOrUnknown(
          data['scan_session_id']!,
          _scanSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('printed_sheet_id')) {
      context.handle(
        _printedSheetIdMeta,
        printedSheetId.isAcceptableOrUnknown(
          data['printed_sheet_id']!,
          _printedSheetIdMeta,
        ),
      );
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    }
    if (data.containsKey('detected_student_no')) {
      context.handle(
        _detectedStudentNoMeta,
        detectedStudentNo.isAcceptableOrUnknown(
          data['detected_student_no']!,
          _detectedStudentNoMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('submission_key')) {
      context.handle(
        _submissionKeyMeta,
        submissionKey.isAcceptableOrUnknown(
          data['submission_key']!,
          _submissionKeyMeta,
        ),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('rectified_image_path')) {
      context.handle(
        _rectifiedImagePathMeta,
        rectifiedImagePath.isAcceptableOrUnknown(
          data['rectified_image_path']!,
          _rectifiedImagePathMeta,
        ),
      );
    }
    if (data.containsKey('omr_engine_version')) {
      context.handle(
        _omrEngineVersionMeta,
        omrEngineVersion.isAcceptableOrUnknown(
          data['omr_engine_version']!,
          _omrEngineVersionMeta,
        ),
      );
    }
    if (data.containsKey('omr_payload')) {
      context.handle(
        _omrPayloadMeta,
        omrPayload.isAcceptableOrUnknown(data['omr_payload']!, _omrPayloadMeta),
      );
    }
    if (data.containsKey('quality_score')) {
      context.handle(
        _qualityScoreMeta,
        qualityScore.isAcceptableOrUnknown(
          data['quality_score']!,
          _qualityScoreMeta,
        ),
      );
    }
    if (data.containsKey('flagged_count')) {
      context.handle(
        _flaggedCountMeta,
        flaggedCount.isAcceptableOrUnknown(
          data['flagged_count']!,
          _flaggedCountMeta,
        ),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('finalized_at')) {
      context.handle(
        _finalizedAtMeta,
        finalizedAt.isAcceptableOrUnknown(
          data['finalized_at']!,
          _finalizedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnswerSheetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnswerSheetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      examinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examination_id'],
      )!,
      examinationVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examination_version_id'],
      ),
      scanSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_session_id'],
      ),
      printedSheetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}printed_sheet_id'],
      ),
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      ),
      detectedStudentNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detected_student_no'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      submissionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submission_key'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      rectifiedImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rectified_image_path'],
      ),
      omrEngineVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}omr_engine_version'],
      ),
      omrPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}omr_payload'],
      ),
      qualityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quality_score'],
      ),
      flaggedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flagged_count'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      finalizedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finalized_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  AnswerSheets createAlias(String alias) {
    return AnswerSheets(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK(status <> \'finalized\' OR(submission_key IS NOT NULL AND finalized_at IS NOT NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class AnswerSheetRow extends DataClass implements Insertable<AnswerSheetRow> {
  final String id;
  final String examinationId;
  final String? examinationVersionId;
  final String? scanSessionId;
  final String? printedSheetId;
  final String? studentId;

  /// Number read from the shaded grid or QR, kept even if no roster match.
  final String? detectedStudentNo;
  final String status;

  /// SHA-256 hex of (exam, version, student identity, paper identity); set on finalize.
  final String? submissionKey;
  final String? imagePath;
  final String? rectifiedImagePath;
  final String? omrEngineVersion;
  final String? omrPayload;
  final double? qualityScore;
  final int flaggedCount;
  final DateTime capturedAt;
  final DateTime? finalizedAt;
  final DateTime updatedAt;
  const AnswerSheetRow({
    required this.id,
    required this.examinationId,
    this.examinationVersionId,
    this.scanSessionId,
    this.printedSheetId,
    this.studentId,
    this.detectedStudentNo,
    required this.status,
    this.submissionKey,
    this.imagePath,
    this.rectifiedImagePath,
    this.omrEngineVersion,
    this.omrPayload,
    this.qualityScore,
    required this.flaggedCount,
    required this.capturedAt,
    this.finalizedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['examination_id'] = Variable<String>(examinationId);
    if (!nullToAbsent || examinationVersionId != null) {
      map['examination_version_id'] = Variable<String>(examinationVersionId);
    }
    if (!nullToAbsent || scanSessionId != null) {
      map['scan_session_id'] = Variable<String>(scanSessionId);
    }
    if (!nullToAbsent || printedSheetId != null) {
      map['printed_sheet_id'] = Variable<String>(printedSheetId);
    }
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<String>(studentId);
    }
    if (!nullToAbsent || detectedStudentNo != null) {
      map['detected_student_no'] = Variable<String>(detectedStudentNo);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || submissionKey != null) {
      map['submission_key'] = Variable<String>(submissionKey);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || rectifiedImagePath != null) {
      map['rectified_image_path'] = Variable<String>(rectifiedImagePath);
    }
    if (!nullToAbsent || omrEngineVersion != null) {
      map['omr_engine_version'] = Variable<String>(omrEngineVersion);
    }
    if (!nullToAbsent || omrPayload != null) {
      map['omr_payload'] = Variable<String>(omrPayload);
    }
    if (!nullToAbsent || qualityScore != null) {
      map['quality_score'] = Variable<double>(qualityScore);
    }
    map['flagged_count'] = Variable<int>(flaggedCount);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    if (!nullToAbsent || finalizedAt != null) {
      map['finalized_at'] = Variable<DateTime>(finalizedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AnswerSheetsCompanion toCompanion(bool nullToAbsent) {
    return AnswerSheetsCompanion(
      id: Value(id),
      examinationId: Value(examinationId),
      examinationVersionId: examinationVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(examinationVersionId),
      scanSessionId: scanSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(scanSessionId),
      printedSheetId: printedSheetId == null && nullToAbsent
          ? const Value.absent()
          : Value(printedSheetId),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      detectedStudentNo: detectedStudentNo == null && nullToAbsent
          ? const Value.absent()
          : Value(detectedStudentNo),
      status: Value(status),
      submissionKey: submissionKey == null && nullToAbsent
          ? const Value.absent()
          : Value(submissionKey),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      rectifiedImagePath: rectifiedImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(rectifiedImagePath),
      omrEngineVersion: omrEngineVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(omrEngineVersion),
      omrPayload: omrPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(omrPayload),
      qualityScore: qualityScore == null && nullToAbsent
          ? const Value.absent()
          : Value(qualityScore),
      flaggedCount: Value(flaggedCount),
      capturedAt: Value(capturedAt),
      finalizedAt: finalizedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finalizedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AnswerSheetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnswerSheetRow(
      id: serializer.fromJson<String>(json['id']),
      examinationId: serializer.fromJson<String>(json['examination_id']),
      examinationVersionId: serializer.fromJson<String?>(
        json['examination_version_id'],
      ),
      scanSessionId: serializer.fromJson<String?>(json['scan_session_id']),
      printedSheetId: serializer.fromJson<String?>(json['printed_sheet_id']),
      studentId: serializer.fromJson<String?>(json['student_id']),
      detectedStudentNo: serializer.fromJson<String?>(
        json['detected_student_no'],
      ),
      status: serializer.fromJson<String>(json['status']),
      submissionKey: serializer.fromJson<String?>(json['submission_key']),
      imagePath: serializer.fromJson<String?>(json['image_path']),
      rectifiedImagePath: serializer.fromJson<String?>(
        json['rectified_image_path'],
      ),
      omrEngineVersion: serializer.fromJson<String?>(
        json['omr_engine_version'],
      ),
      omrPayload: serializer.fromJson<String?>(json['omr_payload']),
      qualityScore: serializer.fromJson<double?>(json['quality_score']),
      flaggedCount: serializer.fromJson<int>(json['flagged_count']),
      capturedAt: serializer.fromJson<DateTime>(json['captured_at']),
      finalizedAt: serializer.fromJson<DateTime?>(json['finalized_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'examination_id': serializer.toJson<String>(examinationId),
      'examination_version_id': serializer.toJson<String?>(
        examinationVersionId,
      ),
      'scan_session_id': serializer.toJson<String?>(scanSessionId),
      'printed_sheet_id': serializer.toJson<String?>(printedSheetId),
      'student_id': serializer.toJson<String?>(studentId),
      'detected_student_no': serializer.toJson<String?>(detectedStudentNo),
      'status': serializer.toJson<String>(status),
      'submission_key': serializer.toJson<String?>(submissionKey),
      'image_path': serializer.toJson<String?>(imagePath),
      'rectified_image_path': serializer.toJson<String?>(rectifiedImagePath),
      'omr_engine_version': serializer.toJson<String?>(omrEngineVersion),
      'omr_payload': serializer.toJson<String?>(omrPayload),
      'quality_score': serializer.toJson<double?>(qualityScore),
      'flagged_count': serializer.toJson<int>(flaggedCount),
      'captured_at': serializer.toJson<DateTime>(capturedAt),
      'finalized_at': serializer.toJson<DateTime?>(finalizedAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AnswerSheetRow copyWith({
    String? id,
    String? examinationId,
    Value<String?> examinationVersionId = const Value.absent(),
    Value<String?> scanSessionId = const Value.absent(),
    Value<String?> printedSheetId = const Value.absent(),
    Value<String?> studentId = const Value.absent(),
    Value<String?> detectedStudentNo = const Value.absent(),
    String? status,
    Value<String?> submissionKey = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    Value<String?> rectifiedImagePath = const Value.absent(),
    Value<String?> omrEngineVersion = const Value.absent(),
    Value<String?> omrPayload = const Value.absent(),
    Value<double?> qualityScore = const Value.absent(),
    int? flaggedCount,
    DateTime? capturedAt,
    Value<DateTime?> finalizedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => AnswerSheetRow(
    id: id ?? this.id,
    examinationId: examinationId ?? this.examinationId,
    examinationVersionId: examinationVersionId.present
        ? examinationVersionId.value
        : this.examinationVersionId,
    scanSessionId: scanSessionId.present
        ? scanSessionId.value
        : this.scanSessionId,
    printedSheetId: printedSheetId.present
        ? printedSheetId.value
        : this.printedSheetId,
    studentId: studentId.present ? studentId.value : this.studentId,
    detectedStudentNo: detectedStudentNo.present
        ? detectedStudentNo.value
        : this.detectedStudentNo,
    status: status ?? this.status,
    submissionKey: submissionKey.present
        ? submissionKey.value
        : this.submissionKey,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    rectifiedImagePath: rectifiedImagePath.present
        ? rectifiedImagePath.value
        : this.rectifiedImagePath,
    omrEngineVersion: omrEngineVersion.present
        ? omrEngineVersion.value
        : this.omrEngineVersion,
    omrPayload: omrPayload.present ? omrPayload.value : this.omrPayload,
    qualityScore: qualityScore.present ? qualityScore.value : this.qualityScore,
    flaggedCount: flaggedCount ?? this.flaggedCount,
    capturedAt: capturedAt ?? this.capturedAt,
    finalizedAt: finalizedAt.present ? finalizedAt.value : this.finalizedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AnswerSheetRow copyWithCompanion(AnswerSheetsCompanion data) {
    return AnswerSheetRow(
      id: data.id.present ? data.id.value : this.id,
      examinationId: data.examinationId.present
          ? data.examinationId.value
          : this.examinationId,
      examinationVersionId: data.examinationVersionId.present
          ? data.examinationVersionId.value
          : this.examinationVersionId,
      scanSessionId: data.scanSessionId.present
          ? data.scanSessionId.value
          : this.scanSessionId,
      printedSheetId: data.printedSheetId.present
          ? data.printedSheetId.value
          : this.printedSheetId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      detectedStudentNo: data.detectedStudentNo.present
          ? data.detectedStudentNo.value
          : this.detectedStudentNo,
      status: data.status.present ? data.status.value : this.status,
      submissionKey: data.submissionKey.present
          ? data.submissionKey.value
          : this.submissionKey,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      rectifiedImagePath: data.rectifiedImagePath.present
          ? data.rectifiedImagePath.value
          : this.rectifiedImagePath,
      omrEngineVersion: data.omrEngineVersion.present
          ? data.omrEngineVersion.value
          : this.omrEngineVersion,
      omrPayload: data.omrPayload.present
          ? data.omrPayload.value
          : this.omrPayload,
      qualityScore: data.qualityScore.present
          ? data.qualityScore.value
          : this.qualityScore,
      flaggedCount: data.flaggedCount.present
          ? data.flaggedCount.value
          : this.flaggedCount,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      finalizedAt: data.finalizedAt.present
          ? data.finalizedAt.value
          : this.finalizedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnswerSheetRow(')
          ..write('id: $id, ')
          ..write('examinationId: $examinationId, ')
          ..write('examinationVersionId: $examinationVersionId, ')
          ..write('scanSessionId: $scanSessionId, ')
          ..write('printedSheetId: $printedSheetId, ')
          ..write('studentId: $studentId, ')
          ..write('detectedStudentNo: $detectedStudentNo, ')
          ..write('status: $status, ')
          ..write('submissionKey: $submissionKey, ')
          ..write('imagePath: $imagePath, ')
          ..write('rectifiedImagePath: $rectifiedImagePath, ')
          ..write('omrEngineVersion: $omrEngineVersion, ')
          ..write('omrPayload: $omrPayload, ')
          ..write('qualityScore: $qualityScore, ')
          ..write('flaggedCount: $flaggedCount, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('finalizedAt: $finalizedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    examinationId,
    examinationVersionId,
    scanSessionId,
    printedSheetId,
    studentId,
    detectedStudentNo,
    status,
    submissionKey,
    imagePath,
    rectifiedImagePath,
    omrEngineVersion,
    omrPayload,
    qualityScore,
    flaggedCount,
    capturedAt,
    finalizedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnswerSheetRow &&
          other.id == this.id &&
          other.examinationId == this.examinationId &&
          other.examinationVersionId == this.examinationVersionId &&
          other.scanSessionId == this.scanSessionId &&
          other.printedSheetId == this.printedSheetId &&
          other.studentId == this.studentId &&
          other.detectedStudentNo == this.detectedStudentNo &&
          other.status == this.status &&
          other.submissionKey == this.submissionKey &&
          other.imagePath == this.imagePath &&
          other.rectifiedImagePath == this.rectifiedImagePath &&
          other.omrEngineVersion == this.omrEngineVersion &&
          other.omrPayload == this.omrPayload &&
          other.qualityScore == this.qualityScore &&
          other.flaggedCount == this.flaggedCount &&
          other.capturedAt == this.capturedAt &&
          other.finalizedAt == this.finalizedAt &&
          other.updatedAt == this.updatedAt);
}

class AnswerSheetsCompanion extends UpdateCompanion<AnswerSheetRow> {
  final Value<String> id;
  final Value<String> examinationId;
  final Value<String?> examinationVersionId;
  final Value<String?> scanSessionId;
  final Value<String?> printedSheetId;
  final Value<String?> studentId;
  final Value<String?> detectedStudentNo;
  final Value<String> status;
  final Value<String?> submissionKey;
  final Value<String?> imagePath;
  final Value<String?> rectifiedImagePath;
  final Value<String?> omrEngineVersion;
  final Value<String?> omrPayload;
  final Value<double?> qualityScore;
  final Value<int> flaggedCount;
  final Value<DateTime> capturedAt;
  final Value<DateTime?> finalizedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AnswerSheetsCompanion({
    this.id = const Value.absent(),
    this.examinationId = const Value.absent(),
    this.examinationVersionId = const Value.absent(),
    this.scanSessionId = const Value.absent(),
    this.printedSheetId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.detectedStudentNo = const Value.absent(),
    this.status = const Value.absent(),
    this.submissionKey = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.rectifiedImagePath = const Value.absent(),
    this.omrEngineVersion = const Value.absent(),
    this.omrPayload = const Value.absent(),
    this.qualityScore = const Value.absent(),
    this.flaggedCount = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.finalizedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnswerSheetsCompanion.insert({
    required String id,
    required String examinationId,
    this.examinationVersionId = const Value.absent(),
    this.scanSessionId = const Value.absent(),
    this.printedSheetId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.detectedStudentNo = const Value.absent(),
    required String status,
    this.submissionKey = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.rectifiedImagePath = const Value.absent(),
    this.omrEngineVersion = const Value.absent(),
    this.omrPayload = const Value.absent(),
    this.qualityScore = const Value.absent(),
    this.flaggedCount = const Value.absent(),
    required DateTime capturedAt,
    this.finalizedAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       examinationId = Value(examinationId),
       status = Value(status),
       capturedAt = Value(capturedAt),
       updatedAt = Value(updatedAt);
  static Insertable<AnswerSheetRow> custom({
    Expression<String>? id,
    Expression<String>? examinationId,
    Expression<String>? examinationVersionId,
    Expression<String>? scanSessionId,
    Expression<String>? printedSheetId,
    Expression<String>? studentId,
    Expression<String>? detectedStudentNo,
    Expression<String>? status,
    Expression<String>? submissionKey,
    Expression<String>? imagePath,
    Expression<String>? rectifiedImagePath,
    Expression<String>? omrEngineVersion,
    Expression<String>? omrPayload,
    Expression<double>? qualityScore,
    Expression<int>? flaggedCount,
    Expression<DateTime>? capturedAt,
    Expression<DateTime>? finalizedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (examinationId != null) 'examination_id': examinationId,
      if (examinationVersionId != null)
        'examination_version_id': examinationVersionId,
      if (scanSessionId != null) 'scan_session_id': scanSessionId,
      if (printedSheetId != null) 'printed_sheet_id': printedSheetId,
      if (studentId != null) 'student_id': studentId,
      if (detectedStudentNo != null) 'detected_student_no': detectedStudentNo,
      if (status != null) 'status': status,
      if (submissionKey != null) 'submission_key': submissionKey,
      if (imagePath != null) 'image_path': imagePath,
      if (rectifiedImagePath != null)
        'rectified_image_path': rectifiedImagePath,
      if (omrEngineVersion != null) 'omr_engine_version': omrEngineVersion,
      if (omrPayload != null) 'omr_payload': omrPayload,
      if (qualityScore != null) 'quality_score': qualityScore,
      if (flaggedCount != null) 'flagged_count': flaggedCount,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (finalizedAt != null) 'finalized_at': finalizedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnswerSheetsCompanion copyWith({
    Value<String>? id,
    Value<String>? examinationId,
    Value<String?>? examinationVersionId,
    Value<String?>? scanSessionId,
    Value<String?>? printedSheetId,
    Value<String?>? studentId,
    Value<String?>? detectedStudentNo,
    Value<String>? status,
    Value<String?>? submissionKey,
    Value<String?>? imagePath,
    Value<String?>? rectifiedImagePath,
    Value<String?>? omrEngineVersion,
    Value<String?>? omrPayload,
    Value<double?>? qualityScore,
    Value<int>? flaggedCount,
    Value<DateTime>? capturedAt,
    Value<DateTime?>? finalizedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AnswerSheetsCompanion(
      id: id ?? this.id,
      examinationId: examinationId ?? this.examinationId,
      examinationVersionId: examinationVersionId ?? this.examinationVersionId,
      scanSessionId: scanSessionId ?? this.scanSessionId,
      printedSheetId: printedSheetId ?? this.printedSheetId,
      studentId: studentId ?? this.studentId,
      detectedStudentNo: detectedStudentNo ?? this.detectedStudentNo,
      status: status ?? this.status,
      submissionKey: submissionKey ?? this.submissionKey,
      imagePath: imagePath ?? this.imagePath,
      rectifiedImagePath: rectifiedImagePath ?? this.rectifiedImagePath,
      omrEngineVersion: omrEngineVersion ?? this.omrEngineVersion,
      omrPayload: omrPayload ?? this.omrPayload,
      qualityScore: qualityScore ?? this.qualityScore,
      flaggedCount: flaggedCount ?? this.flaggedCount,
      capturedAt: capturedAt ?? this.capturedAt,
      finalizedAt: finalizedAt ?? this.finalizedAt,
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
    if (examinationId.present) {
      map['examination_id'] = Variable<String>(examinationId.value);
    }
    if (examinationVersionId.present) {
      map['examination_version_id'] = Variable<String>(
        examinationVersionId.value,
      );
    }
    if (scanSessionId.present) {
      map['scan_session_id'] = Variable<String>(scanSessionId.value);
    }
    if (printedSheetId.present) {
      map['printed_sheet_id'] = Variable<String>(printedSheetId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (detectedStudentNo.present) {
      map['detected_student_no'] = Variable<String>(detectedStudentNo.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (submissionKey.present) {
      map['submission_key'] = Variable<String>(submissionKey.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (rectifiedImagePath.present) {
      map['rectified_image_path'] = Variable<String>(rectifiedImagePath.value);
    }
    if (omrEngineVersion.present) {
      map['omr_engine_version'] = Variable<String>(omrEngineVersion.value);
    }
    if (omrPayload.present) {
      map['omr_payload'] = Variable<String>(omrPayload.value);
    }
    if (qualityScore.present) {
      map['quality_score'] = Variable<double>(qualityScore.value);
    }
    if (flaggedCount.present) {
      map['flagged_count'] = Variable<int>(flaggedCount.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (finalizedAt.present) {
      map['finalized_at'] = Variable<DateTime>(finalizedAt.value);
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
    return (StringBuffer('AnswerSheetsCompanion(')
          ..write('id: $id, ')
          ..write('examinationId: $examinationId, ')
          ..write('examinationVersionId: $examinationVersionId, ')
          ..write('scanSessionId: $scanSessionId, ')
          ..write('printedSheetId: $printedSheetId, ')
          ..write('studentId: $studentId, ')
          ..write('detectedStudentNo: $detectedStudentNo, ')
          ..write('status: $status, ')
          ..write('submissionKey: $submissionKey, ')
          ..write('imagePath: $imagePath, ')
          ..write('rectifiedImagePath: $rectifiedImagePath, ')
          ..write('omrEngineVersion: $omrEngineVersion, ')
          ..write('omrPayload: $omrPayload, ')
          ..write('qualityScore: $qualityScore, ')
          ..write('flaggedCount: $flaggedCount, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('finalizedAt: $finalizedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class StudentAnswers extends Table
    with TableInfo<StudentAnswers, StudentAnswerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  StudentAnswers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _answerSheetIdMeta = const VerificationMeta(
    'answerSheetId',
  );
  late final GeneratedColumn<String> answerSheetId = GeneratedColumn<String>(
    'answer_sheet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES answer_sheets(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _questionNoMeta = const VerificationMeta(
    'questionNo',
  );
  late final GeneratedColumn<int> questionNo = GeneratedColumn<int>(
    'question_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (question_no BETWEEN 1 AND 100)',
  );
  static const VerificationMeta _detectedStateMeta = const VerificationMeta(
    'detectedState',
  );
  late final GeneratedColumn<String> detectedState = GeneratedColumn<String>(
    'detected_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (detected_state IN (\'answered\', \'blank\', \'multiple\', \'uncertain\'))',
  );
  static const VerificationMeta _detectedMaskMeta = const VerificationMeta(
    'detectedMask',
  );
  late final GeneratedColumn<int> detectedMask = GeneratedColumn<int>(
    'detected_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (detected_mask BETWEEN 0 AND 31)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _bubbleScoresMeta = const VerificationMeta(
    'bubbleScores',
  );
  late final GeneratedColumn<String> bubbleScores = GeneratedColumn<String>(
    'bubble_scores',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (confidence BETWEEN 0 AND 1)',
  );
  static const VerificationMeta _finalMaskMeta = const VerificationMeta(
    'finalMask',
  );
  late final GeneratedColumn<int> finalMask = GeneratedColumn<int>(
    'final_mask',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (final_mask IS NULL OR final_mask BETWEEN 0 AND 31)',
  );
  static const VerificationMeta _resolvedByMeta = const VerificationMeta(
    'resolvedBy',
  );
  late final GeneratedColumn<String> resolvedBy = GeneratedColumn<String>(
    'resolved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (resolved_by IS NULL OR resolved_by IN (\'engine\', \'instructor\'))',
  );
  static const VerificationMeta _reviewNoteMeta = const VerificationMeta(
    'reviewNote',
  );
  late final GeneratedColumn<String> reviewNote = GeneratedColumn<String>(
    'review_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (review_note IS NULL OR length(review_note) <= 300)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    answerSheetId,
    questionNo,
    detectedState,
    detectedMask,
    bubbleScores,
    confidence,
    finalMask,
    resolvedBy,
    reviewNote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'student_answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudentAnswerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('answer_sheet_id')) {
      context.handle(
        _answerSheetIdMeta,
        answerSheetId.isAcceptableOrUnknown(
          data['answer_sheet_id']!,
          _answerSheetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_answerSheetIdMeta);
    }
    if (data.containsKey('question_no')) {
      context.handle(
        _questionNoMeta,
        questionNo.isAcceptableOrUnknown(data['question_no']!, _questionNoMeta),
      );
    } else if (isInserting) {
      context.missing(_questionNoMeta);
    }
    if (data.containsKey('detected_state')) {
      context.handle(
        _detectedStateMeta,
        detectedState.isAcceptableOrUnknown(
          data['detected_state']!,
          _detectedStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_detectedStateMeta);
    }
    if (data.containsKey('detected_mask')) {
      context.handle(
        _detectedMaskMeta,
        detectedMask.isAcceptableOrUnknown(
          data['detected_mask']!,
          _detectedMaskMeta,
        ),
      );
    }
    if (data.containsKey('bubble_scores')) {
      context.handle(
        _bubbleScoresMeta,
        bubbleScores.isAcceptableOrUnknown(
          data['bubble_scores']!,
          _bubbleScoresMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bubbleScoresMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('final_mask')) {
      context.handle(
        _finalMaskMeta,
        finalMask.isAcceptableOrUnknown(data['final_mask']!, _finalMaskMeta),
      );
    }
    if (data.containsKey('resolved_by')) {
      context.handle(
        _resolvedByMeta,
        resolvedBy.isAcceptableOrUnknown(data['resolved_by']!, _resolvedByMeta),
      );
    }
    if (data.containsKey('review_note')) {
      context.handle(
        _reviewNoteMeta,
        reviewNote.isAcceptableOrUnknown(data['review_note']!, _reviewNoteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {answerSheetId, questionNo};
  @override
  StudentAnswerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentAnswerRow(
      answerSheetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_sheet_id'],
      )!,
      questionNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_no'],
      )!,
      detectedState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detected_state'],
      )!,
      detectedMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}detected_mask'],
      )!,
      bubbleScores: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bubble_scores'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      finalMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}final_mask'],
      ),
      resolvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_by'],
      ),
      reviewNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_note'],
      ),
    );
  }

  @override
  StudentAnswers createAlias(String alias) {
    return StudentAnswers(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(answer_sheet_id, question_no)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class StudentAnswerRow extends DataClass
    implements Insertable<StudentAnswerRow> {
  final String answerSheetId;
  final int questionNo;
  final String detectedState;
  final int detectedMask;

  /// JSON array with one normalized darkness score (0..1) per choice.
  final String bubbleScores;
  final double confidence;

  /// Answer used for grading. NULL while an uncertain answer is unresolved.
  final int? finalMask;
  final String? resolvedBy;
  final String? reviewNote;
  const StudentAnswerRow({
    required this.answerSheetId,
    required this.questionNo,
    required this.detectedState,
    required this.detectedMask,
    required this.bubbleScores,
    required this.confidence,
    this.finalMask,
    this.resolvedBy,
    this.reviewNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['answer_sheet_id'] = Variable<String>(answerSheetId);
    map['question_no'] = Variable<int>(questionNo);
    map['detected_state'] = Variable<String>(detectedState);
    map['detected_mask'] = Variable<int>(detectedMask);
    map['bubble_scores'] = Variable<String>(bubbleScores);
    map['confidence'] = Variable<double>(confidence);
    if (!nullToAbsent || finalMask != null) {
      map['final_mask'] = Variable<int>(finalMask);
    }
    if (!nullToAbsent || resolvedBy != null) {
      map['resolved_by'] = Variable<String>(resolvedBy);
    }
    if (!nullToAbsent || reviewNote != null) {
      map['review_note'] = Variable<String>(reviewNote);
    }
    return map;
  }

  StudentAnswersCompanion toCompanion(bool nullToAbsent) {
    return StudentAnswersCompanion(
      answerSheetId: Value(answerSheetId),
      questionNo: Value(questionNo),
      detectedState: Value(detectedState),
      detectedMask: Value(detectedMask),
      bubbleScores: Value(bubbleScores),
      confidence: Value(confidence),
      finalMask: finalMask == null && nullToAbsent
          ? const Value.absent()
          : Value(finalMask),
      resolvedBy: resolvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedBy),
      reviewNote: reviewNote == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewNote),
    );
  }

  factory StudentAnswerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentAnswerRow(
      answerSheetId: serializer.fromJson<String>(json['answer_sheet_id']),
      questionNo: serializer.fromJson<int>(json['question_no']),
      detectedState: serializer.fromJson<String>(json['detected_state']),
      detectedMask: serializer.fromJson<int>(json['detected_mask']),
      bubbleScores: serializer.fromJson<String>(json['bubble_scores']),
      confidence: serializer.fromJson<double>(json['confidence']),
      finalMask: serializer.fromJson<int?>(json['final_mask']),
      resolvedBy: serializer.fromJson<String?>(json['resolved_by']),
      reviewNote: serializer.fromJson<String?>(json['review_note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'answer_sheet_id': serializer.toJson<String>(answerSheetId),
      'question_no': serializer.toJson<int>(questionNo),
      'detected_state': serializer.toJson<String>(detectedState),
      'detected_mask': serializer.toJson<int>(detectedMask),
      'bubble_scores': serializer.toJson<String>(bubbleScores),
      'confidence': serializer.toJson<double>(confidence),
      'final_mask': serializer.toJson<int?>(finalMask),
      'resolved_by': serializer.toJson<String?>(resolvedBy),
      'review_note': serializer.toJson<String?>(reviewNote),
    };
  }

  StudentAnswerRow copyWith({
    String? answerSheetId,
    int? questionNo,
    String? detectedState,
    int? detectedMask,
    String? bubbleScores,
    double? confidence,
    Value<int?> finalMask = const Value.absent(),
    Value<String?> resolvedBy = const Value.absent(),
    Value<String?> reviewNote = const Value.absent(),
  }) => StudentAnswerRow(
    answerSheetId: answerSheetId ?? this.answerSheetId,
    questionNo: questionNo ?? this.questionNo,
    detectedState: detectedState ?? this.detectedState,
    detectedMask: detectedMask ?? this.detectedMask,
    bubbleScores: bubbleScores ?? this.bubbleScores,
    confidence: confidence ?? this.confidence,
    finalMask: finalMask.present ? finalMask.value : this.finalMask,
    resolvedBy: resolvedBy.present ? resolvedBy.value : this.resolvedBy,
    reviewNote: reviewNote.present ? reviewNote.value : this.reviewNote,
  );
  StudentAnswerRow copyWithCompanion(StudentAnswersCompanion data) {
    return StudentAnswerRow(
      answerSheetId: data.answerSheetId.present
          ? data.answerSheetId.value
          : this.answerSheetId,
      questionNo: data.questionNo.present
          ? data.questionNo.value
          : this.questionNo,
      detectedState: data.detectedState.present
          ? data.detectedState.value
          : this.detectedState,
      detectedMask: data.detectedMask.present
          ? data.detectedMask.value
          : this.detectedMask,
      bubbleScores: data.bubbleScores.present
          ? data.bubbleScores.value
          : this.bubbleScores,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      finalMask: data.finalMask.present ? data.finalMask.value : this.finalMask,
      resolvedBy: data.resolvedBy.present
          ? data.resolvedBy.value
          : this.resolvedBy,
      reviewNote: data.reviewNote.present
          ? data.reviewNote.value
          : this.reviewNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentAnswerRow(')
          ..write('answerSheetId: $answerSheetId, ')
          ..write('questionNo: $questionNo, ')
          ..write('detectedState: $detectedState, ')
          ..write('detectedMask: $detectedMask, ')
          ..write('bubbleScores: $bubbleScores, ')
          ..write('confidence: $confidence, ')
          ..write('finalMask: $finalMask, ')
          ..write('resolvedBy: $resolvedBy, ')
          ..write('reviewNote: $reviewNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    answerSheetId,
    questionNo,
    detectedState,
    detectedMask,
    bubbleScores,
    confidence,
    finalMask,
    resolvedBy,
    reviewNote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentAnswerRow &&
          other.answerSheetId == this.answerSheetId &&
          other.questionNo == this.questionNo &&
          other.detectedState == this.detectedState &&
          other.detectedMask == this.detectedMask &&
          other.bubbleScores == this.bubbleScores &&
          other.confidence == this.confidence &&
          other.finalMask == this.finalMask &&
          other.resolvedBy == this.resolvedBy &&
          other.reviewNote == this.reviewNote);
}

class StudentAnswersCompanion extends UpdateCompanion<StudentAnswerRow> {
  final Value<String> answerSheetId;
  final Value<int> questionNo;
  final Value<String> detectedState;
  final Value<int> detectedMask;
  final Value<String> bubbleScores;
  final Value<double> confidence;
  final Value<int?> finalMask;
  final Value<String?> resolvedBy;
  final Value<String?> reviewNote;
  final Value<int> rowid;
  const StudentAnswersCompanion({
    this.answerSheetId = const Value.absent(),
    this.questionNo = const Value.absent(),
    this.detectedState = const Value.absent(),
    this.detectedMask = const Value.absent(),
    this.bubbleScores = const Value.absent(),
    this.confidence = const Value.absent(),
    this.finalMask = const Value.absent(),
    this.resolvedBy = const Value.absent(),
    this.reviewNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentAnswersCompanion.insert({
    required String answerSheetId,
    required int questionNo,
    required String detectedState,
    this.detectedMask = const Value.absent(),
    required String bubbleScores,
    required double confidence,
    this.finalMask = const Value.absent(),
    this.resolvedBy = const Value.absent(),
    this.reviewNote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : answerSheetId = Value(answerSheetId),
       questionNo = Value(questionNo),
       detectedState = Value(detectedState),
       bubbleScores = Value(bubbleScores),
       confidence = Value(confidence);
  static Insertable<StudentAnswerRow> custom({
    Expression<String>? answerSheetId,
    Expression<int>? questionNo,
    Expression<String>? detectedState,
    Expression<int>? detectedMask,
    Expression<String>? bubbleScores,
    Expression<double>? confidence,
    Expression<int>? finalMask,
    Expression<String>? resolvedBy,
    Expression<String>? reviewNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (answerSheetId != null) 'answer_sheet_id': answerSheetId,
      if (questionNo != null) 'question_no': questionNo,
      if (detectedState != null) 'detected_state': detectedState,
      if (detectedMask != null) 'detected_mask': detectedMask,
      if (bubbleScores != null) 'bubble_scores': bubbleScores,
      if (confidence != null) 'confidence': confidence,
      if (finalMask != null) 'final_mask': finalMask,
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      if (reviewNote != null) 'review_note': reviewNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentAnswersCompanion copyWith({
    Value<String>? answerSheetId,
    Value<int>? questionNo,
    Value<String>? detectedState,
    Value<int>? detectedMask,
    Value<String>? bubbleScores,
    Value<double>? confidence,
    Value<int?>? finalMask,
    Value<String?>? resolvedBy,
    Value<String?>? reviewNote,
    Value<int>? rowid,
  }) {
    return StudentAnswersCompanion(
      answerSheetId: answerSheetId ?? this.answerSheetId,
      questionNo: questionNo ?? this.questionNo,
      detectedState: detectedState ?? this.detectedState,
      detectedMask: detectedMask ?? this.detectedMask,
      bubbleScores: bubbleScores ?? this.bubbleScores,
      confidence: confidence ?? this.confidence,
      finalMask: finalMask ?? this.finalMask,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      reviewNote: reviewNote ?? this.reviewNote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (answerSheetId.present) {
      map['answer_sheet_id'] = Variable<String>(answerSheetId.value);
    }
    if (questionNo.present) {
      map['question_no'] = Variable<int>(questionNo.value);
    }
    if (detectedState.present) {
      map['detected_state'] = Variable<String>(detectedState.value);
    }
    if (detectedMask.present) {
      map['detected_mask'] = Variable<int>(detectedMask.value);
    }
    if (bubbleScores.present) {
      map['bubble_scores'] = Variable<String>(bubbleScores.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (finalMask.present) {
      map['final_mask'] = Variable<int>(finalMask.value);
    }
    if (resolvedBy.present) {
      map['resolved_by'] = Variable<String>(resolvedBy.value);
    }
    if (reviewNote.present) {
      map['review_note'] = Variable<String>(reviewNote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentAnswersCompanion(')
          ..write('answerSheetId: $answerSheetId, ')
          ..write('questionNo: $questionNo, ')
          ..write('detectedState: $detectedState, ')
          ..write('detectedMask: $detectedMask, ')
          ..write('bubbleScores: $bubbleScores, ')
          ..write('confidence: $confidence, ')
          ..write('finalMask: $finalMask, ')
          ..write('resolvedBy: $resolvedBy, ')
          ..write('reviewNote: $reviewNote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExaminationResults extends Table
    with TableInfo<ExaminationResults, ExaminationResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExaminationResults(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _answerSheetIdMeta = const VerificationMeta(
    'answerSheetId',
  );
  late final GeneratedColumn<String> answerSheetId = GeneratedColumn<String>(
    'answer_sheet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES answer_sheets(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _answerKeyIdMeta = const VerificationMeta(
    'answerKeyId',
  );
  late final GeneratedColumn<String> answerKeyId = GeneratedColumn<String>(
    'answer_key_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES answer_keys(id)',
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (correct_count >= 0)',
  );
  static const VerificationMeta _incorrectCountMeta = const VerificationMeta(
    'incorrectCount',
  );
  late final GeneratedColumn<int> incorrectCount = GeneratedColumn<int>(
    'incorrect_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (incorrect_count >= 0)',
  );
  static const VerificationMeta _blankCountMeta = const VerificationMeta(
    'blankCount',
  );
  late final GeneratedColumn<int> blankCount = GeneratedColumn<int>(
    'blank_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (blank_count >= 0)',
  );
  static const VerificationMeta _multipleCountMeta = const VerificationMeta(
    'multipleCount',
  );
  late final GeneratedColumn<int> multipleCount = GeneratedColumn<int>(
    'multiple_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (multiple_count >= 0)',
  );
  static const VerificationMeta _earnedPointsMeta = const VerificationMeta(
    'earnedPoints',
  );
  late final GeneratedColumn<double> earnedPoints = GeneratedColumn<double>(
    'earned_points',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _possiblePointsMeta = const VerificationMeta(
    'possiblePoints',
  );
  late final GeneratedColumn<double> possiblePoints = GeneratedColumn<double>(
    'possible_points',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (possible_points >= 0)',
  );
  static const VerificationMeta _percentageMeta = const VerificationMeta(
    'percentage',
  );
  late final GeneratedColumn<double> percentage = GeneratedColumn<double>(
    'percentage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (percentage <= 100)',
  );
  static const VerificationMeta _passedMeta = const VerificationMeta('passed');
  late final GeneratedColumn<bool> passed = GeneratedColumn<bool>(
    'passed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT TRUE',
    defaultValue: const CustomExpression('TRUE'),
  );
  static const VerificationMeta _gradedAtMeta = const VerificationMeta(
    'gradedAt',
  );
  late final GeneratedColumn<DateTime> gradedAt = GeneratedColumn<DateTime>(
    'graded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    answerSheetId,
    answerKeyId,
    correctCount,
    incorrectCount,
    blankCount,
    multipleCount,
    earnedPoints,
    possiblePoints,
    percentage,
    passed,
    isCurrent,
    gradedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'examination_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExaminationResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('answer_sheet_id')) {
      context.handle(
        _answerSheetIdMeta,
        answerSheetId.isAcceptableOrUnknown(
          data['answer_sheet_id']!,
          _answerSheetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_answerSheetIdMeta);
    }
    if (data.containsKey('answer_key_id')) {
      context.handle(
        _answerKeyIdMeta,
        answerKeyId.isAcceptableOrUnknown(
          data['answer_key_id']!,
          _answerKeyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_answerKeyIdMeta);
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctCountMeta);
    }
    if (data.containsKey('incorrect_count')) {
      context.handle(
        _incorrectCountMeta,
        incorrectCount.isAcceptableOrUnknown(
          data['incorrect_count']!,
          _incorrectCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_incorrectCountMeta);
    }
    if (data.containsKey('blank_count')) {
      context.handle(
        _blankCountMeta,
        blankCount.isAcceptableOrUnknown(data['blank_count']!, _blankCountMeta),
      );
    } else if (isInserting) {
      context.missing(_blankCountMeta);
    }
    if (data.containsKey('multiple_count')) {
      context.handle(
        _multipleCountMeta,
        multipleCount.isAcceptableOrUnknown(
          data['multiple_count']!,
          _multipleCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_multipleCountMeta);
    }
    if (data.containsKey('earned_points')) {
      context.handle(
        _earnedPointsMeta,
        earnedPoints.isAcceptableOrUnknown(
          data['earned_points']!,
          _earnedPointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_earnedPointsMeta);
    }
    if (data.containsKey('possible_points')) {
      context.handle(
        _possiblePointsMeta,
        possiblePoints.isAcceptableOrUnknown(
          data['possible_points']!,
          _possiblePointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_possiblePointsMeta);
    }
    if (data.containsKey('percentage')) {
      context.handle(
        _percentageMeta,
        percentage.isAcceptableOrUnknown(data['percentage']!, _percentageMeta),
      );
    } else if (isInserting) {
      context.missing(_percentageMeta);
    }
    if (data.containsKey('passed')) {
      context.handle(
        _passedMeta,
        passed.isAcceptableOrUnknown(data['passed']!, _passedMeta),
      );
    } else if (isInserting) {
      context.missing(_passedMeta);
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    if (data.containsKey('graded_at')) {
      context.handle(
        _gradedAtMeta,
        gradedAt.isAcceptableOrUnknown(data['graded_at']!, _gradedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_gradedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {answerSheetId, answerKeyId},
  ];
  @override
  ExaminationResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExaminationResultRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      answerSheetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_sheet_id'],
      )!,
      answerKeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_key_id'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      incorrectCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}incorrect_count'],
      )!,
      blankCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}blank_count'],
      )!,
      multipleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}multiple_count'],
      )!,
      earnedPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}earned_points'],
      )!,
      possiblePoints: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}possible_points'],
      )!,
      percentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percentage'],
      )!,
      passed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}passed'],
      )!,
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
      gradedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}graded_at'],
      )!,
    );
  }

  @override
  ExaminationResults createAlias(String alias) {
    return ExaminationResults(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(answer_sheet_id, answer_key_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ExaminationResultRow extends DataClass
    implements Insertable<ExaminationResultRow> {
  final String id;
  final String answerSheetId;
  final String answerKeyId;
  final int correctCount;
  final int incorrectCount;
  final int blankCount;
  final int multipleCount;
  final double earnedPoints;
  final double possiblePoints;
  final double percentage;
  final bool passed;
  final bool isCurrent;
  final DateTime gradedAt;
  const ExaminationResultRow({
    required this.id,
    required this.answerSheetId,
    required this.answerKeyId,
    required this.correctCount,
    required this.incorrectCount,
    required this.blankCount,
    required this.multipleCount,
    required this.earnedPoints,
    required this.possiblePoints,
    required this.percentage,
    required this.passed,
    required this.isCurrent,
    required this.gradedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['answer_sheet_id'] = Variable<String>(answerSheetId);
    map['answer_key_id'] = Variable<String>(answerKeyId);
    map['correct_count'] = Variable<int>(correctCount);
    map['incorrect_count'] = Variable<int>(incorrectCount);
    map['blank_count'] = Variable<int>(blankCount);
    map['multiple_count'] = Variable<int>(multipleCount);
    map['earned_points'] = Variable<double>(earnedPoints);
    map['possible_points'] = Variable<double>(possiblePoints);
    map['percentage'] = Variable<double>(percentage);
    map['passed'] = Variable<bool>(passed);
    map['is_current'] = Variable<bool>(isCurrent);
    map['graded_at'] = Variable<DateTime>(gradedAt);
    return map;
  }

  ExaminationResultsCompanion toCompanion(bool nullToAbsent) {
    return ExaminationResultsCompanion(
      id: Value(id),
      answerSheetId: Value(answerSheetId),
      answerKeyId: Value(answerKeyId),
      correctCount: Value(correctCount),
      incorrectCount: Value(incorrectCount),
      blankCount: Value(blankCount),
      multipleCount: Value(multipleCount),
      earnedPoints: Value(earnedPoints),
      possiblePoints: Value(possiblePoints),
      percentage: Value(percentage),
      passed: Value(passed),
      isCurrent: Value(isCurrent),
      gradedAt: Value(gradedAt),
    );
  }

  factory ExaminationResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExaminationResultRow(
      id: serializer.fromJson<String>(json['id']),
      answerSheetId: serializer.fromJson<String>(json['answer_sheet_id']),
      answerKeyId: serializer.fromJson<String>(json['answer_key_id']),
      correctCount: serializer.fromJson<int>(json['correct_count']),
      incorrectCount: serializer.fromJson<int>(json['incorrect_count']),
      blankCount: serializer.fromJson<int>(json['blank_count']),
      multipleCount: serializer.fromJson<int>(json['multiple_count']),
      earnedPoints: serializer.fromJson<double>(json['earned_points']),
      possiblePoints: serializer.fromJson<double>(json['possible_points']),
      percentage: serializer.fromJson<double>(json['percentage']),
      passed: serializer.fromJson<bool>(json['passed']),
      isCurrent: serializer.fromJson<bool>(json['is_current']),
      gradedAt: serializer.fromJson<DateTime>(json['graded_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'answer_sheet_id': serializer.toJson<String>(answerSheetId),
      'answer_key_id': serializer.toJson<String>(answerKeyId),
      'correct_count': serializer.toJson<int>(correctCount),
      'incorrect_count': serializer.toJson<int>(incorrectCount),
      'blank_count': serializer.toJson<int>(blankCount),
      'multiple_count': serializer.toJson<int>(multipleCount),
      'earned_points': serializer.toJson<double>(earnedPoints),
      'possible_points': serializer.toJson<double>(possiblePoints),
      'percentage': serializer.toJson<double>(percentage),
      'passed': serializer.toJson<bool>(passed),
      'is_current': serializer.toJson<bool>(isCurrent),
      'graded_at': serializer.toJson<DateTime>(gradedAt),
    };
  }

  ExaminationResultRow copyWith({
    String? id,
    String? answerSheetId,
    String? answerKeyId,
    int? correctCount,
    int? incorrectCount,
    int? blankCount,
    int? multipleCount,
    double? earnedPoints,
    double? possiblePoints,
    double? percentage,
    bool? passed,
    bool? isCurrent,
    DateTime? gradedAt,
  }) => ExaminationResultRow(
    id: id ?? this.id,
    answerSheetId: answerSheetId ?? this.answerSheetId,
    answerKeyId: answerKeyId ?? this.answerKeyId,
    correctCount: correctCount ?? this.correctCount,
    incorrectCount: incorrectCount ?? this.incorrectCount,
    blankCount: blankCount ?? this.blankCount,
    multipleCount: multipleCount ?? this.multipleCount,
    earnedPoints: earnedPoints ?? this.earnedPoints,
    possiblePoints: possiblePoints ?? this.possiblePoints,
    percentage: percentage ?? this.percentage,
    passed: passed ?? this.passed,
    isCurrent: isCurrent ?? this.isCurrent,
    gradedAt: gradedAt ?? this.gradedAt,
  );
  ExaminationResultRow copyWithCompanion(ExaminationResultsCompanion data) {
    return ExaminationResultRow(
      id: data.id.present ? data.id.value : this.id,
      answerSheetId: data.answerSheetId.present
          ? data.answerSheetId.value
          : this.answerSheetId,
      answerKeyId: data.answerKeyId.present
          ? data.answerKeyId.value
          : this.answerKeyId,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      incorrectCount: data.incorrectCount.present
          ? data.incorrectCount.value
          : this.incorrectCount,
      blankCount: data.blankCount.present
          ? data.blankCount.value
          : this.blankCount,
      multipleCount: data.multipleCount.present
          ? data.multipleCount.value
          : this.multipleCount,
      earnedPoints: data.earnedPoints.present
          ? data.earnedPoints.value
          : this.earnedPoints,
      possiblePoints: data.possiblePoints.present
          ? data.possiblePoints.value
          : this.possiblePoints,
      percentage: data.percentage.present
          ? data.percentage.value
          : this.percentage,
      passed: data.passed.present ? data.passed.value : this.passed,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
      gradedAt: data.gradedAt.present ? data.gradedAt.value : this.gradedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExaminationResultRow(')
          ..write('id: $id, ')
          ..write('answerSheetId: $answerSheetId, ')
          ..write('answerKeyId: $answerKeyId, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('blankCount: $blankCount, ')
          ..write('multipleCount: $multipleCount, ')
          ..write('earnedPoints: $earnedPoints, ')
          ..write('possiblePoints: $possiblePoints, ')
          ..write('percentage: $percentage, ')
          ..write('passed: $passed, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('gradedAt: $gradedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    answerSheetId,
    answerKeyId,
    correctCount,
    incorrectCount,
    blankCount,
    multipleCount,
    earnedPoints,
    possiblePoints,
    percentage,
    passed,
    isCurrent,
    gradedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExaminationResultRow &&
          other.id == this.id &&
          other.answerSheetId == this.answerSheetId &&
          other.answerKeyId == this.answerKeyId &&
          other.correctCount == this.correctCount &&
          other.incorrectCount == this.incorrectCount &&
          other.blankCount == this.blankCount &&
          other.multipleCount == this.multipleCount &&
          other.earnedPoints == this.earnedPoints &&
          other.possiblePoints == this.possiblePoints &&
          other.percentage == this.percentage &&
          other.passed == this.passed &&
          other.isCurrent == this.isCurrent &&
          other.gradedAt == this.gradedAt);
}

class ExaminationResultsCompanion
    extends UpdateCompanion<ExaminationResultRow> {
  final Value<String> id;
  final Value<String> answerSheetId;
  final Value<String> answerKeyId;
  final Value<int> correctCount;
  final Value<int> incorrectCount;
  final Value<int> blankCount;
  final Value<int> multipleCount;
  final Value<double> earnedPoints;
  final Value<double> possiblePoints;
  final Value<double> percentage;
  final Value<bool> passed;
  final Value<bool> isCurrent;
  final Value<DateTime> gradedAt;
  final Value<int> rowid;
  const ExaminationResultsCompanion({
    this.id = const Value.absent(),
    this.answerSheetId = const Value.absent(),
    this.answerKeyId = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.blankCount = const Value.absent(),
    this.multipleCount = const Value.absent(),
    this.earnedPoints = const Value.absent(),
    this.possiblePoints = const Value.absent(),
    this.percentage = const Value.absent(),
    this.passed = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.gradedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExaminationResultsCompanion.insert({
    required String id,
    required String answerSheetId,
    required String answerKeyId,
    required int correctCount,
    required int incorrectCount,
    required int blankCount,
    required int multipleCount,
    required double earnedPoints,
    required double possiblePoints,
    required double percentage,
    required bool passed,
    this.isCurrent = const Value.absent(),
    required DateTime gradedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       answerSheetId = Value(answerSheetId),
       answerKeyId = Value(answerKeyId),
       correctCount = Value(correctCount),
       incorrectCount = Value(incorrectCount),
       blankCount = Value(blankCount),
       multipleCount = Value(multipleCount),
       earnedPoints = Value(earnedPoints),
       possiblePoints = Value(possiblePoints),
       percentage = Value(percentage),
       passed = Value(passed),
       gradedAt = Value(gradedAt);
  static Insertable<ExaminationResultRow> custom({
    Expression<String>? id,
    Expression<String>? answerSheetId,
    Expression<String>? answerKeyId,
    Expression<int>? correctCount,
    Expression<int>? incorrectCount,
    Expression<int>? blankCount,
    Expression<int>? multipleCount,
    Expression<double>? earnedPoints,
    Expression<double>? possiblePoints,
    Expression<double>? percentage,
    Expression<bool>? passed,
    Expression<bool>? isCurrent,
    Expression<DateTime>? gradedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (answerSheetId != null) 'answer_sheet_id': answerSheetId,
      if (answerKeyId != null) 'answer_key_id': answerKeyId,
      if (correctCount != null) 'correct_count': correctCount,
      if (incorrectCount != null) 'incorrect_count': incorrectCount,
      if (blankCount != null) 'blank_count': blankCount,
      if (multipleCount != null) 'multiple_count': multipleCount,
      if (earnedPoints != null) 'earned_points': earnedPoints,
      if (possiblePoints != null) 'possible_points': possiblePoints,
      if (percentage != null) 'percentage': percentage,
      if (passed != null) 'passed': passed,
      if (isCurrent != null) 'is_current': isCurrent,
      if (gradedAt != null) 'graded_at': gradedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExaminationResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? answerSheetId,
    Value<String>? answerKeyId,
    Value<int>? correctCount,
    Value<int>? incorrectCount,
    Value<int>? blankCount,
    Value<int>? multipleCount,
    Value<double>? earnedPoints,
    Value<double>? possiblePoints,
    Value<double>? percentage,
    Value<bool>? passed,
    Value<bool>? isCurrent,
    Value<DateTime>? gradedAt,
    Value<int>? rowid,
  }) {
    return ExaminationResultsCompanion(
      id: id ?? this.id,
      answerSheetId: answerSheetId ?? this.answerSheetId,
      answerKeyId: answerKeyId ?? this.answerKeyId,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      blankCount: blankCount ?? this.blankCount,
      multipleCount: multipleCount ?? this.multipleCount,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      possiblePoints: possiblePoints ?? this.possiblePoints,
      percentage: percentage ?? this.percentage,
      passed: passed ?? this.passed,
      isCurrent: isCurrent ?? this.isCurrent,
      gradedAt: gradedAt ?? this.gradedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (answerSheetId.present) {
      map['answer_sheet_id'] = Variable<String>(answerSheetId.value);
    }
    if (answerKeyId.present) {
      map['answer_key_id'] = Variable<String>(answerKeyId.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (incorrectCount.present) {
      map['incorrect_count'] = Variable<int>(incorrectCount.value);
    }
    if (blankCount.present) {
      map['blank_count'] = Variable<int>(blankCount.value);
    }
    if (multipleCount.present) {
      map['multiple_count'] = Variable<int>(multipleCount.value);
    }
    if (earnedPoints.present) {
      map['earned_points'] = Variable<double>(earnedPoints.value);
    }
    if (possiblePoints.present) {
      map['possible_points'] = Variable<double>(possiblePoints.value);
    }
    if (percentage.present) {
      map['percentage'] = Variable<double>(percentage.value);
    }
    if (passed.present) {
      map['passed'] = Variable<bool>(passed.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (gradedAt.present) {
      map['graded_at'] = Variable<DateTime>(gradedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExaminationResultsCompanion(')
          ..write('id: $id, ')
          ..write('answerSheetId: $answerSheetId, ')
          ..write('answerKeyId: $answerKeyId, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('blankCount: $blankCount, ')
          ..write('multipleCount: $multipleCount, ')
          ..write('earnedPoints: $earnedPoints, ')
          ..write('possiblePoints: $possiblePoints, ')
          ..write('percentage: $percentage, ')
          ..write('passed: $passed, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('gradedAt: $gradedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SubscriptionEntitlements extends Table
    with TableInfo<SubscriptionEntitlements, SubscriptionEntitlementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SubscriptionEntitlements(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
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
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (tier IN (\'free\', \'premium\'))',
  );
  static const VerificationMeta _freeLimitMeta = const VerificationMeta(
    'freeLimit',
  );
  late final GeneratedColumn<int> freeLimit = GeneratedColumn<int>(
    'free_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (free_limit >= 0)',
  );
  static const VerificationMeta _freeUsedMeta = const VerificationMeta(
    'freeUsed',
  );
  late final GeneratedColumn<int> freeUsed = GeneratedColumn<int>(
    'free_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (free_used >= 0)',
  );
  static const VerificationMeta _leaseMeta = const VerificationMeta('lease');
  late final GeneratedColumn<int> lease = GeneratedColumn<int>(
    'lease',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (lease >= 0)',
  );
  static const VerificationMeta _premiumUntilMeta = const VerificationMeta(
    'premiumUntil',
  );
  late final GeneratedColumn<DateTime> premiumUntil = GeneratedColumn<DateTime>(
    'premium_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
    'verified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _offlineUntilMeta = const VerificationMeta(
    'offlineUntil',
  );
  late final GeneratedColumn<DateTime> offlineUntil = GeneratedColumn<DateTime>(
    'offline_until',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
    'issued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _tokenIdMeta = const VerificationMeta(
    'tokenId',
  );
  late final GeneratedColumn<String> tokenId = GeneratedColumn<String>(
    'token_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT TRUE',
    defaultValue: const CustomExpression('TRUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    token,
    tier,
    freeLimit,
    freeUsed,
    lease,
    premiumUntil,
    verifiedAt,
    offlineUntil,
    issuedAt,
    tokenId,
    receivedAt,
    isCurrent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscription_entitlements';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubscriptionEntitlementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    } else if (isInserting) {
      context.missing(_tierMeta);
    }
    if (data.containsKey('free_limit')) {
      context.handle(
        _freeLimitMeta,
        freeLimit.isAcceptableOrUnknown(data['free_limit']!, _freeLimitMeta),
      );
    } else if (isInserting) {
      context.missing(_freeLimitMeta);
    }
    if (data.containsKey('free_used')) {
      context.handle(
        _freeUsedMeta,
        freeUsed.isAcceptableOrUnknown(data['free_used']!, _freeUsedMeta),
      );
    } else if (isInserting) {
      context.missing(_freeUsedMeta);
    }
    if (data.containsKey('lease')) {
      context.handle(
        _leaseMeta,
        lease.isAcceptableOrUnknown(data['lease']!, _leaseMeta),
      );
    } else if (isInserting) {
      context.missing(_leaseMeta);
    }
    if (data.containsKey('premium_until')) {
      context.handle(
        _premiumUntilMeta,
        premiumUntil.isAcceptableOrUnknown(
          data['premium_until']!,
          _premiumUntilMeta,
        ),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_verifiedAtMeta);
    }
    if (data.containsKey('offline_until')) {
      context.handle(
        _offlineUntilMeta,
        offlineUntil.isAcceptableOrUnknown(
          data['offline_until']!,
          _offlineUntilMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offlineUntilMeta);
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_issuedAtMeta);
    }
    if (data.containsKey('token_id')) {
      context.handle(
        _tokenIdMeta,
        tokenId.isAcceptableOrUnknown(data['token_id']!, _tokenIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenIdMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubscriptionEntitlementRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubscriptionEntitlementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      )!,
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier'],
      )!,
      freeLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}free_limit'],
      )!,
      freeUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}free_used'],
      )!,
      lease: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lease'],
      )!,
      premiumUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}premium_until'],
      ),
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verified_at'],
      )!,
      offlineUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}offline_until'],
      )!,
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issued_at'],
      )!,
      tokenId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token_id'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
    );
  }

  @override
  SubscriptionEntitlements createAlias(String alias) {
    return SubscriptionEntitlements(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SubscriptionEntitlementRow extends DataClass
    implements Insertable<SubscriptionEntitlementRow> {
  final String id;
  final String accountId;

  /// Compact JWS signed with the server's Ed25519 key. Every other column is a
  /// cache that is re-derived from a successfully verified token on load.
  final String token;
  final String tier;
  final int freeLimit;
  final int freeUsed;
  final int lease;
  final DateTime? premiumUntil;
  final DateTime verifiedAt;
  final DateTime offlineUntil;
  final DateTime issuedAt;
  final String tokenId;
  final DateTime receivedAt;
  final bool isCurrent;
  const SubscriptionEntitlementRow({
    required this.id,
    required this.accountId,
    required this.token,
    required this.tier,
    required this.freeLimit,
    required this.freeUsed,
    required this.lease,
    this.premiumUntil,
    required this.verifiedAt,
    required this.offlineUntil,
    required this.issuedAt,
    required this.tokenId,
    required this.receivedAt,
    required this.isCurrent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['token'] = Variable<String>(token);
    map['tier'] = Variable<String>(tier);
    map['free_limit'] = Variable<int>(freeLimit);
    map['free_used'] = Variable<int>(freeUsed);
    map['lease'] = Variable<int>(lease);
    if (!nullToAbsent || premiumUntil != null) {
      map['premium_until'] = Variable<DateTime>(premiumUntil);
    }
    map['verified_at'] = Variable<DateTime>(verifiedAt);
    map['offline_until'] = Variable<DateTime>(offlineUntil);
    map['issued_at'] = Variable<DateTime>(issuedAt);
    map['token_id'] = Variable<String>(tokenId);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['is_current'] = Variable<bool>(isCurrent);
    return map;
  }

  SubscriptionEntitlementsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionEntitlementsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      token: Value(token),
      tier: Value(tier),
      freeLimit: Value(freeLimit),
      freeUsed: Value(freeUsed),
      lease: Value(lease),
      premiumUntil: premiumUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(premiumUntil),
      verifiedAt: Value(verifiedAt),
      offlineUntil: Value(offlineUntil),
      issuedAt: Value(issuedAt),
      tokenId: Value(tokenId),
      receivedAt: Value(receivedAt),
      isCurrent: Value(isCurrent),
    );
  }

  factory SubscriptionEntitlementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubscriptionEntitlementRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['account_id']),
      token: serializer.fromJson<String>(json['token']),
      tier: serializer.fromJson<String>(json['tier']),
      freeLimit: serializer.fromJson<int>(json['free_limit']),
      freeUsed: serializer.fromJson<int>(json['free_used']),
      lease: serializer.fromJson<int>(json['lease']),
      premiumUntil: serializer.fromJson<DateTime?>(json['premium_until']),
      verifiedAt: serializer.fromJson<DateTime>(json['verified_at']),
      offlineUntil: serializer.fromJson<DateTime>(json['offline_until']),
      issuedAt: serializer.fromJson<DateTime>(json['issued_at']),
      tokenId: serializer.fromJson<String>(json['token_id']),
      receivedAt: serializer.fromJson<DateTime>(json['received_at']),
      isCurrent: serializer.fromJson<bool>(json['is_current']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'account_id': serializer.toJson<String>(accountId),
      'token': serializer.toJson<String>(token),
      'tier': serializer.toJson<String>(tier),
      'free_limit': serializer.toJson<int>(freeLimit),
      'free_used': serializer.toJson<int>(freeUsed),
      'lease': serializer.toJson<int>(lease),
      'premium_until': serializer.toJson<DateTime?>(premiumUntil),
      'verified_at': serializer.toJson<DateTime>(verifiedAt),
      'offline_until': serializer.toJson<DateTime>(offlineUntil),
      'issued_at': serializer.toJson<DateTime>(issuedAt),
      'token_id': serializer.toJson<String>(tokenId),
      'received_at': serializer.toJson<DateTime>(receivedAt),
      'is_current': serializer.toJson<bool>(isCurrent),
    };
  }

  SubscriptionEntitlementRow copyWith({
    String? id,
    String? accountId,
    String? token,
    String? tier,
    int? freeLimit,
    int? freeUsed,
    int? lease,
    Value<DateTime?> premiumUntil = const Value.absent(),
    DateTime? verifiedAt,
    DateTime? offlineUntil,
    DateTime? issuedAt,
    String? tokenId,
    DateTime? receivedAt,
    bool? isCurrent,
  }) => SubscriptionEntitlementRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    token: token ?? this.token,
    tier: tier ?? this.tier,
    freeLimit: freeLimit ?? this.freeLimit,
    freeUsed: freeUsed ?? this.freeUsed,
    lease: lease ?? this.lease,
    premiumUntil: premiumUntil.present ? premiumUntil.value : this.premiumUntil,
    verifiedAt: verifiedAt ?? this.verifiedAt,
    offlineUntil: offlineUntil ?? this.offlineUntil,
    issuedAt: issuedAt ?? this.issuedAt,
    tokenId: tokenId ?? this.tokenId,
    receivedAt: receivedAt ?? this.receivedAt,
    isCurrent: isCurrent ?? this.isCurrent,
  );
  SubscriptionEntitlementRow copyWithCompanion(
    SubscriptionEntitlementsCompanion data,
  ) {
    return SubscriptionEntitlementRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      token: data.token.present ? data.token.value : this.token,
      tier: data.tier.present ? data.tier.value : this.tier,
      freeLimit: data.freeLimit.present ? data.freeLimit.value : this.freeLimit,
      freeUsed: data.freeUsed.present ? data.freeUsed.value : this.freeUsed,
      lease: data.lease.present ? data.lease.value : this.lease,
      premiumUntil: data.premiumUntil.present
          ? data.premiumUntil.value
          : this.premiumUntil,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
      offlineUntil: data.offlineUntil.present
          ? data.offlineUntil.value
          : this.offlineUntil,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      tokenId: data.tokenId.present ? data.tokenId.value : this.tokenId,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionEntitlementRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('token: $token, ')
          ..write('tier: $tier, ')
          ..write('freeLimit: $freeLimit, ')
          ..write('freeUsed: $freeUsed, ')
          ..write('lease: $lease, ')
          ..write('premiumUntil: $premiumUntil, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('offlineUntil: $offlineUntil, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('tokenId: $tokenId, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('isCurrent: $isCurrent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    token,
    tier,
    freeLimit,
    freeUsed,
    lease,
    premiumUntil,
    verifiedAt,
    offlineUntil,
    issuedAt,
    tokenId,
    receivedAt,
    isCurrent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubscriptionEntitlementRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.token == this.token &&
          other.tier == this.tier &&
          other.freeLimit == this.freeLimit &&
          other.freeUsed == this.freeUsed &&
          other.lease == this.lease &&
          other.premiumUntil == this.premiumUntil &&
          other.verifiedAt == this.verifiedAt &&
          other.offlineUntil == this.offlineUntil &&
          other.issuedAt == this.issuedAt &&
          other.tokenId == this.tokenId &&
          other.receivedAt == this.receivedAt &&
          other.isCurrent == this.isCurrent);
}

class SubscriptionEntitlementsCompanion
    extends UpdateCompanion<SubscriptionEntitlementRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> token;
  final Value<String> tier;
  final Value<int> freeLimit;
  final Value<int> freeUsed;
  final Value<int> lease;
  final Value<DateTime?> premiumUntil;
  final Value<DateTime> verifiedAt;
  final Value<DateTime> offlineUntil;
  final Value<DateTime> issuedAt;
  final Value<String> tokenId;
  final Value<DateTime> receivedAt;
  final Value<bool> isCurrent;
  final Value<int> rowid;
  const SubscriptionEntitlementsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.token = const Value.absent(),
    this.tier = const Value.absent(),
    this.freeLimit = const Value.absent(),
    this.freeUsed = const Value.absent(),
    this.lease = const Value.absent(),
    this.premiumUntil = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.offlineUntil = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.tokenId = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionEntitlementsCompanion.insert({
    required String id,
    required String accountId,
    required String token,
    required String tier,
    required int freeLimit,
    required int freeUsed,
    required int lease,
    this.premiumUntil = const Value.absent(),
    required DateTime verifiedAt,
    required DateTime offlineUntil,
    required DateTime issuedAt,
    required String tokenId,
    required DateTime receivedAt,
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       token = Value(token),
       tier = Value(tier),
       freeLimit = Value(freeLimit),
       freeUsed = Value(freeUsed),
       lease = Value(lease),
       verifiedAt = Value(verifiedAt),
       offlineUntil = Value(offlineUntil),
       issuedAt = Value(issuedAt),
       tokenId = Value(tokenId),
       receivedAt = Value(receivedAt);
  static Insertable<SubscriptionEntitlementRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? token,
    Expression<String>? tier,
    Expression<int>? freeLimit,
    Expression<int>? freeUsed,
    Expression<int>? lease,
    Expression<DateTime>? premiumUntil,
    Expression<DateTime>? verifiedAt,
    Expression<DateTime>? offlineUntil,
    Expression<DateTime>? issuedAt,
    Expression<String>? tokenId,
    Expression<DateTime>? receivedAt,
    Expression<bool>? isCurrent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (token != null) 'token': token,
      if (tier != null) 'tier': tier,
      if (freeLimit != null) 'free_limit': freeLimit,
      if (freeUsed != null) 'free_used': freeUsed,
      if (lease != null) 'lease': lease,
      if (premiumUntil != null) 'premium_until': premiumUntil,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (offlineUntil != null) 'offline_until': offlineUntil,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (tokenId != null) 'token_id': tokenId,
      if (receivedAt != null) 'received_at': receivedAt,
      if (isCurrent != null) 'is_current': isCurrent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionEntitlementsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? token,
    Value<String>? tier,
    Value<int>? freeLimit,
    Value<int>? freeUsed,
    Value<int>? lease,
    Value<DateTime?>? premiumUntil,
    Value<DateTime>? verifiedAt,
    Value<DateTime>? offlineUntil,
    Value<DateTime>? issuedAt,
    Value<String>? tokenId,
    Value<DateTime>? receivedAt,
    Value<bool>? isCurrent,
    Value<int>? rowid,
  }) {
    return SubscriptionEntitlementsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      token: token ?? this.token,
      tier: tier ?? this.tier,
      freeLimit: freeLimit ?? this.freeLimit,
      freeUsed: freeUsed ?? this.freeUsed,
      lease: lease ?? this.lease,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      offlineUntil: offlineUntil ?? this.offlineUntil,
      issuedAt: issuedAt ?? this.issuedAt,
      tokenId: tokenId ?? this.tokenId,
      receivedAt: receivedAt ?? this.receivedAt,
      isCurrent: isCurrent ?? this.isCurrent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (freeLimit.present) {
      map['free_limit'] = Variable<int>(freeLimit.value);
    }
    if (freeUsed.present) {
      map['free_used'] = Variable<int>(freeUsed.value);
    }
    if (lease.present) {
      map['lease'] = Variable<int>(lease.value);
    }
    if (premiumUntil.present) {
      map['premium_until'] = Variable<DateTime>(premiumUntil.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (offlineUntil.present) {
      map['offline_until'] = Variable<DateTime>(offlineUntil.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (tokenId.present) {
      map['token_id'] = Variable<String>(tokenId.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionEntitlementsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('token: $token, ')
          ..write('tier: $tier, ')
          ..write('freeLimit: $freeLimit, ')
          ..write('freeUsed: $freeUsed, ')
          ..write('lease: $lease, ')
          ..write('premiumUntil: $premiumUntil, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('offlineUntil: $offlineUntil, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('tokenId: $tokenId, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ScanLedger extends Table with TableInfo<ScanLedger, ScanLedgerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ScanLedger(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _submissionKeyMeta = const VerificationMeta(
    'submissionKey',
  );
  late final GeneratedColumn<String> submissionKey = GeneratedColumn<String>(
    'submission_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE CHECK (length(submission_key) = 64)',
  );
  static const VerificationMeta _answerSheetIdMeta = const VerificationMeta(
    'answerSheetId',
  );
  late final GeneratedColumn<String> answerSheetId = GeneratedColumn<String>(
    'answer_sheet_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES answer_sheets(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (tier IN (\'free\', \'premium\'))',
  );
  static const VerificationMeta _entitlementTokenIdMeta =
      const VerificationMeta('entitlementTokenId');
  late final GeneratedColumn<String> entitlementTokenId =
      GeneratedColumn<String>(
        'entitlement_token_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _consumedAtMeta = const VerificationMeta(
    'consumedAt',
  );
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
    'consumed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _prevHashMeta = const VerificationMeta(
    'prevHash',
  );
  late final GeneratedColumn<String> prevHash = GeneratedColumn<String>(
    'prev_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(prev_hash) = 64)',
  );
  static const VerificationMeta _entryHashMeta = const VerificationMeta(
    'entryHash',
  );
  late final GeneratedColumn<String> entryHash = GeneratedColumn<String>(
    'entry_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE CHECK (length(entry_hash) = 64)',
  );
  static const VerificationMeta _macMeta = const VerificationMeta('mac');
  late final GeneratedColumn<String> mac = GeneratedColumn<String>(
    'mac',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(mac) = 64)',
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _serverReceiptMeta = const VerificationMeta(
    'serverReceipt',
  );
  late final GeneratedColumn<String> serverReceipt = GeneratedColumn<String>(
    'server_receipt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    id,
    accountId,
    submissionKey,
    answerSheetId,
    tier,
    entitlementTokenId,
    consumedAt,
    prevHash,
    entryHash,
    mac,
    syncedAt,
    serverReceipt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_ledger';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanLedgerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('submission_key')) {
      context.handle(
        _submissionKeyMeta,
        submissionKey.isAcceptableOrUnknown(
          data['submission_key']!,
          _submissionKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_submissionKeyMeta);
    }
    if (data.containsKey('answer_sheet_id')) {
      context.handle(
        _answerSheetIdMeta,
        answerSheetId.isAcceptableOrUnknown(
          data['answer_sheet_id']!,
          _answerSheetIdMeta,
        ),
      );
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    } else if (isInserting) {
      context.missing(_tierMeta);
    }
    if (data.containsKey('entitlement_token_id')) {
      context.handle(
        _entitlementTokenIdMeta,
        entitlementTokenId.isAcceptableOrUnknown(
          data['entitlement_token_id']!,
          _entitlementTokenIdMeta,
        ),
      );
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
        _consumedAtMeta,
        consumedAt.isAcceptableOrUnknown(data['consumed_at']!, _consumedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_consumedAtMeta);
    }
    if (data.containsKey('prev_hash')) {
      context.handle(
        _prevHashMeta,
        prevHash.isAcceptableOrUnknown(data['prev_hash']!, _prevHashMeta),
      );
    } else if (isInserting) {
      context.missing(_prevHashMeta);
    }
    if (data.containsKey('entry_hash')) {
      context.handle(
        _entryHashMeta,
        entryHash.isAcceptableOrUnknown(data['entry_hash']!, _entryHashMeta),
      );
    } else if (isInserting) {
      context.missing(_entryHashMeta);
    }
    if (data.containsKey('mac')) {
      context.handle(
        _macMeta,
        mac.isAcceptableOrUnknown(data['mac']!, _macMeta),
      );
    } else if (isInserting) {
      context.missing(_macMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('server_receipt')) {
      context.handle(
        _serverReceiptMeta,
        serverReceipt.isAcceptableOrUnknown(
          data['server_receipt']!,
          _serverReceiptMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  ScanLedgerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanLedgerRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      submissionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submission_key'],
      )!,
      answerSheetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_sheet_id'],
      ),
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier'],
      )!,
      entitlementTokenId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entitlement_token_id'],
      ),
      consumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consumed_at'],
      )!,
      prevHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prev_hash'],
      )!,
      entryHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_hash'],
      )!,
      mac: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mac'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      serverReceipt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_receipt'],
      ),
    );
  }

  @override
  ScanLedger createAlias(String alias) {
    return ScanLedger(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ScanLedgerRow extends DataClass implements Insertable<ScanLedgerRow> {
  final int seq;
  final String id;
  final String? accountId;

  /// One charge per submission: re-scanning the same paper cannot charge again.
  final String submissionKey;
  final String? answerSheetId;
  final String tier;
  final String? entitlementTokenId;
  final DateTime consumedAt;

  /// entry_hash = SHA-256(prev_hash | id | account_id | submission_key | tier |
  ///                      entitlement_token_id | consumed_at)
  final String prevHash;
  final String entryHash;

  /// HMAC-SHA256(entry_hash) with the per-install key from the Android Keystore.
  final String mac;
  final DateTime? syncedAt;
  final String? serverReceipt;
  const ScanLedgerRow({
    required this.seq,
    required this.id,
    this.accountId,
    required this.submissionKey,
    this.answerSheetId,
    required this.tier,
    this.entitlementTokenId,
    required this.consumedAt,
    required this.prevHash,
    required this.entryHash,
    required this.mac,
    this.syncedAt,
    this.serverReceipt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['submission_key'] = Variable<String>(submissionKey);
    if (!nullToAbsent || answerSheetId != null) {
      map['answer_sheet_id'] = Variable<String>(answerSheetId);
    }
    map['tier'] = Variable<String>(tier);
    if (!nullToAbsent || entitlementTokenId != null) {
      map['entitlement_token_id'] = Variable<String>(entitlementTokenId);
    }
    map['consumed_at'] = Variable<DateTime>(consumedAt);
    map['prev_hash'] = Variable<String>(prevHash);
    map['entry_hash'] = Variable<String>(entryHash);
    map['mac'] = Variable<String>(mac);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || serverReceipt != null) {
      map['server_receipt'] = Variable<String>(serverReceipt);
    }
    return map;
  }

  ScanLedgerCompanion toCompanion(bool nullToAbsent) {
    return ScanLedgerCompanion(
      seq: Value(seq),
      id: Value(id),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      submissionKey: Value(submissionKey),
      answerSheetId: answerSheetId == null && nullToAbsent
          ? const Value.absent()
          : Value(answerSheetId),
      tier: Value(tier),
      entitlementTokenId: entitlementTokenId == null && nullToAbsent
          ? const Value.absent()
          : Value(entitlementTokenId),
      consumedAt: Value(consumedAt),
      prevHash: Value(prevHash),
      entryHash: Value(entryHash),
      mac: Value(mac),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      serverReceipt: serverReceipt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverReceipt),
    );
  }

  factory ScanLedgerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanLedgerRow(
      seq: serializer.fromJson<int>(json['seq']),
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String?>(json['account_id']),
      submissionKey: serializer.fromJson<String>(json['submission_key']),
      answerSheetId: serializer.fromJson<String?>(json['answer_sheet_id']),
      tier: serializer.fromJson<String>(json['tier']),
      entitlementTokenId: serializer.fromJson<String?>(
        json['entitlement_token_id'],
      ),
      consumedAt: serializer.fromJson<DateTime>(json['consumed_at']),
      prevHash: serializer.fromJson<String>(json['prev_hash']),
      entryHash: serializer.fromJson<String>(json['entry_hash']),
      mac: serializer.fromJson<String>(json['mac']),
      syncedAt: serializer.fromJson<DateTime?>(json['synced_at']),
      serverReceipt: serializer.fromJson<String?>(json['server_receipt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'id': serializer.toJson<String>(id),
      'account_id': serializer.toJson<String?>(accountId),
      'submission_key': serializer.toJson<String>(submissionKey),
      'answer_sheet_id': serializer.toJson<String?>(answerSheetId),
      'tier': serializer.toJson<String>(tier),
      'entitlement_token_id': serializer.toJson<String?>(entitlementTokenId),
      'consumed_at': serializer.toJson<DateTime>(consumedAt),
      'prev_hash': serializer.toJson<String>(prevHash),
      'entry_hash': serializer.toJson<String>(entryHash),
      'mac': serializer.toJson<String>(mac),
      'synced_at': serializer.toJson<DateTime?>(syncedAt),
      'server_receipt': serializer.toJson<String?>(serverReceipt),
    };
  }

  ScanLedgerRow copyWith({
    int? seq,
    String? id,
    Value<String?> accountId = const Value.absent(),
    String? submissionKey,
    Value<String?> answerSheetId = const Value.absent(),
    String? tier,
    Value<String?> entitlementTokenId = const Value.absent(),
    DateTime? consumedAt,
    String? prevHash,
    String? entryHash,
    String? mac,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<String?> serverReceipt = const Value.absent(),
  }) => ScanLedgerRow(
    seq: seq ?? this.seq,
    id: id ?? this.id,
    accountId: accountId.present ? accountId.value : this.accountId,
    submissionKey: submissionKey ?? this.submissionKey,
    answerSheetId: answerSheetId.present
        ? answerSheetId.value
        : this.answerSheetId,
    tier: tier ?? this.tier,
    entitlementTokenId: entitlementTokenId.present
        ? entitlementTokenId.value
        : this.entitlementTokenId,
    consumedAt: consumedAt ?? this.consumedAt,
    prevHash: prevHash ?? this.prevHash,
    entryHash: entryHash ?? this.entryHash,
    mac: mac ?? this.mac,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    serverReceipt: serverReceipt.present
        ? serverReceipt.value
        : this.serverReceipt,
  );
  ScanLedgerRow copyWithCompanion(ScanLedgerCompanion data) {
    return ScanLedgerRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      submissionKey: data.submissionKey.present
          ? data.submissionKey.value
          : this.submissionKey,
      answerSheetId: data.answerSheetId.present
          ? data.answerSheetId.value
          : this.answerSheetId,
      tier: data.tier.present ? data.tier.value : this.tier,
      entitlementTokenId: data.entitlementTokenId.present
          ? data.entitlementTokenId.value
          : this.entitlementTokenId,
      consumedAt: data.consumedAt.present
          ? data.consumedAt.value
          : this.consumedAt,
      prevHash: data.prevHash.present ? data.prevHash.value : this.prevHash,
      entryHash: data.entryHash.present ? data.entryHash.value : this.entryHash,
      mac: data.mac.present ? data.mac.value : this.mac,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      serverReceipt: data.serverReceipt.present
          ? data.serverReceipt.value
          : this.serverReceipt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanLedgerRow(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('submissionKey: $submissionKey, ')
          ..write('answerSheetId: $answerSheetId, ')
          ..write('tier: $tier, ')
          ..write('entitlementTokenId: $entitlementTokenId, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('prevHash: $prevHash, ')
          ..write('entryHash: $entryHash, ')
          ..write('mac: $mac, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('serverReceipt: $serverReceipt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    id,
    accountId,
    submissionKey,
    answerSheetId,
    tier,
    entitlementTokenId,
    consumedAt,
    prevHash,
    entryHash,
    mac,
    syncedAt,
    serverReceipt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanLedgerRow &&
          other.seq == this.seq &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.submissionKey == this.submissionKey &&
          other.answerSheetId == this.answerSheetId &&
          other.tier == this.tier &&
          other.entitlementTokenId == this.entitlementTokenId &&
          other.consumedAt == this.consumedAt &&
          other.prevHash == this.prevHash &&
          other.entryHash == this.entryHash &&
          other.mac == this.mac &&
          other.syncedAt == this.syncedAt &&
          other.serverReceipt == this.serverReceipt);
}

class ScanLedgerCompanion extends UpdateCompanion<ScanLedgerRow> {
  final Value<int> seq;
  final Value<String> id;
  final Value<String?> accountId;
  final Value<String> submissionKey;
  final Value<String?> answerSheetId;
  final Value<String> tier;
  final Value<String?> entitlementTokenId;
  final Value<DateTime> consumedAt;
  final Value<String> prevHash;
  final Value<String> entryHash;
  final Value<String> mac;
  final Value<DateTime?> syncedAt;
  final Value<String?> serverReceipt;
  const ScanLedgerCompanion({
    this.seq = const Value.absent(),
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.submissionKey = const Value.absent(),
    this.answerSheetId = const Value.absent(),
    this.tier = const Value.absent(),
    this.entitlementTokenId = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.prevHash = const Value.absent(),
    this.entryHash = const Value.absent(),
    this.mac = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.serverReceipt = const Value.absent(),
  });
  ScanLedgerCompanion.insert({
    this.seq = const Value.absent(),
    required String id,
    this.accountId = const Value.absent(),
    required String submissionKey,
    this.answerSheetId = const Value.absent(),
    required String tier,
    this.entitlementTokenId = const Value.absent(),
    required DateTime consumedAt,
    required String prevHash,
    required String entryHash,
    required String mac,
    this.syncedAt = const Value.absent(),
    this.serverReceipt = const Value.absent(),
  }) : id = Value(id),
       submissionKey = Value(submissionKey),
       tier = Value(tier),
       consumedAt = Value(consumedAt),
       prevHash = Value(prevHash),
       entryHash = Value(entryHash),
       mac = Value(mac);
  static Insertable<ScanLedgerRow> custom({
    Expression<int>? seq,
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? submissionKey,
    Expression<String>? answerSheetId,
    Expression<String>? tier,
    Expression<String>? entitlementTokenId,
    Expression<DateTime>? consumedAt,
    Expression<String>? prevHash,
    Expression<String>? entryHash,
    Expression<String>? mac,
    Expression<DateTime>? syncedAt,
    Expression<String>? serverReceipt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (submissionKey != null) 'submission_key': submissionKey,
      if (answerSheetId != null) 'answer_sheet_id': answerSheetId,
      if (tier != null) 'tier': tier,
      if (entitlementTokenId != null)
        'entitlement_token_id': entitlementTokenId,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (prevHash != null) 'prev_hash': prevHash,
      if (entryHash != null) 'entry_hash': entryHash,
      if (mac != null) 'mac': mac,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (serverReceipt != null) 'server_receipt': serverReceipt,
    });
  }

  ScanLedgerCompanion copyWith({
    Value<int>? seq,
    Value<String>? id,
    Value<String?>? accountId,
    Value<String>? submissionKey,
    Value<String?>? answerSheetId,
    Value<String>? tier,
    Value<String?>? entitlementTokenId,
    Value<DateTime>? consumedAt,
    Value<String>? prevHash,
    Value<String>? entryHash,
    Value<String>? mac,
    Value<DateTime?>? syncedAt,
    Value<String?>? serverReceipt,
  }) {
    return ScanLedgerCompanion(
      seq: seq ?? this.seq,
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      submissionKey: submissionKey ?? this.submissionKey,
      answerSheetId: answerSheetId ?? this.answerSheetId,
      tier: tier ?? this.tier,
      entitlementTokenId: entitlementTokenId ?? this.entitlementTokenId,
      consumedAt: consumedAt ?? this.consumedAt,
      prevHash: prevHash ?? this.prevHash,
      entryHash: entryHash ?? this.entryHash,
      mac: mac ?? this.mac,
      syncedAt: syncedAt ?? this.syncedAt,
      serverReceipt: serverReceipt ?? this.serverReceipt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (submissionKey.present) {
      map['submission_key'] = Variable<String>(submissionKey.value);
    }
    if (answerSheetId.present) {
      map['answer_sheet_id'] = Variable<String>(answerSheetId.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (entitlementTokenId.present) {
      map['entitlement_token_id'] = Variable<String>(entitlementTokenId.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    if (prevHash.present) {
      map['prev_hash'] = Variable<String>(prevHash.value);
    }
    if (entryHash.present) {
      map['entry_hash'] = Variable<String>(entryHash.value);
    }
    if (mac.present) {
      map['mac'] = Variable<String>(mac.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (serverReceipt.present) {
      map['server_receipt'] = Variable<String>(serverReceipt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanLedgerCompanion(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('submissionKey: $submissionKey, ')
          ..write('answerSheetId: $answerSheetId, ')
          ..write('tier: $tier, ')
          ..write('entitlementTokenId: $entitlementTokenId, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('prevHash: $prevHash, ')
          ..write('entryHash: $entryHash, ')
          ..write('mac: $mac, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('serverReceipt: $serverReceipt')
          ..write(')'))
        .toString();
  }
}

class AuditLogs extends Table with TableInfo<AuditLogs, AuditLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AuditLogs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (actor IN (\'instructor\', \'system\'))',
  );
  static const VerificationMeta _eventMeta = const VerificationMeta('event');
  late final GeneratedColumn<String> event = GeneratedColumn<String>(
    'event',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(event) BETWEEN 1 AND 80)',
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(entity_type) BETWEEN 1 AND 60)',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _examinationIdMeta = const VerificationMeta(
    'examinationId',
  );
  late final GeneratedColumn<String> examinationId = GeneratedColumn<String>(
    'examination_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _prevHashMeta = const VerificationMeta(
    'prevHash',
  );
  late final GeneratedColumn<String> prevHash = GeneratedColumn<String>(
    'prev_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(prev_hash) = 64)',
  );
  static const VerificationMeta _entryHashMeta = const VerificationMeta(
    'entryHash',
  );
  late final GeneratedColumn<String> entryHash = GeneratedColumn<String>(
    'entry_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE CHECK (length(entry_hash) = 64)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    id,
    occurredAt,
    actor,
    event,
    entityType,
    entityId,
    examinationId,
    details,
    prevHash,
    entryHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    } else if (isInserting) {
      context.missing(_actorMeta);
    }
    if (data.containsKey('event')) {
      context.handle(
        _eventMeta,
        event.isAcceptableOrUnknown(data['event']!, _eventMeta),
      );
    } else if (isInserting) {
      context.missing(_eventMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('examination_id')) {
      context.handle(
        _examinationIdMeta,
        examinationId.isAcceptableOrUnknown(
          data['examination_id']!,
          _examinationIdMeta,
        ),
      );
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    if (data.containsKey('prev_hash')) {
      context.handle(
        _prevHashMeta,
        prevHash.isAcceptableOrUnknown(data['prev_hash']!, _prevHashMeta),
      );
    } else if (isInserting) {
      context.missing(_prevHashMeta);
    }
    if (data.containsKey('entry_hash')) {
      context.handle(
        _entryHashMeta,
        entryHash.isAcceptableOrUnknown(data['entry_hash']!, _entryHashMeta),
      );
    } else if (isInserting) {
      context.missing(_entryHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  AuditLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      )!,
      event: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      examinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examination_id'],
      ),
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
      prevHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prev_hash'],
      )!,
      entryHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_hash'],
      )!,
    );
  }

  @override
  AuditLogs createAlias(String alias) {
    return AuditLogs(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AuditLogRow extends DataClass implements Insertable<AuditLogRow> {
  final int seq;
  final String id;
  final DateTime occurredAt;
  final String actor;

  /// Dotted event name, e.g. 'answer_key.revised', 'answer.overridden'.
  final String event;
  final String entityType;
  final String? entityId;

  /// Not a foreign key on purpose: history must outlive purged examinations.
  final String? examinationId;
  final String? details;
  final String prevHash;
  final String entryHash;
  const AuditLogRow({
    required this.seq,
    required this.id,
    required this.occurredAt,
    required this.actor,
    required this.event,
    required this.entityType,
    this.entityId,
    this.examinationId,
    this.details,
    required this.prevHash,
    required this.entryHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['id'] = Variable<String>(id);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['actor'] = Variable<String>(actor);
    map['event'] = Variable<String>(event);
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    if (!nullToAbsent || examinationId != null) {
      map['examination_id'] = Variable<String>(examinationId);
    }
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    map['prev_hash'] = Variable<String>(prevHash);
    map['entry_hash'] = Variable<String>(entryHash);
    return map;
  }

  AuditLogsCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsCompanion(
      seq: Value(seq),
      id: Value(id),
      occurredAt: Value(occurredAt),
      actor: Value(actor),
      event: Value(event),
      entityType: Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      examinationId: examinationId == null && nullToAbsent
          ? const Value.absent()
          : Value(examinationId),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      prevHash: Value(prevHash),
      entryHash: Value(entryHash),
    );
  }

  factory AuditLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogRow(
      seq: serializer.fromJson<int>(json['seq']),
      id: serializer.fromJson<String>(json['id']),
      occurredAt: serializer.fromJson<DateTime>(json['occurred_at']),
      actor: serializer.fromJson<String>(json['actor']),
      event: serializer.fromJson<String>(json['event']),
      entityType: serializer.fromJson<String>(json['entity_type']),
      entityId: serializer.fromJson<String?>(json['entity_id']),
      examinationId: serializer.fromJson<String?>(json['examination_id']),
      details: serializer.fromJson<String?>(json['details']),
      prevHash: serializer.fromJson<String>(json['prev_hash']),
      entryHash: serializer.fromJson<String>(json['entry_hash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'id': serializer.toJson<String>(id),
      'occurred_at': serializer.toJson<DateTime>(occurredAt),
      'actor': serializer.toJson<String>(actor),
      'event': serializer.toJson<String>(event),
      'entity_type': serializer.toJson<String>(entityType),
      'entity_id': serializer.toJson<String?>(entityId),
      'examination_id': serializer.toJson<String?>(examinationId),
      'details': serializer.toJson<String?>(details),
      'prev_hash': serializer.toJson<String>(prevHash),
      'entry_hash': serializer.toJson<String>(entryHash),
    };
  }

  AuditLogRow copyWith({
    int? seq,
    String? id,
    DateTime? occurredAt,
    String? actor,
    String? event,
    String? entityType,
    Value<String?> entityId = const Value.absent(),
    Value<String?> examinationId = const Value.absent(),
    Value<String?> details = const Value.absent(),
    String? prevHash,
    String? entryHash,
  }) => AuditLogRow(
    seq: seq ?? this.seq,
    id: id ?? this.id,
    occurredAt: occurredAt ?? this.occurredAt,
    actor: actor ?? this.actor,
    event: event ?? this.event,
    entityType: entityType ?? this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    examinationId: examinationId.present
        ? examinationId.value
        : this.examinationId,
    details: details.present ? details.value : this.details,
    prevHash: prevHash ?? this.prevHash,
    entryHash: entryHash ?? this.entryHash,
  );
  AuditLogRow copyWithCompanion(AuditLogsCompanion data) {
    return AuditLogRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      id: data.id.present ? data.id.value : this.id,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      actor: data.actor.present ? data.actor.value : this.actor,
      event: data.event.present ? data.event.value : this.event,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      examinationId: data.examinationId.present
          ? data.examinationId.value
          : this.examinationId,
      details: data.details.present ? data.details.value : this.details,
      prevHash: data.prevHash.present ? data.prevHash.value : this.prevHash,
      entryHash: data.entryHash.present ? data.entryHash.value : this.entryHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogRow(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('actor: $actor, ')
          ..write('event: $event, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('examinationId: $examinationId, ')
          ..write('details: $details, ')
          ..write('prevHash: $prevHash, ')
          ..write('entryHash: $entryHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    id,
    occurredAt,
    actor,
    event,
    entityType,
    entityId,
    examinationId,
    details,
    prevHash,
    entryHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogRow &&
          other.seq == this.seq &&
          other.id == this.id &&
          other.occurredAt == this.occurredAt &&
          other.actor == this.actor &&
          other.event == this.event &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.examinationId == this.examinationId &&
          other.details == this.details &&
          other.prevHash == this.prevHash &&
          other.entryHash == this.entryHash);
}

class AuditLogsCompanion extends UpdateCompanion<AuditLogRow> {
  final Value<int> seq;
  final Value<String> id;
  final Value<DateTime> occurredAt;
  final Value<String> actor;
  final Value<String> event;
  final Value<String> entityType;
  final Value<String?> entityId;
  final Value<String?> examinationId;
  final Value<String?> details;
  final Value<String> prevHash;
  final Value<String> entryHash;
  const AuditLogsCompanion({
    this.seq = const Value.absent(),
    this.id = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.actor = const Value.absent(),
    this.event = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.examinationId = const Value.absent(),
    this.details = const Value.absent(),
    this.prevHash = const Value.absent(),
    this.entryHash = const Value.absent(),
  });
  AuditLogsCompanion.insert({
    this.seq = const Value.absent(),
    required String id,
    required DateTime occurredAt,
    required String actor,
    required String event,
    required String entityType,
    this.entityId = const Value.absent(),
    this.examinationId = const Value.absent(),
    this.details = const Value.absent(),
    required String prevHash,
    required String entryHash,
  }) : id = Value(id),
       occurredAt = Value(occurredAt),
       actor = Value(actor),
       event = Value(event),
       entityType = Value(entityType),
       prevHash = Value(prevHash),
       entryHash = Value(entryHash);
  static Insertable<AuditLogRow> custom({
    Expression<int>? seq,
    Expression<String>? id,
    Expression<DateTime>? occurredAt,
    Expression<String>? actor,
    Expression<String>? event,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? examinationId,
    Expression<String>? details,
    Expression<String>? prevHash,
    Expression<String>? entryHash,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (id != null) 'id': id,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (actor != null) 'actor': actor,
      if (event != null) 'event': event,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (examinationId != null) 'examination_id': examinationId,
      if (details != null) 'details': details,
      if (prevHash != null) 'prev_hash': prevHash,
      if (entryHash != null) 'entry_hash': entryHash,
    });
  }

  AuditLogsCompanion copyWith({
    Value<int>? seq,
    Value<String>? id,
    Value<DateTime>? occurredAt,
    Value<String>? actor,
    Value<String>? event,
    Value<String>? entityType,
    Value<String?>? entityId,
    Value<String?>? examinationId,
    Value<String?>? details,
    Value<String>? prevHash,
    Value<String>? entryHash,
  }) {
    return AuditLogsCompanion(
      seq: seq ?? this.seq,
      id: id ?? this.id,
      occurredAt: occurredAt ?? this.occurredAt,
      actor: actor ?? this.actor,
      event: event ?? this.event,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      examinationId: examinationId ?? this.examinationId,
      details: details ?? this.details,
      prevHash: prevHash ?? this.prevHash,
      entryHash: entryHash ?? this.entryHash,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (event.present) {
      map['event'] = Variable<String>(event.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (examinationId.present) {
      map['examination_id'] = Variable<String>(examinationId.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (prevHash.present) {
      map['prev_hash'] = Variable<String>(prevHash.value);
    }
    if (entryHash.present) {
      map['entry_hash'] = Variable<String>(entryHash.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsCompanion(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('actor: $actor, ')
          ..write('event: $event, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('examinationId: $examinationId, ')
          ..write('details: $details, ')
          ..write('prevHash: $prevHash, ')
          ..write('entryHash: $entryHash')
          ..write(')'))
        .toString();
  }
}

class ApplicationSettings extends Table
    with TableInfo<ApplicationSettings, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ApplicationSettings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (length("key") BETWEEN 1 AND 100)',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(value) <= 10000)',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'application_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  ApplicationSettings createAlias(String alias) {
    return ApplicationSettings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSettingRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ApplicationSettingsCompanion toCompanion(bool nullToAbsent) {
    return ApplicationSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingRow copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSettingRow copyWithCompanion(ApplicationSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class ApplicationSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ApplicationSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApplicationSettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApplicationSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ApplicationSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
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
    return (StringBuffer('ApplicationSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class BackupRecords extends Table
    with TableInfo<BackupRecords, BackupRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  BackupRecords(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'local_export\', \'cloud_upload\', \'restore\'))',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'in_progress\', \'completed\', \'failed\'))',
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _remoteRefMeta = const VerificationMeta(
    'remoteRef',
  );
  late final GeneratedColumn<String> remoteRef = GeneratedColumn<String>(
    'remote_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (size_bytes IS NULL OR size_bytes >= 0)',
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (sha256 IS NULL OR length(sha256) = 64)',
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (schema_version >= 1)',
  );
  static const VerificationMeta _encryptedMeta = const VerificationMeta(
    'encrypted',
  );
  late final GeneratedColumn<bool> encrypted = GeneratedColumn<bool>(
    'encrypted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT TRUE',
    defaultValue: const CustomExpression('TRUE'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (error_message IS NULL OR length(error_message) <= 500)',
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    status,
    fileName,
    remoteRef,
    sizeBytes,
    sha256,
    schemaVersion,
    encrypted,
    errorMessage,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('remote_ref')) {
      context.handle(
        _remoteRefMeta,
        remoteRef.isAcceptableOrUnknown(data['remote_ref']!, _remoteRefMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('encrypted')) {
      context.handle(
        _encryptedMeta,
        encrypted.isAcceptableOrUnknown(data['encrypted']!, _encryptedMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      remoteRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_ref'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      encrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}encrypted'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  BackupRecords createAlias(String alias) {
    return BackupRecords(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class BackupRecordRow extends DataClass implements Insertable<BackupRecordRow> {
  final String id;
  final String kind;
  final String status;
  final String? fileName;
  final String? remoteRef;
  final int? sizeBytes;
  final String? sha256;
  final int schemaVersion;
  final bool encrypted;
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime? completedAt;
  const BackupRecordRow({
    required this.id,
    required this.kind,
    required this.status,
    this.fileName,
    this.remoteRef,
    this.sizeBytes,
    this.sha256,
    required this.schemaVersion,
    required this.encrypted,
    this.errorMessage,
    required this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || remoteRef != null) {
      map['remote_ref'] = Variable<String>(remoteRef);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    map['schema_version'] = Variable<int>(schemaVersion);
    map['encrypted'] = Variable<bool>(encrypted);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  BackupRecordsCompanion toCompanion(bool nullToAbsent) {
    return BackupRecordsCompanion(
      id: Value(id),
      kind: Value(kind),
      status: Value(status),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      remoteRef: remoteRef == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteRef),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      schemaVersion: Value(schemaVersion),
      encrypted: Value(encrypted),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory BackupRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupRecordRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      status: serializer.fromJson<String>(json['status']),
      fileName: serializer.fromJson<String?>(json['file_name']),
      remoteRef: serializer.fromJson<String?>(json['remote_ref']),
      sizeBytes: serializer.fromJson<int?>(json['size_bytes']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      schemaVersion: serializer.fromJson<int>(json['schema_version']),
      encrypted: serializer.fromJson<bool>(json['encrypted']),
      errorMessage: serializer.fromJson<String?>(json['error_message']),
      startedAt: serializer.fromJson<DateTime>(json['started_at']),
      completedAt: serializer.fromJson<DateTime?>(json['completed_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'status': serializer.toJson<String>(status),
      'file_name': serializer.toJson<String?>(fileName),
      'remote_ref': serializer.toJson<String?>(remoteRef),
      'size_bytes': serializer.toJson<int?>(sizeBytes),
      'sha256': serializer.toJson<String?>(sha256),
      'schema_version': serializer.toJson<int>(schemaVersion),
      'encrypted': serializer.toJson<bool>(encrypted),
      'error_message': serializer.toJson<String?>(errorMessage),
      'started_at': serializer.toJson<DateTime>(startedAt),
      'completed_at': serializer.toJson<DateTime?>(completedAt),
    };
  }

  BackupRecordRow copyWith({
    String? id,
    String? kind,
    String? status,
    Value<String?> fileName = const Value.absent(),
    Value<String?> remoteRef = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    Value<String?> sha256 = const Value.absent(),
    int? schemaVersion,
    bool? encrypted,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => BackupRecordRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    status: status ?? this.status,
    fileName: fileName.present ? fileName.value : this.fileName,
    remoteRef: remoteRef.present ? remoteRef.value : this.remoteRef,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    sha256: sha256.present ? sha256.value : this.sha256,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    encrypted: encrypted ?? this.encrypted,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  BackupRecordRow copyWithCompanion(BackupRecordsCompanion data) {
    return BackupRecordRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      status: data.status.present ? data.status.value : this.status,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      remoteRef: data.remoteRef.present ? data.remoteRef.value : this.remoteRef,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      encrypted: data.encrypted.present ? data.encrypted.value : this.encrypted,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupRecordRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('fileName: $fileName, ')
          ..write('remoteRef: $remoteRef, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('encrypted: $encrypted, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    status,
    fileName,
    remoteRef,
    sizeBytes,
    sha256,
    schemaVersion,
    encrypted,
    errorMessage,
    startedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupRecordRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.status == this.status &&
          other.fileName == this.fileName &&
          other.remoteRef == this.remoteRef &&
          other.sizeBytes == this.sizeBytes &&
          other.sha256 == this.sha256 &&
          other.schemaVersion == this.schemaVersion &&
          other.encrypted == this.encrypted &&
          other.errorMessage == this.errorMessage &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class BackupRecordsCompanion extends UpdateCompanion<BackupRecordRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> status;
  final Value<String?> fileName;
  final Value<String?> remoteRef;
  final Value<int?> sizeBytes;
  final Value<String?> sha256;
  final Value<int> schemaVersion;
  final Value<bool> encrypted;
  final Value<String?> errorMessage;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const BackupRecordsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.fileName = const Value.absent(),
    this.remoteRef = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.encrypted = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BackupRecordsCompanion.insert({
    required String id,
    required String kind,
    required String status,
    this.fileName = const Value.absent(),
    this.remoteRef = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    required int schemaVersion,
    this.encrypted = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       status = Value(status),
       schemaVersion = Value(schemaVersion),
       startedAt = Value(startedAt);
  static Insertable<BackupRecordRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? status,
    Expression<String>? fileName,
    Expression<String>? remoteRef,
    Expression<int>? sizeBytes,
    Expression<String>? sha256,
    Expression<int>? schemaVersion,
    Expression<bool>? encrypted,
    Expression<String>? errorMessage,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (status != null) 'status': status,
      if (fileName != null) 'file_name': fileName,
      if (remoteRef != null) 'remote_ref': remoteRef,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (sha256 != null) 'sha256': sha256,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (encrypted != null) 'encrypted': encrypted,
      if (errorMessage != null) 'error_message': errorMessage,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BackupRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? status,
    Value<String?>? fileName,
    Value<String?>? remoteRef,
    Value<int?>? sizeBytes,
    Value<String?>? sha256,
    Value<int>? schemaVersion,
    Value<bool>? encrypted,
    Value<String?>? errorMessage,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return BackupRecordsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      remoteRef: remoteRef ?? this.remoteRef,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      encrypted: encrypted ?? this.encrypted,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (remoteRef.present) {
      map['remote_ref'] = Variable<String>(remoteRef.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (encrypted.present) {
      map['encrypted'] = Variable<bool>(encrypted.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupRecordsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('fileName: $fileName, ')
          ..write('remoteRef: $remoteRef, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('encrypted: $encrypted, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final InstructorProfiles instructorProfiles = InstructorProfiles(this);
  late final Subjects subjects = Subjects(this);
  late final Index subjectsCodeActive = Index(
    'subjects_code_active',
    'CREATE UNIQUE INDEX subjects_code_active ON subjects (code COLLATE NOCASE) WHERE deleted_at IS NULL',
  );
  late final Courses courses = Courses(this);
  late final Index coursesCodeActive = Index(
    'courses_code_active',
    'CREATE UNIQUE INDEX courses_code_active ON courses (code COLLATE NOCASE) WHERE deleted_at IS NULL',
  );
  late final Sections sections = Sections(this);
  late final Index sectionsCourse = Index(
    'sections_course',
    'CREATE INDEX sections_course ON sections (course_id)',
  );
  late final Index sectionsNameTermActive = Index(
    'sections_name_term_active',
    'CREATE UNIQUE INDEX sections_name_term_active ON sections (name COLLATE NOCASE, ifnull(school_year, \'\'), ifnull(term, \'\')) WHERE deleted_at IS NULL',
  );
  late final Students students = Students(this);
  late final Index studentsNoKeyActive = Index(
    'students_no_key_active',
    'CREATE UNIQUE INDEX students_no_key_active ON students (student_no_key) WHERE deleted_at IS NULL',
  );
  late final Index studentsName = Index(
    'students_name',
    'CREATE INDEX students_name ON students (last_name COLLATE NOCASE, first_name COLLATE NOCASE)',
  );
  late final SectionStudents sectionStudents = SectionStudents(this);
  late final Index sectionStudentsStudent = Index(
    'section_students_student',
    'CREATE INDEX section_students_student ON section_students (student_id)',
  );
  late final Examinations examinations = Examinations(this);
  late final Index examinationsSubject = Index(
    'examinations_subject',
    'CREATE INDEX examinations_subject ON examinations (subject_id)',
  );
  late final Index examinationsRecent = Index(
    'examinations_recent',
    'CREATE INDEX examinations_recent ON examinations (deleted_at, updated_at)',
  );
  late final ExaminationSections examinationSections = ExaminationSections(
    this,
  );
  late final Index examinationSectionsSection = Index(
    'examination_sections_section',
    'CREATE INDEX examination_sections_section ON examination_sections (section_id)',
  );
  late final ExaminationVersions examinationVersions = ExaminationVersions(
    this,
  );
  late final AnswerKeys answerKeys = AnswerKeys(this);
  late final Index answerKeysOneCurrent = Index(
    'answer_keys_one_current',
    'CREATE UNIQUE INDEX answer_keys_one_current ON answer_keys (examination_version_id) WHERE is_current = 1',
  );
  late final AnswerKeyItems answerKeyItems = AnswerKeyItems(this);
  late final PrintedSheets printedSheets = PrintedSheets(this);
  late final Index printedSheetsExam = Index(
    'printed_sheets_exam',
    'CREATE INDEX printed_sheets_exam ON printed_sheets (examination_id)',
  );
  late final Index printedSheetsStudent = Index(
    'printed_sheets_student',
    'CREATE INDEX printed_sheets_student ON printed_sheets (student_id)',
  );
  late final ScanSessions scanSessions = ScanSessions(this);
  late final Index scanSessionsExam = Index(
    'scan_sessions_exam',
    'CREATE INDEX scan_sessions_exam ON scan_sessions (examination_id, started_at)',
  );
  late final AnswerSheets answerSheets = AnswerSheets(this);
  late final Index answerSheetsOneFinal = Index(
    'answer_sheets_one_final',
    'CREATE UNIQUE INDEX answer_sheets_one_final ON answer_sheets (submission_key) WHERE status = \'finalized\'',
  );
  late final Index answerSheetsExamStatus = Index(
    'answer_sheets_exam_status',
    'CREATE INDEX answer_sheets_exam_status ON answer_sheets (examination_id, status)',
  );
  late final Index answerSheetsStudent = Index(
    'answer_sheets_student',
    'CREATE INDEX answer_sheets_student ON answer_sheets (student_id)',
  );
  late final StudentAnswers studentAnswers = StudentAnswers(this);
  late final ExaminationResults examinationResults = ExaminationResults(this);
  late final Index examinationResultsOneCurrent = Index(
    'examination_results_one_current',
    'CREATE UNIQUE INDEX examination_results_one_current ON examination_results (answer_sheet_id) WHERE is_current = 1',
  );
  late final Index examinationResultsKey = Index(
    'examination_results_key',
    'CREATE INDEX examination_results_key ON examination_results (answer_key_id)',
  );
  late final SubscriptionEntitlements subscriptionEntitlements =
      SubscriptionEntitlements(this);
  late final Index subscriptionEntitlementsOneCurrent = Index(
    'subscription_entitlements_one_current',
    'CREATE UNIQUE INDEX subscription_entitlements_one_current ON subscription_entitlements (is_current) WHERE is_current = 1',
  );
  late final ScanLedger scanLedger = ScanLedger(this);
  late final Index scanLedgerUnsynced = Index(
    'scan_ledger_unsynced',
    'CREATE INDEX scan_ledger_unsynced ON scan_ledger (synced_at, seq)',
  );
  late final Trigger scanLedgerNoDelete = Trigger(
    'CREATE TRIGGER scan_ledger_no_delete BEFORE DELETE ON scan_ledger BEGIN SELECT RAISE (ABORT, \'scan_ledger is append-only\');END',
    'scan_ledger_no_delete',
  );
  late final Trigger scanLedgerImmutable = Trigger(
    'CREATE TRIGGER scan_ledger_immutable BEFORE UPDATE ON scan_ledger WHEN NEW.seq IS NOT OLD.seq OR NEW.id IS NOT OLD.id OR NEW.account_id IS NOT OLD.account_id OR NEW.submission_key IS NOT OLD.submission_key OR NEW.tier IS NOT OLD.tier OR NEW.entitlement_token_id IS NOT OLD.entitlement_token_id OR NEW.consumed_at IS NOT OLD.consumed_at OR NEW.prev_hash IS NOT OLD.prev_hash OR NEW.entry_hash IS NOT OLD.entry_hash OR NEW.mac IS NOT OLD.mac OR(NEW.answer_sheet_id IS NOT OLD.answer_sheet_id AND NEW.answer_sheet_id IS NOT NULL)OR(OLD.synced_at IS NOT NULL AND NEW.synced_at IS NOT OLD.synced_at)OR(OLD.server_receipt IS NOT NULL AND NEW.server_receipt IS NOT OLD.server_receipt)BEGIN SELECT RAISE (ABORT, \'scan_ledger rows are immutable\');END',
    'scan_ledger_immutable',
  );
  late final AuditLogs auditLogs = AuditLogs(this);
  late final Index auditLogsExam = Index(
    'audit_logs_exam',
    'CREATE INDEX audit_logs_exam ON audit_logs (examination_id, seq)',
  );
  late final Index auditLogsEntity = Index(
    'audit_logs_entity',
    'CREATE INDEX audit_logs_entity ON audit_logs (entity_type, entity_id)',
  );
  late final Trigger auditLogsNoDelete = Trigger(
    'CREATE TRIGGER audit_logs_no_delete BEFORE DELETE ON audit_logs BEGIN SELECT RAISE (ABORT, \'audit_logs is append-only\');END',
    'audit_logs_no_delete',
  );
  late final Trigger auditLogsNoUpdate = Trigger(
    'CREATE TRIGGER audit_logs_no_update BEFORE UPDATE ON audit_logs BEGIN SELECT RAISE (ABORT, \'audit_logs is append-only\');END',
    'audit_logs_no_update',
  );
  late final ApplicationSettings applicationSettings = ApplicationSettings(
    this,
  );
  late final BackupRecords backupRecords = BackupRecords(this);
  late final Index backupRecordsStarted = Index(
    'backup_records_started',
    'CREATE INDEX backup_records_started ON backup_records (started_at)',
  );
  Selectable<DashboardStatsResult> dashboardStats() {
    return customSelect(
      'SELECT (SELECT COUNT(*) FROM examinations WHERE deleted_at IS NULL) AS exam_count, (SELECT COUNT(*) FROM answer_sheets AS a INNER JOIN examinations AS e ON e.id = a.examination_id WHERE a.status = \'finalized\' AND e.deleted_at IS NULL) AS papers_scanned, (SELECT COUNT(*) FROM scan_ledger WHERE tier = \'free\') AS free_scans_used_local',
      variables: [],
      readsFrom: {this.examinations, this.answerSheets, this.scanLedger},
    ).map(
      (QueryRow row) => DashboardStatsResult(
        examCount: row.read<int>('exam_count'),
        papersScanned: row.read<int>('papers_scanned'),
        freeScansUsedLocal: row.read<int>('free_scans_used_local'),
      ),
    );
  }

  Selectable<RecentExaminationsResult> recentExaminations({
    required int limit,
  }) {
    return customSelect(
      'SELECT e.id, e.title, e.item_count, e.status, e.exam_date, e.updated_at, s.code AS subject_code, (SELECT COUNT(*) FROM answer_sheets AS a WHERE a.examination_id = e.id AND a.status = \'finalized\') AS finalized_count FROM examinations AS e LEFT JOIN subjects AS s ON s.id = e.subject_id WHERE e.deleted_at IS NULL ORDER BY e.updated_at DESC LIMIT ?1',
      variables: [Variable<int>(limit)],
      readsFrom: {this.examinations, this.subjects, this.answerSheets},
    ).map(
      (QueryRow row) => RecentExaminationsResult(
        id: row.read<String>('id'),
        title: row.read<String>('title'),
        itemCount: row.read<int>('item_count'),
        status: row.read<String>('status'),
        examDate: row.readNullable<DateTime>('exam_date'),
        updatedAt: row.read<DateTime>('updated_at'),
        subjectCode: row.readNullable<String>('subject_code'),
        finalizedCount: row.read<int>('finalized_count'),
      ),
    );
  }

  Selectable<SectionSummariesResult> sectionSummaries() {
    return customSelect(
      'SELECT"s"."id" AS "nested_0.id", "s"."course_id" AS "nested_0.course_id", "s"."name" AS "nested_0.name", "s"."year_level" AS "nested_0.year_level", "s"."school_year" AS "nested_0.school_year", "s"."term" AS "nested_0.term", "s"."created_at" AS "nested_0.created_at", "s"."updated_at" AS "nested_0.updated_at", "s"."deleted_at" AS "nested_0.deleted_at", c.code AS course_code, (SELECT COUNT(*) FROM section_students AS ss INNER JOIN students AS st ON st.id = ss.student_id WHERE ss.section_id = s.id AND st.deleted_at IS NULL) AS student_count FROM sections AS s LEFT JOIN courses AS c ON c.id = s.course_id WHERE s.deleted_at IS NULL ORDER BY s.name COLLATE NOCASE, s.school_year DESC',
      variables: [],
      readsFrom: {
        this.courses,
        this.sectionStudents,
        this.students,
        this.sections,
      },
    ).asyncMap(
      (QueryRow row) async => SectionSummariesResult(
        s: await this.sections.mapFromRow(row, tablePrefix: 'nested_0'),
        courseCode: row.readNullable<String>('course_code'),
        studentCount: row.read<int>('student_count'),
      ),
    );
  }

  Selectable<StudentRow> sectionRoster({required String sectionId}) {
    return customSelect(
      'SELECT st.* FROM students AS st INNER JOIN section_students AS ss ON ss.student_id = st.id WHERE ss.section_id = ?1 AND st.deleted_at IS NULL ORDER BY st.last_name COLLATE NOCASE, st.first_name COLLATE NOCASE, st.student_no',
      variables: [Variable<String>(sectionId)],
      readsFrom: {this.students, this.sectionStudents},
    ).asyncMap(this.students.mapFromRow);
  }

  Selectable<ActiveExaminationListResult> activeExaminationList() {
    return customSelect(
      'SELECT"e"."id" AS "nested_0.id", "e"."short_code" AS "nested_0.short_code", "e"."title" AS "nested_0.title", "e"."subject_id" AS "nested_0.subject_id", "e"."instructor_id" AS "nested_0.instructor_id", "e"."exam_date" AS "nested_0.exam_date", "e"."item_count" AS "nested_0.item_count", "e"."choice_count" AS "nested_0.choice_count", "e"."passing_percentage" AS "nested_0.passing_percentage", "e"."multiple_mark_policy" AS "nested_0.multiple_mark_policy", "e"."allow_negative_total" AS "nested_0.allow_negative_total", "e"."omr_preset" AS "nested_0.omr_preset", "e"."omr_thresholds" AS "nested_0.omr_thresholds", "e"."student_id_digits" AS "nested_0.student_id_digits", "e"."status" AS "nested_0.status", "e"."created_at" AS "nested_0.created_at", "e"."updated_at" AS "nested_0.updated_at", "e"."deleted_at" AS "nested_0.deleted_at", sub.code AS subject_code, sub.title AS subject_title, (SELECT COUNT(*) FROM examination_versions AS v WHERE v.examination_id = e.id) AS version_count, (SELECT COUNT(*) FROM answer_sheets AS a WHERE a.examination_id = e.id AND a.status = \'finalized\') AS paper_count FROM examinations AS e LEFT JOIN subjects AS sub ON sub.id = e.subject_id WHERE e.deleted_at IS NULL ORDER BY e.updated_at DESC',
      variables: [],
      readsFrom: {
        this.subjects,
        this.examinationVersions,
        this.examinations,
        this.answerSheets,
      },
    ).asyncMap(
      (QueryRow row) async => ActiveExaminationListResult(
        e: await this.examinations.mapFromRow(row, tablePrefix: 'nested_0'),
        subjectCode: row.readNullable<String>('subject_code'),
        subjectTitle: row.readNullable<String>('subject_title'),
        versionCount: row.read<int>('version_count'),
        paperCount: row.read<int>('paper_count'),
      ),
    );
  }

  Selectable<DeletedExaminationListResult> deletedExaminationList() {
    return customSelect(
      'SELECT"e"."id" AS "nested_0.id", "e"."short_code" AS "nested_0.short_code", "e"."title" AS "nested_0.title", "e"."subject_id" AS "nested_0.subject_id", "e"."instructor_id" AS "nested_0.instructor_id", "e"."exam_date" AS "nested_0.exam_date", "e"."item_count" AS "nested_0.item_count", "e"."choice_count" AS "nested_0.choice_count", "e"."passing_percentage" AS "nested_0.passing_percentage", "e"."multiple_mark_policy" AS "nested_0.multiple_mark_policy", "e"."allow_negative_total" AS "nested_0.allow_negative_total", "e"."omr_preset" AS "nested_0.omr_preset", "e"."omr_thresholds" AS "nested_0.omr_thresholds", "e"."student_id_digits" AS "nested_0.student_id_digits", "e"."status" AS "nested_0.status", "e"."created_at" AS "nested_0.created_at", "e"."updated_at" AS "nested_0.updated_at", "e"."deleted_at" AS "nested_0.deleted_at", sub.code AS subject_code, sub.title AS subject_title, (SELECT COUNT(*) FROM examination_versions AS v WHERE v.examination_id = e.id) AS version_count, (SELECT COUNT(*) FROM answer_sheets AS a WHERE a.examination_id = e.id AND a.status = \'finalized\') AS paper_count FROM examinations AS e LEFT JOIN subjects AS sub ON sub.id = e.subject_id WHERE e.deleted_at IS NOT NULL ORDER BY e.deleted_at DESC',
      variables: [],
      readsFrom: {
        this.subjects,
        this.examinationVersions,
        this.examinations,
        this.answerSheets,
      },
    ).asyncMap(
      (QueryRow row) async => DeletedExaminationListResult(
        e: await this.examinations.mapFromRow(row, tablePrefix: 'nested_0'),
        subjectCode: row.readNullable<String>('subject_code'),
        subjectTitle: row.readNullable<String>('subject_title'),
        versionCount: row.read<int>('version_count'),
        paperCount: row.read<int>('paper_count'),
      ),
    );
  }

  Selectable<VersionKeyStatusResult> versionKeyStatus({
    required String examinationId,
  }) {
    return customSelect(
      'SELECT"v"."id" AS "nested_0.id", "v"."examination_id" AS "nested_0.examination_id", "v"."label" AS "nested_0.label", "v"."created_at" AS "nested_0.created_at", k.id AS key_id, k.revision AS revision, (SELECT COUNT(*) FROM answer_key_items AS i WHERE i.answer_key_id = k.id AND(i.mode <> \'normal\' OR i.correct_mask <> 0)) AS complete_count, (SELECT COUNT(*) FROM answer_key_items AS i WHERE i.answer_key_id = k.id) AS item_total FROM examination_versions AS v INNER JOIN answer_keys AS k ON k.examination_version_id = v.id AND k.is_current = 1 WHERE v.examination_id = ?1 ORDER BY v.label',
      variables: [Variable<String>(examinationId)],
      readsFrom: {
        this.answerKeys,
        this.answerKeyItems,
        this.examinationVersions,
      },
    ).asyncMap(
      (QueryRow row) async => VersionKeyStatusResult(
        v: await this.examinationVersions.mapFromRow(
          row,
          tablePrefix: 'nested_0',
        ),
        keyId: row.read<String>('key_id'),
        revision: row.read<int>('revision'),
        completeCount: row.read<int>('complete_count'),
        itemTotal: row.read<int>('item_total'),
      ),
    );
  }

  Selectable<SectionRow> examinationSectionList({
    required String examinationId,
  }) {
    return customSelect(
      'SELECT s.* FROM sections AS s INNER JOIN examination_sections AS es ON es.section_id = s.id WHERE es.examination_id = ?1 ORDER BY s.name COLLATE NOCASE',
      variables: [Variable<String>(examinationId)],
      readsFrom: {this.sections, this.examinationSections},
    ).asyncMap(this.sections.mapFromRow);
  }

  Selectable<int> incompleteKeyItemCount({required String examinationId}) {
    return customSelect(
      'SELECT COUNT(*) AS _c0 FROM answer_key_items AS i INNER JOIN answer_keys AS k ON k.id = i.answer_key_id AND k.is_current = 1 INNER JOIN examination_versions AS v ON v.id = k.examination_version_id WHERE v.examination_id = ?1 AND i.mode = \'normal\' AND i.correct_mask = 0',
      variables: [Variable<String>(examinationId)],
      readsFrom: {
        this.answerKeyItems,
        this.answerKeys,
        this.examinationVersions,
      },
    ).map((QueryRow row) => row.read<int>('_c0'));
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    instructorProfiles,
    subjects,
    subjectsCodeActive,
    courses,
    coursesCodeActive,
    sections,
    sectionsCourse,
    sectionsNameTermActive,
    students,
    studentsNoKeyActive,
    studentsName,
    sectionStudents,
    sectionStudentsStudent,
    examinations,
    examinationsSubject,
    examinationsRecent,
    examinationSections,
    examinationSectionsSection,
    examinationVersions,
    answerKeys,
    answerKeysOneCurrent,
    answerKeyItems,
    printedSheets,
    printedSheetsExam,
    printedSheetsStudent,
    scanSessions,
    scanSessionsExam,
    answerSheets,
    answerSheetsOneFinal,
    answerSheetsExamStatus,
    answerSheetsStudent,
    studentAnswers,
    examinationResults,
    examinationResultsOneCurrent,
    examinationResultsKey,
    subscriptionEntitlements,
    subscriptionEntitlementsOneCurrent,
    scanLedger,
    scanLedgerUnsynced,
    scanLedgerNoDelete,
    scanLedgerImmutable,
    auditLogs,
    auditLogsExam,
    auditLogsEntity,
    auditLogsNoDelete,
    auditLogsNoUpdate,
    applicationSettings,
    backupRecords,
    backupRecordsStarted,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('section_students', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('section_students', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'instructor_profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('examinations', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'examinations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('examination_sections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'examinations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('examination_versions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'examination_versions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answer_keys', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'answer_keys',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answer_key_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'examinations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('printed_sheets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('printed_sheets', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'examinations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('scan_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'examinations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answer_sheets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scan_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answer_sheets', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'printed_sheets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answer_sheets', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answer_sheets', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'answer_sheets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('student_answers', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'answer_sheets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('examination_results', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'answer_sheets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('scan_ledger', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scan_ledger',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scan_ledger',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'audit_logs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'audit_logs',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
  ]);
}

class DashboardStatsResult {
  final int examCount;
  final int papersScanned;
  final int freeScansUsedLocal;
  DashboardStatsResult({
    required this.examCount,
    required this.papersScanned,
    required this.freeScansUsedLocal,
  });
}

class RecentExaminationsResult {
  final String id;
  final String title;
  final int itemCount;
  final String status;
  final DateTime? examDate;
  final DateTime updatedAt;
  final String? subjectCode;
  final int finalizedCount;
  RecentExaminationsResult({
    required this.id,
    required this.title,
    required this.itemCount,
    required this.status,
    this.examDate,
    required this.updatedAt,
    this.subjectCode,
    required this.finalizedCount,
  });
}

class SectionSummariesResult {
  final SectionRow s;
  final String? courseCode;
  final int studentCount;
  SectionSummariesResult({
    required this.s,
    this.courseCode,
    required this.studentCount,
  });
}

class ActiveExaminationListResult {
  final ExaminationRow e;
  final String? subjectCode;
  final String? subjectTitle;
  final int versionCount;
  final int paperCount;
  ActiveExaminationListResult({
    required this.e,
    this.subjectCode,
    this.subjectTitle,
    required this.versionCount,
    required this.paperCount,
  });
}

class DeletedExaminationListResult {
  final ExaminationRow e;
  final String? subjectCode;
  final String? subjectTitle;
  final int versionCount;
  final int paperCount;
  DeletedExaminationListResult({
    required this.e,
    this.subjectCode,
    this.subjectTitle,
    required this.versionCount,
    required this.paperCount,
  });
}

class VersionKeyStatusResult {
  final ExaminationVersionRow v;
  final String keyId;
  final int revision;
  final int completeCount;
  final int itemTotal;
  VersionKeyStatusResult({
    required this.v,
    required this.keyId,
    required this.revision,
    required this.completeCount,
    required this.itemTotal,
  });
}
