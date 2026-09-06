import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/payments/data/payments_providers.dart';
import 'package:mobile_driver/features/payments/presentation/payment_received_notifier.dart';

enum PaymentRequestPhase { loading, waiting, paid, expired, error }

class PaymentRequestState {
  const PaymentRequestState({
    this.phase = PaymentRequestPhase.loading,
    this.payload,
    this.paidEvent,
    this.riderName,
    this.remainingSeconds,
    this.errorMessage,
  });

  final PaymentRequestPhase phase;
  final PaymentRequestPayload? payload;
  final PaymentReceivedEvent? paidEvent;
  final String? riderName;
  final int? remainingSeconds;
  final String? errorMessage;

  PaymentRequestState copyWith({
    PaymentRequestPhase? phase,
    PaymentRequestPayload? payload,
    PaymentReceivedEvent? paidEvent,
    String? riderName,
    int? remainingSeconds,
    String? errorMessage,
  }) {
    return PaymentRequestState(
      phase: phase ?? this.phase,
      payload: payload ?? this.payload,
      paidEvent: paidEvent ?? this.paidEvent,
      riderName: riderName ?? this.riderName,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PaymentRequestArgs {
  const PaymentRequestArgs({
    required this.tripId,
    this.riderName,
  });

  final String tripId;
  final String? riderName;

  @override
  bool operator ==(Object other) =>
      other is PaymentRequestArgs && other.tripId == tripId;

  @override
  int get hashCode => tripId.hashCode;
}

final paymentRequestControllerFamilyProvider = NotifierProvider.family<
    PaymentRequestController, PaymentRequestState, PaymentRequestArgs>(
  PaymentRequestController.new,
);

class PaymentRequestController
    extends FamilyNotifier<PaymentRequestState, PaymentRequestArgs> {
  TripPaymentListener? _listener;
  Timer? _countdown;

  @override
  PaymentRequestState build(PaymentRequestArgs args) {
    ref.onDispose(_dispose);
    Future.microtask(() => _load(args));
    return PaymentRequestState(riderName: args.riderName);
  }

  Future<void> _load(PaymentRequestArgs args) async {
    try {
      final digitalEnabled =
          await ref.read(digitalPaymentsEnabledProvider.future);
      if (!digitalEnabled) {
        state = state.copyWith(
          phase: PaymentRequestPhase.error,
          errorMessage: 'digital_disabled',
        );
        return;
      }

      final payload = await ref
          .read(driverQrRepositoryProvider)
          .createPaymentRequest(args.tripId);

      final tokenFromUrl = QrPayloadParser.tokenFromUrl(payload.url);
      if (tokenFromUrl != payload.token) {
        state = state.copyWith(
          phase: PaymentRequestPhase.error,
          errorMessage: 'token_mismatch',
        );
        return;
      }

      final driverId = ref.read(alongSupabaseProvider).currentUser?.id;
      if (driverId != null) {
        _listener = TripPaymentListener(
          channel: ref.read(driverChannelProvider),
          tripId: args.tripId,
          onPaid: _onPaid,
        );
        await _listener!.start(driverId);
      }

      state = state.copyWith(
        phase: PaymentRequestPhase.waiting,
        payload: payload,
      );
      _startCountdown(payload.expiresAt);
    } catch (_) {
      state = state.copyWith(
        phase: PaymentRequestPhase.error,
        errorMessage: 'create_failed',
      );
    }
  }

  void _onPaid(PaymentReceivedEvent event) {
    if (state.phase == PaymentRequestPhase.paid) return;
    state = state.copyWith(
      phase: PaymentRequestPhase.paid,
      paidEvent: event,
    );
    _countdown?.cancel();
  }

  void _startCountdown(DateTime expiresAt) {
    _countdown?.cancel();
    void tick() {
      final clock = ref.read(clockProvider);
      final remaining = expiresAt.difference(clock.now()).inSeconds;
      if (remaining <= 0) {
        _countdown?.cancel();
        if (state.phase == PaymentRequestPhase.waiting) {
          state = state.copyWith(
            phase: PaymentRequestPhase.expired,
            remainingSeconds: 0,
          );
        }
        return;
      }
      state = state.copyWith(remainingSeconds: remaining);
    }

    tick();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _dispose() {
    _countdown?.cancel();
    unawaited(_listener?.dispose());
  }
}
