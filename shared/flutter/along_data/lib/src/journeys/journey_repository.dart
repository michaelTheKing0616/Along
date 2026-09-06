import 'package:along_core/along_core.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';
import 'package:along_data/src/wayfinding/walking_directions_repository.dart';

/// Lightweight journey row for client polling (doc 04 §11).
class JourneyStatusSnapshot {
  const JourneyStatusSnapshot({
    required this.journeyId,
    required this.status,
    this.currentTripSequence,
    this.candidateId,
  });

  final String journeyId;
  final String status;
  final int? currentTripSequence;
  final String? candidateId;
}

/// Loads journey transfer state and prefetched walk directions (P2-A-04).
class JourneyRepository {
  JourneyRepository(this._gateway, this._directionsRepo);

  final AlongSupabase _gateway;
  final WalkingDirectionsRepository _directionsRepo;

  Future<TransferContext?> transferContext({
    required String journeyId,
    required int afterTripSequence,
  }) async {
    try {
      final journeys = await _gateway.selectRows(
        'journeys',
        filters: {'id': journeyId},
      );
      if (journeys.isEmpty) return null;
      final journey = journeys.first;
      if (journey['status'] != 'transfer') return null;

      final planSnapshot =
          journey['plan_snapshot'] as Map<String, dynamic>? ?? {};
      final nextLegIndex = afterTripSequence;
      final nextLeg = _mapPlanLeg(planSnapshot, nextLegIndex);
      if (nextLeg == null) return null;

      WalkingDirections? directions;
      final walks = await _gateway.selectRows(
        'journey_transfer_walks',
        filters: {
          'journey_id': journeyId,
          'after_trip_sequence': afterTripSequence,
        },
      );
      if (walks.isNotEmpty) {
        final raw = walks.first['directions'] as Map<String, dynamic>? ?? {};
        directions = _directionsRepo.fromPrefetchJson(raw);
      }

      final walkMin = directions != null
          ? (directions.durationS / 60).ceil()
          : _estimateWalkMin(planSnapshot, afterTripSequence);

      return TransferContext(
        journeyId: journeyId,
        afterTripSequence: afterTripSequence,
        walkHeroLabel: 'Walk $walkMin min to ${nextLeg.boardName}',
        nextLeg: nextLeg,
        walkDirections: directions,
        cityId: journey['city_id'] as String?,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  JourneyPlanLeg? _mapPlanLeg(
    Map<String, dynamic> planSnapshot,
    int legIndex,
  ) {
    final legs = (planSnapshot['legs'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    for (final leg in legs) {
      if ((leg['leg_index'] as num?)?.toInt() != legIndex) continue;
      final mode = leg['mode'] as Map<String, dynamic>? ?? {};
      final board = leg['board'] as Map<String, dynamic>? ?? {};
      final alight = leg['alight'] as Map<String, dynamic>? ?? {};
      final location = board['location'] as Map<String, dynamic>?;
      final supply = leg['supply'] as Map<String, dynamic>?;
      return JourneyPlanLeg(
        legIndex: legIndex,
        modeCode: mode['code'] as String? ?? 'car',
        modeLabel: mode['label'] as String? ?? '',
        boardName: board['name'] as String? ?? '',
        alightName: alight['name'] as String? ?? '',
        boardLocation: location == null
            ? null
            : GeoPoint(
                lat: (location['lat'] as num).toDouble(),
                lng: (location['lng'] as num).toDouble(),
              ),
        waitSeconds: (leg['wait_s'] as num?)?.toInt(),
        supplyBucket: supply?['vehicles_bucket'] as String?,
      );
    }
    return null;
  }

  int _estimateWalkMin(Map<String, dynamic> planSnapshot, int afterSequence) {
    final transfers = (planSnapshot['transfers'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    if (transfers.isEmpty) return 3;
    final idx = afterSequence - 1;
    if (idx < 0 || idx >= transfers.length) return 3;
    final walkS = (transfers[idx]['transfer_s'] as num?)?.toInt() ??
        (transfers[idx]['transfer_time_s'] as num?)?.toInt() ??
        180;
    return (walkS / 60).ceil().clamp(1, 999);
  }

  /// Poll-friendly journey status for transfer auto-navigation (R-14).
  Future<JourneyStatusSnapshot?> journeyStatusSnapshot(String journeyId) async {
    try {
      final journeys = await _gateway.selectRows(
        'journeys',
        filters: {'id': journeyId},
      );
      if (journeys.isEmpty) return null;
      final journey = journeys.first;
      final snapshot =
          journey['plan_snapshot'] as Map<String, dynamic>? ?? {};
      return JourneyStatusSnapshot(
        journeyId: journeyId,
        status: journey['status'] as String? ?? '',
        currentTripSequence:
            (journey['current_trip_sequence'] as num?)?.toInt(),
        candidateId: snapshot['candidate_id'] as String?,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// Candidate id stored on the journey for re-planning remaining segment.
  Future<String?> planCandidateId(String journeyId) async {
    final journeys = await _gateway.selectRows(
      'journeys',
      filters: {'id': journeyId},
    );
    if (journeys.isEmpty) return null;
    final snapshot =
        journeys.first['plan_snapshot'] as Map<String, dynamic>? ?? {};
    return snapshot['candidate_id'] as String?;
  }
}
