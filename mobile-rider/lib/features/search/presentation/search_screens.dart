import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:along_map/along_map.dart' show AbujaMapConstants;
import 'package:mobile_rider/routing/routes.dart';
import 'package:mobile_rider/features/pricing/domain/hail_intent_provider.dart';
import 'package:mobile_rider/features/search/presentation/destination_search_panel.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';

/// R-06 Destination search (doc 06).
class DestinationSearchScreen extends ConsumerWidget {
  const DestinationSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hail = ref.watch(hailIntentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(hail != null ? l10n.hailSearchTitle : l10n.searchTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AlongSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DestinationSearchPanel(
                onDestinationSelected: (pick) {
                  _startTripPlan(ref, pick);
                  if (context.mounted) {
                    _afterDestinationSelected(context, ref);
                  }
                },
              ),
            ),
            TextButton(
              key: const Key('search_choose_on_map'),
              onPressed: () => context.push(AppRoutes.adjustPickup),
              child: Text(l10n.homeChooseOnMap),
            ),
          ],
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
                Container(color: AlongColors.surface100),
                Icon(Icons.place, size: 48, color: AlongColors.ink900),
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
                final origin = home.userLocation ??
                    GeoPoint(
                      lat: AbujaMapConstants.centerLat,
                      lng: AbujaMapConstants.centerLng,
                    );
                ref.read(tripPlanSessionProvider.notifier).setSession(
                      TripPlanSession(
                        origin: origin,
                        destination: state.center,
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
  final origin = home.userLocation ??
      GeoPoint(
        lat: AbujaMapConstants.centerLat,
        lng: AbujaMapConstants.centerLng,
      );
  ref.read(tripPlanSessionProvider.notifier).setSession(
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
