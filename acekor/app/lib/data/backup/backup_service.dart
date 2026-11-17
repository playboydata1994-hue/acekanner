import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../db/app_database.dart';
import '../settings/settings_repository.dart';

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// What can be read from a backup file without its password.
class BackupHeader {
  const BackupHeader({
    required this.created,
    required this.appVersion,
    required this.schemaVersion,
    required this.salt,
    required this.nonce,
    required this.iterations,
  });

  final DateTime created;
  final String appVersion;
  final int schemaVersion;
  final List<int> salt;
  final List<int> nonce;
  final int iterations;
}

/// A decrypted backup, ready to restore.
class BackupContents {
  const BackupContents(this.header, this.tables);
  final BackupHeader header;
  final Map<String, List<Map<String, Object?>>> tables;

  int count(String table) => tables[table]?.length ?? 0;
}

/// Local backup and restoration.
///
/// File format (`.acekor`):
///   "ACEKORBK" + version byte (1)
///   uint32 big-endian header length + header JSON (date, app and schema
///   version, PBKDF2 salt and iterations, AES-GCM nonce)
///   AES-256-GCM ciphertext of gzip(JSON of every table) + 16-byte MAC
/// The key is derived from the instructor's password (PBKDF2-HMAC-SHA256).
class BackupService {
  BackupService(this._db, {this.clock = const Clock(), this.iterations = 150000});

  static const List<int> magic = [0x41, 0x43, 0x45, 0x4B, 0x4F, 0x52, 0x42, 0x4B]; // ACEKORBK
  static const int formatVersion = 1;
  static const String extension = 'acekor';

  /// Tables in an order that satisfies foreign keys when inserting.
  static const List<String> tables = [
    'instructor_profile',
    'sections',
    'students',
    'grade_scales',
    'grade_scale_rows',
    'subjects',
    'subject_students',
    'categories',
    'subject_weights',
    'activities',
    'scores',
    'score_history',
    'calc_history',
    'app_settings',
  ];

  /// Settings that belong to this phone and are never restored from a file
  /// (the PIN lives in this phone's secure storage; the plan is re-checked).
  static bool _deviceSetting(String key) =>
      key.startsWith('lock.') || key.startsWith('plan.') || key == SettingKeys.lastBackupAt;

  final AppDatabase _db;
  final Clock clock;
  final int iterations;

  Future<SecretKey> _key(String password, List<int> salt, int iterations) => Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);

  /// Counts of the main records, for the backup screen.
  Future<Map<String, int>> currentCounts() async {
    final out = <String, int>{};
    for (final t in ['students', 'subjects', 'activities', 'scores']) {
      final r = await _db.customSelect('SELECT count(*) AS n FROM $t').getSingle();
      out[t] = r.read<int>('n');
    }
    return out;
  }

  /// Creates an encrypted backup of everything.
  Future<Uint8List> create(String password, {required String appVersion}) async {
    if (password.length < 6) throw const BackupException('Use a backup password of at least 6 characters.');
    final data = <String, List<Map<String, Object?>>>{};
    for (final t in tables) {
      final rows = await _db.customSelect('SELECT * FROM $t').get();
      data[t] = [
        for (final r in rows)
          if (t != 'app_settings' || !_deviceSetting(r.data['setting_key'] as String)) r.data,
      ];
    }
    final plain = GZipCodec().encode(utf8.encode(jsonEncode({'tables': data})));
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final aes = AesGcm.with256bits();
    final nonce = aes.newNonce();
    final box = await aes.encrypt(plain, secretKey: await _key(password, salt, iterations), nonce: nonce);
    final header = utf8.encode(
      jsonEncode({
        'created': clock.now().toUtc().toIso8601String(),
        'app': appVersion,
        'schema': AppDatabase.currentSchemaVersion,
        'kdf': {'alg': 'pbkdf2-hmac-sha256', 'iter': iterations, 'salt': base64.encode(salt)},
        'nonce': base64.encode(nonce),
      }),
    );
    final out = BytesBuilder(copy: false)
      ..add(magic)
      ..addByte(formatVersion)
      ..add((ByteData(4)..setUint32(0, header.length)).buffer.asUint8List())
      ..add(header)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return out.toBytes();
  }

  /// Reads the unencrypted header. Throws [BackupException] if this is not
  /// an ACEkor backup.
  BackupHeader readHeader(Uint8List bytes) => _parse(bytes).$1;

  (BackupHeader, int) _parse(Uint8List bytes) {
    if (bytes.length < magic.length + 5 + 16) throw const BackupException('This is not an ACEkor backup file.');
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) throw const BackupException('This is not an ACEkor backup file.');
    }
    if (bytes[magic.length] != formatVersion) {
      throw const BackupException('This backup was made by a newer ACEkor. Update the app first.');
    }
    final len = ByteData.sublistView(bytes, magic.length + 1, magic.length + 5).getUint32(0);
    final start = magic.length + 5;
    if (start + len > bytes.length) throw const BackupException('The backup file is damaged.');
    try {
      final h = jsonDecode(utf8.decode(bytes.sublist(start, start + len))) as Map<String, dynamic>;
      final kdf = h['kdf'] as Map<String, dynamic>;
      return (
        BackupHeader(
          created: DateTime.parse(h['created'] as String),
          appVersion: h['app'] as String,
          schemaVersion: (h['schema'] as num).toInt(),
          salt: base64.decode(kdf['salt'] as String),
          nonce: base64.decode(h['nonce'] as String),
          iterations: (kdf['iter'] as num).toInt(),
        ),
        start + len,
      );
    } catch (_) {
      throw const BackupException('The backup file is damaged.');
    }
  }

  /// Decrypts with [password]. Throws [BackupException] for a wrong password
  /// or a damaged file.
  Future<BackupContents> open(Uint8List bytes, String password) async {
    final (header, body) = _parse(bytes);
    if (header.schemaVersion > AppDatabase.currentSchemaVersion) {
      throw const BackupException('This backup was made by a newer ACEkor. Update the app first.');
    }
    final cipher = bytes.sublist(body, bytes.length - 16);
    final mac = Mac(bytes.sublist(bytes.length - 16));
    final List<int> plain;
    try {
      plain = await AesGcm.with256bits().decrypt(
        SecretBox(cipher, nonce: header.nonce, mac: mac),
        secretKey: await _key(password, header.salt, header.iterations),
      );
    } on SecretBoxAuthenticationError {
      throw const BackupException('Wrong password, or the file is damaged.');
    }
    final json = jsonDecode(utf8.decode(GZipCodec().decode(plain))) as Map<String, dynamic>;
    final raw = json['tables'] as Map<String, dynamic>;
    return BackupContents(header, {
      for (final e in raw.entries) e.key: [for (final r in e.value as List) (r as Map).cast<String, Object?>()],
    });
  }

  /// Replaces every record with the backup's, in one transaction (all or
  /// nothing). Settings that belong to this phone are kept.
  Future<void> restore(BackupContents contents) async {
    final keep = await _db.customSelect('SELECT * FROM app_settings').get();
    await _db.transaction(() async {
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final t in tables.reversed) {
        await _db.customStatement('DELETE FROM $t');
      }
      for (final t in tables) {
        final rows = contents.tables[t] ?? const [];
        if (rows.isEmpty) continue;
        final columns = (await _db.customSelect('PRAGMA table_info($t)').get())
            .map((r) => r.read<String>('name'))
            .toSet();
        for (final row in rows) {
          if (t == 'app_settings' && _deviceSetting(row['setting_key'] as String)) continue;
          final cols = row.keys.where(columns.contains).toList();
          await _db.customInsert(
            'INSERT OR REPLACE INTO $t (${cols.join(', ')}) VALUES (${List.filled(cols.length, '?').join(', ')})',
            variables: [for (final c in cols) _variable(row[c])],
          );
        }
        // Inserting scores wrote "create" history rows; the backup's own
        // history replaces them.
        if (t == 'scores') await _db.customStatement('DELETE FROM score_history');
      }
      for (final r in keep) {
        final k = r.read<String>('setting_key');
        if (_deviceSetting(k)) {
          await _db.customInsert(
            'INSERT OR REPLACE INTO app_settings (setting_key, value, updated_at) VALUES (?, ?, ?)',
            variables: [
              Variable.withString(k),
              Variable.withString(r.read<String>('value')),
              Variable.withInt(r.read<int>('updated_at')),
            ],
          );
        }
      }
    });
    await AppDatabase.seed(_db);
    final problems = await _db.integrityProblems();
    if (problems.isNotEmpty) throw BackupException('Restored, but the check found problems: ${problems.first}');
    // Every table changed: let open screens reload.
    _db.notifyUpdates({for (final t in _db.allTables) TableUpdate.onTable(t)});
  }

  static Variable<Object> _variable(Object? v) => switch (v) {
    null => const Variable(null),
    final int i => Variable.withInt(i),
    final double d => Variable.withReal(d),
    final bool b => Variable.withInt(b ? 1 : 0),
    final String s => Variable.withString(s),
    _ => Variable.withString(v.toString()),
  };
}
