import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:along_map/along_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/home/domain/ambient_cell_mapper.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/home/presentation/widgets/home_bottom_sheet.dart';
import 'package:mobile_rider/features/home/presentation/widgets/location_denied_banner.dart';
import 'package:mobile_rider/features/offline/low_data_providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/features/pricing/domain/hail_intent_provider.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_helpers.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-05 Home — ambient clusters, the Where-to sheet, recents, nearby rides
/// (doc 06). One tap from any row to search or a quote.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  MapLayerController? _layerController;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final config = ref.watch(appConfigProvider);
    final lowData = ref
        .watch(lowDataModeProvider)
        .maybeWhen(data: (mode) => mode, orElse: () => LowDataMode.disabled());
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: lowData.enabled
                ? TextMapBoard(
                    key: const Key('home_text_map'),
                    title: l10n.textMapTitle,
                    emptyLabel: l10n.textMapEmpty,
                    rows: [
                      for (final row in state.nearbyRows)
                        TextMapEntry(
                          id: row.modeCode,
                          title: row.modeLabel,
                          detail: l10n.homeNearbyRow(
                            row.countBucket,
                            row.modeLabel,
                            row.headingLabel,
                            row.etaMinutes,
                          ),
                          heading: row.headingLabel,
                        ),
                    ],
                    onRowTap: (id) {
                      for (final row in state.nearbyRows) {
                        if (row.modeCode == id) {
                          _onNearbyRowTap(row);
                          return;
                        }
                      }
                    },
                  )
                : AlongMap(
                    key: const Key('home_map'),
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
          if (state.showLocationBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LocationDeniedBanner(
                onChooseOnMap: () => context.push(AppRoutes.adjustPickup),
              ),
            ),
          Positioned(
            top: state.showLocationBanner ? 72 : AlongSpace.s16,
            left: AlongSpace.s16,
            child: AlongMapButton(
              key: const Key('home_menu_button'),
              tooltip: l10n.homeMenu,
              onPressed: () => context.go(AppRoutes.account),
              icon: AlongIcons.menu,
            ),
          ),
          Positioned(
            top: state.showLocationBanner ? 72 : AlongSpace.s16,
            left: 72,
            child: AlongMapButton(
              key: const Key('home_vehicles_button'),
              tooltip: l10n.homeVehicles,
              onPressed: () => context.push(AppRoutes.vehicles),
              icon: AlongIcons.seat,
            ),
          ),
          Positioned(
            top: state.showLocationBanner ? 72 : AlongSpace.s16,
            right: AlongSpace.s16,
            child: AlongMapButton(
              key: const Key('home_recenter_button'),
              tooltip: l10n.homeRecenter,
              onPressed: state.userLocation == null
                  ? null
                  : () => _recenter(state.userLocation!),
              icon: AlongIcons.locate,
            ),
          ),
          Positioned.fill(
            top: null,
            child: AlongSpringSheet(
              shrinkWrap: true,
              child: HomePeekSheet(
                state: state,
                onSearchTap: () => context.push(AppRoutes.search),
                onRecentTap: (_) => context.push(AppRoutes.tripOptions),
                onNearbyTap: _onNearbyRowTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = ref.read(homeControllerProvider);
    _syncMapLayers(state);
  }

  void _syncMapLayers(HomeState state) {
    final controller = _layerController;
    if (controller == null) return;

    assert(
      HomeMapLayerPolicy.isVehicleLayerAllowed(state.activeLayers) == false,
    );

    if (state.userLocation != null &&
        state.activeLayers.contains(HomeMapOverlayLayer.puck)) {
      controller.setPuck(state.userLocation!);
    }

    if (state.activeLayers.contains(HomeMapOverlayLayer.ambientCells)) {
      controller.setAmbientCells(state.ambientCells);
    } else {
      controller.setAmbientCells(const []);
    }

    controller.clearVehicle();
  }

  Future<void> _recenter(GeoPoint location) async {
    _layerController?.setPuck(location);
    await ref.read(homeControllerProvider.notifier).refreshAmbientOnce();
  }

  void _onNearbyRowTap(NearbyAmbientRow row) {
    final token = row.candidateToken;
    if (token == null) {
      context.push(AppRoutes.search);
      return;
    }
    ref.read(hailIntentProvider.notifier).state = HailIntent(
      candidateToken: token,
      modeCode: row.modeCode,
      etaBandSeconds: row.etaBandSeconds ?? row.etaMinutes * 60,
    );
    context.push(AppRoutes.search);
  }
}
