import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/trip/domain/driver_trip_config.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Route args for driver SOS active (D-16 → honest safety line copy).
class SosActiveRouteArgs {
  const SosActiveRouteArgs({
    required this.trip,
    this.initialLocation,
  });

  final TripSummary trip;
  final Point? initialLocation;
}

/// Driver SOS active — honest copy, emergency call, hold-to-cancel, no back dismiss.
class SosActiveScreen extends ConsumerStatefulWidget {
  const SosActiveScreen({super.key, required this.args});

  final SosActiveRouteArgs args;

  @override
  ConsumerState<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends ConsumerState<SosActiveScreen> {
  String? _sosId;
  String? _emergencyNumber;
  bool _raising = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _raiseSos();
  }

  Point _locationPayload() {
    final live = widget.args.trip.live;
    final driver = live?.driver;
    if (driver != null) {
      return Point(lat: driver.lat, lng: driver.lng);
    }
    final rider = live?.rider;
    if (rider != null) {
      return Point(lat: rider.lat, lng: rider.lng);
    }
    final initial = widget.args.initialLocation;
    if (initial != null) return initial;
    return const Point(lat: 9.0579, lng: 7.4951);
  }

  Future<void> _raiseSos() async {
    setState(() {
      _raising = true;
      _error = null;
    });
    try {
      final response = await ref.read(safetyRepositoryProvider).raiseSos(
            tripId: widget.args.trip.tripId,
            journeyId: widget.args.trip.journeyId,
            location: _locationPayload(),
          );
      if (!mounted) return;
      setState(() {
        _sosId = response.sos_id;
        _emergencyNumber = response.emergency_number;
        _raising = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _raising = false;
      });
    }
  }

  Future<void> _callEmergency() async {
    final number = _emergencyNumber ?? '112';
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _cancelSos() async {
    final sosId = _sosId;
    if (sosId == null) return;
    await ref.read(safetyRepositoryProvider).cancelSos(sosId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final holdDuration = ref.watch(driverTripConfigProvider).maybeWhen(
          data: (cfg) => cfg.sosHoldDurationMs,
          orElse: () => const Duration(milliseconds: 600),
        );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AlongColors.semanticDangerTint,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AlongSpace.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AlongSpace.s32),
                if (_raising) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: AlongSpace.s16),
                  Text(
                    l10n.sosRaising,
                    style: AlongText.heading2,
                    textAlign: TextAlign.center,
                  ),
                ] else if (_error != null) ...[
                  Text(
                    l10n.sosRaiseFailed,
                    style: AlongText.heading2.copyWith(
                      color: AlongColors.semanticDanger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AlongSpace.s12),
                  AlongButton(
                    key: const Key('sos_retry'),
                    label: l10n.sosRetry,
                    variant: AlongButtonVariant.secondary,
                    onPressed: _raiseSos,
                  ),
                ] else ...[
                  Text(
                    l10n.sosTeamAlerted,
                    key: const Key('sos_team_alerted'),
                    style: AlongText.heading1.copyWith(
                      color: AlongColors.semanticDanger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AlongSpace.s12),
                  Text(
                    l10n.sosSharingDetails,
                    style: AlongText.body,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  AlongButton(
                    key: const Key('sos_call_emergency'),
                    label: l10n.sosCallEmergency(_emergencyNumber ?? '112'),
                    variant: AlongButtonVariant.danger,
                    onPressed: _callEmergency,
                  ),
                  const SizedBox(height: AlongSpace.s24),
                  Center(
                    child: Column(
                      children: [
                        HoldButton(
                          key: const Key('sos_hold_cancel'),
                          type: HoldButtonType.sos,
                          holdDuration: holdDuration,
                          label: l10n.sosHoldToCancel,
                          onFired: _cancelSos,
                        ),
                        const SizedBox(height: AlongSpace.s8),
                        Text(
                          l10n.sosHoldToCancel,
                          style: AlongText.label,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
