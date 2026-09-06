import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/trip/domain/driver_trip_config.dart';

class ManifestState {
  const ManifestState({
    this.entries = const [],
    this.isLoading = true,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final List<DriverManifestEntry> entries;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  ManifestState copyWith({
    List<DriverManifestEntry>? entries,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ManifestState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final manifestControllerProvider =
    NotifierProvider<ManifestController, ManifestState>(ManifestController.new);

/// Polls `driver_manifest()` for D-15.
class ManifestController extends Notifier<ManifestState> {
  Timer? _pollTimer;

  @override
  ManifestState build() {
    ref.onDispose(() => _pollTimer?.cancel());
    Future.microtask(refresh);
    _startPolling();
    return const ManifestState();
  }

  Future<void> _startPolling() async {
    final config = await ref.read(driverTripConfigProvider.future);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(config.manifestPollInterval, (_) {
      unawaited(refresh(silent: true));
    });
  }

  Future<void> refresh({bool silent = false}) async {
    state = state.copyWith(
      isLoading: !silent && state.entries.isEmpty,
      isRefreshing: silent,
      clearError: true,
    );
    try {
      final entries =
          await ref.read(tripsRepositoryProvider).driverManifest();
      state = state.copyWith(
        entries: entries,
        isLoading: false,
        isRefreshing: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<TripSummary?> markBoarded(String tripId) async {
    try {
      final summary =
          await ref.read(tripsRepositoryProvider).markBoarded(tripId);
      await refresh(silent: true);
      return summary;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  void stopPolling() => _pollTimer?.cancel();
}
