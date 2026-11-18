import 'dart:math';

import 'secret_store.dart';

/// Result of looking up the database encryption key.
sealed class DatabaseKeyOutcome {
  const DatabaseKeyOutcome();
}

class DatabaseKeyReady extends DatabaseKeyOutcome {
  const DatabaseKeyReady(this.hexKey, {required this.created});

  /// 256-bit key as 64 lower-case hex characters.
  final String hexKey;

  /// True when the key was generated during this call (first run).
  final bool created;
}

/// A database file exists, but its key is gone (for example the Keystore was
/// reset). The data cannot be decrypted; the user must restore a backup or
/// start fresh.
class DatabaseKeyMissing extends DatabaseKeyOutcome {
  const DatabaseKeyMissing();
}

/// Creates and retrieves the random key that encrypts the local database.
class DatabaseKeyManager {
  DatabaseKeyManager(this._store, {Random? random}) : _random = random ?? Random.secure();

  static const String storageKey = 'acekor.db_key.v1';

  final SecretStore _store;
  final Random _random;

  Future<DatabaseKeyOutcome> obtain({required bool databaseExists}) async {
    final existing = await _store.read(storageKey);
    if (existing != null && _isValid(existing)) {
      return DatabaseKeyReady(existing, created: false);
    }
    if (databaseExists) {
      return const DatabaseKeyMissing();
    }
    final key = _generate();
    await _store.write(storageKey, key);
    final stored = await _store.read(storageKey);
    if (stored != key) {
      throw StateError('The database key could not be saved securely.');
    }
    return DatabaseKeyReady(key, created: true);
  }

  String _generate() {
    final buffer = StringBuffer();
    for (var i = 0; i < 32; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static bool _isValid(String key) => RegExp(r'^[0-9a-f]{64}$').hasMatch(key);
}
