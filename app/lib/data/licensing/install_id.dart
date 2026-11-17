import 'package:uuid/uuid.dart';

import '../secure/secret_store.dart';

/// A random ID for this installation (not a hardware ID). It identifies the
/// phone to the licensing server so the free-scan lease is held by one phone
/// at a time. Reinstalling the app creates a new ID.
class InstallIdStore {
  InstallIdStore(this._store);

  static const String key = 'acekanner.install_id.v1';
  final SecretStore _store;
  Future<String>? _value;

  Future<String> get() => _value ??= _load();

  Future<String> _load() async {
    final existing = await _store.read(key);
    if (existing != null && RegExp(r'^[A-Za-z0-9-]{16,64}$').hasMatch(existing)) return existing;
    final id = const Uuid().v4();
    await _store.write(key, id);
    return id;
  }
}
