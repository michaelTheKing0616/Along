import 'package:along_core/along_core.dart';
import 'package:along_data/src/payments/payment_models.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// QR resolve, payment initiate, methods, and receipts (doc 14 §4).
class PaymentsRepository {
  PaymentsRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<QrResolveResult> resolveQr({
    required String driverCode,
    String? token,
  }) async {
    try {
      final slug = token != null
          ? 'qr/resolve/$driverCode'
          : 'qr/resolve/$driverCode';
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

  Future<PaymentInitiateResult> initiatePayment({
    required String driverCode,
    String? tripId,
    Money? amount,
    String? token,
    required String methodPref,
    bool confirmOtherDriver = false,
    String? paymentMethodId,
  }) async {
    try {
      final body = <String, dynamic>{
        'driver_code': driverCode,
        'method_pref': methodPref,
        'channel': 'app',
        if (tripId != null) 'trip_id': tripId,
        if (amount != null) 'amount': amount.amount.toDouble(),
        if (token != null) 'token': token,
        if (confirmOtherDriver) 'confirm_other_driver': true,
        if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      };
      final raw = await _gateway.invokeFunction('payments/initiate', body: body);
      final data = raw['data'] as Map<String, dynamic>? ?? raw;
      return PaymentInitiateResult.fromJson(data);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<PaymentMethodSummary>> listPaymentMethods() async {
    try {
      final raw = await _gateway.invokeFunction(
        'payments/methods',
        body: {'action': 'list'},
      );
      final data = raw['data'] as Map<String, dynamic>? ?? raw;
      final methods = data['methods'] as List<dynamic>? ?? [];
      return methods
          .whereType<Map<String, dynamic>>()
          .map(PaymentMethodSummary.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<PaymentMethodSummary>> addPaymentMethod({
    required String authorizationCode,
    String? brand,
    String? last4,
    bool setDefault = true,
  }) async {
    try {
      final raw = await _gateway.invokeFunction(
        'payments/methods',
        body: {
          'action': 'add',
          'authorization_code': authorizationCode,
          if (brand != null) 'brand': brand,
          if (last4 != null) 'last4': last4,
          'set_default': setDefault,
        },
      );
      final data = raw['data'] as Map<String, dynamic>? ?? raw;
      final methods = data['methods'] as List<dynamic>? ?? [];
      return methods
          .whereType<Map<String, dynamic>>()
          .map(PaymentMethodSummary.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<PaymentMethodSummary>> removePaymentMethod(String id) async {
    try {
      final raw = await _gateway.invokeFunction(
        'payments/methods',
        body: {'action': 'remove', 'payment_method_id': id},
      );
      final data = raw['data'] as Map<String, dynamic>? ?? raw;
      final methods = data['methods'] as List<dynamic>? ?? [];
      return methods
          .whereType<Map<String, dynamic>>()
          .map(PaymentMethodSummary.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<PaymentMethodSummary>> setDefaultPaymentMethod(String id) async {
    try {
      final raw = await _gateway.invokeFunction(
        'payments/methods',
        body: {'action': 'default', 'payment_method_id': id},
      );
      final data = raw['data'] as Map<String, dynamic>? ?? raw;
      final methods = data['methods'] as List<dynamic>? ?? [];
      return methods
          .whereType<Map<String, dynamic>>()
          .map(PaymentMethodSummary.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<PaymentReceipt> fetchReceipt(String paymentId) async {
    try {
      final raw = await _gateway.invokeFunction(
        'payments/receipt/$paymentId',
        method: AlongHttpMethod.get,
      );
      final data = raw['data'] as Map<String, dynamic>? ?? raw;
      return PaymentReceipt.fromJson(data);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
