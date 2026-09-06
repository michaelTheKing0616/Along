import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/payments/presentation/payment_received_notifier.dart';
import 'package:mobile_driver/features/trip/domain/driver_trip_config.dart';

class ActiveTripArgs {
  const ActiveTripArgs({
    required this.tripId,
    this.initialEntry,
    this.initialTrip,
  });

  final String tripId;
  final DriverManifestEntry? initialEntry;
  final TripSummary? initialTrip;

  @override
  bool operator ==(Object other) =>
      other is ActiveTripArgs && other.tripId == tripId;

  @override
  int get hashCode => tripId.hashCode;
}

class ActiveTripState {
  const ActiveTripState({
    this.trip,
    this.entry,
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.completeResult,
    this.digitalPayment,
  });

  final TripSummary? trip;
  final DriverManifestEntry? entry;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final CompleteTripResult? completeResult;
  final PaymentReceivedEvent? digitalPayment;

  ActiveTripState copyWith({
    TripSummary? trip,
    DriverManifestEntry? entry,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    CompleteTripResult? completeResult,
    PaymentReceivedEvent? digitalPayment,
    bool clearComplete = false,
    bool clearError = false,
  }) {
    return ActiveTripState(
      trip: trip ?? this.trip,
      entry: entry ?? this.entry,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      completeResult:
          clearComplete ? null : (completeResult ?? this.completeResult),
      digitalPayment: digitalPayment ?? this.digitalPayment,
    );
  }
}

final activeTripControllerFamilyProvider = NotifierProvider.family<
    ActiveTripController, ActiveTripState, ActiveTripArgs>(
  ActiveTripController.new,
);

/// D-16 active trip — start/complete RPCs + location publishing hook.
class ActiveTripController
    extends FamilyNotifier<ActiveTripState, ActiveTripArgs> {
  TripLocationPublisher? _locationPublisher;
  TripPaymentListener? _paymentListener;

  @override
  ActiveTripState build(ActiveTripArgs args) {
    ref.onDispose(() {
      unawaited(_locationPublisher?.stop());
      unawaited(_paymentListener?.dispose());
    });
    Future.microtask(_bootstrap);
    return ActiveTripState(
      entry: args.initialEntry,
      trip: args.initialTrip,
    );
  }

  Future<void> _bootstrap() async {
    try {
      final summary =
          await ref.read(tripsRepositoryProvider).tripSnapshot(arg.tripId);
      state = state.copyWith(trip: summary, isLoading: false, clearError: true);
      await _syncLocationPublisher(summary.status);
      await _syncPaymentListener(summary.status);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> _syncLocationPublisher(TripStatus status) async {
    final publisher = ref.read(tripLocationPublisherProvider);
    _locationPublisher = publisher;
    if (status == TripStatus.accepted ||
        status == TripStatus.boarded ||
        status == TripStatus.inTransit ||
        status == TripStatus.transfer) {
      final config = await ref.read(driverTripConfigProvider.future);
      await publisher.start(
        tripId: arg.tripId,
        sampleInterval: config.tripLocationSampleInterval,
      );
    } else {
      await publisher.stop();
    }
  }

  Future<void> _syncPaymentListener(TripStatus status) async {
    if (status != TripStatus.inTransit) {
      await _paymentListener?.dispose();
      _paymentListener = null;
      return;
    }

    final driverId = ref.read(alongSupabaseProvider).currentUser?.id;
    if (driverId == null) return;

    _paymentListener ??= TripPaymentListener(
      channel: ref.read(driverChannelProvider),
      tripId: arg.tripId,
      onPaid: _onDigitalPayment,
    );
    await _paymentListener!.start(driverId);
  }

  void _onDigitalPayment(PaymentReceivedEvent event) {
    state = state.copyWith(digitalPayment: event);
  }

  Future<void> startTrip() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final summary =
          await ref.read(tripsRepositoryProvider).startTrip(arg.tripId);
      state = state.copyWith(trip: summary, isSubmitting: false, clearError: true);
      await _syncLocationPublisher(summary.status);
      await _syncPaymentListener(summary.status);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<CompleteTripResult?> completeTrip() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result =
          await ref.read(tripsRepositoryProvider).completeTrip(arg.tripId);
      await _locationPublisher?.stop();
      await _paymentListener?.dispose();
      _paymentListener = null;
      state = state.copyWith(
        trip: result.trip,
        completeResult: result,
        isSubmitting: false,
        clearError: true,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<TripSummary?> markBoarded() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final summary =
          await ref.read(tripsRepositoryProvider).markBoarded(arg.tripId);
      state = state.copyWith(trip: summary, isSubmitting: false, clearError: true);
      await _syncLocationPublisher(summary.status);
      await _syncPaymentListener(summary.status);
      return summary;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return null;
    }
  }

  void stopLocationPublisher() {
    unawaited(_locationPublisher?.stop());
  }
}

final tripLocationPublisherProvider = Provider<TripLocationPublisher>((ref) {
  return TripLocationPublisher(
    locationSource: ref.watch(locationStreamSourceProvider),
    onSample: ({required tripId, required points}) async {
      await ref.read(tripsRepositoryProvider).tripLocationSample(
            tripId: tripId,
            points: points
                .map(
                  (point) => LocationSamplePoint(
                    ts: point.ts,
                    lat: point.lat,
                    lng: point.lng,
                    accuracy_m: point.accuracyM,
                    speed_mps: point.speedMps,
                    heading: point.heading,
                  ),
                )
                .toList(growable: false),
          );
    },
  );
});
