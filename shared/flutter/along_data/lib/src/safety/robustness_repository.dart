import 'package:along_core/along_core.dart';
import 'package:along_data/src/database/pending_action_queue.dart';
import 'package:along_data/src/safety/phase_d_rules.dart';
import 'package:along_data/src/safety/sos_delivery.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Server writes for guardian events, rest, and masked trip messages.
///
/// A retryable failure is stored on the offline queue with the same
/// idempotency key the server will accept once.
class RobustnessRepository {
  RobustnessRepository(this._gateway, {this._queue});

  final AlongSupabase _gateway;
  final PendingActionQueue? _queue;

  Future<void> saveGuardianPrefs(
    GuardianPrefs prefs, {
    required String idempotencyKey,
  }) {
    return _send('save_guardian_prefs', idempotencyKey, {
      'p_enabled': prefs.enabled,
      'p_off_route_m': prefs.offRouteMeters,
      'p_long_stop_minutes': prefs.longStopMinutes,
      'p_check_in_minutes': prefs.checkInMinutes,
      'p_safe_word': prefs.safeWord.trim().isEmpty
          ? null
          : prefs.safeWord.trim(),
      'p_idempotency_key': idempotencyKey,
    });
  }

  Future<void> recordGuardianEvent({
    required String tripId,
    required String kind,
    required String idempotencyKey,
    required bool escalate,
    double? lat,
    double? lng,
  }) {
    return _send('record_guardian_event', idempotencyKey, {
      'p_trip_id': tripId,
      'p_kind': kind,
      'p_idempotency_key': idempotencyKey,
      'p_escalate': escalate,
      if (lat != null && lng != null) 'p_location': {'lat': lat, 'lng': lng},
    });
  }

  Future<void> saveRestPrefs(
    RestPrefs prefs, {
    required String idempotencyKey,
  }) {
    return _send('save_rest_prefs', idempotencyKey, {
      'p_drive_minutes': prefs.driveMinutes,
      'p_rest_minutes': prefs.restMinutes,
      'p_idempotency_key': idempotencyKey,
    });
  }

  Future<void> recordDriverRest({
    required DateTime startedAt,
    required DateTime endedAt,
    required String idempotencyKey,
  }) {
    return _send('record_driver_rest', idempotencyKey, {
      'p_started_at': startedAt.toUtc().toIso8601String(),
      'p_ended_at': endedAt.toUtc().toIso8601String(),
      'p_idempotency_key': idempotencyKey,
    });
  }

  Future<void> postTripMessage({
    required String tripId,
    required String body,
    required String clientRef,
  }) {
    return _send('post_trip_message', clientRef, {
      'p_trip_id': tripId,
      'p_body': body,
      'p_client_ref': clientRef,
    });
  }

  Future<List<TripMessage>> listTripMessages(String tripId) async {
    try {
      final raw = await _gateway.rpc(
        'list_trip_messages',
        params: {'p_trip_id': tripId},
      );
      if (raw is! List) return const [];
      return [
        for (final row in raw)
          if (row is Map<String, dynamic>) TripMessage.fromJson(row),
      ];
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  Future<void> _send(
    String fn,
    String idempotencyKey,
    Map<String, dynamic> params,
  ) async {
    try {
      await _gateway.rpc(fn, params: params);
    } catch (error) {
      final mapped = error is AlongException ? error : mapSupabaseError(error);
      final queue = _queue;
      if (queue != null && sosFailureIsRetryable(mapped)) {
        await queue.enqueue(
          id: '$fn:$idempotencyKey',
          type: fn,
          payload: params,
        );
        return;
      }
      throw mapped;
    }
  }
}

/// A masked lost-and-found line. Role only, never a phone number.
class TripMessage {
  const TripMessage({
    required this.id,
    required this.authorRole,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorRole;
  final String body;
  final DateTime createdAt;

  factory TripMessage.fromJson(Map<String, dynamic> json) {
    return TripMessage(
      id: json['id'] as String? ?? '',
      authorRole: json['author_role'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
