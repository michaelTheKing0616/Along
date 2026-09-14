import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/presentation/pay_driver_sheet.dart';
import 'package:mobile_rider/features/payments/data/payments_providers.dart';
import 'package:mobile_rider/features/payments/domain/qr_scanner_port.dart';
import 'package:mobile_rider/features/payments/presentation/scan_to_pay_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';

import 'support/trip_options_fixtures.dart';

Widget _harness({
  required ProviderContainer container,
  required Widget child,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

ProviderContainer _paymentContainer(
  FakeAlongSupabase fake, {
  QrScannerPort? scanner,
}) {
  return ProviderContainer(
    overrides: [
      ...buildProviderOverrides(
        config: const AppConfig(
          flavor: 'dev',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        ),
        supabase: fake,
        ambientChannel: FakeAmbientChannel(),
        database: AlongDatabase.memory(),
      ),
      if (scanner != null) qrScannerProvider.overrideWithValue(scanner),
    ],
  );
}

void main() {
  List<Map<String, dynamic>> digitalEnabledConfig() => [
        ...defaultTestConfigRows().where(
          (row) => row['key'] != 'payments.digital_enabled',
        ),
        {
          'key': 'payments.digital_enabled',
          'scope_type': 'global',
          'scope_id': '*',
          'value': 'true',
        },
      ];

  group('QrPayloadParser', () {
    test('accepts along.ng/p/* payloads', () {
      expect(
        QrPayloadParser.parse('https://along.ng/p/TEST0301'),
        'TEST0301',
      );
    });

    test('accepts along://p/* payloads', () {
      expect(
        QrPayloadParser.parse('along://p/TEST0301'),
        'TEST0301',
      );
    });

    test('rejects non-Along payloads', () {
      expect(QrPayloadParser.parse('https://evil.com/p/TEST0301'), isNull);
      expect(QrPayloadParser.parse('not-a-code'), isNull);
    });

    test('normalises Crockford confusables in URLs', () {
      expect(
        QrPayloadParser.parse('https://along.ng/p/TEST0I01'),
        'TEST0101',
      );
    });
  });

  group('TS-UI-06 tap budgets', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;
    late TripSummary trip;

    setUp(() {
      trip = tripSummaryFromFixture(
        sampleAcceptedTripResponse(status: 'in_transit'),
      );
      fakeSupabase = FakeAlongSupabase(
        configRows: digitalEnabledConfig(),
        requestTripResponse: sampleAcceptedTripResponse(status: 'in_transit'),
        qrResolveResponse: sampleQrResolveMatchedTrip(),
        paymentMethods: sampleSavedPaymentMethods(),
        paymentInitiateImmediateSuccess: true,
      );
      container = _paymentContainer(fakeSupabase);
    });

    tearDown(() {
      container.dispose();
      fakeSupabase.dispose();
    });

    testWidgets('matched trip + saved method = 1 tap after scan', (tester) async {
      var payTaps = 0;
      final db = container.read(alongDatabaseProvider);
      await db.into(db.kvStore).insertOnConflictUpdate(
            KvStoreCompanion.insert(
              key: 'rider_prefs:payment_method_pref',
              value: '"saved"',
            ),
          );
      container.invalidate(paymentMethodPrefProvider);

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) => AlongButton(
              label: 'Open pay from scan',
              onPressed: () async {
                final resolved = await container
                    .read(paymentsRepositoryProvider)
                    .resolveQr(driverCode: 'TEST0301');
                if (!context.mounted) return;
                await PayDriverSheet.show(
                  context,
                  driverCode: 'TEST0301',
                  preloadedResolve: resolved,
                  trip: trip,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate scan → R-27 open (0 pay taps so far).
      await tester.tap(find.text('Open pay from scan'));
      await tester.pumpAndSettle();

      final payButton = find.byKey(const Key('pay_driver_submit'));
      expect(payButton, findsOneWidget);

      await tester.tap(payButton);
      payTaps++;
      await tester.pumpAndSettle();

      expect(payTaps, 1);
      expect(find.byKey(const Key('pay_driver_success_itemised')), findsOneWidget);
      expect(fakeSupabase.paymentInitiateInvokeCount, 1);
    });

    testWidgets('defaults to bank transfer even when a card is saved', (tester) async {
      fakeSupabase.paymentInitiateImmediateSuccess = false;
      fakeSupabase.paymentInitiateTransferAccount = {
        'account_number': '0123456789',
        'account_name': 'PAYSTACK CHECKOUT',
        'bank_name': 'Test Bank',
      };

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) => AlongButton(
              label: 'Open pay',
              onPressed: () => PayDriverSheet.show(
                context,
                driverCode: 'TEST0301',
                preloadedResolve: QrResolveResult.fromJson(
                  sampleQrResolveMatchedTrip(),
                ),
                trip: trip,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open pay'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pay_driver_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fakeSupabase.lastPaymentInitiateBody?['method_pref'], 'bank_transfer');
      expect(find.byKey(const Key('pay_driver_account_number')), findsOneWidget);
      expect(find.text('0123456789'), findsOneWidget);
    });

    testWidgets('unique suggested fare skips amount chips', (tester) async {
      final unique = {
        'driver': {
          'first_name': 'Musa',
          'plate': 'ABC-123-XY',
          'mode': {'code': 'keke', 'label': 'Keke'},
          'accepts_digital': true,
          'active': true,
        },
        'suggested_amounts': [
          {'amount': '450.00', 'currency': 'NGN'},
        ],
        'currency': 'NGN',
        'min_amount': {'amount': '100.00', 'currency': 'NGN'},
      };

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) => AlongButton(
              label: 'Open pay',
              onPressed: () => PayDriverSheet.show(
                context,
                driverCode: 'TEST0301',
                preloadedResolve: QrResolveResult.fromJson(unique),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open pay'));
      await tester.pumpAndSettle();

      expect(find.byType(ActionChip), findsNothing);
      expect(find.byKey(const Key('pay_driver_other_amount')), findsOneWidget);
      expect(find.byKey(const Key('pay_driver_submit')), findsOneWidget);
    });

    testWidgets('in-trip Pay auto-initiates transfer', (tester) async {
      fakeSupabase.paymentInitiateImmediateSuccess = false;
      fakeSupabase.paymentInitiateTransferAccount = {
        'account_number': '5555666677',
        'account_name': 'PAYSTACK CHECKOUT',
        'bank_name': 'Test Bank',
      };

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) => AlongButton(
              label: 'Open pay',
              onPressed: () => PayDriverSheet.show(
                context,
                trip: trip,
                autoInitiate: true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open pay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fakeSupabase.paymentInitiateInvokeCount, 1);
      expect(find.byKey(const Key('pay_driver_account_number')), findsOneWidget);
      expect(find.text('5555666677'), findsOneWidget);
    });

    testWidgets('different_driver warning blocks Pay until confirmed', (tester) async {
      fakeSupabase.qrResolveResponse = sampleQrResolveDifferentDriver();

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) => AlongButton(
              label: 'Open pay',
              onPressed: () => PayDriverSheet.show(
                context,
                driverCode: 'TEST0301',
                preloadedResolve: QrResolveResult.fromJson(
                  sampleQrResolveDifferentDriver(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open pay'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pay_driver_different_driver')), findsOneWidget);

      final payButton = find.byKey(const Key('pay_driver_submit'));
      await tester.tap(payButton);
      await tester.pump();
      expect(fakeSupabase.paymentInitiateInvokeCount, 0);

      await tester.tap(find.byKey(const Key('pay_driver_confirm_other')));
      await tester.pumpAndSettle();
      await tester.tap(payButton);
      await tester.pumpAndSettle();

      expect(fakeSupabase.paymentInitiateInvokeCount, 1);
    });

    testWidgets('scanner rejects non-Along payloads', (tester) async {
      final scanner = FakeQrScanner();
      addTearDown(scanner.dispose);

      container = _paymentContainer(fakeSupabase, scanner: scanner);
      await tester.pumpWidget(
        _harness(
          container: container,
          child: const ScanToPayScreen(),
        ),
      );
      await tester.pumpAndSettle();

      scanner.emit('https://notalong.ng/p/TEST0301');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scan_reject_message')), findsOneWidget);
      expect(find.text('Not an Along code'), findsOneWidget);
    });
  });

  group('TS-UI-06 2G resolve payload', () {
    test('qr/resolve fixture is ≤ 2 KB', () {
      final bytes = utf8.encode(jsonEncode(sampleQrResolveMatchedTrip()));
      expect(bytes.length, lessThanOrEqualTo(2048));
    });
  });
}
