import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;
import 'package:along_data/src/database/along_database.dart';
import 'package:along_data/src/mappers/domain_mappers.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Trip RPCs plus local trip cache.
class TripsRepository {
  TripsRepository(this._gateway, this._db);

  final AlongSupabase _gateway;
  final AlongDatabase _db;

  Future<TripSummary> requestTrip(dto.RequestTripRequest request) async {
    try {
      final raw = await _gateway.rpc('request_trip', params: request.toJson());
      final view = dto.TripView.fromJson(raw as Map<String, dynamic>);
      final summary = DomainMappers.tripFromDto(view, raw: raw);
      await _cacheTrip(view);
      await _persistNaMePairing(summary);
      return summary;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<TripSummary> tripSnapshot(String tripId) async {
    try {
      final raw = await _gateway.rpc(
        'trip_snapshot',
        params: dto.TripSnapshotRequest(p_trip_id: tripId).toJson(),
      );
      final map = raw as Map<String, dynamic>;
      final view = dto.TripView.fromJson(map);
      await _cacheTrip(view);
      final summary = DomainMappers.tripFromDto(view, raw: map);
      await _persistNaMePairing(summary);
      return summary;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> cancelTrip(String tripId, {String? reason}) async {
    try {
      await _gateway.rpc(
        'cancel_trip',
        params: dto.CancelTripRequest(
          p_trip_id: tripId,
          p_reason: reason,
        ).toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<TripSummary> releaseMatch(String tripId) async {
    try {
      final raw = await _gateway.rpc(
        'release_match',
        params: dto.TripSnapshotRequest(p_trip_id: tripId).toJson(),
      );
      final map = raw as Map<String, dynamic>;
      final view = dto.TripView.fromJson(map);
      await _cacheTrip(view);
      final summary = DomainMappers.tripFromDto(view, raw: map);
      await _persistNaMePairing(summary);
      return summary;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<TripSummary> respondToTrip({
    required String tripId,
    required String action,
    String? declineReason,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'respond_to_trip',
        params: dto.RespondToTripRequest(
          p_trip_id: tripId,
          p_action: action,
          p_decline_reason: declineReason,
        ).toJson(),
      );
      final view = dto.TripView.fromJson(raw as Map<String, dynamic>);
      final summary = DomainMappers.tripFromDto(view, raw: raw);
      await _cacheTrip(view);
      await _persistNaMePairing(summary);
      return summary;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<TripSummary?> cachedActiveTrip() async {
    final rows = await _db.select(_db.tripCache).get();
    for (final row in rows) {
      final map = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      final view = dto.TripView.fromJson(map);
      final summary = DomainMappers.tripFromDto(view, raw: map);
      if (summary.isActive) return summary;
    }
    return null;
  }

  Future<NaMePairing?> cachedNaMePairing(String tripId) async {
    final rows = await (_db.select(
      _db.kvStore,
    )..where((t) => t.key.equals('na_me:$tripId'))).get();
    if (rows.isEmpty) return null;
    return NaMePairing.fromJson(
      jsonDecode(rows.first.value) as Map<String, dynamic>,
    );
  }

  Future<TripSummary> markBoarded(String tripId) async {
    try {
      final raw = await _gateway.rpc(
        'mark_boarded',
        params: dto.TripSnapshotRequest(p_trip_id: tripId).toJson(),
      );
      final map = raw as Map<String, dynamic>;
      final view = dto.TripView.fromJson(map);
      await _cacheTrip(view);
      final summary = DomainMappers.tripFromDto(view, raw: map);
      await _persistNaMePairing(summary);
      return summary;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<DriverManifestEntry>> driverManifest() async {
    try {
      final raw = await _gateway.rpc('driver_manifest');
      final rows = raw as List<dynamic>? ?? [];
      final entries = <DriverManifestEntry>[];
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final entry = DomainMappers.manifestEntryFromJson(row);
        entries.add(entry);
        await _db
            .into(_db.kvStore)
            .insertOnConflictUpdate(
              KvStoreCompanion.insert(
                key: 'na_me:${entry.tripId}',
                value: jsonEncode(entry.naMe.toJson()),
              ),
            );
      }
      return entries;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// Driver enters the rider's 4-digit PIN. A correct PIN boards the rider
  /// server-side; wrong tries are capped at 5 and limited to one a second.
  Future<TripPinResult> verifyTripPin(String tripId, String pin) async {
    try {
      final raw = await _gateway.rpc(
        'verify_trip_pin',
        params: {'p_trip_id': tripId, 'p_pin': pin},
      );
      return TripPinResult.fromJson(raw);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// Rider asks for a fresh pickup PIN (accepted, not yet boarded). Returns
  /// the PIN now in force: the new one, or the old one when rate limited.
  Future<TripPinRefresh> regenerateTripPin(String tripId) async {
    try {
      final raw = await _gateway.rpc(
        'regenerate_trip_pin',
        params: {'p_trip_id': tripId},
      );
      final m = Map<String, dynamic>.from(raw as Map);
      return TripPinRefresh(
        pin: m['pin']?.toString() ?? '',
        regenerated: m['regenerated'] == true,
        limited: m['rate_limited'] == true || m['limit_reached'] == true,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// A short-lived call/SMS action from the trip-contact relay. Null when the
  /// relay is not available.
  Future<TripContactAction?> tripContact(String tripId, String channel) async {
    try {
      final raw = await _gateway.invokeFunction(
        'trip-contact',
        body: {'trip_id': tripId, 'channel': channel},
      );
      return TripContactAction.fromJson(raw['data'] ?? raw);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<TripSummary> startTrip(String tripId) async {
    try {
      final raw = await _gateway.rpc(
        'start_trip',
        params: dto.TripSnapshotRequest(p_trip_id: tripId).toJson(),
      );
      final map = raw as Map<String, dynamic>;
      final view = dto.TripView.fromJson(map);
      await _cacheTrip(view);
      final summary = DomainMappers.tripFromDto(view, raw: map);
      await _persistNaMePairing(summary);
      return summary;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<CompleteTripResult> completeTrip(String tripId) async {
    try {
      final raw = await _gateway.rpc(
        'complete_trip',
        params: dto.TripSnapshotRequest(p_trip_id: tripId).toJson(),
      );
      final map = raw as Map<String, dynamic>;
      final result = DomainMappers.completeTripFromJson(map);
      await _cacheTrip(
        dto.TripView.fromJson(map['trip'] as Map<String, dynamic>),
      );
      await _persistNaMePairing(result.trip);
      return result;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> confirmFare({
    required String tripId,
    required String outcome,
    Money? paidAmount,
  }) async {
    try {
      await _gateway.rpc(
        'confirm_fare',
        params: dto.ConfirmFareRequest(
          p_trip_id: tripId,
          p_outcome: outcome,
          p_paid_amount: paidAmount != null
              ? DomainMappers.moneyToDto(paidAmount)
              : null,
        ).toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> rateTrip({
    required String tripId,
    required int score,
    required List<String> tags,
    String? comment,
  }) async {
    try {
      await _gateway.rpc(
        'rate_trip',
        params: dto.RateTripRequest(
          p_trip_id: tripId,
          p_score: score,
          p_tags: tags,
          p_comment: comment,
        ).toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<ProposeExtensionResult> proposeExtension({
    required String tripId,
    required Map<String, dynamic> newAlight,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'propose_extension',
        params: {'p_trip_id': tripId, 'p_new_alight': newAlight},
      );
      return DomainMappers.proposeExtensionFromJson(
        raw as Map<String, dynamic>,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<TripSummary?> respondExtension({
    required String extensionId,
    required String response,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'respond_extension',
        params: {'p_extension_id': extensionId, 'p_response': response},
      );
      final map = raw as Map<String, dynamic>;
      final tripJson = map['trip'];
      if (tripJson is! Map<String, dynamic>) return null;
      final view = dto.TripView.fromJson(tripJson);
      final summary = DomainMappers.tripFromDto(view, raw: tripJson);
      await _cacheTrip(view);
      await _persistNaMePairing(summary);
      return summary;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<TripExtensionProposal?> resolvePendingExtension(
    TripSummary summary,
  ) async {
    final fromView = summary.pendingExtension;
    if (fromView != null && fromView.isFromDriver) return fromView;
    return pendingExtensionFromTable(summary.tripId);
  }

  Future<TripExtensionProposal?> pendingExtensionFromTable(
    String tripId,
  ) async {
    try {
      final rows = await _gateway.selectRows(
        'trip_extensions',
        filters: {'trip_id': tripId, 'status': 'proposed'},
      );
      if (rows.isEmpty) return null;
      final row = rows.first;
      if (row['proposed_by'] == 'rider') return null;
      final stageId = row['new_alighting_stage_id'] as String?;
      var destinationName = 'New destination';
      if (stageId != null) {
        final stages = await _gateway.selectRows(
          'route_stages',
          filters: {'id': stageId},
        );
        if (stages.isNotEmpty) {
          destinationName = stages.first['name'] as String? ?? destinationName;
        }
      }
      return DomainMappers.extensionProposalFromRow(
        row,
        destinationName: destinationName,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<TripHistoryEntry>> completedTrips({int limit = 50}) async {
    try {
      final rows = await _gateway.selectRows('trips');
      final entries =
          rows
              .where((row) => row['status'] == 'completed')
              .map(DomainMappers.historyEntryFromTripRow)
              .toList()
            ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      if (entries.length > limit) {
        return entries.sublist(0, limit);
      }
      return entries;
    } catch (e) {
      final cached = await _completedTripsFromCache(limit: limit);
      if (cached.isNotEmpty) return cached;
      throw mapSupabaseError(e);
    }
  }

  Future<TripHistoryEntry?> tripHistoryDetail(String tripId) async {
    try {
      final rows = await _gateway.selectRows('trips', filters: {'id': tripId});
      if (rows.isEmpty) {
        return _historyFromCache(tripId);
      }
      return DomainMappers.historyEntryFromTripRow(rows.first);
    } catch (e) {
      return _historyFromCache(tripId);
    }
  }

  Future<List<TripHistoryEntry>> _completedTripsFromCache({
    int limit = 50,
  }) async {
    final rows = await _db.select(_db.tripCache).get();
    final entries = <TripHistoryEntry>[];
    for (final row in rows) {
      final map = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      if (map['status'] != 'completed') continue;
      final view = dto.TripView.fromJson(map);
      final summary = DomainMappers.tripFromDto(view, raw: map);
      entries.add(
        TripHistoryEntry(
          tripId: summary.tripId,
          completedAt: _endedAtFromTripJson(map) ?? row.updatedAt,
          boardName: summary.board.name,
          alightName: summary.alight.name,
          modeCode: summary.modeCode,
          modeLabel: summary.modeLabel,
          status: summary.status,
          totalFare: summary.totalFare,
          driverName: summary.driver.displayName,
          plateNumber: summary.vehicle.plateNumber,
          receipt: TripReceipt(
            fare: summary.totalFare,
            total: summary.totalFare,
          ),
        ),
      );
    }
    entries.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    if (entries.length > limit) return entries.sublist(0, limit);
    return entries;
  }

  TripHistoryEntry? _historyFromCache(String tripId) {
    // Sync read not available — callers use async path above.
    return null;
  }

  DateTime? _endedAtFromTripJson(Map<String, dynamic> json) {
    final timestamps = json['timestamps'];
    if (timestamps is! Map<String, dynamic>) return null;
    final ended = timestamps['ended_at'] as String?;
    return ended != null ? DateTime.parse(ended) : null;
  }

  Future<dto.TripLocationSampleResponse> tripLocationSample({
    required String tripId,
    required List<dto.LocationSamplePoint> points,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'trip_location_sample',
        params: dto.TripLocationSampleRequest(
          p_trip_id: tripId,
          p_points: points,
        ).toJson(),
      );
      return dto.TripLocationSampleResponse.fromJson(
        raw as Map<String, dynamic>,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> _cacheTrip(dto.TripView view) async {
    await _db
        .into(_db.tripCache)
        .insertOnConflictUpdate(
          TripCacheCompanion.insert(
            tripId: view.trip_id,
            payloadJson: jsonEncode(view.toJson()),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> _persistNaMePairing(TripSummary summary) async {
    await _db
        .into(_db.kvStore)
        .insertOnConflictUpdate(
          KvStoreCompanion.insert(
            key: 'na_me:${summary.tripId}',
            value: jsonEncode(summary.naMe.toJson()),
          ),
        );
  }
}

class TripPinRefresh {
  const TripPinRefresh({
    required this.pin,
    required this.regenerated,
    required this.limited,
  });

  final String pin;
  final bool regenerated;
  final bool limited;
}

class TripPinResult {
  const TripPinResult({
    required this.verified,
    required this.attemptsLeft,
    this.locked = false,
    this.rateLimited = false,
  });

  final bool verified;
  final int attemptsLeft;
  final bool locked;
  final bool rateLimited;

  factory TripPinResult.fromJson(Object? raw) {
    final m = raw is Map ? raw : const <String, dynamic>{};
    final left = m['attempts_left'];
    return TripPinResult(
      verified: m['verified'] == true,
      attemptsLeft: left is num ? left.toInt() : 0,
      locked: m['locked'] == true,
      rateLimited: m['rate_limited'] == true,
    );
  }
}

class TripContactAction {
  const TripContactAction({
    required this.uri,
    required this.masked,
    required this.expiresAt,
  });

  final Uri uri;
  final bool masked;
  final DateTime expiresAt;

  static TripContactAction? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final uri = Uri.tryParse('${raw['uri'] ?? ''}');
    if (uri == null || (uri.scheme != 'tel' && uri.scheme != 'sms')) {
      return null;
    }
    return TripContactAction(
      uri: uri,
      masked: raw['masked'] == true,
      expiresAt: DateTime.tryParse('${raw['expires_at']}') ?? DateTime.now(),
    );
  }
}
