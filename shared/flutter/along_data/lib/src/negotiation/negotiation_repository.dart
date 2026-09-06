import 'package:along_core/along_core.dart';
import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;
import 'package:along_data/src/mappers/domain_mappers.dart';
import 'package:along_data/src/negotiation/negotiation_view.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Along Pricing RPCs (P2-A-02) plus roaming hail (P2-A-03).
class NegotiationRepository {
  NegotiationRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<NegotiationView> openNegotiation({
    required String context,
    required GeoPoint from,
    required GeoPoint to,
    required String clientRef,
    String? candidateToken,
    String? driverId,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'open_negotiation',
        params: dto.OpenNegotiationRequest(
          p_context: context,
          p_from: _endpointJson(from),
          p_to: _endpointJson(to),
          p_client_ref: clientRef,
          p_candidate_token: candidateToken,
          p_driver_id: driverId,
        ).toJson(),
      );
      final map = raw as Map<String, dynamic>;
      if (map.containsKey('negotiation_id') && !map.containsKey('status')) {
        final open = dto.OpenNegotiationResponse.fromJson(map);
        return NegotiationView.fromOpenResponse(open, context: context);
      }
      return NegotiationView.fromJson(map);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<NegotiationView> negotiationRound({
    required String negotiationId,
    required String action,
    Money? amount,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'negotiation_round',
        params: dto.NegotiationRoundRequest(
          p_negotiation_id: negotiationId,
          p_action: action,
          p_amount: amount == null
              ? null
              : dto.Money(amount: amount.toApiString(), currency: amount.currency),
        ).toJson(),
      );
      return NegotiationView.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<NegotiationView> negotiationSplit(String negotiationId) async {
    try {
      final raw = await _gateway.rpc(
        'negotiation_split',
        params: dto.NegotiationSplitRequest(p_negotiation_id: negotiationId)
            .toJson(),
      );
      return NegotiationView.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<TripSummary> hailRoaming({
    required String candidateToken,
    required GeoPoint destination,
    required String clientRef,
    bool womenOnly = false,
    dto.LoadFlag? load,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'hail_roaming',
        params: dto.HailRoamingRequest(
          p_candidate_token: candidateToken,
          p_destination: dto.Point(lat: destination.lat, lng: destination.lng),
          p_women_only: womenOnly,
          p_client_ref: clientRef,
          p_load: load,
        ).toJson(),
      );
      final view = dto.TripView.fromJson(raw as Map<String, dynamic>);
      return DomainMappers.tripFromDto(view);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  static Map<String, dynamic> _endpointJson(GeoPoint point) => {
        'lat': point.lat,
        'lng': point.lng,
      };
}
