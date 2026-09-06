import 'package:along_core/along_core.dart';
import 'package:along_data/src/payments/payment_models.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Driver QR profile for D-25 (doc 14 §6).
class DriverQrProfile {
  const DriverQrProfile({
    required this.driverCode,
    required this.plate,
    required this.acceptsDigital,
    required this.hasSubaccount,
    this.publicOrigin,
  });

  final String? driverCode;
  final String plate;
  final bool acceptsDigital;
  final bool hasSubaccount;
  final String? publicOrigin;

  bool get canShowQr =>
      hasSubaccount && driverCode != null && driverCode!.isNotEmpty;
}

/// Dynamic trip QR from `create_payment_request` (doc 14 §4).
class PaymentRequestPayload {
  const PaymentRequestPayload({
    required this.url,
    required this.token,
    required this.amount,
    required this.expiresAt,
  });

  final String url;
  final String token;
  final Money amount;
  final DateTime expiresAt;

  factory PaymentRequestPayload.fromJson(Map<String, dynamic> json) {
    final amountJson = json['amount'] as Map<String, dynamic>? ?? {};
    return PaymentRequestPayload(
      url: json['url'] as String,
      token: json['token'] as String,
      amount: Money.parse(
        amountJson['amount']?.toString() ?? '0',
        currency: amountJson['currency'] as String? ?? 'NGN',
      ),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

/// Succeeded digital payment row for D-19 (doc 06).
class DriverDigitalPayment {
  const DriverDigitalPayment({
    required this.id,
    required this.amount,
    required this.driverAmount,
    required this.commissionAmount,
    required this.source,
    required this.createdAt,
    this.tripId,
  });

  final String id;
  final Money amount;
  final Money driverAmount;
  final Money commissionAmount;
  final String source;
  final DateTime createdAt;
  final String? tripId;

  factory DriverDigitalPayment.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as String? ?? 'NGN';
    Money money(dynamic value) {
      if (value is Map<String, dynamic>) {
        return Money.parse(
          value['amount']?.toString() ?? '0',
          currency: value['currency'] as String? ?? currency,
        );
      }
      return Money.parse(value?.toString() ?? '0', currency: currency);
    }

    return DriverDigitalPayment(
      id: json['id'] as String,
      amount: money(json['amount']),
      driverAmount: money(json['driver_amount']),
      commissionAmount: money(json['commission_amount']),
      source: json['source'] as String? ?? 'qr_static',
      createdAt: DateTime.parse(json['created_at'] as String),
      tripId: json['trip_id'] as String?,
    );
  }
}

/// Ops sticker print request (doc 14 §6 D-25).
class QrStickerRequest {
  const QrStickerRequest({
    required this.id,
    required this.driverCode,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String driverCode;
  final String reason;
  final String status;
  final DateTime createdAt;

  factory QrStickerRequest.fromJson(Map<String, dynamic> json) {
    return QrStickerRequest(
      id: json['id'] as String,
      driverCode: json['driver_code'] as String,
      reason: json['reason'] as String? ?? 'initial',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Broadcast payload for `payment_received` on `driver:{id}` (doc 14 §4.3).
class PaymentReceivedEvent {
  const PaymentReceivedEvent({
    required this.paymentId,
    required this.amount,
    required this.driverAmount,
    required this.commissionAmount,
    required this.currency,
    required this.source,
    this.tripId,
  });

  final String paymentId;
  final Money amount;
  final Money driverAmount;
  final Money commissionAmount;
  final String currency;
  final String source;
  final String? tripId;

  factory PaymentReceivedEvent.fromBroadcast(Map<String, dynamic> json) {
    Money money(dynamic value, {required String currency}) {
      if (value is num) {
        return Money.parse(value.toStringAsFixed(2), currency: currency);
      }
      return Money.parse(value?.toString() ?? '0', currency: currency);
    }

    final currency = json['currency'] as String? ?? 'NGN';
    return PaymentReceivedEvent(
      paymentId: json['payment_id'] as String? ?? '',
      amount: money(json['amount'], currency: currency),
      driverAmount: money(json['driver_amount'], currency: currency),
      commissionAmount: money(json['commission_amount'], currency: currency),
      currency: currency,
      source: json['source'] as String? ?? 'qr_static',
      tripId: json['trip_id'] as String?,
    );
  }
}

/// Driver-side QR and digital payment operations (doc 14 §6 D-25/D-26).
class DriverQrRepository {
  DriverQrRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<DriverQrProfile> fetchProfile(String driverId) async {
    try {
      final rows = await _gateway.selectRows(
        'drivers',
        filters: {'id': driverId},
      );
      if (rows.isEmpty) {
        throw AlongException(
          code: AlongErrorCode.notFound,
          message: 'Driver profile not found',
        );
      }
      final row = rows.first;
      final subaccount = row['payout_subaccount_code'] as String?;
      final originRows = await _gateway.selectRows(
        'app_config',
        filters: {'key': 'public.origin'},
      );
      String? publicOrigin;
      if (originRows.isNotEmpty) {
        final raw = originRows.first['value'];
        publicOrigin = raw?.toString().replaceAll('"', '').trim();
        if (publicOrigin != null && publicOrigin.isEmpty) {
          publicOrigin = null;
        }
      }

      final vehicleLinks = await _gateway.selectRows(
        'driver_vehicles',
        filters: {'driver_id': driverId, 'active': true},
      );
      String plate = '';
      if (vehicleLinks.isNotEmpty) {
        final vehicleId = vehicleLinks.first['vehicle_id'] as String?;
        if (vehicleId != null) {
          final vehicleRows = await _gateway.selectRows(
            'vehicles',
            filters: {'id': vehicleId},
          );
          if (vehicleRows.isNotEmpty) {
            plate = vehicleRows.first['plate_number'] as String? ?? '';
          }
        }
      }

      return DriverQrProfile(
        driverCode: row['driver_code'] as String?,
        plate: plate,
        acceptsDigital: row['accepts_digital'] as bool? ?? false,
        hasSubaccount: subaccount != null && subaccount.trim().isNotEmpty,
        publicOrigin: publicOrigin,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<PaymentRequestPayload> createPaymentRequest(String tripId) async {
    try {
      final raw = await _gateway.rpc(
        'create_payment_request',
        params: {'p_trip_id': tripId},
      );
      return PaymentRequestPayload.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<String> rotateDriverCode() async {
    try {
      final raw = await _gateway.rpc('rotate_driver_code');
      final map = Map<String, dynamic>.from(raw as Map);
      return map['driver_code'] as String;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<bool> setAcceptsDigital(bool enabled) async {
    try {
      final raw = await _gateway.rpc(
        'set_accepts_digital',
        params: {'p_enabled': enabled},
      );
      final map = Map<String, dynamic>.from(raw as Map);
      return map['accepts_digital'] as bool? ?? enabled;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<QrStickerRequest> requestSticker() async {
    try {
      final raw = await _gateway.rpc('request_qr_sticker');
      return QrStickerRequest.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<QrStickerRequest>> fetchStickerRequests(String driverId) async {
    try {
      final rows = await _gateway.selectRows(
        'qr_sticker_requests',
        filters: {'driver_id': driverId},
      );
      return rows
          .map(QrStickerRequest.fromJson)
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<DriverDigitalPayment>> fetchDigitalPayments(
    String driverId,
  ) async {
    try {
      final rows = await _gateway.selectRows(
        'payments',
        filters: {'driver_id': driverId, 'status': 'succeeded'},
      );
      return rows
          .map(DriverDigitalPayment.fromJson)
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<QrResolveResult> resolveQr({
    required String driverCode,
    String? token,
  }) async {
    try {
      final slug = 'qr/resolve/$driverCode';
      final raw = await _gateway.invokeFunction(
        slug,
        method: AlongHttpMethod.get,
        queryParameters: token != null ? {'t': token} : null,
      );
      final data = raw['data'] as Map<String, dynamic>? ?? raw;
      return QrResolveResult.fromJson(data);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
