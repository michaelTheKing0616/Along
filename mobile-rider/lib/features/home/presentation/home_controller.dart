import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_location/along_location.dart';
import 'package:along_map/along_map.dart' as map_geo;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:along_map/along_map.dart';
import 'package:mobile_rider/features/home/domain/ambient_cell_mapper.dart';

class HomeState {
  const HomeState({
    this.locationGranted = false,
    this.locationDenied = false,
    this.userLocation,
    this.ambientCells = const [],
    this.activeLayers = const {HomeMapOverlayLayer.puck},
    this.nearbyRows = const [],
    this.recents = const [],
    this.isLoadingAmbient = false,
    this.staleAfterS,
    this.fanoutRadiusM,
    this.cityId,
  });

  final bool locationGranted;
  final bool locationDenied;
  final GeoPoint? userLocation;
  final List<map_geo.AmbientCell> ambientCells;
  final Set<HomeMapOverlayLayer> activeLayers;
  final List<NearbyAmbientRow> nearbyRows;
  final List<RecentPlace> recents;
  final bool isLoadingAmbient;
  final int? staleAfterS;
  final int? fanoutRadiusM;
  final String? cityId;

  bool get showLocationBanner => locationDenied;

  HomeState copyWith({
    bool? locationGranted,
    bool? locationDenied,
    GeoPoint? userLocation,
    List<map_geo.AmbientCell>? ambientCells,
    Set<HomeMapOverlayLayer>? activeLayers,
    List<NearbyAmbientRow>? nearbyRows,
    List<RecentPlace>? recents,
    bool? isLoadingAmbient,
    int? staleAfterS,
    int? fanoutRadiusM,
    String? cityId,
  }) {
    return HomeState(
      locationGranted: locationGranted ?? this.locationGranted,
      locationDenied: locationDenied ?? this.locationDenied,
      userLocation: userLocation ?? this.userLocation,
      ambientCells: ambientCells ?? this.ambientCells,
      activeLayers: activeLayers ?? this.activeLayers,
      nearbyRows: nearbyRows ?? this.nearbyRows,
      recents: recents ?? this.recents,
      isLoadingAmbient: isLoadingAmbient ?? this.isLoadingAmbient,
      staleAfterS: staleAfterS ?? this.staleAfterS,
      fanoutRadiusM: fanoutRadiusM ?? this.fanoutRadiusM,
      cityId: cityId ?? this.cityId,
    );
  }
}

class NearbyAmbientRow {
  const NearbyAmbientRow({
    required this.modeLabelKey,
    required this.countBucket,
    required this.headingLabel,
    required this.etaMinutes,
    required this.modeCode,
  });

  final String modeLabelKey;
  final String countBucket;
  final String headingLabel;
  final int etaMinutes;
  final String modeCode;
}

final homeControllerProvider =
    NotifierProvider<HomeController, HomeState>(HomeController.new);

class HomeController extends Notifier<HomeState> {
  StreamSubscription<LocationSample>? _locationSub;
  Timer? _ambientTimer;

  @override
  HomeState build() {
    ref.onDispose(() {
      _locationSub?.cancel();
      _ambientTimer?.cancel();
    });
    Future.microtask(_bootstrap);
    return const HomeState();
  }

  Future<void> _bootstrap() async {
    final recents = await ref.read(recentPlacesStoreProvider).load();
    state = state.copyWith(recents: recents);
    await _loadConfig();
    await _initLocation();
  }

  Future<void> _loadConfig() async {
    final config = ref.read(configRepositoryProvider);
    final staleAfterS =
        (await config.configNum('presence.stale_after_s')).round();
    final fanoutRadiusM =
        (await config.configNum('presence.fanout_radius_m')).round();
    state = state.copyWith(
      staleAfterS: staleAfterS,
      fanoutRadiusM: fanoutRadiusM,
    );
  }

  Future<void> _initLocation() async {
    final source = ref.read(locationStreamSourceProvider);
    final granted = await source.ensurePermission();
    if (!granted) {
      state = state.copyWith(
        locationDenied: true,
        locationGranted: false,
        activeLayers: const {},
      );
      return;
    }

    state = state.copyWith(
      locationGranted: true,
      locationDenied: false,
      activeLayers: {HomeMapOverlayLayer.puck},
    );

    _locationSub?.cancel();
    _locationSub = FilteredLocationStream(source).track().listen((sample) {
      state = state.copyWith(
        userLocation: sample.point,
        activeLayers: {
          HomeMapOverlayLayer.puck,
          ...state.activeLayers.where(
            (layer) => layer != HomeMapOverlayLayer.puck,
          ),
        },
      );
      unawaited(_refreshAmbient(sample.point));
    });

    _ambientTimer?.cancel();
    _ambientTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final loc = state.userLocation;
      if (loc != null) unawaited(_refreshAmbient(loc));
    });
  }

  Future<void> openManualPinFlow() async {
    // Location denied path — user can still search via R-06 / R-06b.
  }

  Future<void> _refreshAmbient(GeoPoint location) async {
    final radius = state.fanoutRadiusM;
    final staleAfterS = state.staleAfterS;
    if (radius == null || staleAfterS == null) return;

    state = state.copyWith(isLoadingAmbient: true);
    try {
      final places = ref.read(placesRepositoryProvider);
      final cityId = state.cityId ?? await places.cityForLocation(location);
      if (cityId != null && state.cityId == null) {
        state = state.copyWith(cityId: cityId);
      }

      final presence = ref.read(presenceRepositoryProvider);
      final response = await presence.ambientVehicles(
        AmbientVehiclesRequest(
          p_lat: location.lat,
          p_lng: location.lng,
          p_radius_m: radius,
        ),
      );

      if (response.cells.isEmpty) {
        state = state.copyWith(
          ambientCells: const [],
          nearbyRows: const [],
          activeLayers: {HomeMapOverlayLayer.puck},
          isLoadingAmbient: false,
        );
        return;
      }

      final asOf = DateTime.parse(response.as_of);
      final mapCells = AmbientCellMapper.toMapCells(
        apiCells: response.cells,
        asOf: asOf,
        staleAfterS: staleAfterS,
        now: ref.read(clockProvider).now(),
      );

      final rows = [
        for (final cell in response.cells)
          NearbyAmbientRow(
            modeLabelKey: 'mode_${cell.mode.code}',
            countBucket: cell.count_bucket,
            headingLabel: AmbientCellMapper.headingLabel(
              AmbientCellMapper.toMapCells(
                apiCells: [cell],
                asOf: asOf,
                staleAfterS: staleAfterS,
                now: ref.read(clockProvider).now(),
              ).first.headingDegrees,
            ),
            etaMinutes: (cell.eta_band_s / 60).ceil(),
            modeCode: cell.mode.code,
          ),
      ];

      state = state.copyWith(
        ambientCells: mapCells,
        nearbyRows: rows,
        activeLayers: {
          HomeMapOverlayLayer.puck,
          HomeMapOverlayLayer.ambientCells,
        },
        isLoadingAmbient: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingAmbient: false);
    }
  }

  Future<void> reloadRecents() async {
    final recents = await ref.read(recentPlacesStoreProvider).load();
    state = state.copyWith(recents: recents);
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.recents = const [],
    this.isOffline = false,
    this.isSearching = false,
  });

  final String query;
  final List<PlaceResult> results;
  final List<RecentPlace> recents;
  final bool isOffline;
  final bool isSearching;

  SearchState copyWith({
    String? query,
    List<PlaceResult>? results,
    List<RecentPlace>? recents,
    bool? isOffline,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      recents: recents ?? this.recents,
      isOffline: isOffline ?? this.isOffline,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class SearchController extends Notifier<SearchState> {
  Timer? _debounce;

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_bootstrap);
    return const SearchState();
  }

  Future<void> _bootstrap() async {
    final recents = await ref.read(recentPlacesStoreProvider).load();
    final connectivity = await Connectivity().checkConnectivity();
    final offline = connectivity.contains(ConnectivityResult.none);
    state = state.copyWith(recents: recents, isOffline: offline);
  }

  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (query.trim().length < 2 || state.isOffline) {
      state = state.copyWith(results: const [], isSearching: false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_search(query.trim()));
    });
  }

  Future<void> _search(String query) async {
    final home = ref.read(homeControllerProvider);
    final location = home.userLocation ??
        const GeoPoint(
          lat: AbujaMapConstants.centerLat,
          lng: AbujaMapConstants.centerLng,
        );
    final cityId = home.cityId ??
        await ref.read(placesRepositoryProvider).cityForLocation(location);
    if (cityId == null) return;

    state = state.copyWith(isSearching: true);
    try {
      final results = await ref.read(placesRepositoryProvider).searchPlaces(
            query: query,
            near: location,
            cityId: cityId,
            limit: 8,
          );
      state = state.copyWith(results: results, isSearching: false);
    } catch (_) {
      state = state.copyWith(results: const [], isSearching: false);
    }
  }

  Future<void> selectPlace(PlaceResult place) async {
    await ref.read(recentPlacesStoreProvider).add(
          RecentPlace(
            label: place.name,
            location: place.location,
            kind: place.kind,
            id: place.id,
          ),
        );
  }
}

final adjustPickupControllerProvider =
    NotifierProvider<AdjustPickupController, AdjustPickupState>(
  AdjustPickupController.new,
);

class AdjustPickupState {
  const AdjustPickupState({
    required this.center,
    this.nearbyPlaces = const [],
    this.snappedStage,
    this.snapRadiusM,
    this.isLoading = false,
  });

  final GeoPoint center;
  final List<PlaceResult> nearbyPlaces;
  final SnappedStage? snappedStage;
  final int? snapRadiusM;
  final bool isLoading;

  AdjustPickupState copyWith({
    GeoPoint? center,
    List<PlaceResult>? nearbyPlaces,
    SnappedStage? snappedStage,
    int? snapRadiusM,
    bool? isLoading,
    bool clearSnap = false,
  }) {
    return AdjustPickupState(
      center: center ?? this.center,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      snappedStage: clearSnap ? null : (snappedStage ?? this.snappedStage),
      snapRadiusM: snapRadiusM ?? this.snapRadiusM,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AdjustPickupController extends Notifier<AdjustPickupState> {
  @override
  AdjustPickupState build() {
    final home = ref.read(homeControllerProvider);
    final center = home.userLocation ??
        const GeoPoint(
          lat: AbujaMapConstants.centerLat,
          lng: AbujaMapConstants.centerLng,
        );
    Future.microtask(() => _bootstrap(center));
    return AdjustPickupState(center: center);
  }

  Future<void> _bootstrap(GeoPoint center) async {
    final config = ref.read(configRepositoryProvider);
    final snapRadiusM =
        (await config.configNum('graph.snap_radius_m')).round();
    state = state.copyWith(snapRadiusM: snapRadiusM);
    await refresh(center);
  }

  Future<void> refresh(GeoPoint center) async {
    state = state.copyWith(center: center, isLoading: true, clearSnap: true);
    try {
      final placesRepo = ref.read(placesRepositoryProvider);
      final home = ref.read(homeControllerProvider);
      final cityId = home.cityId ??
          await placesRepo.cityForLocation(center);
      final snapped = await placesRepo.snapStage(location: center);
      List<PlaceResult> nearby = const [];
      if (cityId != null) {
        nearby = await placesRepo.searchPlaces(
          query: 'park',
          near: center,
          cityId: cityId,
          limit: 8,
        );
      }
      state = state.copyWith(
        snappedStage: snapped,
        nearbyPlaces: nearby,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}
