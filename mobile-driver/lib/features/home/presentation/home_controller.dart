import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:along_location/along_location.dart';
import 'package:along_map/along_map.dart' as map_geo;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/domain/ambient_demand_cell_mapper.dart';
import 'package:mobile_driver/features/ledger/presentation/ledger_controller.dart';

enum RoamingDirection { onRoute, none }

class SelectedPark {
  const SelectedPark({required this.id, required this.name});

  final String id;
  final String name;
}

class DriverHomeState {
  const DriverHomeState({
    this.status = DriverStatus.offline,
    this.userLocation,
    this.locationGranted = false,
    this.demandCells = const [],
    this.demandLabels = const [],
    this.selectedPark,
    this.seatsAvailable = 4,
    this.roamingDirection = RoamingDirection.none,
    this.isVerified = false,
    this.ledgerBlocked = false,
    this.batteryGuardActive = false,
    this.foregroundVisible = false,
    this.isBusy = false,
    this.errorMessage,
    this.cityId,
    this.mapCenter,
    this.movingPingIntervalS = 4,
    this.stillPingIntervalS = 15,
    this.demandRadiusM = 3000,
  });

  final DriverStatus status;
  final GeoPoint? userLocation;
  final bool locationGranted;
  final List<map_geo.AmbientCell> demandCells;
  final List<String> demandLabels;
  final SelectedPark? selectedPark;
  final int seatsAvailable;
  final RoamingDirection roamingDirection;
  final bool isVerified;
  final bool ledgerBlocked;
  final bool batteryGuardActive;
  final bool foregroundVisible;
  final bool isBusy;
  final String? errorMessage;
  final String? cityId;
  final GeoPoint? mapCenter;
  final int movingPingIntervalS;
  final int stillPingIntervalS;
  final int demandRadiusM;

  bool get toggleEnabled => isVerified && !ledgerBlocked && !isBusy;

  bool get isOnline => status != DriverStatus.offline;

  bool get isRoaming =>
      status == DriverStatus.roamingAvailable ||
      status == DriverStatus.roamingFull;

  DriverHomeState copyWith({
    DriverStatus? status,
    GeoPoint? userLocation,
    bool? locationGranted,
    List<map_geo.AmbientCell>? demandCells,
    List<String>? demandLabels,
    SelectedPark? selectedPark,
    int? seatsAvailable,
    RoamingDirection? roamingDirection,
    bool? isVerified,
    bool? ledgerBlocked,
    bool? batteryGuardActive,
    bool? foregroundVisible,
    bool? isBusy,
    String? errorMessage,
    String? cityId,
    GeoPoint? mapCenter,
    int? movingPingIntervalS,
    int? stillPingIntervalS,
    int? demandRadiusM,
    bool clearPark = false,
    bool clearError = false,
  }) {
    return DriverHomeState(
      status: status ?? this.status,
      userLocation: userLocation ?? this.userLocation,
      locationGranted: locationGranted ?? this.locationGranted,
      demandCells: demandCells ?? this.demandCells,
      demandLabels: demandLabels ?? this.demandLabels,
      selectedPark: clearPark ? null : (selectedPark ?? this.selectedPark),
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      roamingDirection: roamingDirection ?? this.roamingDirection,
      isVerified: isVerified ?? this.isVerified,
      ledgerBlocked: ledgerBlocked ?? this.ledgerBlocked,
      batteryGuardActive: batteryGuardActive ?? this.batteryGuardActive,
      foregroundVisible: foregroundVisible ?? this.foregroundVisible,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      cityId: cityId ?? this.cityId,
      mapCenter: mapCenter ?? this.mapCenter,
      movingPingIntervalS: movingPingIntervalS ?? this.movingPingIntervalS,
      stillPingIntervalS: stillPingIntervalS ?? this.stillPingIntervalS,
      demandRadiusM: demandRadiusM ?? this.demandRadiusM,
    );
  }
}

final driverHomeControllerProvider =
    NotifierProvider<DriverHomeController, DriverHomeState>(
  DriverHomeController.new,
);

class DriverHomeController extends Notifier<DriverHomeState> {
  StreamSubscription<LocationSample>? _locationSub;
  DriverPresenceSession? _presenceSession;

  @override
  DriverHomeState build() {
    ref.onDispose(() {
      _locationSub?.cancel();
      unawaited(_presenceSession?.goOffline());
    });
    Future.microtask(_bootstrap);
    return const DriverHomeState();
  }

  Future<void> _bootstrap() async {
    await _loadConfig();
    await _loadProfile();
    await _initLocation();
  }

  Future<void> _loadConfig() async {
    final configRepo = ref.read(configRepositoryProvider);
    final moving = (await configRepo.configNum('presence.ping_interval_moving_s'))
        .round();
    final still =
        (await configRepo.configNum('presence.ping_interval_still_s')).round();
    final radius =
        (await configRepo.configNum('presence.fanout_radius_m')).round();
    state = state.copyWith(
      movingPingIntervalS: moving,
      stillPingIntervalS: still,
      demandRadiusM: radius,
    );
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    final profile =
        await ref.read(driverRepositoryProvider).fetchDriverProfile(user.id);
    if (profile == null) return;

    final centroid = await ref
        .read(placesRepositoryProvider)
        .cityCentroidForId(profile.cityId);

    state = state.copyWith(
      isVerified: profile.isVerified,
      ledgerBlocked: profile.isLedgerBlocked,
      cityId: profile.cityId,
      mapCenter: centroid,
    );
    await ref.read(driverLedgerControllerProvider.notifier).refresh();
    final ledger = ref.read(driverLedgerControllerProvider);
    state = state.copyWith(
      ledgerBlocked: profile.isLedgerBlocked || ledger.isLedgerBlocked,
    );
  }

  Future<void> _initLocation() async {
    final source = ref.read(locationStreamSourceProvider);
    final granted = await source.ensurePermission();
    if (!granted) {
      state = state.copyWith(locationGranted: false);
      return;
    }

    state = state.copyWith(locationGranted: true);
    _locationSub?.cancel();
    _locationSub = FilteredLocationStream(source).track().listen((sample) {
      state = state.copyWith(userLocation: sample.point);
      if (state.isOnline) {
        unawaited(_refreshDemand(sample.point));
      }
    });
  }

  Future<void> setStatus(DriverStatus next) async {
    if (!state.toggleEnabled && next != DriverStatus.offline) return;

    if (next == DriverStatus.atPark && state.selectedPark == null) {
      state = state.copyWith(errorMessage: 'select_park');
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      if (next == DriverStatus.offline) {
        await _setPresenceOffline();
        await _stopOnlineSession();
        state = state.copyWith(
          status: DriverStatus.offline,
          isBusy: false,
          foregroundVisible: false,
          batteryGuardActive: false,
          demandCells: const [],
          demandLabels: const [],
        );
        return;
      }

      final location = state.userLocation;
      if (location == null) {
        state = state.copyWith(isBusy: false, errorMessage: 'location_required');
        return;
      }

      await _applyOnlineStatus(next, location);
      await _startOnlineSession();
      await _refreshDemand(location);

      state = state.copyWith(
        status: next,
        isBusy: false,
        foregroundVisible: _presenceSession?.notificationVisible ?? false,
        batteryGuardActive:
            ref.read(presencePingSchedulerProvider).batteryGuardActive,
      );
    } on AlongException catch (e) {
      if (e.code == AlongErrorCode.ledgerBlocked) {
        state = state.copyWith(
          isBusy: false,
          ledgerBlocked: true,
          errorMessage: 'ledger_blocked',
        );
        return;
      }
      state = state.copyWith(isBusy: false, errorMessage: 'generic');
    } catch (_) {
      state = state.copyWith(isBusy: false, errorMessage: 'generic');
    }
  }

  Future<void> selectPark(SelectedPark park) async {
    state = state.copyWith(selectedPark: park, clearError: true);
    if (state.status == DriverStatus.atPark) {
      await setStatus(DriverStatus.atPark);
    }
  }

  Future<void> adjustSeats(int delta) async {
    final next = (state.seatsAvailable + delta).clamp(0, 60);
    state = state.copyWith(seatsAvailable: next);
    _presenceSession?.updateSeats(next);
    if (state.isRoaming && state.isOnline) {
      final location = state.userLocation;
      if (location != null) {
        await _applyOnlineStatus(state.status, location);
      }
    }
  }

  Future<void> setRoamingDirection(RoamingDirection direction) async {
    state = state.copyWith(roamingDirection: direction);
    if (state.isRoaming && state.isOnline) {
      final location = state.userLocation;
      if (location != null) {
        await _applyOnlineStatus(state.status, location);
      }
    }
  }

  Future<void> _setPresenceOffline() async {
    final location = state.userLocation ??
        const GeoPoint(lat: 0, lng: 0);
    await ref.read(presenceRepositoryProvider).setPresence(
          SetPresenceRequest(
            p_status: 'offline',
            p_location: Point(lat: location.lat, lng: location.lng),
            p_seats_available: state.seatsAvailable,
          ),
        );
  }

  Future<void> _applyOnlineStatus(DriverStatus status, GeoPoint location) async {
    final rpcStatus = switch (status) {
      DriverStatus.offline => 'offline',
      DriverStatus.atPark => 'at_park',
      DriverStatus.roamingAvailable => 'roaming_available',
      DriverStatus.roamingFull => 'roaming_full',
    };

    await ref.read(presenceRepositoryProvider).setPresence(
          SetPresenceRequest(
            p_status: rpcStatus,
            p_location: Point(lat: location.lat, lng: location.lng),
            p_seats_available: state.seatsAvailable,
            p_park_id: status == DriverStatus.atPark
                ? state.selectedPark?.id
                : null,
            p_declared_route_profile_id:
                state.roamingDirection == RoamingDirection.onRoute
                    ? null
                    : null,
          ),
        );
  }

  Future<void> _startOnlineSession() async {
    final scheduler = ref.read(presencePingSchedulerProvider);
    final session = ref.read(driverPresenceSessionProvider);
    _presenceSession = session;

    await session.goOnline(
      movingInterval: Duration(seconds: state.movingPingIntervalS),
      stillInterval: Duration(seconds: state.stillPingIntervalS),
      seatsAvailable: state.seatsAvailable,
    );

    state = state.copyWith(
      foregroundVisible: session.notificationVisible,
      batteryGuardActive: scheduler.batteryGuardActive,
    );
  }

  Future<void> _stopOnlineSession() async {
    await _presenceSession?.goOffline();
    _presenceSession = null;
  }

  /// Called from presence ping cadence (`presence.ping_interval_*`) while online.
  Future<void> refreshDemandAt(GeoPoint location) async {
    if (!state.isOnline) return;
    await _refreshDemand(location);
  }

  Future<void> _refreshDemand(GeoPoint location) async {
    try {
      final response = await ref.read(presenceRepositoryProvider).ambientDemand(
            AmbientDemandRequest(
              p_lat: location.lat,
              p_lng: location.lng,
              p_radius_m: state.demandRadiusM,
            ),
          );

      final mapCells = AmbientDemandCellMapper.toMapCells(
        apiCells: response.cells,
      );
      final labels = [
        for (final cell in response.cells)
          AmbientDemandCellMapper.labelForCell(cell: cell),
      ];

      state = state.copyWith(
        demandCells: mapCells,
        demandLabels: labels,
        batteryGuardActive:
            ref.read(presencePingSchedulerProvider).batteryGuardActive,
      );
    } catch (_) {
      // Demand is best-effort; silence keeps the map honest.
    }
  }
}

final parkPickerControllerProvider =
    NotifierProvider<ParkPickerController, ParkPickerState>(
  ParkPickerController.new,
);

class ParkPickerState {
  const ParkPickerState({
    this.parks = const [],
    this.isLoading = false,
  });

  final List<PlaceResult> parks;
  final bool isLoading;

  ParkPickerState copyWith({
    List<PlaceResult>? parks,
    bool? isLoading,
  }) {
    return ParkPickerState(
      parks: parks ?? this.parks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ParkPickerController extends Notifier<ParkPickerState> {
  @override
  ParkPickerState build() => const ParkPickerState();

  Future<void> loadNearby() async {
    final home = ref.read(driverHomeControllerProvider);
    final location = home.userLocation;
    if (location == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final configRepo = ref.read(configRepositoryProvider);
      final places = ref.read(placesRepositoryProvider);
      final cityId = home.cityId ?? await places.cityForLocation(location);
      if (cityId == null) {
        state = state.copyWith(isLoading: false, parks: const []);
        return;
      }

      final results = await places.searchPlaces(
        query: 'st',
        near: location,
        cityId: cityId,
        limit: 12,
      );

      final radiusM =
          (await configRepo.configNum('presence.at_park_radius_m')).round();
      final parks = results
          .where(
            (place) =>
                place.kind == 'park' &&
                place.id != null &&
                place.distanceM <= radiusM,
          )
          .toList(growable: false);

      state = state.copyWith(parks: parks, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, parks: const []);
    }
  }
}
