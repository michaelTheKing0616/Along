import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/rider_prefs/rider_prefs_store.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_panel.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-19 Wayfinding — standalone screen (coverage gap, transfer walk, etc.).
class WayfindingScreen extends ConsumerStatefulWidget {
  const WayfindingScreen({super.key, required this.args});

  final WayfindingRouteArgs args;

  @override
  ConsumerState<WayfindingScreen> createState() => _WayfindingScreenState();
}

class _WayfindingScreenState extends ConsumerState<WayfindingScreen> {
  WayfindingMode _mode = WayfindingMode.text;
  WalkingDirections? _directions;
  var _loading = true;
  var _arrived = false;
  String? _error;
  int? _arrivedRadiusM;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final prefs = ref.read(riderPrefsStoreProvider);
      final mode = await prefs.wayfindingMode();
      final directionsRepo = ref.read(walkingDirectionsRepositoryProvider);
      final configRepo = ref.read(configRepositoryProvider);

      final directions = await directionsRepo.fetchDirections(
        from: widget.args.from,
        to: widget.args.to,
        mode: mode,
        cacheTripId: widget.args.cacheTripId,
      );

      final radiusRaw = await _readWayfindingArrivedRadius(
        configRepo,
        widget.args.cityId,
      );

      if (!mounted) return;
      setState(() {
        _mode = mode;
        _directions = directions;
        _loading = false;
        _arrivedRadiusM = radiusRaw;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wayfindingTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _directions == null
                  ? Center(child: Text(l10n.errorGeneric))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_arrived)
                            Text(
                              l10n.wayfindingArrived,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.green.shade700,
                                  ),
                            ),
                          Expanded(
                            child: WayfindingPanel(
                              directions: _directions!,
                              mode: _mode,
                              tts: ref.read(wayfindingTtsProvider),
                              arrivedRadiusM: _arrivedRadiusM,
                              destination: widget.args.to,
                              userLocation: widget.args.userLocation,
                              onModeChanged: (mode) async {
                                setState(() => _mode = mode);
                                await ref
                                    .read(riderPrefsStoreProvider)
                                    .setWayfindingMode(mode);
                              },
                              onArrived: () {
                                if (!_arrived && mounted) {
                                  setState(() => _arrived = true);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class WayfindingRouteArgs {
  const WayfindingRouteArgs({
    required this.from,
    required this.to,
    this.userLocation,
    this.cacheTripId,
    this.cityId,
    this.destinationLabel,
  });

  final GeoPoint from;
  final GeoPoint to;
  final GeoPoint? userLocation;
  final String? cacheTripId;
  final String? cityId;
  final String? destinationLabel;
}

Future<int?> _readWayfindingArrivedRadius(
  ConfigRepository configRepo,
  String? cityId,
) async {
  try {
    return (await configRepo.configNum(
      'wayfinding.arrived_radius_m',
      cityId: cityId,
    ))
        .toInt();
  } catch (_) {
    return null;
  }
}
