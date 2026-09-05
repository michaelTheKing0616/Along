import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:along_map/along_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart' hide GeoPoint;
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/home/domain/ambient_cell_mapper.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/home/presentation/widgets/home_bottom_sheet.dart';
import 'package:mobile_rider/features/home/presentation/widgets/location_denied_banner.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-05 Home — ambient clusters, peek sheet, recents (doc 06).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  MapLayerController? _layerController;
  bool _expandedNearby = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final config = ref.watch(appConfigProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AlongMap(
              key: const Key('home_map'),
              styleUrl: config.tilesBaseUrl == null
                  ? null
                  : '${config.tilesBaseUrl}/styles/along-light.json',
              offlineStyleJson: config.tilesBaseUrl == null
                  ? ref.watch(homeOfflineStyleProvider).maybeWhen(
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
            child: IconButton.filled(
              key: const Key('home_menu_button'),
              onPressed: () => context.go(AppRoutes.account),
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
          Positioned(
            top: state.showLocationBanner ? 72 : AlongSpace.s16,
            right: AlongSpace.s16,
            child: IconButton.filled(
              key: const Key('home_recenter_button'),
              onPressed: state.userLocation == null
                  ? null
                  : () => _recenter(state.userLocation!),
              icon: const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 72,
            child: _expandedNearby && state.nearbyRows.isNotEmpty
                ? HomeNearbySheet(
                    rows: state.nearbyRows,
                    onRowTap: (_) => context.push(AppRoutes.tripOptions),
                  )
                : HomePeekSheet(
                    state: state,
                    onSearchTap: () => context.push(AppRoutes.search),
                    onRecentTap: (_) => context.push(AppRoutes.tripOptions),
                    onNearbyTap: (_) {},
                  ),
          ),
          if (state.nearbyRows.isNotEmpty)
            Positioned(
              right: AlongSpace.s16,
              bottom: 180,
              child: TextButton(
                key: const Key('home_expand_nearby'),
                onPressed: () => setState(() => _expandedNearby = !_expandedNearby),
                child: Text(
                  _expandedNearby ? l10n.homeCollapseNearby : l10n.homeExpandNearby,
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

    assert(HomeMapLayerPolicy.isVehicleLayerAllowed(state.activeLayers) == false);

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
    // Camera recentre is handled by myLocationEnabled when granted.
    _layerController?.setPuck(location);
  }
}

final homeOfflineStyleProvider = FutureProvider<String>((ref) async {
  final dir = await ref.watch(mapCacheDirectoryProvider.future);
  final config = await AlongMap.bootstrapOffline(cacheDirectory: dir);
  return config.styleJson;
});
