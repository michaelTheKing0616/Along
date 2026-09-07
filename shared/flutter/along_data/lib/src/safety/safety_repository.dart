import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Active trip share row (rider-owned via RLS).
class TripShareRow {
  const TripShareRow({
    required this.id,
    required this.journeyId,
    required this.expiresAt,
    this.contactName,
    this.createdAt,
  });

  final String id;
  final String journeyId;
  final DateTime expiresAt;
  final String? contactName;
  final DateTime? createdAt;

  factory TripShareRow.fromJson(Map<String, dynamic> json) => TripShareRow(
        id: json['id'] as String,
        journeyId: json['journey_id'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        contactName: json['contact_name'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );
}

/// Result of [SafetyRepository.createTripShare].
class TripShareCreated {
  const TripShareCreated({
    required this.url,
    required this.expiresAt,
    required this.shareId,
  });

  final String url;
  final DateTime expiresAt;
  final String shareId;
}

/// SOS / trip share / incident RPCs (doc 03 §8).
class SafetyRepository {
  SafetyRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<dto.RaiseSosResponse> raiseSos({
    String? tripId,
    String? journeyId,
    required dto.Point location,
    double? accuracyM,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'raise_sos',
        params: dto.RaiseSosRequest(
          p_trip_id: tripId,
          p_journey_id: journeyId,
          p_location: location,
          p_accuracy_m: accuracyM ?? 25,
        ).toJson(),
      );
      return dto.RaiseSosResponse.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> cancelSos(String sosId) async {
    try {
      await _gateway.rpc(
        'update_sos',
        params: dto.UpdateSosRequest(p_sos_id: sosId).toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> reportIncident({
    String? tripId,
    required String type,
    required String description,
    List<String> attachmentPaths = const [],
  }) async {
    try {
      await _gateway.rpc(
        'report_incident',
        params: dto.ReportIncidentRequest(
          p_trip_id: tripId,
          p_type: type,
          p_description: description,
          p_attachment_paths: attachmentPaths,
        ).toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<TripShareCreated> createTripShare({
    required String journeyId,
    String? contactName,
    String? contactPhone,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'create_trip_share',
        params: dto.CreateTripShareRequest(
          p_journey_id: journeyId,
          p_contact_name: contactName,
          p_contact_phone: contactPhone,
        ).toJson(),
      );
      final map = raw as Map<String, dynamic>;
      return TripShareCreated(
        url: map['url'] as String,
        expiresAt: DateTime.parse(map['expires_at'] as String),
        shareId: map['share_id'] as String,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> revokeTripShare(String shareId) async {
    try {
      await _gateway.rpc(
        'revoke_trip_share',
        params: dto.RevokeTripShareRequest(p_share_id: shareId).toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<TripShareRow>> listActiveShares(String journeyId) async {
    try {
      final rows = await _gateway.selectRows(
        'trip_shares',
        filters: {'journey_id': journeyId},
      );
      final now = DateTime.now().toUtc();
      return rows
          .where((row) =>
              row['revoked_at'] == null &&
              DateTime.parse(row['expires_at'] as String).isAfter(now))
          .map(TripShareRow.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<dto.SharedTripViewResponse> sharedTripView(String token) async {
    try {
      final raw = await _gateway.rpc(
        'shared_trip_view',
        params: dto.SharedTripViewRequest(p_token: token).toJson(),
      );
      return dto.SharedTripViewResponse.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
