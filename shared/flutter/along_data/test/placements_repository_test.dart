import 'package:along_data/along_data.dart';
import 'package:along_data/src/placements/placements_repository.dart';
import '../test/support/fake_along_supabase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlacementsRepository request builder (FM39)', () {
    test('resolve params contain only contextual fields', () {
      final params = PlacementsRepository.buildResolvePlacementsParams(
        const PlacementContext(
          type: PlacementContextType.park,
          targetReference: '0a020000-0000-4000-8000-000000000001',
          deploymentId: '0f500000-0000-4000-8000-000000000001',
        ),
      );

      expect(params.keys.toSet(), {
        'p_context_type',
        'p_target_reference',
        'p_deployment_id',
      });
      expect(params['p_context_type'], 'park');
      expect(params['p_target_reference'],
          '0a020000-0000-4000-8000-000000000001');
    });

    test('counter params contain only placement id and metric', () {
      final params = PlacementsRepository.buildRecordCounterParams(
        placementId: '0f510000-0000-4000-8000-000000000001',
        metric: 'impression',
      );

      expect(params.keys.toSet(), {'p_placement_id', 'p_metric'});
      expect(params['p_metric'], 'impression');
    });

    test('rejects personal identifiers in resolve params', () {
      expect(
        () => PlacementsRepository.assertNoPersonalIdentifiers({
          'p_context_type': 'park',
          'p_target_reference': '0a020000-0000-4000-8000-000000000001',
          'p_rider_id': 'secret',
        }),
        throwsArgumentError,
      );
    });
  });

  group('PlacementsRepository RPC calls', () {
    test('resolve and counter RPCs omit personal identifiers', () async {
      final fake = FakeAlongSupabase(
        rpcHandler: (fn, params) {
          PlacementsRepository.assertNoPersonalIdentifiers(params);
          if (fn == 'resolve_sponsored_placements') {
            return [
              {
                'id': '0f510000-0000-4000-8000-000000000001',
                'context_type': 'park',
                'target_reference': params['p_target_reference'],
                'advertiser': 'Fixture',
                'content': {'headline': 'Visit Test Park'},
              },
            ];
          }
          return {};
        },
      );
      final repo = PlacementsRepository(fake);

      final placements = await repo.resolvePlacements(
        const PlacementContext(
          type: PlacementContextType.park,
          targetReference: '0a020000-0000-4000-8000-000000000001',
        ),
      );
      expect(placements, hasLength(1));

      await repo.recordImpression(placements.first.id);

      expect(fake.rpcCalls.map((c) => c.$1).toList(), [
        'resolve_sponsored_placements',
        'record_placement_counter',
      ]);
      for (final (_, params) in fake.rpcCalls) {
        PlacementsRepository.assertNoPersonalIdentifiers(params);
      }
    });
  });
}
