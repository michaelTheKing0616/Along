import 'package:along_data/along_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';

/// Reads OS network generation / data-saver flags when available.
class RiderNetworkProbe extends NetworkConditionsProbe {
  RiderNetworkProbe({
    NetworkConditionsProbe? base,
    MethodChannel? channel,
    this._flagsOverride,
  })  : _base = base ?? ConnectivityNetworkProbe(),
        _channel = channel ?? const MethodChannel('ng.along.rider/network');

  final NetworkConditionsProbe _base;
  final MethodChannel _channel;
  final PlatformNetworkFlags Function()? _flagsOverride;

  @override
  Future<NetworkConditionsSnapshot> snapshot() async {
    final base = await _base.snapshot();
    final flags = _flagsOverride?.call() ?? await _readPlatformFlags();
    return NetworkConditionsSnapshot(
      offline: base.offline,
      onMobile: base.onMobile,
      slowMobile: flags.is2G,
      dataSaverEnabled: flags.dataSaverEnabled,
    );
  }

  Future<PlatformNetworkFlags> _readPlatformFlags() async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>('snapshot');
      if (raw == null) return const PlatformNetworkFlags();
      return PlatformNetworkFlags(
        is2G: raw['is_2g'] == true,
        dataSaverEnabled: raw['data_saver'] == true,
      );
    } on MissingPluginException {
      return const PlatformNetworkFlags();
    } on PlatformException {
      return const PlatformNetworkFlags();
    }
  }
}

class PlatformNetworkFlags {
  const PlatformNetworkFlags({
    this.is2G = false,
    this.dataSaverEnabled = false,
  });

  final bool is2G;
  final bool dataSaverEnabled;
}

final networkConditionsProbeProvider = Provider<NetworkConditionsProbe>((ref) {
  throw UnimplementedError(
    'networkConditionsProbeProvider must be overridden at startup',
  );
});

final lowDataModeProvider = FutureProvider<LowDataMode>((ref) async {
  final probe = ref.watch(networkConditionsProbeProvider);
  final config = ref.watch(configRepositoryProvider);
  final snapshot = await probe.snapshot();

  var maxTileZoom = LowDataMode.defaultMaxTileZoom;
  var ambientPollS = LowDataMode.defaultAmbientPollIntervalS;
  try {
    maxTileZoom =
        (await config.configNum('client.low_data_tile_max_zoom')).toInt();
  } catch (_) {}
  try {
    ambientPollS =
        (await config.configNum('client.ambient_poll_interval_s')).toInt();
  } catch (_) {}

  return LowDataMode.fromSnapshot(
    snapshot,
    maxTileZoom: maxTileZoom,
    ambientPollIntervalS: ambientPollS,
  );
});

final isOfflineProvider = FutureProvider<bool>((ref) async {
  final probe = ref.watch(networkConditionsProbeProvider);
  final snapshot = await probe.snapshot();
  return snapshot.offline;
});
