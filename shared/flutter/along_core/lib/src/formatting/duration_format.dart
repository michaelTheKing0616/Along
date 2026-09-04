/// Human-readable duration (e.g. `14 min`, `1 hr 5 min`).
String formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes;
  if (totalMinutes < 1) return '${duration.inSeconds} sec';
  if (totalMinutes < 60) return '$totalMinutes min';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) return '$hours hr';
  return '$hours hr $minutes min';
}
