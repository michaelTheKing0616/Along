import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;
import 'package:along_data/src/database/along_database.dart';
import 'package:along_data/src/database/pending_action_queue.dart';
import 'package:along_data/src/safety/safety_repository.dart';

/// Arguments for one SOS attempt, including the copy used when offline.
class SosRaiseRequest {
  const SosRaiseRequest({
    this.tripId,
    this.journeyId,
    required this.lat,
    required this.lng,
    this.accuracyM = 25,
  });

  final String? tripId;
  final String? journeyId;
  final double lat;
  final double lng;
  final double accuracyM;

  /// One queued alert per trip so a retry updates location instead of stacking.
  String get queueId => 'sos:${tripId ?? journeyId ?? 'standalone'}';

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'journey_id': journeyId,
    'lat': lat,
    'lng': lng,
    'accuracy_m': accuracyM,
  };

  factory SosRaiseRequest.fromJson(Map<String, dynamic> json) {
    return SosRaiseRequest(
      tripId: json['trip_id'] as String?,
      journeyId: json['journey_id'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      accuracyM: (json['accuracy_m'] as num?)?.toDouble() ?? 25,
    );
  }
}

enum SosDeliveryState { sent, queued }

class SosDeliveryOutcome {
  const SosDeliveryOutcome.sent(this.result) : state = SosDeliveryState.sent;

  const SosDeliveryOutcome.queued()
    : state = SosDeliveryState.queued,
      result = null;

  final SosDeliveryState state;
  final SosRaiseResult? result;

  bool get isQueued => state == SosDeliveryState.queued;
}

/// Free channels. Push is sent by the notify function; these links are the
/// on-device fallback that does not need a paid SMS gateway.
class SosContactChannel {
  const SosContactChannel({
    required this.name,
    required this.phoneE164,
    required this.whatsappUrl,
    required this.smsUri,
  });

  final String name;
  final String phoneE164;
  final String whatsappUrl;
  final String smsUri;
}

/// Message a contact can open with no data plan beyond the share itself.
String sosHelpMessage({
  required double lat,
  required double lng,
  String? shareUrl,
}) {
  final pin =
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng';
  final where = (shareUrl != null && shareUrl.isNotEmpty) ? shareUrl : pin;
  return 'I need help on an Along trip. Live location: $where';
}

List<SosContactChannel> sosContactChannels({
  required List<EmergencyContact> contacts,
  required String message,
}) {
  final encoded = Uri.encodeComponent(message);
  return [
    for (final contact in contacts)
      SosContactChannel(
        name: contact.name,
        phoneE164: contact.phoneE164,
        whatsappUrl:
            'https://wa.me/${contact.phoneE164.replaceAll(RegExp(r'\D'), '')}?text=$encoded',
        smsUri: 'sms:${contact.phoneE164}?body=$encoded',
      ),
  ];
}

bool sosFailureIsRetryable(AlongException error) {
  return error.code == AlongErrorCode.unknown ||
      error.code == AlongErrorCode.degradedUpstream;
}

/// Server cap in `emergency_contacts` (migration 83).
const emergencyContactLimit = 5;

final RegExp _e164Phone = RegExp(r'^\+[1-9][0-9]{7,14}$');

/// Accepts E.164, a Nigerian local `0…` number, or `234…` without a plus.
String? normalizeEmergencyPhone(String raw) {
  final compact = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (compact.isEmpty) return null;
  if (_e164Phone.hasMatch(compact)) return compact;
  if (RegExp(r'^0[1-9][0-9]{8,10}$').hasMatch(compact)) {
    final candidate = '+234${compact.substring(1)}';
    return _e164Phone.hasMatch(candidate) ? candidate : null;
  }
  if (RegExp(r'^234[1-9][0-9]{7,12}$').hasMatch(compact)) {
    final candidate = '+$compact';
    return _e164Phone.hasMatch(candidate) ? candidate : null;
  }
  return null;
}

/// Last known contacts, so SOS can still open WhatsApp when the network is down.
class EmergencyContactStore {
  EmergencyContactStore(this._db);

  static const cacheKey = 'emergency_contacts';

  final AlongDatabase _db;

  Future<List<EmergencyContact>> read() async {
    final row = await (_db.select(
      _db.kvStore,
    )..where((table) => table.key.equals(cacheKey))).getSingleOrNull();
    if (row == null || row.value.isEmpty) return const [];
    final decoded = jsonDecode(row.value);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) EmergencyContact.fromJson(item),
    ];
  }

  Future<void> write(List<EmergencyContact> contacts) async {
    await _db
        .into(_db.kvStore)
        .insertOnConflictUpdate(
          KvStoreCompanion.insert(
            key: cacheKey,
            value: jsonEncode([
              for (final contact in contacts) contact.toJson(),
            ]),
          ),
        );
  }
}

/// Queues a failed SOS raise and replays it when the device is back online.
class SosOutbox {
  SosOutbox(this._queue);

  static const actionType = 'raise_sos';

  final PendingActionQueue _queue;

  Future<void> enqueue(SosRaiseRequest request) {
    return _queue.enqueue(
      id: request.queueId,
      type: actionType,
      payload: request.toJson(),
    );
  }

  Future<void> discard(SosRaiseRequest request) {
    return _queue.remove(request.queueId);
  }

  Future<bool> hasPending() async {
    final rows = await _queue.pendingFifo();
    return rows.any((row) => row.type == actionType);
  }

  Future<SosRaiseResult?> flush(SafetyRepository repository) async {
    SosRaiseResult? last;
    await _queue.replay((action) async {
      if (action.type != actionType) {
        throw StateError('Leaving non-SOS action ${action.type} queued');
      }
      final request = SosRaiseRequest.fromJson(action.payload);
      last = await repository.raiseSos(
        tripId: request.tripId,
        journeyId: request.journeyId,
        location: dto.Point(lat: request.lat, lng: request.lng),
        accuracyM: request.accuracyM,
      );
    });
    return last;
  }
}

/// Sends SOS now, or stores it for retry. Does not drop a validation failure
/// into the queue — only connectivity-shaped errors.
class SosRaiseCoordinator {
  SosRaiseCoordinator({required this.repository, required this.outbox});

  final SafetyRepository repository;
  final SosOutbox outbox;

  Future<SosDeliveryOutcome> submit(SosRaiseRequest request) async {
    try {
      final result = await repository.raiseSos(
        tripId: request.tripId,
        journeyId: request.journeyId,
        location: dto.Point(lat: request.lat, lng: request.lng),
        accuracyM: request.accuracyM,
      );
      try {
        await outbox.discard(request);
      } catch (_) {
        // The alert is already on the server. A leftover queue row is retried
        // later; failing the success path would hide a delivered SOS.
      }
      return SosDeliveryOutcome.sent(result);
    } on AlongException catch (error) {
      if (!sosFailureIsRetryable(error)) rethrow;
      await outbox.enqueue(request);
      return const SosDeliveryOutcome.queued();
    }
  }

  /// Replays a queued raise. Stays queued when the network is still down.
  Future<SosDeliveryOutcome> flushPending() async {
    final flushed = await outbox.flush(repository);
    if (flushed == null) return const SosDeliveryOutcome.queued();
    return SosDeliveryOutcome.sent(flushed);
  }
}
