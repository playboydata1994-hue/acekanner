/// Source of the current time. Injected so tests and licensing logic can
/// control time explicitly.
class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}

/// A clock frozen at [fixed], for tests.
class FixedClock extends Clock {
  const FixedClock(this.fixed);

  final DateTime fixed;

  @override
  DateTime now() => fixed;
}
