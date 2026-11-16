import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/data/secure/database_key_manager.dart';
import 'package:acekanner/data/secure/secret_store.dart';

void main() {
  test('first run creates and stores a 256-bit key', () async {
    final store = MemorySecretStore();
    final outcome = await DatabaseKeyManager(store).obtain(databaseExists: false);

    expect(outcome, isA<DatabaseKeyReady>());
    final ready = outcome as DatabaseKeyReady;
    expect(ready.created, isTrue);
    expect(ready.hexKey, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(store.values[DatabaseKeyManager.storageKey], ready.hexKey);
  });

  test('later runs reuse the stored key', () async {
    final store = MemorySecretStore();
    final first = await DatabaseKeyManager(store).obtain(databaseExists: false)
        as DatabaseKeyReady;
    final second = await DatabaseKeyManager(store).obtain(databaseExists: true)
        as DatabaseKeyReady;

    expect(second.hexKey, first.hexKey);
    expect(second.created, isFalse);
  });

  test('keys differ between installations', () async {
    final a = await DatabaseKeyManager(MemorySecretStore())
        .obtain(databaseExists: false) as DatabaseKeyReady;
    final b = await DatabaseKeyManager(MemorySecretStore())
        .obtain(databaseExists: false) as DatabaseKeyReady;
    expect(a.hexKey, isNot(b.hexKey));
  });

  test('an existing database without its key is reported, never re-keyed', () async {
    final store = MemorySecretStore();
    final outcome = await DatabaseKeyManager(store).obtain(databaseExists: true);

    expect(outcome, isA<DatabaseKeyMissing>());
    expect(store.values, isEmpty);
  });

  test('a corrupted stored key with an existing database is reported', () async {
    final store = MemorySecretStore()
      ..values[DatabaseKeyManager.storageKey] = 'not-a-key';
    final outcome = await DatabaseKeyManager(store).obtain(databaseExists: true);
    expect(outcome, isA<DatabaseKeyMissing>());
  });
}
