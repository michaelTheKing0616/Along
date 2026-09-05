import 'package:along_design/along_design.dart';
import 'package:along_map/along_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/features/home/presentation/widgets/park_picker_sheet.dart';
import 'package:mobile_driver/features/incoming_request/presentation/decline_reason_sheet.dart';
import 'package:mobile_driver/features/incoming_request/presentation/incoming_request_notifier.dart';
import 'package:mobile_driver/features/incoming_request/presentation/incoming_request_sheet.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// D-08 Home — presence control + demand awareness (doc 06).
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  MapLayerController? _layerController;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverHomeControllerProvider);
    final incoming = ref.watch(incomingRequestNotifierProvider);
    final config = ref.watch(appConfigProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    ref.listen(incomingRequestNotifierProvider, (previous, next) {
      if (next?.showDeclineReasons == true &&
          previous?.showDeclineReasons != true) {
        _openDeclineReasons(l10n);
      }
    });

    ref.listen(driverHomeControllerProvider, (previous, next) {
      if (next.status == DriverStatus.atPark &&
          next.selectedPark == null &&
          previous?.status != DriverStatus.atPark) {
        _openParkPicker();
      }
      _syncMapLayers(next);
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AlongMap(
              key: const Key('driver_home_map'),
              styleUrl: config.tilesBaseUrl == null
                  ? null
                  : '${config.tilesBaseUrl}/styles/along-light.json',
              offlineStyleJson: config.tilesBaseUrl == null
                  ? ref.watch(driverHomeOfflineStyleProvider).maybeWhen(
                        data: (value) => value,
                        orElse: () => null,
                      )
                  : null,
              initialCameraPosition: MapCamera.abujaDefault(),
              myLocationEnabled: state.locationGranted,
              onLayerControllerReady: (controller) {
                _layerController = controller;
                _syncMapLayers(state);
              },
            ),
          ),
          if (incoming != null)
            Positioned.fill(
              child: ColoredBox(
                color: AlongColors.ink900.withValues(alpha: 0.55),
              ),
            ),
          if (incoming != null)
            Positioned.fill(
              child: IncomingRequestSheet(
                key: const Key('incoming_request_sheet'),
                state: incoming,
                l10n: l10n,
                onAccept: () => ref
                    .read(incomingRequestNotifierProvider.notifier)
                    .accept(),
                onDecline: () => ref
                    .read(incomingRequestNotifierProvider.notifier)
                    .openDeclineReasons(),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AlongSpace.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CompactBalanceStrip(
                      onTap: () {},
                    ),
                    if (state.ledgerBlocked) ...[
                      const SizedBox(height: AlongSpace.s8),
                      _LedgerBlockedBanner(l10n: l10n),
                    ],
                    if (!state.isVerified) ...[
                      const SizedBox(height: AlongSpace.s8),
                      _InfoBanner(message: l10n.homeUnverifiedBanner),
                    ],
                    if (state.batteryGuardActive) ...[
                      const SizedBox(height: AlongSpace.s8),
                      _InfoBanner(message: l10n.homeBatteryGuardBanner),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (state.demandLabels.isNotEmpty)
            Positioned(
              left: AlongSpace.s16,
              right: AlongSpace.s16,
              top: 140,
              child: _DemandLabelsCard(labels: state.demandLabels),
            ),
          Positioned(
            left: AlongSpace.s16,
            right: AlongSpace.s16,
            bottom: AlongSpace.s16,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.status == DriverStatus.atPark)
                    _ParkChip(
                      label: state.selectedPark == null
                          ? l10n.homeSelectPark
                          : l10n.homeAtPark(state.selectedPark!.name),
                      onTap: _openParkPicker,
                    ),
                  if (state.isRoaming) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _SeatsChip(
                            seats: state.seatsAvailable,
                            onDecrement: state.toggleEnabled
                                ? () => ref
                                    .read(driverHomeControllerProvider.notifier)
                                    .adjustSeats(-1)
                                : null,
                            onIncrement: state.toggleEnabled
                                ? () => ref
                                    .read(driverHomeControllerProvider.notifier)
                                    .adjustSeats(1)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AlongSpace.s8),
                        Expanded(
                          child: _DirectionChip(
                            direction: state.roamingDirection,
                            onRouteLabel: l10n.homeDirectionOnRoute,
                            noneLabel: l10n.homeDirectionNone,
                            onTap: state.toggleEnabled ? _toggleDirection : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AlongSpace.s8),
                  ],
                  AbsorbPointer(
                    absorbing: !state.toggleEnabled,
                    child: Opacity(
                      opacity: state.toggleEnabled ? 1 : 0.5,
                      child: StatusToggle(
                        key: const Key('driver_status_toggle'),
                        selected: state.status,
                        onChanged: (next) => ref
                            .read(driverHomeControllerProvider.notifier)
                            .setStatus(next),
                      ),
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AlongSpace.s8),
                    Text(
                      _errorText(l10n, state.errorMessage!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AlongColors.semanticDanger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _errorText(AppLocalizations l10n, String key) => switch (key) {
        'select_park' => l10n.homeErrorSelectPark,
        'location_required' => l10n.homeErrorLocation,
        'ledger_blocked' => l10n.homeLedgerBlockedBanner,
        _ => l10n.errorGeneric,
      };

  Future<void> _openParkPicker() async {
    await ref.read(parkPickerControllerProvider.notifier).loadNearby();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AlongColors.surface0,
      builder: (context) => ParkPickerSheet(l10n: l10n),
    );
  }

  Future<void> _toggleDirection() async {
    final current = ref.read(driverHomeControllerProvider).roamingDirection;
    final next = current == RoamingDirection.onRoute
        ? RoamingDirection.none
        : RoamingDirection.onRoute;
    await ref.read(driverHomeControllerProvider.notifier).setRoamingDirection(next);
  }

  Future<void> _openDeclineReasons(AppLocalizations l10n) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DeclineReasonSheet(
        l10n: l10n,
        onReasonSelected: (reason) {
          Navigator.of(context).pop();
          ref
              .read(incomingRequestNotifierProvider.notifier)
              .decline(reason: reason);
        },
      ),
    );
    ref.read(incomingRequestNotifierProvider.notifier).closeDeclineReasons();
  }

  void _syncMapLayers(DriverHomeState state) {
    final controller = _layerController;
    if (controller == null) return;

    if (state.userLocation != null && state.locationGranted) {
      controller.setPuck(state.userLocation!);
    }
    controller.setAmbientCells(state.demandCells);
    controller.clearVehicle();
  }
}

final driverHomeOfflineStyleProvider = FutureProvider<String>((ref) async {
  final dir = await ref.watch(mapCacheDirectoryProvider.future);
  final config = await AlongMap.bootstrapOffline(cacheDirectory: dir);
  return config.styleJson;
});

class _CompactBalanceStrip extends StatelessWidget {
  const _CompactBalanceStrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AlongColors.surface0,
      borderRadius: BorderRadius.circular(AlongRadius.md.x),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AlongRadius.md.x),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AlongSpace.s16,
            vertical: AlongSpace.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ledger balance',
                      style: AlongText.caption.copyWith(
                        color: AlongColors.ink500,
                      ),
                    ),
                    Text(
                      formatMoney(0),
                      style: AlongText.numericL.copyWith(
                        color: AlongColors.ink900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AlongSpace.s8,
                  vertical: AlongSpace.s4,
                ),
                decoration: BoxDecoration(
                  color: AlongColors.semanticSuccessFill,
                  borderRadius: BorderRadius.circular(AlongRadius.sm.x),
                ),
                child: Text(
                  'Good standing',
                  style: AlongText.caption.copyWith(
                    color: AlongColors.semanticSuccess,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerBlockedBanner extends StatelessWidget {
  const _LedgerBlockedBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AlongSpace.s12),
      decoration: BoxDecoration(
        color: AlongColors.semanticDangerFill,
        borderRadius: BorderRadius.circular(AlongRadius.sm.x),
      ),
      child: Text(
        l10n.homeLedgerBlockedBanner,
        style: AlongText.body.copyWith(color: AlongColors.semanticDanger),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AlongSpace.s12),
      color: AlongColors.surfaceInverse,
      child: Text(
        message,
        style: AlongText.body.copyWith(color: AlongColors.surface0),
      ),
    );
  }
}

class _DemandLabelsCard extends StatelessWidget {
  const _DemandLabelsCard({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AlongColors.surface0.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AlongRadius.sm.x),
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final label in labels.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: AlongSpace.s4),
                child: Text(label, style: AlongText.body),
              ),
          ],
        ),
      ),
    );
  }
}

class _ParkChip extends StatelessWidget {
  const _ParkChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AlongSpace.s8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          label: Text(label),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _SeatsChip extends StatelessWidget {
  const _SeatsChip({
    required this.seats,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int seats;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Seats',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove),
          ),
          Text('$seats', style: AlongText.label),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  const _DirectionChip({
    required this.direction,
    required this.onRouteLabel,
    required this.noneLabel,
    required this.onTap,
  });

  final RoamingDirection direction;
  final String onRouteLabel;
  final String noneLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        direction == RoamingDirection.onRoute ? onRouteLabel : noneLabel;
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
