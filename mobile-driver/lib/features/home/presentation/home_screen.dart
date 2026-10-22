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
import 'package:mobile_driver/features/negotiation/presentation/driver_pricing_controller.dart';
import 'package:mobile_driver/features/negotiation/presentation/driver_pricing_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/ledger/presentation/ledger_controller.dart';
import 'package:mobile_driver/features/ledger/presentation/widgets/ledger_blocked_banner.dart';
import 'package:mobile_driver/features/payments/presentation/payment_received_notifier.dart';
import 'package:mobile_driver/features/payments/presentation/widgets/payment_toast.dart';
import 'package:mobile_driver/features/trip/presentation/manifest_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-08 Home — presence control + demand awareness (doc 06).
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  MapLayerController? _layerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _startPaymentListener(),
    );
  }

  Future<void> _startPaymentListener() async {
    final userId = ref.read(alongSupabaseProvider).currentUser?.id;
    if (userId == null) return;
    await ref.read(paymentToastProvider.notifier).start(userId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverHomeControllerProvider);
    final ledger = ref.watch(driverLedgerControllerProvider);
    final incoming = ref.watch(incomingRequestNotifierProvider);
    final paymentToast = ref.watch(paymentToastProvider);
    final pricing = ref.watch(driverPricingNotifierProvider);
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
              styleUrl: AlongStyleLoader.resolveBasemapStyleUrl(
                tilesBase: config.tilesBaseUrl,
                citySlug: state.citySlug,
              ),
              allowDemoStyleFallback: false,
              initialCameraPosition: state.mapCenter == null
                  ? null
                  : MapCamera.forCenter(
                      lat: state.mapCenter!.lat,
                      lng: state.mapCenter!.lng,
                    ),
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
                onAccept: () =>
                    ref.read(incomingRequestNotifierProvider.notifier).accept(),
                onDecline: () => ref
                    .read(incomingRequestNotifierProvider.notifier)
                    .openDeclineReasons(),
              ),
            ),
          if (incoming == null && pricing.isVisible)
            Positioned.fill(
              child: ColoredBox(
                color: AlongColors.ink900.withValues(alpha: 0.55),
              ),
            ),
          if (incoming == null && pricing.isVisible)
            Positioned.fill(child: const DriverPricingSheet()),
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
                    BalanceCard(
                      key: const Key('home_balance_strip'),
                      variant: BalanceCardVariant.compact,
                      state: ledger.cardState,
                      balanceNaira: ledger.balance.minorUnits ~/ 100,
                      thresholdNaira: ledger.blockThreshold.minorUnits ~/ 100,
                      standingLabel: ledger.standingLabel,
                      onTap: () => context.go(AppRoutes.earnings),
                    ),
                    if (state.ledgerBlocked || ledger.isLedgerBlocked) ...[
                      const SizedBox(height: AlongSpace.s8),
                      LedgerBlockedBanner(
                        balance: ledger.balance,
                        blockThreshold: ledger.blockThreshold,
                        l10n: l10n,
                        onSettle: () => context.push(AppRoutes.settle),
                      ),
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
          if (paymentToast.event != null)
            Positioned(
              left: AlongSpace.s16,
              right: AlongSpace.s16,
              top: 96,
              child: SafeArea(
                bottom: false,
                child: PaymentToast(
                  amount: paymentToast.event!.amount,
                  onDismiss: () =>
                      ref.read(paymentToastProvider.notifier).dismiss(),
                ),
              ),
            ),
          Positioned(
            left: AlongSpace.s16,
            top: 120,
            child: _ManifestEntryChip(l10n: l10n),
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
                            label: l10n.seatMapTitle,
                            onTap: () => context.push(AppRoutes.seatBoard),
                          ),
                        ),
                        const SizedBox(width: AlongSpace.s8),
                        Expanded(
                          child: _DirectionChip(
                            direction: state.roamingDirection,
                            onRouteLabel: l10n.homeDirectionOnRoute,
                            noneLabel: l10n.homeDirectionNone,
                            onTap: state.toggleEnabled
                                ? _toggleDirection
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AlongSpace.s8),
                  ],
                  Wrap(
                    spacing: AlongSpace.s8,
                    children: [
                      ActionChip(
                        key: const Key('build_my_day_button'),
                        label: Text(l10n.buildMyDayTitle),
                        onPressed: () => context.push(AppRoutes.buildMyDay),
                      ),
                      ActionChip(
                        key: const Key('conductor_entry_button'),
                        label: Text(l10n.conductorTitle),
                        onPressed: () => context.push(AppRoutes.conductor),
                      ),
                      ActionChip(
                        key: const Key('rest_entry_button'),
                        label: Text(l10n.restTitle),
                        onPressed: () => context.push(AppRoutes.rest),
                      ),
                    ],
                  ),
                  const SizedBox(height: AlongSpace.s8),
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
      backgroundColor: AlongPalette.of(context).bg,
      builder: (context) => ParkPickerSheet(l10n: l10n),
    );
  }

  Future<void> _toggleDirection() async {
    final current = ref.read(driverHomeControllerProvider).roamingDirection;
    final next = current == RoamingDirection.onRoute
        ? RoamingDirection.none
        : RoamingDirection.onRoute;
    await ref
        .read(driverHomeControllerProvider.notifier)
        .setRoamingDirection(next);
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

class _ManifestEntryChip extends ConsumerWidget {
  const _ManifestEntryChip({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifest = ref.watch(manifestControllerProvider);
    if (manifest.entries.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: ActionChip(
        key: const Key('home_manifest_chip'),
        label: Text(l10n.manifestOpen(manifest.entries.length)),
        onPressed: () => context.push(AppRoutes.manifest),
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
        child: ActionChip(label: Text(label), onPressed: onTap),
      ),
    );
  }
}

class _SeatsChip extends StatelessWidget {
  const _SeatsChip({
    required this.seats,
    required this.label,
    required this.onTap,
  });

  final int seats;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      key: const Key('driver_seat_map_chip'),
      label: Text('$label · $seats'),
      onPressed: onTap,
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
    final label = direction == RoamingDirection.onRoute
        ? onRouteLabel
        : noneLabel;
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}
