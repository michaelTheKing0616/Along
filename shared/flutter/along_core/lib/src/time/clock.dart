/// Injectable clock for deterministic tests.
abstract class Clock {
  DateTime now();

  static Clock system = _SystemClock();

  static Clock fixed(DateTime instant) => _FixedClock(instant);
}

class _SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now().toUtc();
}

class _FixedClock implements Clock {
  _FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant;
}
