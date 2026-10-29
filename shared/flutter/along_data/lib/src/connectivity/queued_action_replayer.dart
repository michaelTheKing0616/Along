import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;
import 'package:along_data/src/database/pending_action_queue.dart';
import 'package:along_data/src/safety/incident_delivery.dart';
import 'package:along_data/src/safety/safety_repository.dart';
import 'package:along_data/src/safety/sos_delivery.dart';
import 'package:along_data/src/supabase/along_supabase.dart';

/// How a queued action behaves while offline.
enum QueuedDelivery {
  /// Idempotent on the server: sent automatically when back online.
  sendsWhenOnline,

  /// No safe replay exists: the user has to redo it with a connection.
  needsConnection,
}

/// RPCs written by RobustnessRepository. Each payload carries its own
/// `p_idempotency_key` or `p_client_ref`, so a replay is applied once.
const idempotentQueuedRpcs = {
  'save_guardian_prefs',
  'record_guardian_event',
  'save_rest_prefs',
  'record_driver_rest',
  'post_trip_message',
};

QueuedDelivery queuedDeliveryFor(String type) =>
    type == SosOutbox.actionType ||
        type == IncidentReporter.actionType ||
        idempotentQueuedRpcs.contains(type)
    ? QueuedDelivery.sendsWhenOnline
    : QueuedDelivery.needsConnection;

/// Counts of queued actions by delivery class.
class QueuedSummary {
  const QueuedSummary({this.sendsWhenOnline = 0, this.needsConnection = 0});

  final int sendsWhenOnline;
  final int needsConnection;

  int get total => sendsWhenOnline + needsConnection;
}

/// Replays every queued action type that is safe to resend. Unknown types
/// are never touched, so they keep their attempts until a feature that owns
/// them sends or drops them.
class QueuedActionReplayer {
  QueuedActionReplayer({
    required this.queue,
    required this.gateway,
    required this.safety,
  });

  final PendingActionQueue queue;
  final AlongSupabase gateway;
  final SafetyRepository safety;

  Future<QueuedSummary> summary() async {
    var send = 0;
    var needs = 0;
    for (final a in await queue.pendingFifo()) {
      if (queuedDeliveryFor(a.type) == QueuedDelivery.sendsWhenOnline) {
        send++;
      } else {
        needs++;
      }
    }
    return QueuedSummary(sendsWhenOnline: send, needsConnection: needs);
  }

  Future<int> replay() {
    return queue.replay(
      where: (a) => queuedDeliveryFor(a.type) == QueuedDelivery.sendsWhenOnline,
      (action) async {
        if (action.type == SosOutbox.actionType) {
          final r = SosRaiseRequest.fromJson(action.payload);
          await safety.raiseSos(
            tripId: r.tripId,
            journeyId: r.journeyId,
            location: dto.Point(lat: r.lat, lng: r.lng),
            accuracyM: r.accuracyM,
          );
        } else if (action.type == IncidentReporter.actionType) {
          await IncidentReporter(
            gateway: gateway,
            safety: safety,
            queue: queue,
          ).send(IncidentReportDraft.fromJson(action.payload));
        } else {
          await gateway.rpc(action.type, params: action.payload);
        }
      },
    );
  }
}
