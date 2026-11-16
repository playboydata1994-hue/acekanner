import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key-value store for device secrets.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Android Keystore-backed store (AES-GCM data, RSA-OAEP wrapped key).
class KeystoreSecretStore implements SecretStore {
  KeystoreSecretStore()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            // Never wipe secrets automatically after a Keystore error: losing
            // the database key would make the encrypted database unreadable.
            // ACEkanner shows a recovery screen instead.
            resetOnError: false,
          ),
        );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

/// In-memory store for tests.
class MemorySecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
