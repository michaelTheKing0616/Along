import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/payments/domain/qr_scanner_port.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(alongSupabaseProvider));
});

final qrScannerProvider = Provider<QrScannerPort>((ref) {
  return StubQrScanner();
});

/// Rider preference: bank transfer vs saved card (R-32 default).
enum PaymentMethodPref { bankTransfer, ussd, savedCard }

const _prefKey = 'rider_prefs:payment_method_pref';

final paymentMethodPrefProvider =
    FutureProvider<PaymentMethodPref>((ref) async {
  final db = ref.read(alongDatabaseProvider);
  final row = await (db.select(db.kvStore)
        ..where((t) => t.key.equals(_prefKey)))
      .getSingleOrNull();
  if (row == null) return PaymentMethodPref.bankTransfer;
  return switch (row.value.replaceAll('"', '')) {
    'ussd' => PaymentMethodPref.ussd,
    'saved' => PaymentMethodPref.savedCard,
    _ => PaymentMethodPref.bankTransfer,
  };
});

Future<void> setPaymentMethodPref(
  WidgetRef ref,
  PaymentMethodPref pref,
) async {
  final db = ref.read(alongDatabaseProvider);
  final wire = switch (pref) {
    PaymentMethodPref.bankTransfer => 'bank_transfer',
    PaymentMethodPref.ussd => 'ussd',
    PaymentMethodPref.savedCard => 'saved',
  };
  await db.into(db.kvStore).insertOnConflictUpdate(
        KvStoreCompanion.insert(
          key: _prefKey,
          value: '"$wire"',
        ),
      );
  ref.invalidate(paymentMethodPrefProvider);
}

final savedPaymentMethodsProvider =
    FutureProvider<List<PaymentMethodSummary>>((ref) async {
  return ref.read(paymentsRepositoryProvider).listPaymentMethods();
});
