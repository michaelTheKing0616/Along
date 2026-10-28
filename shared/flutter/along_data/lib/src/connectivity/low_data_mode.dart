import 'package:connectivity_plus/connectivity_plus.dart';

/// Network conditions probe for [LowDataMode] (doc 07 §4).
abstract class NetworkConditionsProbe {
  const NetworkConditionsProbe();

  Future<NetworkConditionsSnapshot> snapshot();
}

class ConnectivityNetworkProbe extends NetworkConditionsProbe {
  ConnectivityNetworkProbe({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<NetworkConditionsSnapshot> snapshot() async {
    final results = await _connectivity.checkConnectivity();
    final offline = results.contains(ConnectivityResult.none);
    final onMobile = results.contains(ConnectivityResult.mobile);
    return NetworkConditionsSnapshot(
      offline: offline,
      onMobile: onMobile,
      slowMobile: onMobile && !offline,
      dataSaverEnabled: false,
    );
  }
}

/// Test double — inject offline / 2G / data-saver without a device.
class FakeNetworkConditionsProbe extends NetworkConditionsProbe {
  FakeNetworkConditionsProbe(this._snapshot);

  NetworkConditionsSnapshot _snapshot;

  set currentSnapshot(NetworkConditionsSnapshot value) => _snapshot = value;

  @override
  Future<NetworkConditionsSnapshot> snapshot() async => _snapshot;
}

class NetworkConditionsSnapshot {
  const NetworkConditionsSnapshot({
    this.offline = false,
    this.onMobile = false,
    this.slowMobile = false,
    this.dataSaverEnabled = false,
  });

  final bool offline;
  final bool onMobile;
  final bool slowMobile;
  final bool dataSaverEnabled;

  bool get lowDataMode => slowMobile || dataSaverEnabled;
}

/// Low-data behaviour flags (doc 07 §4).
class LowDataMode {
  const LowDataMode({
    required this.enabled,
    this.maxTileZoom = defaultMaxTileZoom,
    this.ambientPollIntervalS = defaultAmbientPollIntervalS,
    this.loadAvatars = true,
    this.useAmbientBroadcast = true,
  });

  static const defaultMaxTileZoom = 15;
  static const defaultAmbientPollIntervalS = 30;

  final bool enabled;
  final int maxTileZoom;
  final int ambientPollIntervalS;
  final bool loadAvatars;
  final bool useAmbientBroadcast;

  factory LowDataMode.fromSnapshot(
    NetworkConditionsSnapshot snapshot, {
    int maxTileZoom = defaultMaxTileZoom,
    int ambientPollIntervalS = defaultAmbientPollIntervalS,
  }) {
    final enabled = snapshot.lowDataMode;
    return LowDataMode(
      enabled: enabled,
      maxTileZoom: maxTileZoom,
      ambientPollIntervalS: ambientPollIntervalS,
      loadAvatars: !enabled,
      useAmbientBroadcast: !enabled,
    );
  }

  factory LowDataMode.disabled() => const LowDataMode(enabled: false);
}
