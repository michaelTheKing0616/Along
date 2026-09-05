/// Planner leg warning when load may not fit the selected mode (FM36).
class LoadWarning {
  const LoadWarning({
    required this.reason,
    this.modeCapacity,
  });

  final String reason;
  final String? modeCapacity;

  bool get blocksMode => modeCapacity == 'none';
}
