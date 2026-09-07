import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_location/along_location.dart';
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/offline/low_data_providers.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:along_map/along_map.dart' show AbujaMapConstants;
import 'package:along_map/along_map.dart' as map_geo;
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
    this.candidateToken,
    this.etaBandSeconds,
  });

  final String modeLabelKey;
  final String countBucket;
  final String headingLabel;
  final int etaMinutes;
  final String modeCode;
  final String? candidateToken;
  final int? etaBandSeconds;
}

final homeControllerProvider =
    NotifierProvider<HomeController, HomeState>(HomeController.new);

class HomeController extends Notifier<HomeState> {
  StreamSubscription<LocationSample>? _locationSub;
  StreamSubscription<Map<String, dynamic>>? _ambientBroadcastSub;
  Timer? _ambientPollTimer;
  String? _ambientTopic;
  late final AmbientChannel _ambientChannel;
  LowDataMode _lowDataMode = LowDataMode.disabled();

  @override
  HomeState build() {
    _ambientChannel = ref.read(ambientChannelProvider);
    ref.onDispose(() {
      _locationSub?.cancel();
      _ambientBroadcastSub?.cancel();
      _ambientPollTimer?.cancel();
      unawaited(_ambientChannel.unsubscribe());
    });
    Future.microtask(_bootstrap);
    return const HomeState();
  }

  Future<void> _bootstrap() async {
    final recents = await ref.read(recentPlacesStoreProvider).load();
    state = state.copyWith(recents: recents);
    await _loadConfig();
    _lowDataMode = await ref.read(lowDataModeProvider.future);
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

    _ambientBroadcastSub ??=
        _ambientChannel.cellUpdates.listen(_onAmbientBroadcast);

    if (!_lowDataMode.useAmbientBroadcast) {
      await _startAmbientPolling();
    }

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
      unawaited(_ensureAmbientSubscription(sample.point));
    });
  }

  Future<void> openManualPinFlow() async {
    // Location denied path — user can still search via R-06 / R-06b.
  }

  /// One-shot RPC refresh on recenter / resume (doc 07 §5).
  Future<void> refreshAmbientOnce() async {
    final location = state.userLocation;
    if (location == null) return;
    await _fetchAmbientRpc(location);
  }

  Future<void> _ensureAmbientSubscription(GeoPoint location) async {
    final radius = state.fanoutRadiusM;
    if (radius == null) return;

    final places = ref.read(placesRepositoryProvider);
    final cityId = state.cityId ?? await places.cityForLocation(location);
    if (cityId == null) return;

    final citySlug = await places.citySlugForId(cityId);
    if (citySlug == null) return;

    if (_lowDataMode.useAmbientBroadcast) {
      final topic = ambientChannelTopic(citySlug: citySlug, location: location);
      if (_ambientTopic != topic) {
        await _ambientChannel.subscribe(
              citySlug: citySlug,
              geohash5: geohashEncode(location, precision: 5),
            );
        _ambientTopic = topic;
        if (state.cityId == null) {
          state = state.copyWith(cityId: cityId);
        }
      }
    }

    await _fetchAmbientRpc(location);
  }

  Future<void> _startAmbientPolling() async {
    _ambientPollTimer?.cancel();
    final interval = Duration(seconds: _lowDataMode.ambientPollIntervalS);
    _ambientPollTimer = Timer.periodic(interval, (_) {
      final location = state.userLocation;
      if (location != null) {
        unawaited(_fetchAmbientRpc(location));
      }
    });
  }

  void _onAmbientBroadcast(Map<String, dynamic> payload) {
    if (payload['type'] != 'cells') return;
    final asOf = payload['as_of'];
    final cells = payload['cells'];
    if (asOf is! String || cells is! List<dynamic>) return;
    _applyAmbientData(asOf: asOf, rawCells: cells);
  }

  Future<void> _fetchAmbientRpc(GeoPoint location) async {
    final radius = state.fanoutRadiusM;
    final staleAfterS = state.staleAfterS;
    if (radius == null || staleAfterS == null) return;

    state = state.copyWith(isLoadingAmbient: true);
    try {
      final presence = ref.read(presenceRepositoryProvider);
      final response = await presence.ambientVehicles(
        AmbientVehiclesRequest(
          p_lat: location.lat,
          p_lng: location.lng,
          p_radius_m: radius,
        ),
      );
      _applyAmbientData(
        asOf: response.as_of,
        rawCells: response.cells.map((cell) => cell.toJson()).toList(),
      );
    } catch (_) {
      state = state.copyWith(isLoadingAmbient: false);
    }
  }

  void _applyAmbientData({
    required String asOf,
    required List<dynamic> rawCells,
  }) {
    final staleAfterS = state.staleAfterS;
    if (staleAfterS == null) return;

    if (rawCells.isEmpty) {
      state = state.copyWith(
        ambientCells: const [],
        nearbyRows: const [],
        activeLayers: {HomeMapOverlayLayer.puck},
        isLoadingAmbient: false,
      );
      return;
    }

    final apiCells = rawCells
        .cast<Map<String, dynamic>>()
        .map(AmbientCell.fromJson)
        .toList(growable: false);
    final parsedAsOf = DateTime.parse(asOf);
    final now = ref.read(clockProvider).now();
    final mapCells = AmbientCellMapper.toMapCells(
      apiCells: apiCells,
      asOf: parsedAsOf,
      staleAfterS: staleAfterS,
      now: now,
    );

    final rows = [
      for (final cell in apiCells)
        NearbyAmbientRow(
          modeLabelKey: 'mode_${cell.mode.code}',
          countBucket: cell.count_bucket,
          headingLabel: AmbientCellMapper.headingLabel(
            AmbientCellMapper.toMapCells(
              apiCells: [cell],
              asOf: parsedAsOf,
              staleAfterS: staleAfterS,
              now: now,
            ).first.headingDegrees,
          ),
          etaMinutes: (cell.eta_band_s / 60).ceil(),
          modeCode: cell.mode.code,
          candidateToken: cell.candidate_token,
          etaBandSeconds: cell.eta_band_s,
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
    this.isStaleResults = false,
  });

  final String query;
  final List<PlaceResult> results;
  final List<RecentPlace> recents;
  final bool isOffline;
  final bool isSearching;
  final bool isStaleResults;

  SearchState copyWith({
    String? query,
    List<PlaceResult>? results,
    List<RecentPlace>? recents,
    bool? isOffline,
    bool? isSearching,
    bool? isStaleResults,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      recents: recents ?? this.recents,
      isOffline: isOffline ?? this.isOffline,
      isSearching: isSearching ?? this.isSearching,
      isStaleResults: isStaleResults ?? this.isStaleResults,
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
    final probe = ref.read(networkConditionsProbeProvider);
    final offline = (await probe.snapshot()).offline;
    state = state.copyWith(recents: recents, isOffline: offline);
  }

  void onQueryChanged(String query) {
    state = state.copyWith(query: query, isStaleResults: false);
    _debounce?.cancel();
    if (query.trim().length < 2) {
      state = state.copyWith(results: const [], isSearching: false);
      return;
    }
    if (state.isOffline) {
      unawaited(_searchOffline(query.trim()));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_search(query.trim()));
    });
  }

  Future<void> _search(String query) async {
    final home = ref.read(homeControllerProvider);
    final location = home.userLocation ??
        GeoPoint(
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
      if (cityId.isNotEmpty) {
        unawaited(
          ref.read(graphCacheStoreProvider).refreshIfNeeded(cityId: cityId),
        );
      }
    } catch (_) {
      state = state.copyWith(results: const [], isSearching: false);
    }
  }

  Future<void> _searchOffline(String query) async {
    state = state.copyWith(isSearching: true);
    try {
      final graphCache = ref.read(graphCacheStoreProvider);
      final hits = await graphCache.searchByName(query: query);
      final results = hits
          .map(
            (hit) => PlaceResult(
              kind: hit.kind,
              id: hit.id,
              name: hit.name,
              area: hit.area,
              location: hit.location,
              distanceM: 0,
            ),
          )
          .toList(growable: false);
      state = state.copyWith(
        results: results,
        isSearching: false,
        isStaleResults: results.isNotEmpty,
      );
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
        GeoPoint(
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
      final cityId = home.cityId ?? await placesRepo.cityForLocation(center);
      if (cityId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final snapRadiusM = state.snapRadiusM;
      SnappedStage? snapped;
      if (snapRadiusM != null) {
        snapped = await placesRepo.snapStage(
          location: center,
          cityId: cityId,
          snapRadiusM: snapRadiusM,
        );
      }

      final nearby = await placesRepo.searchPlaces(
        query: 'st',
        near: center,
        cityId: cityId,
        limit: 8,
      );

      state = state.copyWith(
        snappedStage: snapped,
        nearbyPlaces: nearby
            .where((place) => place.kind == 'park' || place.kind == 'stage')
            .toList(growable: false),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}
