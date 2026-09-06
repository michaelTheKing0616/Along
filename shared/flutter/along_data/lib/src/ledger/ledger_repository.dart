import 'package:along_core/along_core.dart';
import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;
import 'package:along_data/src/mappers/domain_mappers.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Ledger, settlement, standing, and guarantor RPCs (doc 03 §7).
class LedgerRepository {
  LedgerRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<dto.DriverBalanceResponse> driverBalance() async {
    try {
      final raw = await _gateway.rpc('driver_balance');
      return dto.DriverBalanceResponse.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<DriverLedgerPage> driverLedger({
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'driver_ledger',
        params: dto.DriverLedgerRequest(
          p_cursor: cursor,
          p_limit: limit,
        ).toJson(),
      );
      final map = raw as Map<String, dynamic>;
      final rows = map['entries'] as List<dynamic>? ?? [];
      final meta = map['meta'] as Map<String, dynamic>? ?? {};
      final entries = rows
          .whereType<Map<String, dynamic>>()
          .map(DomainMappers.ledgerEntryFromJson)
          .toList(growable: false);
      return DriverLedgerPage(
        entries: entries,
        nextCursor: meta['next_cursor'] as String?,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<SettlementInitiateResult> initiateSettlement({
    required Money amount,
    required String channel,
  }) async {
    try {
      final raw = await _gateway.invokeFunction(
        'settlement/initiate',
        body: {
          'amount': amount.amount.toDouble(),
          'channel': channel,
        },
      );
      final data = raw['data'] as Map<String, dynamic>? ?? raw;
      return SettlementInitiateResult.fromJson(data);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<dto.CreateAgentCodeResponse> createAgentCode({
    required Money amount,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'create_agent_code',
        params: {'p_amount': amount.amount.toDouble()},
      );
      return dto.CreateAgentCodeResponse.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<dto.StandingTransitionEntry>> standingHistory() async {
    try {
      final raw = await _gateway.rpc('my_standing_history');
      final rows = raw as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(dto.StandingTransitionEntry.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<String> registerGuarantor({
    required String guarantorType,
    required String name,
    required String phoneE164,
    String? profileId,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'register_guarantor',
        params: {
          'p_guarantor_type': guarantorType,
          'p_name': name,
          'p_phone_e164': phoneE164,
          'p_profile_id': profileId,
        },
      );
      return raw.toString();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<SettlementStatusSnapshot?> settlementStatus(String settlementId) async {
    try {
      final rows = await _gateway.selectRows(
        'settlements',
        filters: {'id': settlementId},
      );
      if (rows.isEmpty) return null;
      return SettlementStatusSnapshot.fromRow(rows.first);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<NearbySettlementAgent>> nearbySettlementAgents({
    GeoPoint? location,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (location != null) {
        params['p_location'] = {'lat': location.lat, 'lng': location.lng};
      }
      final raw = await _gateway.rpc('nearby_settlement_agents', params: params);
      final rows = raw as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(NearbySettlementAgent.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<TripCashSummary>> todaysCashTrips() async {
    try {
      final rows = await _gateway.selectRows('trips');
      final today = DateTime.now().toUtc();
      final start = DateTime.utc(today.year, today.month, today.day);
      return rows
          .where((row) {
            if (row['status'] != 'completed') return false;
            if (row['payment_method'] == 'digital') return false;
            final ended = row['ended_at'] as String?;
            if (ended == null) return false;
            return DateTime.parse(ended).toUtc().isAfter(start);
          })
          .map(TripCashSummary.fromTripRow)
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}

class SettlementInitiateResult {
  const SettlementInitiateResult({
    required this.settlementId,
    required this.expiresAt,
    this.authorizationUrl,
    this.ussdCode,
    this.bankAccount,
  });

  final String settlementId;
  final DateTime expiresAt;
  final String? authorizationUrl;
  final String? ussdCode;
  final Map<String, dynamic>? bankAccount;

  factory SettlementInitiateResult.fromJson(Map<String, dynamic> json) {
    return SettlementInitiateResult(
      settlementId: json['settlement_id'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      authorizationUrl: json['authorization_url'] as String?,
      ussdCode: json['ussd_code'] as String?,
      bankAccount: json['bank_account'] as Map<String, dynamic>?,
    );
  }
}

class SettlementStatusSnapshot {
  const SettlementStatusSnapshot({
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
  });

  final String id;
  final String status;
  final double amount;
  final String currency;

  factory SettlementStatusSnapshot.fromRow(Map<String, dynamic> row) {
    return SettlementStatusSnapshot(
      id: row['id'] as String,
      status: row['status'] as String,
      amount: (row['amount'] as num).toDouble(),
      currency: row['currency'] as String,
    );
  }
}

class TripCashSummary {
  const TripCashSummary({
    required this.tripId,
    required this.fare,
    required this.completedAt,
    required this.destinationLabel,
  });

  final String tripId;
  final Money fare;
  final DateTime completedAt;
  final String destinationLabel;

  factory TripCashSummary.fromTripRow(Map<String, dynamic> row) {
    final fareAmount = (row['fare_shown'] as num?) ?? 0;
    return TripCashSummary(
      tripId: row['id'] as String,
      fare: Money.parse(fareAmount.toString(), currency: 'NGN'),
      completedAt: DateTime.parse(row['ended_at'] as String),
      destinationLabel: row['destination_label'] as String? ?? 'Trip',
    );
  }
}
