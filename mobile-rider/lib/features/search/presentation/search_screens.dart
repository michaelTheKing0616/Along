import 'package:along_design/along_design.dart';
import 'package:along_data/along_data.dart';
import 'package:along_map/along_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';
import 'package:mobile_rider/features/pricing/domain/hail_intent_provider.dart';
import 'package:mobile_rider/features/search/presentation/destination_search_panel.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';

/// R-06 Destination search (doc 06).
class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  ConsumerState<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends ConsumerState<DestinationSearchScreen> {
  String? _voiceQuery;
  String? _voiceOrigin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hail = ref.watch(hailIntentProvider);

    final palette = AlongPalette.of(context);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AlongSpace.s16,
            AlongSpace.s8,
            AlongSpace.s16,
            AlongSpace.s8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AlongMapButton(
                    key: const Key('search_back'),
                    icon: AlongIcons.back,
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: AlongSpace.s12),
                  Expanded(
                    child: Text(
                      hail != null ? l10n.hailSearchTitle : l10n.searchTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AlongType.heading(palette),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AlongSpace.s16),
              Expanded(
                child: DestinationSearchPanel(
                  initialQuery: _voiceQuery,
                  onDestinationSelected: (pick) {
                    _startTripPlan(ref, pick);
                    if (context.mounted) {
                      _afterDestinationSelected(context, ref);
                    }
                  },
                ),
              ),
              const SizedBox(height: AlongSpace.s8),
              TextField(
                key: const Key('voice_booking_field'),
                decoration: InputDecoration(hintText: l10n.voiceBookingHint),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  final phrase = parseBookingPhrase(value);
                  setState(() {
                    _voiceQuery = phrase?.destination;
                    _voiceOrigin = phrase?.origin;
                  });
                },
              ),
              if (_voiceOrigin != null)
                Padding(
                  padding: const EdgeInsets.only(top: AlongSpace.s8),
                  child: Text(
                    _voiceOrigin!,
                    key: const Key('voice_booking_origin'),
                    style: AlongType.caption(palette),
                  ),
                ),
              const SizedBox(height: AlongSpace.s8),
              AlongButton(
                key: const Key('search_choose_on_map'),
                label: l10n.homeChooseOnMap,
                variant: AlongButtonVariant.secondary,
                onPressed: () => context.push(AppRoutes.adjustPickup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// R-06b Adjust pickup / choose on map (doc 06).
class AdjustPickupScreen extends ConsumerWidget {
  const AdjustPickupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adjustPickupControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adjustPickupTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AlongMap(
                    styleUrl: AlongStyleLoader.resolveBasemapStyleUrl(),
                    allowDemoStyleFallback: false,
                    initialCameraPosition: state.center == null
                        ? null
                        : MapCamera.forCenter(
                            lat: state.center!.lat,
                            lng: state.center!.lng,
                            zoom: 16,
                          ),
                  ),
                ),
                const Icon(Icons.place, size: 48, color: AlongColors.ink900),
                if (state.isLoading)
                  const Positioned(
                    top: AlongSpace.s16,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          if (state.snappedStage != null)
            Padding(
              padding: const EdgeInsets.all(AlongSpace.s16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.adjustPickupBoardingAt(state.snappedStage!.name),
                  style: AlongText.bodyStrong,
                ),
              ),
            ),
          Expanded(
            flex: 0,
            child: SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: state.nearbyPlaces.length,
                itemBuilder: (context, index) {
                  final place = state.nearbyPlaces[index];
                  return ListTile(
                    title: Text(place.name),
                    subtitle: Text(
                      l10n.searchResultSubtitle(
                        place.area,
                        place.distanceM.round(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AlongSpace.s16),
            child: AlongButton(
              key: const Key('adjust_pickup_confirm'),
              label: l10n.adjustPickupConfirm,
              onPressed: () {
                final home = ref.read(homeControllerProvider);
                final origin = home.userLocation ?? home.mapCenter;
                if (origin == null || state.center == null) return;
                ref
                    .read(tripPlanSessionProvider.notifier)
                    .setSession(
                      TripPlanSession(
                        origin: origin,
                        destination: state.center!,
                        destinationLabel: l10n.adjustPickupConfirm,
                      ),
                    );
                context.push(AppRoutes.tripOptions);
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _startTripPlan(WidgetRef ref, DestinationPick pick) {
  final home = ref.read(homeControllerProvider);
  final hail = ref.read(hailIntentProvider);
  final origin = home.userLocation ?? home.mapCenter;
  if (origin == null) return;
  ref
      .read(tripPlanSessionProvider.notifier)
      .setSession(
        TripPlanSession(
          origin: origin,
          destination: pick.location,
          destinationLabel: pick.name,
          hailIntent: hail,
          placementContext: pick.toPlacementContext(),
        ),
      );
}

void _afterDestinationSelected(BuildContext context, WidgetRef ref) {
  ref.read(hailIntentProvider.notifier).state = null;
  context.push(AppRoutes.tripOptions);
}
