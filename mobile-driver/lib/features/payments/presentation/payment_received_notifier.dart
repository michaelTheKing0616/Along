import 'dart:async';

import 'package:along_data/along_data.dart';
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';

/// Latest unattributed payment toast for D-08 home.
class PaymentToastState {
  const PaymentToastState({this.event});

  final PaymentReceivedEvent? event;

  PaymentToastState copyWith({PaymentReceivedEvent? event, bool clear = false}) {
    return PaymentToastState(event: clear ? null : (event ?? this.event));
  }
}

final paymentToastProvider =
    NotifierProvider<PaymentToastNotifier, PaymentToastState>(
  PaymentToastNotifier.new,
);

class PaymentToastNotifier extends Notifier<PaymentToastState> {
  StreamSubscription<Map<String, dynamic>>? _subscription;
  String? _driverId;

  @override
  PaymentToastState build() {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
    });
    return const PaymentToastState();
  }

  Future<void> start(String driverId) async {
    if (_driverId == driverId && _subscription != null) return;
    _driverId = driverId;
    await _subscription?.cancel();

    final channel = ref.read(driverChannelProvider);
    await channel.subscribe(driverId);
    _subscription = channel.events.listen(_onEvent);
  }

  void _onEvent(Map<String, dynamic> payload) {
    final type = payload['type'] as String?;
    if (type != 'payment_received') return;

    final event = PaymentReceivedEvent.fromBroadcast(payload);
    if (event.tripId != null) return;

    state = PaymentToastState(event: event);
  }

  void dismiss() {
    state = const PaymentToastState();
  }
}

/// Trip-scoped payment listener for D-26 paid state.
class TripPaymentListener {
  TripPaymentListener({
    required this.channel,
    required this.tripId,
    required this.onPaid,
  });

  final DriverChannel channel;
  final String tripId;
  final void Function(PaymentReceivedEvent event) onPaid;

  StreamSubscription<Map<String, dynamic>>? _subscription;

  Future<void> start(String driverId) async {
    await channel.subscribe(driverId);
    await _subscription?.cancel();
    _subscription = channel.events.listen((payload) {
      if (payload['type'] != 'payment_received') return;
      final event = PaymentReceivedEvent.fromBroadcast(payload);
      if (event.tripId == tripId) {
        onPaid(event);
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
