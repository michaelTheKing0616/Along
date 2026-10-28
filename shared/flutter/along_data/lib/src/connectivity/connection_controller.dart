import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Where the app is in the offline → back-online cycle.
enum ConnectionPhase {
  /// Connected; no banner.
  online,

  /// No network. Core actions keep working and queue.
  offline,

  /// Network is back (or the user tapped Retry); queued actions are sending.
  reconnecting,

  /// Briefly confirms the reconnect before settling to [online].
  restored,
}

/// What the banner shows.
class ConnectionSnapshot {
  const ConnectionSnapshot({
    this.phase = ConnectionPhase.online,
    this.queued = 0,
    this.sent = 0,
    this.offlineSince,
  });

  final ConnectionPhase phase;

  /// Actions saved on the device, waiting to send.
  final int queued;

  /// Actions sent during the last reconnect.
  final int sent;
  final DateTime? offlineSince;

  bool get showBanner => phase != ConnectionPhase.online;

  ConnectionSnapshot copyWith({
    ConnectionPhase? phase,
    int? queued,
    int? sent,
    DateTime? offlineSince,
  }) => ConnectionSnapshot(
    phase: phase ?? this.phase,
    queued: queued ?? this.queued,
    sent: sent ?? this.sent,
    offlineSince: offlineSince ?? this.offlineSince,
  );
}

/// Reachability signal. Swap for [FakeConnectionSource] in tests.
abstract class ConnectionSource {
  Future<bool> isOnline();
  Stream<bool> get changes;
}

class ConnectivityConnectionSource implements ConnectionSource {
  ConnectivityConnectionSource({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _online(List<ConnectivityResult> r) =>
      r.isNotEmpty && !r.every((x) => x == ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _online(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes =>
      _connectivity.onConnectivityChanged.map(_online).distinct();
}

class FakeConnectionSource implements ConnectionSource {
  FakeConnectionSource({bool online = true}) : _isOnline = online;

  bool _isOnline;
  final _controller = StreamController<bool>.broadcast();

  set online(bool value) {
    _isOnline = value;
    _controller.add(value);
  }

  @override
  Future<bool> isOnline() async => _isOnline;

  @override
  Stream<bool> get changes => _controller.stream;
}

/// Drives the connection banner. Never blocks: it only reports state and
/// replays the queue when the network returns.
class ConnectionController {
  ConnectionController({
    required this.source,
    Future<int> Function()? queuedCount,
    Future<int> Function()? replay,
    DateTime Function()? now,
    this.restoredHold = const Duration(milliseconds: 2500),
  }) : _queuedCount = queuedCount ?? (() async => 0),
       _replay = replay ?? (() async => 0),
       _now = now ?? DateTime.now;

  final ConnectionSource source;
  final Future<int> Function() _queuedCount;
  final Future<int> Function() _replay;
  final DateTime Function() _now;
  final Duration restoredHold;

  final _out = StreamController<ConnectionSnapshot>.broadcast();
  StreamSubscription<bool>? _sub;
  Timer? _settle;
  ConnectionSnapshot _current = const ConnectionSnapshot();
  bool _replaying = false;

  ConnectionSnapshot get current => _current;
  Stream<ConnectionSnapshot> get changes => _out.stream;

  /// Starts listening. A missing or failing platform signal counts as
  /// online so the app never shows a false offline state.
  Future<void> start() async {
    try {
      _sub ??= source.changes.listen(_onSignal, onError: (Object _) {});
      if (!await source.isOnline()) await _goOffline();
    } catch (_) {}
  }

  /// Call after enqueueing an action so the count stays honest.
  Future<void> refreshQueued() async {
    _emit(_current.copyWith(queued: await _safeCount()));
  }

  /// User tapped Retry: check now instead of waiting for the OS signal.
  Future<void> retry() async {
    if (_current.phase != ConnectionPhase.offline) return;
    _emit(_current.copyWith(phase: ConnectionPhase.reconnecting));
    if (await _safeOnline()) {
      await _reconnect();
    } else {
      _emit(_current.copyWith(phase: ConnectionPhase.offline));
    }
  }

  Future<void> _onSignal(bool online) async {
    if (!online) {
      await _goOffline();
    } else if (_current.phase == ConnectionPhase.offline) {
      await _reconnect();
    }
  }

  Future<void> _goOffline() async {
    _settle?.cancel();
    final since = _current.phase == ConnectionPhase.offline
        ? _current.offlineSince
        : _now();
    _emit(
      ConnectionSnapshot(
        phase: ConnectionPhase.offline,
        queued: await _safeCount(),
        offlineSince: since,
      ),
    );
  }

  Future<void> _reconnect() async {
    if (_replaying) return;
    _replaying = true;
    _emit(_current.copyWith(phase: ConnectionPhase.reconnecting));
    var sent = 0;
    try {
      sent = await _replay();
    } catch (_) {
      // Anything unsent stays queued for the next reconnect.
    }
    _replaying = false;
    if (!await _safeOnline()) {
      await _goOffline();
      return;
    }
    _emit(
      ConnectionSnapshot(
        phase: ConnectionPhase.restored,
        queued: await _safeCount(),
        sent: sent,
      ),
    );
    _settle?.cancel();
    _settle = Timer(restoredHold, () {
      if (_current.phase == ConnectionPhase.restored) {
        _emit(ConnectionSnapshot(queued: _current.queued));
      }
    });
  }

  Future<bool> _safeOnline() async {
    try {
      return await source.isOnline();
    } catch (_) {
      return true;
    }
  }

  Future<int> _safeCount() async {
    try {
      return await _queuedCount();
    } catch (_) {
      return _current.queued;
    }
  }

  void _emit(ConnectionSnapshot next) {
    _current = next;
    if (!_out.isClosed) _out.add(next);
  }

  Future<void> dispose() async {
    _settle?.cancel();
    await _sub?.cancel();
    await _out.close();
  }
}
