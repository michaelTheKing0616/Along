import 'dart:convert';

import 'package:along_data/src/database/along_database.dart';
import 'package:drift/drift.dart';

/// Persists last plan-trip results keyed by OD geohash + filters (doc 07 §4).
class PlanCacheStore {
  PlanCacheStore(this._db, {this.maxEntries = defaultMaxEntries});

  static const defaultMaxEntries = 20;

  final AlongDatabase _db;
  final int maxEntries;

  Future<PlanCacheData?> read(String cacheKey) async {
    return (_db.select(_db.planCache)
          ..where((t) => t.cacheKey.equals(cacheKey)))
        .getSingleOrNull();
  }

  Future<Map<String, dynamic>?> readPayload(String cacheKey) async {
    final row = await read(cacheKey);
    if (row == null) return null;
    return jsonDecode(row.payloadJson) as Map<String, dynamic>;
  }

  Future<void> write({
    required String cacheKey,
    required Map<String, dynamic> planTripPayload,
    DateTime? cachedAt,
  }) async {
    await _db.into(_db.planCache).insertOnConflictUpdate(
          PlanCacheCompanion.insert(
            cacheKey: cacheKey,
            payloadJson: jsonEncode(planTripPayload),
            cachedAt: cachedAt ?? DateTime.now().toUtc(),
          ),
        );
    await _trimToMaxEntries();
  }

  Future<void> _trimToMaxEntries() async {
    final rows = await (_db.select(_db.planCache)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.cachedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    if (rows.length <= maxEntries) return;

    final toDelete = rows.skip(maxEntries).map((r) => r.cacheKey).toList();
    await (_db.delete(_db.planCache)
          ..where((t) => t.cacheKey.isIn(toDelete)))
        .go();
  }
}
