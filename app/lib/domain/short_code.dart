import 'dart:math';

/// Short human-readable codes printed on sheets (Crockford base32: no I, L, O, U).
abstract final class ShortCode {
  static const String alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static final Random _random = Random.secure();

  /// Random code of [length] characters (8 chars = 40 bits).
  static String generate({int length = 8, Random? random}) {
    final r = random ?? _random;
    return List.generate(length, (_) => alphabet[r.nextInt(alphabet.length)]).join();
  }

  static bool isValid(String code, {int length = 8}) =>
      code.length == length && code.split('').every(alphabet.contains);
}
