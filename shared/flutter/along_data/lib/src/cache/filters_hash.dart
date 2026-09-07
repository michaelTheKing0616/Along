import 'dart:convert';

/// Stable hash for plan-trip filter objects (doc 07 §4, backend edge_cache.ts).
String filtersHash(Object? filters) {
  return jsonEncode(_sortKeys(filters));
}

Object? _sortKeys(Object? value) {
  if (value == null || value is! Object) return value;
  if (value is List) return value.map(_sortKeys).toList(growable: false);
  if (value is Map) {
    final sorted = <String, Object?>{};
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    for (final key in keys) {
      sorted[key] = _sortKeys(value[key]);
    }
    return sorted;
  }
  return value;
}
