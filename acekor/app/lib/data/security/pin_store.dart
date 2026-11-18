import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../core/util/clock.dart';
import '../secure/secret_store.dart';

/// The app-lock PIN. Only a salted PBKDF2-HMAC-SHA256 hash is kept, in the
/// Android Keystore-backed store. Wrong attempts add a growing wait.
class PinStore {
  PinStore(this._store, {this.clock = const Clock(), this.iterations = 120000});

  static const String key = 'acekor.pin.v1';
  static const String failKey = 'acekor.pin.fails.v1';

  final SecretStore _store;
  final Clock clock;
  final int iterations;

  static bool validFormat(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);

  Future<bool> hasPin() async => await _store.read(key) != null;

  /// Number of digits, so the lock screen can check as soon as it is typed.
  Future<int?> pinLength() async {
    final raw = await _store.read(key);
    if (raw == null) return null;
    return ((jsonDecode(raw) as Map<String, dynamic>)['n'] as num?)?.toInt();
  }

  Future<List<int>> _hash(String pin, List<int> salt, int iterations) async {
    final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
    final k = await kdf.deriveKey(secretKey: SecretKey(utf8.encode(pin)), nonce: salt);
    return k.extractBytes();
  }

  Future<void> setPin(String pin) async {
    if (!validFormat(pin)) throw ArgumentError('PIN must be 4 to 6 digits');
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final hash = await _hash(pin, salt, iterations);
    await _store.write(
      key,
      jsonEncode({'s': base64.encode(salt), 'h': base64.encode(hash), 'i': iterations, 'n': pin.length}),
    );
    await _store.delete(failKey);
  }

  Future<void> clear() async {
    await _store.delete(key);
    await _store.delete(failKey);
  }

  /// Seconds to wait before the next attempt (0 = may try now).
  Future<int> waitSeconds() async {
    final f = _fails(await _store.read(failKey));
    if (f.count < 5) return 0;
    final wait = 30 * (1 << (f.count - 5).clamp(0, 6)); // 30 s, 60 s, … up to 32 min
    final until = f.last.add(Duration(seconds: wait));
    final left = until.difference(clock.now()).inSeconds;
    return left > 0 ? left : 0;
  }

  /// Checks [pin]. Wrong attempts are counted (and survive restarts).
  Future<bool> verify(String pin) async {
    if (await waitSeconds() > 0) return false;
    final raw = await _store.read(key);
    if (raw == null) return true;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final salt = base64.decode(m['s'] as String);
    final expected = base64.decode(m['h'] as String);
    final actual = await _hash(pin, salt, (m['i'] as num).toInt());
    var diff = expected.length ^ actual.length;
    for (var i = 0; i < expected.length && i < actual.length; i++) {
      diff |= expected[i] ^ actual[i];
    }
    if (diff == 0) {
      await _store.delete(failKey);
      return true;
    }
    final f = _fails(await _store.read(failKey));
    await _store.write(failKey, jsonEncode({'c': f.count + 1, 't': clock.now().millisecondsSinceEpoch}));
    return false;
  }

  static ({int count, DateTime last}) _fails(String? raw) {
    if (raw == null) return (count: 0, last: DateTime.fromMillisecondsSinceEpoch(0));
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return (count: (m['c'] as num).toInt(), last: DateTime.fromMillisecondsSinceEpoch((m['t'] as num).toInt()));
    } catch (_) {
      return (count: 0, last: DateTime.fromMillisecondsSinceEpoch(0));
    }
  }
}
