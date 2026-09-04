/// Exponential backoff for Realtime reconnect (1, 2, 4, 8 s … capped at 30 s).
class ReconnectPolicy {
  const ReconnectPolicy({
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.multiplier = 2,
  });

  final Duration baseDelay;
  final Duration maxDelay;
  final int multiplier;

  Duration delayForAttempt(int attempt) {
    if (attempt <= 0) return baseDelay;
    var seconds = baseDelay.inSeconds;
    for (var i = 0; i < attempt; i++) {
      seconds = (seconds * multiplier).clamp(1, maxDelay.inSeconds);
    }
    return Duration(seconds: seconds);
  }
}
