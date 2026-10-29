import 'dart:io';
import 'dart:math';

import 'package:along_core/along_core.dart';
import 'package:along_data/src/database/pending_action_queue.dart';
import 'package:along_data/src/safety/safety_repository.dart';
import 'package:along_data/src/supabase/along_supabase.dart';

/// Server cap in `report_incident` (migration 103).
const incidentPhotoLimit = 4;

/// Private bucket created in migration 51; RLS keys objects by `<uid>/…`.
const incidentPhotoBucket = 'incidents';

/// Random v4 UUID for `incidents.client_ref`.
String newIncidentClientRef([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Reads a local photo. Tests inject bytes; the app reads the file.
typedef PhotoBytesReader = Future<List<int>> Function(String localPath);

Future<List<int>> readPhotoFile(String localPath) =>
    File(localPath).readAsBytes();

/// A report the rider has written. [clientRef] makes the server write
/// idempotent, so the queue may replay it without a duplicate.
class IncidentReportDraft {
  const IncidentReportDraft({
    required this.clientRef,
    required this.type,
    required this.description,
    this.tripId,
    this.photoPaths = const [],
  });

  factory IncidentReportDraft.fromJson(Map<String, dynamic> json) {
    return IncidentReportDraft(
      clientRef: json['client_ref'] as String,
      type: json['type'] as String,
      description: json['description'] as String? ?? '',
      tripId: json['trip_id'] as String?,
      photoPaths: [
        for (final p in (json['photo_paths'] as List<dynamic>? ?? const []))
          p as String,
      ],
    );
  }

  final String clientRef;
  final String type;
  final String description;
  final String? tripId;

  /// Local file paths on the device, uploaded at send time.
  final List<String> photoPaths;

  Map<String, dynamic> toJson() => {
    'client_ref': clientRef,
    'type': type,
    'description': description,
    'trip_id': tripId,
    'photo_paths': photoPaths,
  };
}

/// Storage object name for photo [index] of a report. Stable per report, so
/// a retried upload overwrites rather than piling up copies.
String incidentPhotoObject(String userId, String clientRef, int index) {
  final safeIndex = index.clamp(0, incidentPhotoLimit - 1);
  return '$userId/$clientRef-$safeIndex.jpg';
}

/// Outcome of a send attempt.
enum IncidentDelivery { sent, queued }

/// Uploads photos, then files the report. Photos go first: the server
/// rejects a path with no uploaded object.
class IncidentReporter {
  IncidentReporter({
    required this.gateway,
    required this.safety,
    required this.queue,
    PhotoBytesReader? readBytes,
  }) : _readBytes = readBytes ?? readPhotoFile;

  static const actionType = 'report_incident_v2';

  final AlongSupabase gateway;
  final SafetyRepository safety;
  final PendingActionQueue queue;
  final PhotoBytesReader _readBytes;

  /// Sends now; on a connectivity-shaped failure stores the draft and
  /// returns [IncidentDelivery.queued]. Validation errors are rethrown.
  Future<IncidentDelivery> submit(
    IncidentReportDraft draft, {
    void Function(int uploaded, int total)? onProgress,
  }) async {
    try {
      await send(draft, onProgress: onProgress);
      await queue.remove(_queueId(draft));
      return IncidentDelivery.sent;
    } on AlongException catch (error) {
      if (!_retryable(error)) rethrow;
      await _enqueue(draft);
      return IncidentDelivery.queued;
    } on SocketException {
      await _enqueue(draft);
      return IncidentDelivery.queued;
    }
  }

  Future<void> send(
    IncidentReportDraft draft, {
    void Function(int uploaded, int total)? onProgress,
  }) async {
    if (draft.photoPaths.length > incidentPhotoLimit) {
      throw const AlongException(
        code: AlongErrorCode.validation,
        message: 'too many photos',
      );
    }
    final total = draft.photoPaths.length;
    final userId = gateway.currentUser?.id;
    if (userId == null && total > 0) {
      throw const AlongException(
        code: AlongErrorCode.unauthenticated,
        message: 'signed out',
      );
    }
    final remote = <String>[];
    onProgress?.call(0, total);
    for (var i = 0; i < total; i++) {
      final object = incidentPhotoObject(userId!, draft.clientRef, i);
      final bytes = await _readBytes(draft.photoPaths[i]);
      try {
        await gateway.uploadStorageObject(
          bucket: incidentPhotoBucket,
          path: object,
          bytes: bytes,
        );
      } on AlongException {
        rethrow;
      } catch (error) {
        throw AlongException(
          code: AlongErrorCode.unknown,
          message: error.toString(),
        );
      }
      remote.add('$incidentPhotoBucket/$object');
      onProgress?.call(i + 1, total);
    }
    await safety.reportIncident(
      tripId: draft.tripId,
      type: draft.type,
      description: draft.description,
      attachmentPaths: remote,
      clientRef: draft.clientRef,
    );
  }

  Future<bool> hasPending() async {
    final rows = await queue.pendingFifo();
    return rows.any((row) => row.type == actionType);
  }

  Future<int> flush() {
    return queue.replay(
      where: (action) => action.type == actionType,
      (action) => send(IncidentReportDraft.fromJson(action.payload)),
    );
  }

  Future<void> _enqueue(IncidentReportDraft draft) {
    return queue.enqueue(
      id: _queueId(draft),
      type: actionType,
      payload: draft.toJson(),
    );
  }

  static String _queueId(IncidentReportDraft draft) =>
      'incident:${draft.clientRef}';

  static bool _retryable(AlongException error) =>
      error.code == AlongErrorCode.unknown ||
      error.code == AlongErrorCode.degradedUpstream;
}
