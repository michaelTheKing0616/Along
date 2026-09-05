/// FM36 — warn when mode load capacity is listed for the rider's load size.
bool shouldWarnLoadCapacity({
  required String? loadSize,
  required String? modeLoadCapacity,
  required Map<String, List<String>> warnCapacities,
}) {
  if (loadSize == null || modeLoadCapacity == null) return false;
  final capacities = warnCapacities[loadSize];
  if (capacities == null) return false;
  return capacities.contains(modeLoadCapacity);
}

/// Parses `cfg.load.warn_capacities` from app_config JSON.
Map<String, List<String>> parseWarnCapacities(Object? raw) {
  if (raw is! Map) return const {};
  return raw.map((key, value) {
    if (value is! List) {
      return MapEntry(key.toString(), const <String>[]);
    }
    return MapEntry(
      key.toString(),
      value.map((item) => item.toString()).toList(growable: false),
    );
  });
}
