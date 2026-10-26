import 'package:along_design/along_design.dart';
import 'package:along_data/along_data.dart';
import 'package:along_map/along_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:along_core/along_core.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/l10n/l10n_format.dart';
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
                  extra: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Say or type the whole trip: "from Wuse to Garki".
                      DecoratedBox(
                        decoration: AlongCraft.surface(
                          palette,
                          radius: AlongRadius.card.x,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: AlongSpace.s12),
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: AlongCraft.compactFill(
                                palette.recessed,
                                40,
                              ),
                              child: AlongIcon(
                                AlongIcons.microphone,
                                size: 20,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(width: AlongSpace.s12),
                            Expanded(
                              child: TextField(
                                key: const Key('voice_booking_field'),
                                style: AlongType.body(palette),
                                decoration: InputDecoration(
                                  hintText: l10n.voiceBookingHint,
                                  hintMaxLines: 2,
                                  hintStyle: AlongType.body(palette)
                                      .copyWith(color: palette.muted),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: AlongSpace.s16,
                                  ),
                                ),
                                textInputAction: TextInputAction.search,
                                onSubmitted: (value) {
                                  final phrase = parseBookingPhrase(value);
                                  setState(() {
                                    _voiceQuery = phrase?.destination;
                                    _voiceOrigin = phrase?.origin;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
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
                    ],
                  ),
                  hint: l10n.searchEmpty,
                  initialQuery: _voiceQuery,
                  onChooseOnMap: () => context.push(AppRoutes.adjustPickup),
                  onDestinationSelected: (pick) {
                    _startTripPlan(ref, pick);
                    if (context.mounted) {
                      _afterDestinationSelected(context, ref);
                    }
                  },
                ),
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
    final palette = AlongPalette.of(context);
    final controller = ref.read(adjustPickupControllerProvider.notifier);
    final stage = state.snappedStage;
    final nearest = state.nearbyPlaces.firstOrNull;
    final pinLabel = stage?.name ?? nearest?.name ?? l10n.adjustPickupPinLabel;

    return TripSheetScaffold(
      mapFraction: 0.44,
      leading: AlongMapButton(
        key: const Key('adjust_pickup_back'),
        icon: AlongIcons.back,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => context.pop(),
      ),
      map: (top, bottom) => Stack(
        children: [
          Positioned.fill(
            child: AlongMap(
              styleUrl: AlongStyleLoader.resolveBasemapStyleUrl(),
              allowDemoStyleFallback: false,
              placeholder: AlongRoutePreview(
                route: false,
                topInset: top,
                bottomInset: bottom,
              ),
              initialCameraPosition: state.center == null
                  ? null
                  : MapCamera.forCenter(
                      lat: state.center!.lat,
                      lng: state.center!.lng,
                      zoom: 16,
                    ),
              onMapClick: (_, at) {
                AlongHaptics.tick(context);
                controller.refresh(
                  GeoPoint(lat: at.latitude, lng: at.longitude),
                );
              },
            ),
          ),
          Positioned.fill(
            top: top,
            bottom: bottom,
            child: IgnorePointer(
              child: Center(child: _CentrePin(label: pinLabel)),
            ),
          ),
        ],
      ),
      footer: AlongButton(
        key: const Key('adjust_pickup_confirm'),
        label: l10n.adjustPickupConfirm,
        onPressed: state.center == null
            ? null
            : () {
                final home = ref.read(homeControllerProvider);
                final origin = home.userLocation ?? home.mapCenter;
                if (origin == null) return;
                ref
                    .read(tripPlanSessionProvider.notifier)
                    .setSession(
                      TripPlanSession(
                        origin: origin,
                        destination: state.center!,
                        destinationLabel: pinLabel,
                      ),
                    );
                context.push(AppRoutes.tripOptions);
              },
      ),
      children: [
        Text(l10n.adjustPickupTitle, style: AlongType.title(palette)),
        const SizedBox(height: 2),
        Text(l10n.adjustPickupHint, style: AlongType.caption(palette)),
        const SizedBox(height: AlongSpace.s12),
        AnimatedSwitcher(
          duration: AlongMoves.arrive.of(context),
          child: stage != null
              ? TripNotice(
                  key: ValueKey(stage.stageId),
                  icon: AlongIcons.signpost,
                  text: l10n.adjustPickupBoardingAt(stage.name),
                )
              : state.isLoading
              ? const AlongSkeleton(
                  key: ValueKey('loading'),
                  variant: SkeletonVariant.line,
                )
              : const SizedBox.shrink(),
        ),
        if (state.nearbyPlaces.isNotEmpty) ...[
          const SizedBox(height: AlongSpace.s16),
          Text(l10n.adjustPickupNearby, style: AlongType.label(palette)),
          const SizedBox(height: AlongSpace.s4),
          for (final place in state.nearbyPlaces)
            AlongPlaceRow(
              key: Key('adjust_pickup_place_${place.name}'),
              stacked: true,
              place: AlongPlace(
                icon: place.kind == 'park'
                    ? AlongIcons.storefront
                    : AlongIcons.signpost,
                title: place.name,
                detail: l10n.searchResultDetail(
                  place.area,
                  l10n.distance(place.distanceM),
                ),
                onTap: () {
                  AlongHaptics.tick(context);
                  controller.refresh(place.location);
                },
              ),
            ),
        ],
      ],
    );
  }
}

/// The pin at the map centre: an ink squircle with a short stem, and the
/// name it will snap to above it.
class _CentrePin extends StatelessWidget {
  const _CentrePin({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final dark = p.brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: AlongCraft.compactFill(
            p.surface,
            30,
            corner: 10,
            side: BorderSide(color: p.line),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AlongType.label(p),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: AlongCraft.compactFill(
            dark ? p.accent : p.ink,
            36,
            corner: 12,
            side: BorderSide(color: dark ? p.bg : p.surface, width: 2),
          ),
          child: AlongIcon(
            AlongIcons.mapPin,
            size: 18,
            color: dark ? p.bg : p.onInk,
          ),
        ),
        Container(width: 2, height: 10, color: dark ? p.accent : p.ink),
        // Keeps the stem tip, not the column centre, on the map centre.
        const SizedBox(height: 82),
      ],
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
