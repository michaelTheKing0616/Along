import 'package:along_core/along_core.dart';
import 'package:along_data/src/planner/planner_repository.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Itinerary RPCs and parse-itinerary Edge (P5-A-03 / P5-B-02).
class ItineraryRepository {
  ItineraryRepository(this._gateway, this._planner);

  final AlongSupabase _gateway;
  final PlannerRepository _planner;

  Future<ItineraryStateView> createItinerary({
    required List<Map<String, dynamic>> stops,
    Map<String, dynamic>? load,
  }) async {
    try {
      final raw = await _gateway.rpc('create_itinerary', params: {
        'p_stops': stops,
        if (load != null) 'p_load': load,
      });
      return _mapItineraryState(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<ItineraryStateView> updateItineraryStops({
    required String itineraryId,
    required List<Map<String, dynamic>> ops,
  }) async {
    try {
      final raw = await _gateway.rpc('update_itinerary_stops', params: {
        'p_itinerary_id': itineraryId,
        'p_ops': ops,
      });
      return _mapItineraryState(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<ItineraryStateView> itineraryState(String itineraryId) async {
    try {
      final raw = await _gateway.rpc('itinerary_state', params: {
        'p_itinerary_id': itineraryId,
      });
      return _mapItineraryState(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<ItineraryStateView> itineraryMatchNext(String itineraryId) async {
    try {
      final raw = await _gateway.rpc('itinerary_match_next', params: {
        'p_itinerary_id': itineraryId,
      });
      return _mapItineraryState(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<ParseItineraryResult> parseItinerary({
    required String text,
    required String cityId,
  }) async {
    try {
      final envelope = await _gateway.invokeFunction(
        'parse-itinerary',
        body: {
          'text': text,
          'city_id': cityId,
        },
      );
      final data = envelope['data'] as Map<String, dynamic>? ?? envelope;
      final proposalJson =
          (data['proposal'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return ParseItineraryResult(
        needsConfirmation: data['needs_confirmation'] as bool? ?? true,
        proposal: proposalJson.map(_mapProposalItem).toList(growable: false),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// Maps prepared_plan JSON (same shape as plan-trip) to [PlanResult].
  PlanResult mapPreparedPlan(Map<String, dynamic> data) {
    return _planner.planResultFromData(data);
  }

  ItineraryStateView _mapItineraryState(Map<String, dynamic> json) {
    final stopsJson =
        (json['stops'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final nextPreparedRaw = json['next_prepared_plan'];
    return ItineraryStateView(
      itineraryId: json['itinerary_id'] as String,
      status: json['status'] as String? ?? 'active',
      planDate: DateTime.parse(json['plan_date'] as String),
      loadFlagged: json['load_flagged'] as bool? ?? false,
      loadSize: json['load_size'] as String?,
      loadNote: json['load_note'] as String?,
      stops: stopsJson.map(_mapStop).toList(growable: false),
      nextPendingStopId: json['next_pending_stop_id'] as String?,
      nextPreparedPlan: nextPreparedRaw is Map<String, dynamic>
          ? _planner.planResultFromData(nextPreparedRaw)
          : null,
      notBooked: json['not_booked'] as bool? ?? true,
      matchAction: json['match_action'] as String? ?? 'request_trip',
    );
  }

  String? _etaLabel(Object? eta) {
    if (eta is! Map) return null;
    final trip = eta['trip'];
    if (trip is Map && trip['label'] is String) return trip['label'] as String;
    final pickup = eta['pickup'];
    if (pickup is Map && pickup['label'] is String) {
      return pickup['label'] as String;
    }
    return null;
  }

  ItineraryStopView _mapStop(Map<String, dynamic> json) {
    final loc = json['destination_location'];
    GeoPoint? point;
    if (loc is Map<String, dynamic>) {
      point = GeoPoint(
        lat: (loc['lat'] as num).toDouble(),
        lng: (loc['lng'] as num).toDouble(),
      );
    }
    final preparedRaw = json['prepared_plan'];
    return ItineraryStopView(
      stopId: json['id'] as String,
      sequence: (json['sequence'] as num).toInt(),
      destinationDescription: json['destination_description'] as String,
      status: ItineraryStopStatus.fromString(json['status'] as String? ?? 'pending'),
      destinationLocation: point,
      preparedPlan: preparedRaw is Map<String, dynamic>
          ? _planner.planResultFromData(preparedRaw)
          : null,
      linkedJourneyId: json['linked_journey_id'] as String?,
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      etaLabel: json['eta_label'] as String? ?? _etaLabel(json['eta']),
    );
  }

  ParseItineraryProposalItem _mapProposalItem(Map<String, dynamic> json) {
    final resolved = json['resolved'];
    GeoPoint? location;
    String? label;
    double? confidence;
    if (resolved is Map<String, dynamic>) {
      label = resolved['label'] as String?;
      confidence = (resolved['confidence'] as num?)?.toDouble();
      final loc = resolved['location'];
      if (loc is Map<String, dynamic>) {
        location = GeoPoint(
          lat: (loc['lat'] as num).toDouble(),
          lng: (loc['lng'] as num).toDouble(),
        );
      }
    }
    return ParseItineraryProposalItem(
      sequence: (json['sequence'] as num).toInt(),
      destinationDescription: json['destination_description'] as String,
      resolved: resolved != null,
      resolvedLabel: label,
      resolvedLocation: location,
      confidence: confidence,
    );
  }
}
