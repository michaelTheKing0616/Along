import 'dart:async';

import 'package:along_data/src/connectivity/connection_controller.dart';

/// Builds a controller parked in [phase] for goldens and widget tests.
/// Call [ConnectionController.start] (or let the provider do it) and pump.
ConnectionController connectionControllerIn(
  ConnectionPhase phase, {
  int queued = 2,
}) {
  final source = FakeConnectionSource(online: phase == ConnectionPhase.online);
  var left = queued;
  final controller = ConnectionController(
    source: source,
    queuedCount: () async => left,
    replay: () {
      if (phase == ConnectionPhase.reconnecting) {
        return Completer<int>().future;
      }
      final sent = left;
      left = 0;
      return Future.value(sent);
    },
    restoredHold: const Duration(seconds: 2),
  );
  if (phase == ConnectionPhase.reconnecting ||
      phase == ConnectionPhase.restored) {
    scheduleMicrotask(() async {
      await Future<void>.delayed(Duration.zero);
      source.online = true;
    });
  }
  return controller;
}
