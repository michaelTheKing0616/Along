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
      final view = dto.TripView.fromJson(raw);
      final summary = DomainMappers.tripFromDto(view);
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
      final view = dto.TripView.fromJson(raw);
      await _cacheTrip(view);
      return DomainMappers.tripFromDto(view);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> cancelTrip(String tripId, {String? reason}) async {
    try {
      await _gateway.rpc(
        'cancel_trip',
        params: dto.CancelTripRequest(p_trip_id: tripId, p_reason: reason)
            .toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<TripSummary?> cachedActiveTrip() async {
    final rows = await _db.select(_db.tripCache).get();
    for (final row in rows) {
      final map = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      final summary = DomainMappers.tripFromDto(dto.TripView.fromJson(map));
      if (summary.isActive) return summary;
    }
    return null;
  }

  Future<void> _cacheTrip(dto.TripView view) async {
    await _db.into(_db.tripCache).insertOnConflictUpdate(
          TripCacheCompanion.insert(
            tripId: view.trip_id,
            payloadJson: jsonEncode(view.toJson()),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> _persistNaMePairing(TripSummary summary) async {
    await _db.into(_db.kvStore).insertOnConflictUpdate(
          KvStoreCompanion.insert(
            key: 'na_me:${summary.tripId}',
            value: jsonEncode(summary.naMe.toJson()),
          ),
        );
  }
}
