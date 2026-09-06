import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:drift/drift.dart';

/// Local rider UI preferences (`saved_sort`, `wayfinding_mode`) in Drift kv.
class RiderPrefsStore {
  RiderPrefsStore(this._db);

  final AlongDatabase _db;

  static const _sortKey = 'rider_prefs:saved_sort';
  static const _wayfindingKey = 'rider_prefs:wayfinding_mode';

  Future<SortCriterion> savedSort() async {
    final row = await (_db.select(_db.kvStore)
          ..where((t) => t.key.equals(_sortKey)))
        .getSingleOrNull();
    if (row == null) return SortCriterion.recommended;
    final raw = jsonDecode(row.value) as String?;
    return switch (raw) {
      'cheapest' => SortCriterion.cheapest,
      'fastest' => SortCriterion.fastest,
      'least_strenuous' => SortCriterion.leastStrenuous,
      _ => SortCriterion.recommended,
    };
  }

  Future<void> setSavedSort(SortCriterion sort) async {
    final wire = switch (sort) {
      SortCriterion.recommended => 'recommended',
      SortCriterion.cheapest => 'cheapest',
      SortCriterion.fastest => 'fastest',
      SortCriterion.leastStrenuous => 'least_strenuous',
    };
    await _db.into(_db.kvStore).insertOnConflictUpdate(
          KvStoreCompanion.insert(
            key: _sortKey,
            value: jsonEncode(wire),
          ),
        );
  }

  Future<WayfindingMode> wayfindingMode() async {
    final row = await (_db.select(_db.kvStore)
          ..where((t) => t.key.equals(_wayfindingKey)))
        .getSingleOrNull();
    if (row == null) return WayfindingMode.text;
    return WayfindingMode.tryParse(jsonDecode(row.value) as String?);
  }

  Future<void> setWayfindingMode(WayfindingMode mode) async {
    await _db.into(_db.kvStore).insertOnConflictUpdate(
          KvStoreCompanion.insert(
            key: _wayfindingKey,
            value: jsonEncode(mode.wireValue),
          ),
        );
  }
}
