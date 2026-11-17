/// Why a key press was refused.
enum EntryRejection {
  /// The score would be above the activity's maximum points.
  aboveMaximum,

  /// Backspace with nothing entered.
  empty,
}

/// The number typed on the academic calculator's keypad.
///
/// Only whole points can be entered (the keypad has no decimal point). A score
/// above the maximum is refused and the previous value stays, so a wrong key
/// never produces an invalid score.
class ScoreEntry {
  const ScoreEntry._(this.digits, this.maxPoints);

  const ScoreEntry.empty(int maxPoints) : this._('', maxPoints);

  /// Typed digits without leading zeros ('' = nothing typed, '0' = zero).
  final String digits;
  final int maxPoints;

  bool get isEmpty => digits.isEmpty;

  /// The score, or null when nothing has been typed.
  int? get value => digits.isEmpty ? null : int.parse(digits);

  /// The same entry checked against another maximum (activity changed):
  /// kept when it still fits, otherwise cleared.
  ScoreEntry withMaximum(int newMax) {
    final v = value;
    if (v != null && v > newMax) return ScoreEntry.empty(newMax);
    return ScoreEntry._(digits, newMax);
  }

  /// Appends [digit] (0-9). Returns the new entry, or the rejection.
  ({ScoreEntry entry, EntryRejection? rejected}) press(int digit) {
    if (digit < 0 || digit > 9) throw ArgumentError.value(digit, 'digit');
    final next = (digits == '0' || digits.isEmpty) ? '$digit' : '$digits$digit';
    if (int.parse(next) > maxPoints) {
      return (entry: this, rejected: EntryRejection.aboveMaximum);
    }
    return (entry: ScoreEntry._(next, maxPoints), rejected: null);
  }

  /// Removes the last digit; does nothing when empty.
  ({ScoreEntry entry, EntryRejection? rejected}) backspace() {
    if (digits.isEmpty) return (entry: this, rejected: EntryRejection.empty);
    return (entry: ScoreEntry._(digits.substring(0, digits.length - 1), maxPoints), rejected: null);
  }

  ScoreEntry cleared() => ScoreEntry.empty(maxPoints);

  /// An entry showing a saved score (e.g. when the instructor reopens it).
  factory ScoreEntry.ofValue(int value, int maxPoints) {
    if (value < 0 || value > maxPoints) throw RangeError.range(value, 0, maxPoints);
    return ScoreEntry._('$value', maxPoints);
  }

  @override
  bool operator ==(Object other) => other is ScoreEntry && other.digits == digits && other.maxPoints == maxPoints;

  @override
  int get hashCode => Object.hash(digits, maxPoints);
}
