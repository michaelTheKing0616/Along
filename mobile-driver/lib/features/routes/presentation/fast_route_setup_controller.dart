import 'package:along_core/along_core.dart';
import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/routes/domain/route_draft.dart';
import 'package:mobile_driver/features/routes/domain/route_price_validator.dart';
import 'package:mobile_driver/features/routes/presentation/routes_list_controller.dart';

class FastRouteSetupState {
  const FastRouteSetupState({
    required this.suggestion,
    required this.stops,
    this.loadSurcharge,
    this.isPublishing = false,
    this.publishError,
  });

  final SuggestedKnownRoute suggestion;
  final List<RouteStopDraft> stops;
  final Decimal? loadSurcharge;
  final bool isPublishing;
  final String? publishError;

  RoutePriceValidation get priceValidation =>
      validateRoutePrices(stops.map((s) => s.priceToEnd).toList(growable: false));

  bool get canPublish => priceValidation.isValid && !isPublishing;

  FastRouteSetupState copyWith({
    List<RouteStopDraft>? stops,
    Decimal? loadSurcharge,
    bool? isPublishing,
    String? publishError,
    bool clearLoadSurcharge = false,
  }) {
    return FastRouteSetupState(
      suggestion: suggestion,
      stops: stops ?? this.stops,
      loadSurcharge: clearLoadSurcharge ? null : loadSurcharge ?? this.loadSurcharge,
      isPublishing: isPublishing ?? this.isPublishing,
      publishError: publishError,
    );
  }
}

class FastRouteSetupController extends StateNotifier<FastRouteSetupState> {
  FastRouteSetupController(this._ref, SuggestedKnownRoute suggestion)
      : super(
          FastRouteSetupState(
            suggestion: suggestion,
            stops: draftsFromSuggestion(suggestion),
          ),
        );

  final Ref _ref;

  RoutesRepository get _routesRepo => _ref.read(routesRepositoryProvider);

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
        modeCode: state.suggestion.modeCode,
        stops: state.stops.map((s) => s.toPublishInput()).toList(growable: false),
        loadSurcharge: state.loadSurcharge == null
            ? null
            : Money.parse(state.loadSurcharge!.toString(), currency: 'NGN'),
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
}

final fastRouteSetupControllerProvider = StateNotifierProvider.autoDispose
    .family<FastRouteSetupController, FastRouteSetupState, SuggestedKnownRoute>(
  (ref, suggestion) => FastRouteSetupController(ref, suggestion),
);
