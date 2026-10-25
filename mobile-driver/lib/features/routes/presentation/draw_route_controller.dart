import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/routes/domain/route_draft.dart';
import 'package:mobile_driver/features/routes/domain/route_price_validator.dart';
import 'package:mobile_driver/features/routes/presentation/routes_list_controller.dart';

class DrawRouteArgs {
  const DrawRouteArgs({
    this.existingProfileId,
    this.initialStops = const [],
    this.modeCode = 'keke',
    this.initialLoadSurcharge,
  });

  final String? existingProfileId;
  final List<RouteStopDraft> initialStops;
  final String modeCode;
  final Decimal? initialLoadSurcharge;
}

class DrawRouteState {
  const DrawRouteState({
    required this.modeCode,
    this.profileId,
    this.stops = const [],
    this.loadSurcharge,
    this.isPublishing = false,
    this.publishError,
    this.snapRadiusM = 60,
    this.cityId,
    this.currencyCode = 'NGN',
  });

  final String? profileId;
  final String modeCode;
  final List<RouteStopDraft> stops;
  final Decimal? loadSurcharge;
  final bool isPublishing;
  final String? publishError;
  final int snapRadiusM;
  final String? cityId;
  final String currencyCode;

  RoutePriceValidation get priceValidation =>
      validateRoutePrices(stops.map((s) => s.priceToEnd).toList(growable: false));

  bool get canPublish =>
      priceValidation.isValid && stops.length >= 2 && !isPublishing;

  DrawRouteState copyWith({
    String? profileId,
    String? modeCode,
    List<RouteStopDraft>? stops,
    Decimal? loadSurcharge,
    bool? isPublishing,
    String? publishError,
    int? snapRadiusM,
    String? cityId,
    String? currencyCode,
    bool clearLoadSurcharge = false,
  }) {
    return DrawRouteState(
      profileId: profileId ?? this.profileId,
      modeCode: modeCode ?? this.modeCode,
      stops: stops ?? this.stops,
      loadSurcharge: clearLoadSurcharge ? null : loadSurcharge ?? this.loadSurcharge,
      isPublishing: isPublishing ?? this.isPublishing,
      publishError: publishError,
      snapRadiusM: snapRadiusM ?? this.snapRadiusM,
      cityId: cityId ?? this.cityId,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}

class DrawRouteController extends StateNotifier<DrawRouteState> {
  DrawRouteController(this._ref, DrawRouteArgs args)
      : super(
          DrawRouteState(
            profileId: args.existingProfileId,
            modeCode: args.modeCode,
            stops: _normalizeSequences(args.initialStops),
            loadSurcharge: args.initialLoadSurcharge,
          ),
        ) {
    _bootstrap();
  }

  final Ref _ref;

  RoutesRepository get _routesRepo => _ref.read(routesRepositoryProvider);
  PlacesRepository get _placesRepo => _ref.read(placesRepositoryProvider);
  ConfigRepository get _configRepo => _ref.read(configRepositoryProvider);
  DriverRepository get _driverRepo => _ref.read(driverRepositoryProvider);

  CatalogRepository get _catalogRepo => _ref.read(catalogRepositoryProvider);

  Future<void> _bootstrap() async {
    final userId = _ref.read(alongSupabaseProvider).currentUser?.id;
    if (userId == null) return;
    final profile = await _driverRepo.fetchDriverProfile(userId);
    final cityId = profile?.cityId;
    if (cityId == null) return;

    final snapRadius = (await _configRepo.configNum(
      'graph.snap_radius_m',
      cityId: cityId,
    )).round();
    final currencyCode = await _catalogRepo.currencyCodeForCity(cityId);
    if (!mounted) return;

    state = state.copyWith(
      cityId: cityId,
      snapRadiusM: snapRadius,
      currencyCode: currencyCode,
    );
  }

  static List<RouteStopDraft> _normalizeSequences(List<RouteStopDraft> stops) {
    return [
      for (var i = 0; i < stops.length; i++) stops[i].copyWith(sequence: i + 1),
    ];
  }

  Future<void> addStopAt(GeoPoint location) async {
    final cityId = state.cityId;
    if (cityId == null) return;

    SnappedStage? snapped;
    try {
      snapped = await _placesRepo.snapStage(
        location: location,
        cityId: cityId,
        snapRadiusM: state.snapRadiusM,
      );
    } catch (_) {
      snapped = null;
    }

    final sequence = state.stops.length + 1;
    final stop = RouteStopDraft(
      sequence: sequence,
      location: location,
      routeStageId: snapped?.stageId,
      matchedStageName: snapped?.name,
      isNewStop: snapped == null,
      priceToEnd: Decimal.zero,
    );

    final updated = [...state.stops];
    if (updated.isNotEmpty) {
      final lastIndex = updated.length - 1;
      final previousLast = updated[lastIndex];
      if (previousLast.priceToEnd == Decimal.zero) {
        final suggested = await _fetchSuggestedPrice(
          previousLast.sequence,
          previousLast.location,
        );
        if (suggested != null) {
          updated[lastIndex] = previousLast.copyWith(priceToEnd: suggested);
        }
      }
    }
    updated.add(stop);

    state = state.copyWith(stops: _normalizeSequences(updated), publishError: null);
  }

  Future<Decimal?> _fetchSuggestedPrice(int sequence, GeoPoint location) async {
    final profileId = state.profileId;
    if (profileId == null) return null;
    try {
      final value = await _routesRepo.suggestedStopPrice(
        profileId: profileId,
        sequence: sequence,
        location: location,
      );
      if (value == null) return null;
      return Decimal.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  void reorderStop(int oldIndex, int newIndex) {
    final stops = [...state.stops];
    final item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);

    final resequenced = _normalizeSequences(stops);
    final withLastZero = [
      for (var i = 0; i < resequenced.length; i++)
        if (i == resequenced.length - 1)
          resequenced[i].copyWith(priceToEnd: Decimal.zero)
        else
          resequenced[i],
    ];

    state = state.copyWith(stops: withLastZero, publishError: null);
  }

  void updateStopPrice(int sequence, Decimal price) {
    state = state.copyWith(
      stops: [
        for (final stop in state.stops)
          if (stop.sequence == sequence)
            stop.copyWith(priceToEnd: price)
          else
            stop,
      ],
      publishError: null,
    );
  }

  void updateStopLabel(int sequence, String label) {
    state = state.copyWith(
      stops: [
        for (final stop in state.stops)
          if (stop.sequence == sequence)
            stop.copyWith(customLabel: label, isNewStop: true)
          else
            stop,
      ],
    );
  }

  void setLoadSurcharge(Decimal? amount) {
    state = state.copyWith(
      loadSurcharge: amount,
      clearLoadSurcharge: amount == null,
      publishError: null,
    );
  }

  Future<bool> publish() async {
    if (!state.canPublish) return false;

    state = state.copyWith(isPublishing: true, publishError: null);
    try {
      await _routesRepo.upsertRouteProfile(
        id: state.profileId,
        modeCode: state.modeCode,
        stops: state.stops.map((s) => s.toPublishInput()).toList(growable: false),
        loadSurcharge: state.loadSurcharge == null
            ? null
            : Money.parse(state.loadSurcharge!.toString(), currency: state.currencyCode),
      );
      state = state.copyWith(isPublishing: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        isPublishing: false,
        publishError: 'routePublishError',
      );
      return false;
    }
  }

  /// Client-side snap for tests and offline draw without RPC.
  RouteStopDraft snapStopLocally({
    required GeoPoint tap,
    required GeoPoint stageLocation,
    required String stageId,
    required String stageName,
  }) {
    final distance = haversineDistanceM(tap, stageLocation);
    if (distance <= state.snapRadiusM) {
      return RouteStopDraft(
        sequence: state.stops.length + 1,
        location: tap,
        routeStageId: stageId,
        matchedStageName: stageName,
        priceToEnd: Decimal.zero,
      );
    }
    return RouteStopDraft(
      sequence: state.stops.length + 1,
      location: tap,
      isNewStop: true,
      priceToEnd: Decimal.zero,
    );
  }
}

final drawRouteControllerProvider = StateNotifierProvider.autoDispose
    .family<DrawRouteController, DrawRouteState, DrawRouteArgs>(
  (ref, args) => DrawRouteController(ref, args),
);
