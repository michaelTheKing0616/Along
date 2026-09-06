import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/src/mappers/domain_mappers.dart';
import 'package:along_data/src/trips/trips_repository.dart';
import 'package:along_notifications/along_notifications.dart';
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';

/// UI state for D-14 incoming request sheet.
class IncomingRequestState {
  const IncomingRequestState({
    required this.trip,
    required this.commissionRate,
    required this.requestTtlS,
    required this.remainingSeconds,
    this.isResponding = false,
    this.showDeclineReasons = false,
    this.errorMessage,
    this.maxCascade = 3,
  });

  final TripSummary trip;
  final num commissionRate;
  final int requestTtlS;
  final int remainingSeconds;
  final bool isResponding;
  final bool showDeclineReasons;
  final String? errorMessage;
  final int maxCascade;

  Money get alongFee => computeAlongCommission(trip.totalFare, commissionRate);

  IncomingRequestState copyWith({
    TripSummary? trip,
    num? commissionRate,
    int? requestTtlS,
    int? remainingSeconds,
    bool? isResponding,
    bool? showDeclineReasons,
    String? errorMessage,
    int? maxCascade,
    bool clearError = false,
  }) {
    return IncomingRequestState(
      trip: trip ?? this.trip,
      commissionRate: commissionRate ?? this.commissionRate,
      requestTtlS: requestTtlS ?? this.requestTtlS,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isResponding: isResponding ?? this.isResponding,
      showDeclineReasons: showDeclineReasons ?? this.showDeclineReasons,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      maxCascade: maxCascade ?? this.maxCascade,
    );
  }
}

/// Listens to Broadcast `driver:{id}` and FCM data for incoming trip requests.
class IncomingRequestNotifier extends Notifier<IncomingRequestState?> {
  StreamSubscription<Map<String, dynamic>>? _broadcastSub;
  StreamSubscription<PushMessage>? _pushSub;
  Timer? _countdownTimer;
  String? _subscribedDriverId;

  @override
  IncomingRequestState? build() {
    ref.onDispose(_teardown);
    ref.listen(driverHomeControllerProvider, (previous, next) {
      if (next.isOnline && _subscribedDriverId == null) {
        unawaited(_ensureSubscribed());
      } else if (!next.isOnline) {
        _teardownSubscriptions();
        state = null;
      }
    });
    Future.microtask(_ensureSubscribed);
    return null;
  }

  Future<void> _ensureSubscribed() async {
    final home = ref.read(driverHomeControllerProvider);
    if (!home.isOnline) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    if (_subscribedDriverId == user.id) return;

    await _teardownSubscriptions();
    _subscribedDriverId = user.id;

    final channel = ref.read(driverChannelProvider);
    await channel.subscribe(user.id);
    _broadcastSub = channel.events.listen(_onBroadcastEvent);

    final push = ref.read(pushServiceProvider);
    _pushSub = push.onDataMessage.listen(_onPushMessage);
  }

  void _onBroadcastEvent(Map<String, dynamic> payload) {
    if (payload['type'] != 'trip_request') return;
    unawaited(_presentRequest(payload));
  }

  void _onPushMessage(PushMessage message) {
    if (!message.isDriverRequest) return;
    final tripId = message.tripId;
    if (tripId == null || tripId.isEmpty) return;
    unawaited(_loadAndPresent(tripId));
  }

  Future<void> _presentRequest(Map<String, dynamic> payload) async {
    try {
      final trip = DomainMappers.incomingTripFromEnvelope(payload);
      if (trip.status != TripStatus.requested) return;
      await _showTrip(trip);
    } catch (_) {
      // Malformed payloads are ignored; Realtime remains best-effort.
    }
  }

  Future<void> _loadAndPresent(String tripId) async {
    try {
      final trip = await ref.read(tripsRepositoryProvider).tripSnapshot(tripId);
      if (trip.status != TripStatus.requested) return;
      await _showTrip(trip);
    } catch (_) {
      // Snapshot fallback may fail if trip expired; ignore.
    }
  }

  Future<void> _showTrip(TripSummary trip) async {
    final home = ref.read(driverHomeControllerProvider);
    final configRepo = ref.read(configRepositoryProvider);
    final commissionRate = await configRepo.configNum(
      'commission.rate',
      cityId: home.cityId,
    );
    final requestTtlS =
        (await configRepo.configNum('dispatch.request_ttl_s')).round();
    final maxCascade =
        (await configRepo.configNum('dispatch.max_cascade')).round();

    _startCountdown(trip.expiresAt, requestTtlS);

    state = IncomingRequestState(
      trip: trip,
      commissionRate: commissionRate,
      requestTtlS: requestTtlS,
      remainingSeconds: _secondsRemaining(trip.expiresAt),
      maxCascade: maxCascade,
    );
  }

  void _startCountdown(DateTime expiresAt, int requestTtlS) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (current == null) return;

      final remaining = _secondsRemaining(expiresAt);
      if (remaining <= 0) {
        state = null;
        _countdownTimer?.cancel();
        return;
      }

      state = current.copyWith(remainingSeconds: remaining);
    });
  }

  int _secondsRemaining(DateTime expiresAt) {
    final now = ref.read(clockProvider).now();
    return expiresAt.difference(now).inSeconds.clamp(0, 86400);
  }

  Future<void> accept() async {
    final current = state;
    if (current == null || current.isResponding) return;

    state = current.copyWith(isResponding: true, clearError: true);
    try {
      await ref.read(tripsRepositoryProvider).respondToTrip(
            tripId: current.trip.tripId,
            action: 'accept',
          );
      state = null;
      _countdownTimer?.cancel();
    } on AlongException catch (_) {
      state = current.copyWith(
        isResponding: false,
        errorMessage: 'generic',
      );
    } catch (_) {
      state = current.copyWith(
        isResponding: false,
        errorMessage: 'generic',
      );
    }
  }

  void openDeclineReasons() {
    final current = state;
    if (current == null || current.isResponding) return;
    state = current.copyWith(showDeclineReasons: true);
  }

  void closeDeclineReasons() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(showDeclineReasons: false);
  }

  Future<void> decline({required String reason}) async {
    final current = state;
    if (current == null || current.isResponding) return;

    state = current.copyWith(
      isResponding: true,
      showDeclineReasons: false,
      clearError: true,
    );
    try {
      await ref.read(tripsRepositoryProvider).respondToTrip(
            tripId: current.trip.tripId,
            action: 'decline',
            declineReason: reason,
          );
      state = null;
      _countdownTimer?.cancel();
    } on AlongException catch (_) {
      state = current.copyWith(
        isResponding: false,
        errorMessage: 'generic',
      );
    } catch (_) {
      state = current.copyWith(
        isResponding: false,
        errorMessage: 'generic',
      );
    }
  }

  void dismiss() {
    state = null;
    _countdownTimer?.cancel();
  }

  Future<void> _teardownSubscriptions({bool fromDispose = false}) async {
    _broadcastSub?.cancel();
    _broadcastSub = null;
    _pushSub?.cancel();
    _pushSub = null;
    _subscribedDriverId = null;
    if (fromDispose) return;
    await ref.read(driverChannelProvider).unsubscribe();
  }

  void _teardown() {
    _countdownTimer?.cancel();
    _teardownSubscriptions(fromDispose: true);
  }
}

final incomingRequestNotifierProvider =
    NotifierProvider<IncomingRequestNotifier, IncomingRequestState?>(
  IncomingRequestNotifier.new,
);
