import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_panel.dart';
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
    final p = AlongPalette.of(context);
    final directions = _directions;
    final label = widget.args.destinationLabel;
    final subtitle = directions == null
        ? label
        : [
            if (label != null) l10n.wayfindingTo(label),
            l10n.wayfindingSummary(
              _formatWalk(directions.distanceM),
              (directions.durationS / 60).ceil(),
            ),
          ].join(' · ');

    return RiderTripStrings(
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AlongSpace.s20,
              AlongSpace.s8,
              AlongSpace.s20,
              AlongSpace.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Transform.translate(
                    offset: const Offset(-4, 0),
                    child: AlongMapButton(
                      key: const Key('wayfinding_back'),
                      icon: AlongIcons.back,
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
                const SizedBox(height: AlongSpace.s16),
                Text(l10n.wayfindingTitle, style: AlongType.display(p)),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: AlongSpace.s4),
                  Text(subtitle, style: AlongType.bodyMuted(p)),
                ],
                if (_arrived) ...[
                  const SizedBox(height: AlongSpace.s12),
                  TripNotice(
                    key: const Key('wayfinding_arrived'),
                    icon: AlongIcons.flag,
                    text: l10n.wayfindingArrived,
                  ),
                ],
                const SizedBox(height: AlongSpace.s20),
                Expanded(child: _body(l10n, p)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, AlongPalette p) {
    if (_loading) {
      return const Column(
        children: [
          AlongSkeleton(height: 52, width: double.infinity),
          SizedBox(height: AlongSpace.s16),
          AlongSkeleton(height: 220, width: double.infinity),
        ],
      );
    }
    final directions = _directions;
    if (_error != null || directions == null) {
      return Align(
        alignment: Alignment.topCenter,
        child: TripNotice(
          icon: AlongIcons.info,
          text: l10n.errorGeneric,
          warn: true,
        ),
      );
    }
    return WayfindingPanel(
      directions: directions,
      mode: _mode,
      tts: ref.read(wayfindingTtsProvider),
      arrivedRadiusM: _arrivedRadiusM,
      destination: widget.args.to,
      userLocation: widget.args.userLocation,
      onModeChanged: (mode) async {
        setState(() => _mode = mode);
        await ref.read(riderPrefsStoreProvider).setWayfindingMode(mode);
      },
      onArrived: () {
        if (!_arrived && mounted) setState(() => _arrived = true);
      },
    );
  }

  String _formatWalk(int meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '$meters m';
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
      'boarding.colocation_radius_m',
      cityId: cityId,
    )).toInt();
  } catch (_) {
    return null;
  }
}
