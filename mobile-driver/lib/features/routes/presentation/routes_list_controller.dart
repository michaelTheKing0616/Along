import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';

class RoutesListState {
  const RoutesListState({
    this.profiles = const [],
    this.suggestion,
    this.isLoading = true,
    this.errorMessage,
  });

  final List<DriverRouteProfileRow> profiles;
  final SuggestedKnownRoute? suggestion;
  final bool isLoading;
  final String? errorMessage;

  bool get isEmpty => profiles.isEmpty;

  RoutesListState copyWith({
    List<DriverRouteProfileRow>? profiles,
    SuggestedKnownRoute? suggestion,
    bool? isLoading,
    String? errorMessage,
    bool clearSuggestion = false,
  }) {
    return RoutesListState(
      profiles: profiles ?? this.profiles,
      suggestion: clearSuggestion ? null : suggestion ?? this.suggestion,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class RoutesListController extends StateNotifier<RoutesListState> {
  RoutesListController(this._ref) : super(const RoutesListState()) {
    refresh();
  }

  final Ref _ref;

  RoutesRepository get _routesRepo => _ref.read(routesRepositoryProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _routesRepo.fetchMyRouteProfiles(),
        _routesRepo.suggestKnownRoute(),
      ]);
      state = RoutesListState(
        profiles: results[0] as List<DriverRouteProfileRow>,
        suggestion: results[1] as SuggestedKnownRoute?,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'routeLoadError',
      );
    }
  }

  Future<void> toggleActive(DriverRouteProfileRow profile, bool active) async {
    if (!active) {
      await _routesRepo.deactivateRouteProfile(profile.id);
      await refresh();
    }
  }
}

final routesListControllerProvider =
    StateNotifierProvider<RoutesListController, RoutesListState>((ref) {
  return RoutesListController(ref);
});

final routesRepositoryProvider = Provider<RoutesRepository>((ref) {
  return RoutesRepository(ref.watch(alongSupabaseProvider));
});
