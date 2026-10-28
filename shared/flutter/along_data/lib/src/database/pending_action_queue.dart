import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/src/database/along_database.dart';
import 'package:drift/drift.dart';

/// FIFO offline action queue with idempotent replay via `p_client_ref`.
class PendingActionQueue {
  PendingActionQueue(this._db, {Clock? clock}) : _clock = clock ?? Clock.system;

  final AlongDatabase _db;
  final Clock _clock;

  static const maxAge = Duration(days: 7);
  static const maxAttempts = 8;

  Future<void> enqueue({
    required String id,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    await _db
        .into(_db.pendingActions)
        .insertOnConflictUpdate(
          PendingActionsCompanion.insert(
            id: id,
            type: type,
            payloadJson: jsonEncode(payload),
            createdAt: _clock.now(),
          ),
        );
  }

  Future<List<QueuedAction>> pendingFifo() async {
    await _dropExpired();
    final rows = await (_db.select(
      _db.pendingActions,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    return rows
        .map(
          (row) => QueuedAction(
            id: row.id,
            type: row.type,
            payload: jsonDecode(row.payloadJson) as Map<String, dynamic>,
            createdAt: row.createdAt,
            attempts: row.attempts,
          ),
        )
        .toList();
  }

  /// Replays queued actions FIFO. [where] limits replay to the types the
  /// caller can send; anything else stays queued with its attempts intact.
  Future<int> replay(
    Future<void> Function(QueuedAction action) handler, {
    bool Function(QueuedAction action)? where,
  }) async {
    var processed = 0;
    for (final action in await pendingFifo()) {
      if (where != null && !where(action)) continue;
      if (action.attempts >= maxAttempts) {
        await remove(action.id);
        continue;
      }
      try {
        await handler(action);
        await (_db.delete(
          _db.pendingActions,
        )..where((t) => t.id.equals(action.id))).go();
        processed++;
      } on AlongException catch (error) {
        if (_terminal(error)) {
          await remove(action.id);
          continue;
        }
        await _incrementAttempts(action.id);
      } catch (_) {
        await _incrementAttempts(action.id);
      }
    }
    return processed;
  }

  /// Validation and state errors will not succeed on a retry.
  bool _terminal(AlongException error) {
    return switch (error.code) {
      AlongErrorCode.validation ||
      AlongErrorCode.forbidden ||
      AlongErrorCode.notFound ||
      AlongErrorCode.stateInvalid ||
      AlongErrorCode.conflict ||
      AlongErrorCode.unauthenticated => true,
      _ => false,
    };
  }

  Future<void> _incrementAttempts(String id) async {
    final row = await (_db.select(
      _db.pendingActions,
    )..where((t) => t.id.equals(id))).getSingle();
    await (_db.update(_db.pendingActions)..where((t) => t.id.equals(id))).write(
      PendingActionsCompanion(
        attempts: Value(row.attempts + 1),
        lastAttemptAt: Value(_clock.now()),
      ),
    );
  }

  Future<void> remove(String id) async {
    await (_db.delete(_db.pendingActions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> _dropExpired() async {
    final cutoff = _clock.now().subtract(maxAge);
    await (_db.delete(
      _db.pendingActions,
    )..where((t) => t.createdAt.isSmallerThanValue(cutoff))).go();
  }
}

class QueuedAction {
  const QueuedAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.attempts,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
}
