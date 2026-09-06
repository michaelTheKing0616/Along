import 'dart:async';

import 'package:along_realtime/along_realtime.dart';

/// In-memory driver channel for widget/controller tests.
class FakeDriverChannel implements DriverChannel {
  FakeDriverChannel();

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  String? subscribedDriverId;

  @override
  Stream<Map<String, dynamic>> get events => _events.stream;

  @override
  Future<void> subscribe(String driverId) async {
    subscribedDriverId = driverId;
  }

  @override
  Future<void> unsubscribe() async {
    subscribedDriverId = null;
  }

  void emitTripRequest(Map<String, dynamic> payload) {
    if (!_events.isClosed) {
      _events.add(payload);
    }
  }

  void emitPaymentReceived({
    required String paymentId,
    required double amount,
    required double driverAmount,
    required double commissionAmount,
    String currency = 'NGN',
    String source = 'qr_static',
    String? tripId,
  }) {
    if (!_events.isClosed) {
      _events.add({
        'type': 'payment_received',
        'payment_id': paymentId,
        'amount': amount,
        'driver_amount': driverAmount,
        'commission_amount': commissionAmount,
        'currency': currency,
        'source': source,
        'trip_id': tripId,
      });
    }
  }

  void dispose() {
    _events.close();
  }
}
