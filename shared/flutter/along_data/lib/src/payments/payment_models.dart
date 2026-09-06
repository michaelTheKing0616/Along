import 'package:along_core/along_core.dart';

/// Resolved driver identity from `qr/resolve` (doc 14 §4.1).
class QrDriverInfo {
  const QrDriverInfo({
    required this.firstName,
    required this.plate,
    required this.modeCode,
    required this.acceptsDigital,
    required this.active,
  });

  final String firstName;
  final String plate;
  final String modeCode;
  final bool acceptsDigital;
  final bool active;

  factory QrDriverInfo.fromJson(Map<String, dynamic> json) {
    final mode = json['mode'];
    return QrDriverInfo(
      firstName: json['first_name'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      modeCode: mode is Map ? mode['code'] as String? ?? 'car' : mode as String? ?? 'car',
      acceptsDigital: json['accepts_digital'] as bool? ?? false,
      active: json['active'] as bool? ?? false,
    );
  }
}

/// Trip or dynamic-token context from `qr/resolve`.
class QrPaymentContext {
  const QrPaymentContext({
    required this.tripId,
    required this.amount,
    required this.locked,
    this.label,
  });

  final String tripId;
  final Money amount;
  final bool locked;
  final String? label;

  factory QrPaymentContext.fromJson(Map<String, dynamic> json) {
    final amountJson = json['amount'] as Map<String, dynamic>? ?? {};
    return QrPaymentContext(
      tripId: json['trip_id'] as String,
      amount: Money.parse(
        amountJson['amount']?.toString() ?? '0',
        currency: amountJson['currency'] as String? ?? 'NGN',
      ),
      locked: json['locked'] as bool? ?? true,
      label: json['label'] as String?,
    );
  }
}

/// Full `qr/resolve` payload consumed by R-27.
class QrResolveResult {
  const QrResolveResult({
    this.driver,
    this.context,
    this.suggestedAmounts = const [],
    this.warning,
    this.currency = 'NGN',
    this.minAmount,
  });

  final QrDriverInfo? driver;
  final QrPaymentContext? context;
  final List<Money> suggestedAmounts;
  final String? warning;
  final String currency;
  final Money? minAmount;

  bool get isDifferentDriver => warning == 'different_driver';

  factory QrResolveResult.fromJson(Map<String, dynamic> json) {
    final driverJson = json['driver'] as Map<String, dynamic>?;
    final contextJson = json['context'] as Map<String, dynamic>?;
    final suggested = (json['suggested_amounts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => Money.parse(
            m['amount']?.toString() ?? '0',
            currency: m['currency'] as String? ?? 'NGN',
          ),
        )
        .toList(growable: false);
    final minJson = json['min_amount'] as Map<String, dynamic>?;
    return QrResolveResult(
      driver: driverJson != null ? QrDriverInfo.fromJson(driverJson) : null,
      context: contextJson != null ? QrPaymentContext.fromJson(contextJson) : null,
      suggestedAmounts: suggested,
      warning: json['warning'] as String?,
      currency: json['currency'] as String? ?? 'NGN',
      minAmount: minJson != null
          ? Money.parse(
              minJson['amount']?.toString() ?? '0',
              currency: minJson['currency'] as String? ?? 'NGN',
            )
          : null,
    );
  }
}

/// Saved Paystack authorisation summary (brand/last4 only — doc 14 §5).
class PaymentMethodSummary {
  const PaymentMethodSummary({
    required this.id,
    required this.brand,
    required this.last4,
    required this.isDefault,
  });

  final String id;
  final String brand;
  final String last4;
  final bool isDefault;

  factory PaymentMethodSummary.fromJson(Map<String, dynamic> json) {
    return PaymentMethodSummary(
      id: json['id'] as String,
      brand: json['brand'] as String? ?? 'Card',
      last4: json['last4'] as String? ?? '****',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}

/// Result of `payments/initiate`.
class PaymentInitiateResult {
  const PaymentInitiateResult({
    required this.paymentId,
    required this.amount,
    required this.commissionAmount,
    required this.driverAmount,
    required this.expiresAt,
    this.authorizationUrl,
    this.ussdCode,
    this.transferAccount,
    this.status,
  });

  final String paymentId;
  final Money amount;
  final Money commissionAmount;
  final Money driverAmount;
  final DateTime expiresAt;
  final String? authorizationUrl;
  final String? ussdCode;
  final Map<String, dynamic>? transferAccount;
  final String? status;

  bool get isImmediateSuccess => status == 'succeeded';

  factory PaymentInitiateResult.fromJson(Map<String, dynamic> json) {
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

    return PaymentInitiateResult(
      paymentId: json['payment_id'] as String,
      amount: money(json['amount']),
      commissionAmount: money(json['commission_amount']),
      driverAmount: money(json['driver_amount']),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      authorizationUrl: json['authorization_url'] as String?,
      ussdCode: json['ussd_code'] as String?,
      transferAccount: json['transfer_account'] as Map<String, dynamic>?,
      status: json['status'] as String?,
    );
  }
}

/// Itemised receipt from `payments/receipt`.
class PaymentReceipt {
  const PaymentReceipt({
    required this.paymentId,
    required this.amount,
    required this.commissionAmount,
    required this.driverAmount,
    required this.driverFirstName,
    this.tripId,
  });

  final String paymentId;
  final Money amount;
  final Money commissionAmount;
  final Money driverAmount;
  final String driverFirstName;
  final String? tripId;

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as String? ?? 'NGN';
    Money money(String key) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return Money.parse(
          value['amount']?.toString() ?? '0',
          currency: value['currency'] as String? ?? currency,
        );
      }
      return Money.parse(value?.toString() ?? '0', currency: currency);
    }

    return PaymentReceipt(
      paymentId: json['payment_id'] as String,
      amount: money('amount'),
      commissionAmount: money('commission_amount'),
      driverAmount: money('driver_amount'),
      driverFirstName: json['driver_first_name'] as String? ?? '',
      tripId: json['trip_id'] as String?,
    );
  }
}
