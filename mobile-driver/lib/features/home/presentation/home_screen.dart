import 'package:along_core/along_core.dart' show Money, formatMoney;
import 'package:along_data/along_data.dart' show TripCashSummary;
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:along_map/along_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/features/home/presentation/widgets/driver_home_chrome.dart';
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
    final today = ref
        .watch(earningsCashTripsProvider)
        .whenOrNull(data: (trips) => _today(trips));

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
                      DriverHomeNotice(message: l10n.homeUnverifiedBanner),
                    ],
                    if (state.batteryGuardActive) ...[
                      const SizedBox(height: AlongSpace.s8),
                      DriverHomeNotice(message: l10n.homeBatteryGuardBanner),
                    ],
                    _ManifestEntryChip(l10n: l10n),
                  ],
                ),
              ),
            ),
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
            left: 0,
            right: 0,
            bottom: 0,
            child: DriverHomePanel(
              state: state,
              todayEarned: today?.$1,
              todayTrips: today?.$2,
              errorText: state.errorMessage == null
                  ? null
                  : _errorText(l10n, state.errorMessage!),
              onGo: () => ref
                  .read(driverHomeControllerProvider.notifier)
                  .setStatus(DriverStatus.roamingAvailable),
              onGoOffline: () => ref
                  .read(driverHomeControllerProvider.notifier)
                  .setStatus(DriverStatus.offline),
              onMode: (next) => ref
                  .read(driverHomeControllerProvider.notifier)
                  .setStatus(next),
              onPark: _openParkPicker,
              onSeats: () => context.push(AppRoutes.seatBoard),
              onDirection: state.toggleEnabled ? _toggleDirection : null,
              onBuildDay: () => context.push(AppRoutes.buildMyDay),
              onConductor: () => context.push(AppRoutes.conductor),
              onRest: () => context.push(AppRoutes.rest),
              onMarketplace: () => context.push(AppRoutes.marketplace),
            ),
          ),
        ],
      ),
    );
  }

  /// Today's cash takings and trip count, money formatted the Along way.
  (String, int) _today(List<TripCashSummary> trips) {
    final now = DateTime.now();
    final todays = [
      for (final t in trips)
        if (DateUtils.isSameDay(t.completedAt.toLocal(), now)) t,
    ];
    final total = todays.fold<Money>(Money.zero(), (sum, t) => sum + t.fare);
    return (formatMoney(total), todays.length);
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

class _ManifestEntryChip extends ConsumerWidget {
  const _ManifestEntryChip({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifest = ref.watch(manifestControllerProvider);
    if (manifest.entries.isEmpty) return const SizedBox.shrink();
    final p = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AlongSpace.s8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: p.surface,
          shape: AlongCraft.border(16),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          child: InkWell(
            key: const Key('home_manifest_chip'),
            onTap: () => context.push(AppRoutes.manifest),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AlongIcon(AlongIcons.path, size: 18, color: p.ink),
                  const SizedBox(width: AlongSpace.s8),
                  Text(
                    l10n.manifestOpen(manifest.entries.length),
                    style: AlongType.label(p),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
