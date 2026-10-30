import 'dart:async';

import 'package:along_data/along_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/connection/connection_banner_host.dart';
import 'package:permission_handler/permission_handler.dart';

/// Asks for the three permissions Along needs, one after another.
abstract class PermissionPrimer {
  Future<void> requestAll();
}

class SystemPermissionPrimer implements PermissionPrimer {
  const SystemPermissionPrimer();

  @override
  Future<void> requestAll() async {
    try {
      await [
        Permission.locationWhenInUse,
        Permission.notification,
        Permission.camera,
      ].request();
    } catch (_) {
      // No plugin (tests, desktop): the app asks again at first use.
    }
  }
}

final permissionPrimerProvider = Provider<PermissionPrimer>(
  (ref) => const SystemPermissionPrimer(),
);

/// Sign-in screens explain offline inline, so they hide the global banner
/// while they are open and read reachability themselves.
mixin AuthOfflineAware<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  StateController<int>? _mute;

  @override
  void initState() {
    super.initState();
    _mute = ref.read(connectionBannerMutedProvider.notifier);
    scheduleMicrotask(() => _mute?.state++);
  }

  @override
  void dispose() {
    final mute = _mute;
    scheduleMicrotask(() {
      try {
        mute?.state--;
      } catch (_) {}
    });
    super.dispose();
  }

  bool watchOffline() {
    final controller = ref.watch(connectionControllerProvider);
    final snap =
        ref.watch(connectionSnapshotProvider).valueOrNull ?? controller.current;
    return snap.phase == ConnectionPhase.offline;
  }

  void retryConnection() => ref.read(connectionControllerProvider).retry();
}

/// Ticks a rate-limit wait down to zero so the button can come back.
class RetryClock {
  RetryClock(this._onTick);

  final VoidCallback _onTick;
  Timer? _timer;
  int remaining = 0;

  void start(int seconds) {
    _timer?.cancel();
    remaining = seconds;
    _onTick();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining--;
      if (remaining <= 0) {
        remaining = 0;
        t.cancel();
      }
      _onTick();
    });
  }

  void dispose() => _timer?.cancel();
}
