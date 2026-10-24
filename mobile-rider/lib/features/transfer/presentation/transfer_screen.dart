import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/transfer/active_journey_monitor.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_screen.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_panel.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-14 Transfer / next leg — walk hero, wayfinding, request next leg (1 tap).
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key, required this.args});

  final TransferRouteArgs args;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  WayfindingMode _mode = WayfindingMode.text;
  var _arrived = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPrefs);
  }

  Future<void> _loadPrefs() async {
    final mode = await ref.read(riderPrefsStoreProvider).wayfindingMode();
    if (mounted) setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(transferControllerProvider(widget.args));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transferTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.context == null
              ? Center(child: Text(state.errorMessage ?? l10n.errorGeneric))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AlongSpace.s16),
                      child: Text(
                        state.context!.walkHeroLabel,
                        style: AlongText.heading1,
                      ),
                    ),
                    if (_arrived)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AlongSpace.s16,
                        ),
                        child: Text(
                          l10n.wayfindingArrived,
                          style: AlongText.bodyStrong.copyWith(
                            color: AlongColors.semanticSuccessFill,
                          ),
                        ),
                      ),
                    if (state.context!.walkDirections != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AlongSpace.s16,
                          ),
                          child: WayfindingPanel(
                            directions: state.context!.walkDirections!,
                            mode: _mode,
                            tts: ref.read(wayfindingTtsProvider),
                            arrivedRadiusM: state.arrivedRadiusM,
                            destination: state.context!.nextLeg.boardLocation,
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
                      )
                    else
                      Expanded(
                        child: Center(
                          child: Text(
                            l10n.transferWalkLoading,
                            style: AlongText.body.copyWith(
                              color: AlongColors.ink500,
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(AlongSpace.s16),
                      child: _NextLegCard(
                        leg: state.context!.nextLeg,
                        l10n: l10n,
                        onRequest: () => _requestNextLeg(state),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AlongSpace.s16,
                        0,
                        AlongSpace.s16,
                        AlongSpace.s24,
                      ),
                      child: AlongButton(
                        key: const Key('transfer_change_plan'),
                        label: l10n.transferChangePlan,
                        variant: AlongButtonVariant.tertiary,
                        onPressed: () => context.go(AppRoutes.tripOptions),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _requestNextLeg(TransferState state) async {
    try {
      final trip = await ref
          .read(transferControllerProvider(widget.args).notifier)
          .requestNextLeg();
      if (trip != null && mounted) {
        ref.read(activeJourneyMonitorProvider.notifier).trackFromTrip(
              trip,
              candidateId: widget.args.candidateId,
            );
        context.push(
          AppRoutes.requesting,
          extra: RequestingRouteArgs(trip: trip, roamingSource: false),
        );
      }
    } catch (_) {
      if (mounted) {
        showAlongToast(
          context,
          message: AppLocalizations.of(context).errorGeneric,
          variant: AlongToastVariant.info,
        );
      }
    }
  }
}

class _NextLegCard extends StatelessWidget {
  const _NextLegCard({
    required this.leg,
    required this.l10n,
    required this.onRequest,
  });

  final JourneyPlanLeg leg;
  final AppLocalizations l10n;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final supply = leg.supplyBucket;
    return Container(
      padding: const EdgeInsets.all(AlongSpace.s16),
      clipBehavior: Clip.antiAlias,
      decoration: AlongCraft.fill(
        AlongColors.surface0,
        corner: AlongRadius.card.x,
        side: const BorderSide(color: AlongColors.ink100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.transferNextLegTitle, style: AlongText.title),
          const SizedBox(height: AlongSpace.s8),
          Text(
            '${leg.boardName} → ${leg.alightName}',
            style: AlongText.body,
          ),
          if (supply != null) ...[
            const SizedBox(height: AlongSpace.s4),
            Text(
              l10n.transferSupply(supply),
              style: AlongText.caption.copyWith(color: AlongColors.ink500),
            ),
          ],
          const SizedBox(height: AlongSpace.s12),
          AlongButton(
            key: const Key('transfer_request_next_leg'),
            label: l10n.transferRequestNextLeg,
            variant: AlongButtonVariant.yellow,
            onPressed: onRequest,
          ),
        ],
      ),
    );
  }
}

class TransferRouteArgs {
  const TransferRouteArgs({
    required this.journeyId,
    required this.afterTripSequence,
    required this.candidateId,
  });

  final String journeyId;
  final int afterTripSequence;
  final String candidateId;

  @override
  bool operator ==(Object other) =>
      other is TransferRouteArgs &&
      other.journeyId == journeyId &&
      other.afterTripSequence == afterTripSequence &&
      other.candidateId == candidateId;

  @override
  int get hashCode => Object.hash(journeyId, afterTripSequence, candidateId);
}

class TransferState {
  const TransferState({
    this.context,
    this.isLoading = false,
    this.errorMessage,
    this.arrivedRadiusM,
  });

  final TransferContext? context;
  final bool isLoading;
  final String? errorMessage;
  final int? arrivedRadiusM;

  TransferState copyWith({
    TransferContext? context,
    bool? isLoading,
    String? errorMessage,
    int? arrivedRadiusM,
  }) {
    return TransferState(
      context: context ?? this.context,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      arrivedRadiusM: arrivedRadiusM ?? this.arrivedRadiusM,
    );
  }
}

final transferControllerProvider = NotifierProvider.family<
    TransferController, TransferState, TransferRouteArgs>(
  TransferController.new,
);

class TransferController extends FamilyNotifier<TransferState, TransferRouteArgs> {
  @override
  TransferState build(TransferRouteArgs args) {
    Future.microtask(_load);
    return const TransferState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final configRepo = ref.read(configRepositoryProvider);
      final journeyRepo = ref.read(journeyRepositoryProvider);
      final ctx = await journeyRepo.transferContext(
        journeyId: arg.journeyId,
        afterTripSequence: arg.afterTripSequence,
      );
      final radiusRaw = await _readArrivedRadius(configRepo, ctx?.cityId);
      state = state.copyWith(
        context: ctx,
        isLoading: false,
        arrivedRadiusM: radiusRaw,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<TripSummary?> requestNextLeg() async {
    final ctx = state.context;
    if (ctx == null) return null;

    final trips = ref.read(tripsRepositoryProvider);
    return trips.requestTrip(
      RequestTripRequest(
        p_candidate_id: arg.candidateId,
        p_leg_index: ctx.nextLeg.legIndex,
        p_women_only: false,
        p_client_ref:
            '${arg.candidateId}-leg${ctx.nextLeg.legIndex}-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
  }
}

Future<int?> _readArrivedRadius(ConfigRepository configRepo, String? cityId) async {
  try {
    return (await configRepo.configNum(
      'boarding.colocation_radius_m',
      cityId: cityId,
    ))
        .toInt();
  } catch (_) {
    return null;
  }
}
