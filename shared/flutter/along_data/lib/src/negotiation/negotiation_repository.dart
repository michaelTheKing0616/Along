import 'package:along_core/along_core.dart';
import 'package:along_data/src/config/config_repository.dart';
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

  /// Polls the driver's latest open negotiation (RLS party select on price_negotiations).
  Future<NegotiationView?> fetchLatestOpenNegotiationForDriver({
    required String driverId,
    required ConfigRepository config,
    String? cityId,
  }) async {
    try {
      final rows = await _gateway.selectRows(
        'price_negotiations',
        filters: {'driver_id': driverId, 'status': 'open'},
      );
      if (rows.isEmpty) return null;

      rows.sort((a, b) {
        final aCreated = a['created_at'] as String? ?? '';
        final bCreated = b['created_at'] as String? ?? '';
        return bCreated.compareTo(aCreated);
      });
      final row = rows.first;
      final negotiationId = row['id'] as String;
      final currency = row['currency'] as String? ?? 'NGN';

      final rounds = await _gateway.selectRows(
        'price_negotiation_rounds',
        filters: {'negotiation_id': negotiationId},
      );
      Map<String, dynamic>? latestRound;
      var latestNumber = -1;
      for (final round in rounds) {
        final number = (round['round_number'] as num?)?.toInt() ?? 0;
        if (number >= latestNumber) {
          latestNumber = number;
          latestRound = round;
        }
      }

      final chipSteps = await _chipStepsFromConfig(
        config,
        cityId: cityId,
        currency: currency,
      );
      final anchorAmount = (row['anchor_amount'] as num?)?.toDouble() ?? 0;
      final amount = latestRound == null
          ? anchorAmount
          : (latestRound['amount'] as num?)?.toDouble() ?? anchorAmount;

      return NegotiationView(
        negotiationId: negotiationId,
        status: row['status'] as String? ?? 'open',
        context: row['context'] as String? ?? 'park',
        anchor: Money.fromMinorUnits(
          (anchorAmount * 100).round(),
          currency: currency,
        ),
        agreedAmount: row['agreed_amount'] == null
            ? null
            : Money.fromMinorUnits(
                ((row['agreed_amount'] as num) * 100).round(),
                currency: currency,
              ),
        roundCap: (row['round_cap'] as num?)?.toInt() ?? 1,
        roundTimeoutS: (row['round_timeout_s'] as num?)?.toInt() ?? 20,
        etaBand: row['eta_band'] as String?,
        expiresAt: DateTime.parse(row['expires_at'] as String).toUtc(),
        round: latestNumber <= 0 ? 1 : latestNumber,
        amount: Money.fromMinorUnits((amount * 100).round(), currency: currency),
        proposedBy: latestRound?['proposed_by'] as String? ?? 'rider',
        chipSteps: chipSteps,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  static Future<List<Money>> _chipStepsFromConfig(
    ConfigRepository config, {
    String? cityId,
    required String currency,
  }) async {
    final raw = await config.configJson('negotiation.chip_steps', cityId: cityId);
    if (raw is! List) return const [];
    return raw
        .map((step) {
          final naira = (step as num).abs().toInt();
          return Money.fromMinorUnits(naira * 100, currency: currency);
        })
        .toList(growable: false);
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
