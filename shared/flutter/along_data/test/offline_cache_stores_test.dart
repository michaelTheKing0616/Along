import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filtersHash', () {
    test('sorts keys for stable hash', () {
      expect(
        filtersHash({'b': 1, 'a': 2}),
        filtersHash({'a': 2, 'b': 1}),
      );
    });
  });

  group('PlanCacheStore', () {
    test('trims to max 20 entries', () async {
      final db = AlongDatabase.memory();
      final store = PlanCacheStore(db, maxEntries: 2);

      await store.write(
        cacheKey: 'a',
        planTripPayload: {'query_id': 'a'},
        cachedAt: DateTime.utc(2026, 1, 1),
      );
      await store.write(
        cacheKey: 'b',
        planTripPayload: {'query_id': 'b'},
        cachedAt: DateTime.utc(2026, 1, 2),
      );
      await store.write(
        cacheKey: 'c',
        planTripPayload: {'query_id': 'c'},
        cachedAt: DateTime.utc(2026, 1, 3),
      );

      final rows = await db.select(db.planCache).get();
      expect(rows, hasLength(2));
      expect(rows.map((r) => r.cacheKey), containsAll(['b', 'c']));
    });
  });

  group('GraphCacheStore', () {
    test('searchByName finds parks offline', () async {
      final db = AlongDatabase.memory();
      final store = GraphCacheStore(
        db,
        _ThrowingSupabase(),
        RoutesRepository(_ThrowingSupabase()),
      );

      await store.upsert(
        cityId: 'city-1',
        graphVersion: 'v1',
        payload: {
          'parks': [
            {'id': 'p1', 'name': 'Area 1 Park', 'lat': 9.05, 'lng': 7.45},
          ],
          'stages': [],
          'legs': [],
        },
      );

      final hits = await store.searchByName(query: 'area 1', cityId: 'city-1');
      expect(hits, hasLength(1));
      expect(hits.single.name, 'Area 1 Park');
    });
  });
}

class _ThrowingSupabase implements AlongSupabase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
