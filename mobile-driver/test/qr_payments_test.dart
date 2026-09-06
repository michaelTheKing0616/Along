import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/ledger/presentation/earnings_screen.dart';
import 'package:mobile_driver/features/payments/domain/qr_scanner_port.dart';
import 'package:mobile_driver/features/payments/domain/share_image_port.dart';
import 'package:mobile_driver/features/payments/data/payments_providers.dart';
import 'package:mobile_driver/features/payments/presentation/my_qr_controller.dart';
import 'package:mobile_driver/features/payments/presentation/my_qr_screen.dart';
import 'package:mobile_driver/features/payments/presentation/payment_received_notifier.dart';
import 'package:mobile_driver/features/payments/presentation/payment_request_controller.dart';
import 'package:mobile_driver/features/payments/presentation/payment_request_screen.dart';
import 'package:mobile_driver/features/payments/presentation/widgets/payment_toast.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_driver/testing/fakes/fake_driver_channel.dart';

const _testConfig = AppConfig(
  flavor: 'dev',
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'anon',
  batteryGuardPercent: 15,
);

class _FixedClock extends Clock {
  _FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration delta) => _now = _now.add(delta);
}

Widget _harness({
  required ProviderContainer container,
  required Widget child,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: alongTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

ProviderContainer _qrContainer({
  required FakeAlongSupabase fake,
  required FakeDriverChannel channel,
  FakeShareImagePort? share,
  FakeQrScanner? scanner,
  Clock? clock,
}) {
  final container = ProviderContainer(
    overrides: buildProviderOverrides(
      config: _testConfig,
      supabase: fake,
      database: AlongDatabase.memory(),
      driverChannel: channel,
      shareImagePort: share ?? FakeShareImagePort(),
      qrScanner: scanner ?? FakeQrScanner(),
      clock: clock,
      locationStreamSource: FakeLocationStreamSource(
        permissionGranted: true,
        fixedSamples: [
          LocationSample(
            point: const GeoPoint(lat: 9.05, lng: 7.49),
            accuracyM: 8,
            recordedAt: DateTime.utc(2026, 9, 6),
          ),
        ],
      ),
    ),
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('P4-C-02 QR payments', () {
    test('dynamic QR verifies against create_payment_request token', () async {
      final fake = FakeAlongSupabase(digitalPaymentsEnabled: true);
      final repo = DriverQrRepository(fake);
      final payload = await repo.createPaymentRequest('trip-in-transit-1');
      expect(QrPayloadParser.tokenFromUrl(payload.url), payload.token);
      expect(payload.url, contains('t=${payload.token}'));
      expect(fake.paymentRequestsByTrip['trip-in-transit-1'], isNotNull);
    });

    testWidgets('D-26 paid state within 2s after Broadcast payment_received', (tester) async {
      final fake = FakeAlongSupabase(digitalPaymentsEnabled: true);
      final channel = FakeDriverChannel();
      final container = _qrContainer(fake: fake, channel: channel);
      const tripId = 'trip-paid-1';
      const args = PaymentRequestArgs(tripId: tripId, riderName: 'Ada');

      await tester.pumpWidget(
        _harness(
          container: container,
          child: PaymentRequestScreen(args: args),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      channel.emitPaymentReceived(
        paymentId: 'pay-1',
        amount: 450,
        driverAmount: 416,
        commissionAmount: 34,
        tripId: tripId,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('payment_request_paid')), findsOneWidget);
      expect(find.textContaining('450'), findsWidgets);
    });

    testWidgets('D-25 static QR renders with driver code and share stub', (tester) async {
      final fake = FakeAlongSupabase(
        digitalPaymentsEnabled: true,
        driverCode: 'ABC12345',
        driverPlate: 'ABC-123-KJ',
      );
      final share = FakeShareImagePort();
      final container = _qrContainer(
        fake: fake,
        channel: FakeDriverChannel(),
        share: share,
      );

      await tester.pumpWidget(
        _harness(container: container, child: const MyQrScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('my_qr_screen')), findsOneWidget);
      expect(find.byKey(const Key('along_qr_widget')), findsOneWidget);
      expect(find.text('ABC12345'), findsOneWidget);
      expect(find.text('ABC-123-KJ'), findsOneWidget);

      await tester.tap(find.byKey(const Key('my_qr_share')));
      await tester.pump();
      expect(share.invokeCount, 1);
      expect(share.lastPayloadUrl, contains('ABC12345'));
    });

    testWidgets('D-25 verify sticker confirms matching resolve', (tester) async {
      final fake = FakeAlongSupabase(
        digitalPaymentsEnabled: true,
        driverCode: 'ABC12345',
        driverPlate: 'ABC-123-KJ',
      );
      final scanner = FakeQrScanner();
      final container = _qrContainer(
        fake: fake,
        channel: FakeDriverChannel(),
        scanner: scanner,
      );

      await tester.pumpWidget(
        _harness(container: container, child: const MyQrScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final verifyFuture = container.read(myQrControllerProvider.notifier).verifySticker(scanner);
      await tester.pump();
      scanner.emit('along://p/ABC12345');
      await verifyFuture;
      await tester.pump();

      expect(
        container.read(myQrControllerProvider).verifyMessage,
        'match',
      );
    });

    testWidgets('D-19 shows digital payments received section', (tester) async {
      final fake = FakeAlongSupabase(
        digitalPayments: [
          {
            'id': 'pay-1',
            'amount': 450,
            'driver_amount': 416,
            'commission_amount': 34,
            'currency': 'NGN',
            'source': 'qr_dynamic',
            'status': 'succeeded',
            'created_at': '2026-09-06T10:00:00Z',
            'driver_id': 'test-driver-id',
          },
        ],
      );
      final container = _qrContainer(fake: fake, channel: FakeDriverChannel());

      await tester.pumpWidget(
        _harness(container: container, child: const EarningsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('earnings_digital_list')), findsOneWidget);
      expect(find.textContaining('416'), findsWidgets);
    });

    testWidgets('D-08 payment toast on unattributed payment_received', (tester) async {
      final fake = FakeAlongSupabase();
      final channel = FakeDriverChannel();
      final container = _qrContainer(fake: fake, channel: channel);

      await container.read(paymentToastProvider.notifier).start('test-driver-id');

      channel.emitPaymentReceived(
        paymentId: 'pay-unattributed',
        amount: 450,
        driverAmount: 416,
        commissionAmount: 34,
        tripId: null,
      );
      await tester.pump();

      expect(container.read(paymentToastProvider).event, isNotNull);
      expect(
        container.read(paymentToastProvider).event!.amount.minorUnits,
        45000,
      );

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) {
              final toast = container.read(paymentToastProvider);
              if (toast.event == null) return const SizedBox.shrink();
              return PaymentToast(
                amount: toast.event!.amount,
                onDismiss: () {},
              );
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('payment_toast')), findsOneWidget);
    });

    test('D-16 request payment gated on digital_enabled', () async {
      final disabled = FakeAlongSupabase(digitalPaymentsEnabled: false);
      final containerOff = _qrContainer(
        fake: disabled,
        channel: FakeDriverChannel(),
      );
      expect(
        await containerOff.read(digitalPaymentsEnabledProvider.future),
        isFalse,
      );
      containerOff.dispose();

      final enabled = FakeAlongSupabase(digitalPaymentsEnabled: true);
      final containerOn = _qrContainer(
        fake: enabled,
        channel: FakeDriverChannel(),
      );
      expect(
        await containerOn.read(digitalPaymentsEnabledProvider.future),
        isTrue,
      );
      containerOn.dispose();
    });
  });
}
