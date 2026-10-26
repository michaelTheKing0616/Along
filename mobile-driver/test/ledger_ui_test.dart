import 'package:along_core/along_core.dart' hide formatMoney;
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/ledger/presentation/widgets/ledger_blocked_banner.dart';
import 'package:mobile_driver/features/ledger/presentation/ledger_controller.dart';
import 'package:mobile_driver/features/ledger/presentation/settle_screen.dart';
import 'package:mobile_driver/features/trip/presentation/extend_trip_sheet.dart';
import 'package:mobile_driver/features/trip/presentation/trip_complete_sheet.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_driver/testing/fakes/fake_driver_channel.dart';

const _testConfig = AppConfig(
  flavor: 'dev',
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'anon',
  batteryGuardPercent: 15,
);

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

FakeAlongSupabase _ledgerFake() => FakeAlongSupabase(
      driverBalanceResponse:
          FakeAlongSupabase.ledgerBlockedDriverBalanceResponse(),
    );

ProviderContainer _ledgerContainer(FakeAlongSupabase fake) {
  final container = ProviderContainer(
    overrides: buildProviderOverrides(
      config: _testConfig,
      supabase: fake,
      database: AlongDatabase.memory(),
      driverChannel: FakeDriverChannel(),
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

CompleteTripResult _sampleCompleteResult() {
  final tripJson = FakeAlongSupabase.sampleTripView(
    tripId: 'trip-1',
    status: 'completed',
  );
  final trip = DomainMappers.tripFromDto(
    TripView.fromJson(tripJson),
    raw: tripJson,
  );
  return CompleteTripResult(
    trip: trip,
    commission: Money.parse('34.00', currency: 'NGN'),
    fare: Money.parse('450.00', currency: 'NGN'),
  );
}

void main() {
  group('TS-UI-05 blocked banner', () {
    testWidgets('shows balance, threshold and Settle CTA', (tester) async {
      var settleTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: alongTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LedgerBlockedBanner(
              balance: Money.parse('-5200.00', currency: 'NGN'),
              blockThreshold: Money.parse('-5000.00', currency: 'NGN'),
              onSettle: () => settleTapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('ledger_blocked_banner')), findsOneWidget);
      expect(find.textContaining('₦'), findsWidgets);
      expect(find.textContaining('5,000'), findsWidgets);
      expect(find.byKey(const Key('ledger_blocked_settle')), findsOneWidget);
      expect(find.text('Settle'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ledger_blocked_settle')));
      expect(settleTapped, isTrue);
    });
  });

  group('human ledger labels', () {
    test('ledgerEntryLabel never returns raw enum names', () {
      const entryTypes = [
        'cash_commission_debit',
        'digital_settlement_credit',
        'onboarding_deposit',
        'deposit_drawdown',
        'payout_debit',
        'manual_adjustment',
      ];
      for (final type in entryTypes) {
        final label = ledgerEntryLabel(
          type,
          destinationLabel: 'Area 1',
          memo: 'Paystack settlement',
        );
        expect(isRawLedgerEnum(label), isFalse);
      }
      expect(standingLabel('matching_paused'), isNot('matching_paused'));
    });

    testWidgets('LedgerRow renders human label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: alongTheme(),
          home: Scaffold(
            body: LedgerRow(
              label: ledgerEntryLabel(
                'cash_commission_debit',
                destinationLabel: 'Area 1',
              ),
              amount: Money.parse('-34.00', currency: 'NGN'),
              balanceAfter: Money.parse('-1234.00', currency: 'NGN'),
              kind: LedgerRowKind.debit,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Along fee · Trip to Area 1'), findsOneWidget);
      expect(find.text('cash_commission_debit'), findsNothing);
    });
  });

  group('D-18 trip complete two-tap', () {
    testWidgets('Yes then Done completes in two taps', (tester) async {
      final fake = _ledgerFake();
      final container = _ledgerContainer(fake);
      final result = _sampleCompleteResult();

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) {
              return AlongButton(
                label: 'Open',
                onPressed: () => TripCompleteSheet.show(context, result: result),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('trip_complete_yes')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('trip_complete_done')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fake.confirmFareInvokeCount, 1);
      expect(find.byType(TripCompleteSheet), findsNothing);
    });
  });

  group('D-17 extension one-tap accept', () {
    testWidgets('accept rider extension in one tap', (tester) async {
      final fake = _ledgerFake();
      final container = _ledgerContainer(fake);
      final proposal = TripExtensionProposal(
        extensionId: 'ext-1',
        tripId: 'trip-1',
        proposedBy: 'rider',
        destinationName: 'Wuse Market',
        fareDelta: Money.parse('150.00', currency: 'NGN'),
        currency: 'NGN',
      );

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) {
              return AlongButton(
                label: 'Show extension',
                onPressed: () => IncomingRiderExtensionSheet.show(
                  context,
                  proposal: proposal,
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Show extension'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('driver_extension_accept')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fake.respondExtensionInvokeCount, 1);
    });
  });

  group('D-20 nearby agents', () {
    testWidgets('shows city-bound agent list under agent code', (tester) async {
      final fake = _ledgerFake();
      final container = _ledgerContainer(fake);

      await tester.pumpWidget(
        _harness(
          container: container,
          child: const SettleScreen(),
        ),
      );
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await container.read(driverLedgerControllerProvider.notifier).refresh();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('settle_agent')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('settle_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('settle_agent_code')), findsOneWidget);
      expect(find.text('ABC123'), findsOneWidget);
      expect(find.text('Nearby agents'), findsOneWidget);
      expect(find.text('Zaria POS'), findsOneWidget);
      expect(find.text('Zaria Far POS'), findsOneWidget);
      expect(find.text('Other POS'), findsNothing);
      expect(find.text('120 m away'), findsOneWidget);
    });
  });
}
