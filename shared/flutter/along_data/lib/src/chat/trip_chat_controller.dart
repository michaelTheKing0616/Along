import 'dart:async';
import 'dart:math';

import 'package:along_core/along_core.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter/foundation.dart';

enum TripChatState { sending, sent, read, failed }

class TripChatEntry {
  const TripChatEntry({
    required this.key,
    required this.body,
    required this.mine,
    required this.at,
    required this.state,
    this.serverId,
    this.lostFound = false,
  });

  /// client_ref for my lines, server id for theirs.
  final String key;
  final String body;
  final bool mine;
  final DateTime at;
  final TripChatState state;
  final String? serverId;

  /// Posted on the post-trip lost-and-found thread, not the live chat.
  final bool lostFound;

  TripChatEntry copyWith({TripChatState? state, String? serverId}) =>
      TripChatEntry(
        key: key,
        body: body,
        mine: mine,
        at: at,
        state: state ?? this.state,
        serverId: serverId ?? this.serverId,
        lostFound: lostFound,
      );
}

/// Free in-app trip chat: Postgres RPCs plus a private Realtime channel.
///
/// Sends are optimistic: the line shows at once as `sending`, then `sent`
/// on the server ack and `read` on the other side's receipt. Failed sends
/// stay queued and retry on a timer (same client_ref, so the server dedupes);
/// after [maxAutoRetries] they show `failed` and retry on tap.
class TripChatController extends ChangeNotifier {
  TripChatController({
    required this.gateway,
    required this.channel,
    required this.tripId,
    required this.myRole,
    this.retryDelay = const Duration(seconds: 3),
    this.maxAutoRetries = 3,
    String Function()? newRef,
    DateTime Function()? now,
  }) : _newRef = newRef ?? _randomRef,
       _now = now ?? DateTime.now;

  final AlongSupabase gateway;
  final TripChatChannel channel;
  final String tripId;

  /// 'rider' or 'driver'.
  final String myRole;
  final Duration retryDelay;
  final int maxAutoRetries;
  final String Function() _newRef;
  final DateTime Function() _now;

  final List<TripChatEntry> _lines = [];
  final Map<String, int> _attempts = {};
  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _retry;
  bool _visible = false;
  bool _disposed = false;
  int _unread = 0;
  bool _closed = false;

  /// Fires when the other party's message lands (haptic hook).
  VoidCallback? onIncoming;

  List<TripChatEntry> get lines => List.unmodifiable(_lines);
  int get unread => _unread;
  bool get closed => _closed;

  Future<void> start() async {
    _sub ??= channel.events.listen(_onEvent);
    try {
      await channel.subscribe(tripId);
    } catch (_) {
      // Realtime down: the list below and the retry loop still work.
    }
    await refresh();
  }

  Future<void> refresh() async {
    List<dynamic> rows;
    try {
      final raw = await gateway.rpc(
        'list_trip_messages',
        params: {'p_trip_id': tripId},
      );
      if (raw is! List) return;
      rows = raw;
    } catch (_) {
      return;
    }
    final pending = _lines.where((l) => l.mine && l.serverId == null).toList();
    final next = <TripChatEntry>[];
    var unread = 0;
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final entry = _fromRow(row);
      next.add(entry);
      if (!entry.mine && row['read_at'] == null) unread++;
    }
    final known = {for (final e in next) e.key};
    next.addAll(pending.where((p) => !known.contains(p.key)));
    _lines
      ..clear()
      ..addAll(next);
    _unread = _visible ? 0 : unread;
    _notify();
    if (_visible && unread > 0) unawaited(_markRead());
  }

  void send(String body) {
    final text = body.trim();
    if (text.isEmpty || _closed) return;
    final ref = _newRef();
    _lines.add(
      TripChatEntry(
        key: ref,
        body: text,
        mine: true,
        at: _now(),
        state: TripChatState.sending,
      ),
    );
    _notify();
    unawaited(_post(ref));
  }

  void retry(String key) {
    final i = _lines.indexWhere((l) => l.key == key);
    if (i < 0 || _lines[i].state != TripChatState.failed) return;
    _attempts[key] = 0;
    _lines[i] = _lines[i].copyWith(state: TripChatState.sending);
    _notify();
    unawaited(_post(key));
  }

  /// Sheet open: clears the badge and sends a read receipt.
  set visible(bool value) {
    _visible = value;
    if (value && _unread > 0) {
      _unread = 0;
      _notify();
      unawaited(_markRead());
    }
  }

  Future<void> _post(String ref) async {
    final i = _lines.indexWhere((l) => l.key == ref);
    if (i < 0) return;
    try {
      final raw = await gateway.rpc(
        'post_trip_message',
        params: {
          'p_trip_id': tripId,
          'p_body': _lines[i].body,
          'p_client_ref': ref,
          'p_thread': 'chat',
        },
      );
      final j = _lines.indexWhere((l) => l.key == ref);
      if (j < 0) return;
      final id = raw is Map ? raw['id'] as String? : null;
      final state = _lines[j].state == TripChatState.read
          ? TripChatState.read
          : TripChatState.sent;
      _lines[j] = _lines[j].copyWith(state: state, serverId: id ?? ref);
      _attempts.remove(ref);
      _notify();
    } catch (error) {
      final mapped = error is AlongException ? error : mapSupabaseError(error);
      final j = _lines.indexWhere((l) => l.key == ref);
      if (j < 0) return;
      final code = mapped.code;
      if (code == AlongErrorCode.stateInvalid ||
          code == AlongErrorCode.forbidden) {
        _closed = code == AlongErrorCode.stateInvalid;
        _lines[j] = _lines[j].copyWith(state: TripChatState.failed);
        _notify();
        return;
      }
      if (code == AlongErrorCode.validation) {
        _lines[j] = _lines[j].copyWith(state: TripChatState.failed);
        _notify();
        return;
      }
      final n = (_attempts[ref] ?? 0) + 1;
      _attempts[ref] = n;
      if (n >= maxAutoRetries) {
        _lines[j] = _lines[j].copyWith(state: TripChatState.failed);
        _notify();
        return;
      }
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_retry?.isActive ?? false) return;
    _retry = Timer(retryDelay, () {
      if (_disposed) return;
      for (final l in _lines.toList()) {
        if (l.mine && l.serverId == null && l.state == TripChatState.sending) {
          unawaited(_post(l.key));
        }
      }
    });
  }

  Future<void> _markRead() async {
    try {
      await gateway.rpc(
        'mark_trip_messages_read',
        params: {'p_trip_id': tripId},
      );
    } catch (_) {
      // Next open retries; the badge is local.
    }
  }

  void _onEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'message':
        final row = event['message'];
        if (row is! Map<String, dynamic>) return;
        final role = row['author_role'];
        if (role == myRole) {
          final ref = row['client_ref'] as String?;
          final i = _lines.indexWhere((l) => l.key == ref);
          if (i >= 0 && _lines[i].serverId == null) {
            _lines[i] = _lines[i].copyWith(
              state: TripChatState.sent,
              serverId: row['id'] as String?,
            );
            _notify();
          }
          return;
        }
        final entry = _fromRow(row);
        if (_lines.any((l) => l.key == entry.key)) return;
        _lines.add(entry);
        if (_visible) {
          unawaited(_markRead());
        } else {
          _unread++;
        }
        onIncoming?.call();
        _notify();
      case 'read':
        if (event['reader_role'] == myRole) return;
        var changed = false;
        for (var i = 0; i < _lines.length; i++) {
          final l = _lines[i];
          if (l.mine && l.state == TripChatState.sent) {
            _lines[i] = l.copyWith(state: TripChatState.read);
            changed = true;
          }
        }
        if (changed) _notify();
    }
  }

  TripChatEntry _fromRow(Map<String, dynamic> row) {
    final mine = row['author_role'] == myRole;
    final id = row['id'] as String? ?? '';
    final ref = row['client_ref'] as String?;
    return TripChatEntry(
      key: mine && ref != null ? ref : id,
      body: row['body'] as String? ?? '',
      mine: mine,
      at:
          DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
          _now(),
      state: mine
          ? (row['read_at'] != null ? TripChatState.read : TripChatState.sent)
          : TripChatState.sent,
      serverId: id,
      lostFound: row['thread'] == 'lost_found',
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    unawaited(_sub?.cancel());
    unawaited(channel.unsubscribe());
    super.dispose();
  }

  static String _randomRef() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join();
  }
}

/// Quick replies from `chat.quick_replies` config, with built-in fallbacks.
List<String> tripChatQuickReplies(Object? raw, String role) {
  if (raw is Map && raw[role] is List) {
    final list = [
      for (final v in raw[role] as List)
        if (v is String && v.trim().isNotEmpty) v.trim(),
    ];
    if (list.isNotEmpty) return list;
  }
  return role == 'driver'
      ? const ["I'm here", 'Arriving in 2 min', 'Okay, thanks']
      : const ["I'm at the pickup", 'Where are you?', 'Okay, thanks'];
}
