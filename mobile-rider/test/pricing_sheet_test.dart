import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_route_args.dart';
import 'package:mobile_rider/features/pricing/presentation/pricing_controller.dart';
import 'package:mobile_rider/features/pricing/presentation/pricing_sheet_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_negotiation_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

import 'support/pricing_fixtures.dart';

void main() {
  group('R-16 Along Pricing widget tests (P2-B-02)', () {
    late FakeAlongSupabase fakeSupabase;
    late FakeNegotiationChannel fakeNegotiationChannel;
    late ProviderContainer container;
    late PricingRouteArgs parkArgs;

    setUp(() {
      fakeNegotiationChannel = FakeNegotiationChannel();
      fakeSupabase = FakeAlongSupabase(
        configRows: [
          ...defaultTestConfigRows(),
          ...defaultNegotiationConfigRows(),
        ],
        requestTripResponse: sampleRequestTripResponse(),
      );
      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          ambientChannel: FakeAmbientChannel(),
          negotiationChannel: fakeNegotiationChannel,
          recentPlacesStore: FakeRecentPlacesStore(),
          clock: Clock.fixed(DateTime.utc(2026, 9, 5, 16, 0, 0)),
        ),
      );
      parkArgs = PricingRouteArgs(
        context: 'park',
        from: const GeoPoint(lat: 9.0765, lng: 7.3986),
        to: const GeoPoint(lat: 9.08, lng: 7.45),
        clientRef: 'test-park-1',
        destinationLabel: 'Area 1 Park',
      );
    });

    tearDown(() {
      fakeSupabase.dispose();
      fakeNegotiationChannel.dispose();
    });

    Future<void> cleanupPricingTest(WidgetTester tester, PricingRouteArgs args) async {
      try {
        container
            .read(pricingControllerFamilyProvider(args).notifier)
            .disposeCountdown();
      } catch (_) {}
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump();
    }

    Future<void> pumpPricing(WidgetTester tester, PricingRouteArgs args) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PricingSheetScreen(args: args),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('(a) park full round-cap flow shows split-the-difference', (tester) async {
      await pumpPricing(tester, parkArgs);

      expect(find.byKey(const Key('pricing_negotiation_sheet')), findsOneWidget);
      expect(find.text('Round 1 of 4'), findsOneWidget);

      final chip = find.widgetWithText(ActionChip, '+₦50');
      expect(chip, findsWidgets);
      await tester.tap(chip.first);
      await tester.pump();

      await tester.tap(find.widgetWithText(AlongButton, 'Offer ₦650'));
      await tester.pumpAndSettle();

      expect(find.text('Round 2 of 4'), findsOneWidget);

      await tester.tap(find.textContaining('Offer ₦'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Offer ₦'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Split the difference'), findsOneWidget);

      await tester.tap(find.textContaining('Split the difference'));
      await tester.pumpAndSettle();

      await cleanupPricingTest(tester, parkArgs);
    });

    testWidgets('(b) roaming none band shows Accept and Skip only', (tester) async {
      final args = PricingRouteArgs(
        context: 'roaming',
        from: const GeoPoint(lat: 9.0765, lng: 7.3986),
        to: const GeoPoint(lat: 9.08, lng: 7.45),
        clientRef: 'test-roam-none',
        candidateToken: 'tok-none-1',
      );
      await pumpPricing(tester, args);

      expect(find.text('Accept ₦600'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Round 1 of 0'), findsNothing);
      expect(find.widgetWithText(ActionChip, '+₦50'), findsNothing);

      await cleanupPricingTest(tester, args);
    });

    testWidgets('(b) roaming single band shows one counter-offer caption', (tester) async {
      final args = PricingRouteArgs(
        context: 'roaming',
        from: const GeoPoint(lat: 9.0765, lng: 7.3986),
        to: const GeoPoint(lat: 9.08, lng: 7.45),
        clientRef: 'test-roam-single',
        candidateToken: 'tok-single-1',
      );
      await pumpPricing(tester, args);

      expect(find.text('One counter-offer allowed'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, '+₦50'), findsWidgets);

      await cleanupPricingTest(tester, args);
    });

    testWidgets('(b) roaming full band shows multi-round chips', (tester) async {
      final args = PricingRouteArgs(
        context: 'roaming',
        from: const GeoPoint(lat: 9.0765, lng: 7.3986),
        to: const GeoPoint(lat: 9.08, lng: 7.45),
        clientRef: 'test-roam-full',
        candidateToken: 'tok-full-1',
      );
      await pumpPricing(tester, args);

      expect(find.text('Round 1 of 3'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, '+₦50'), findsWidgets);

      await cleanupPricingTest(tester, args);
    });

    testWidgets('(c) lapsed timeout terminal state', (tester) async {
      await pumpPricing(tester, parkArgs);

      final controller = container.read(pricingControllerFamilyProvider(parkArgs).notifier);
      controller.setTerminalForTest(PricingTerminalKind.lapsedTimeout);
      await tester.pump();

      expect(find.byKey(const Key('pricing_terminal_lapsedTimeout')), findsOneWidget);
      expect(find.text('No agreement — try another vehicle'), findsOneWidget);

      await cleanupPricingTest(tester, parkArgs);
    });

    testWidgets('(c) out-of-range terminal state', (tester) async {
      await pumpPricing(tester, parkArgs);

      final controller = container.read(pricingControllerFamilyProvider(parkArgs).notifier);
      controller.setTerminalForTest(PricingTerminalKind.lapsedOutOfRange);
      await tester.pump();

      expect(find.byKey(const Key('pricing_terminal_lapsedOutOfRange')), findsOneWidget);
      expect(find.text('Vehicle has passed'), findsOneWidget);

      await cleanupPricingTest(tester, parkArgs);
    });

    testWidgets('chip steps come from server open_negotiation response', (tester) async {
      fakeSupabase.negotiationEngine.chipSteps = [200, 100, 100, 200];
      await pumpPricing(tester, parkArgs);

      expect(find.widgetWithText(ActionChip, '+₦200'), findsWidgets);
      expect(find.widgetWithText(ActionChip, '+₦100'), findsWidgets);

      await cleanupPricingTest(tester, parkArgs);
    });
  });
}

Map<String, dynamic> sampleRequestTripResponse({
  String tripId = 'trip-neg-1',
}) =>
    {
      'trip_id': tripId,
      'journey_id': 'journey-1',
      'journey_sequence': 1,
      'status': 'requested',
      'mode': {
        'code': 'keke',
        'label': 'Keke',
        'icon_key': 'keke',
        'color_token': 'modeKeke',
      },
      'rider': {},
      'driver': {},
      'vehicle': {},
      'board': {
        'stage_id': 's-lugbe',
        'name': 'Lugbe Park',
        'location': {'lat': 9.01, 'lng': 7.40},
        'walk_m': 240,
        'walk_s': 240,
        'wayfinding_available': true,
      },
      'alight': {
        'stage_id': 's-area1',
        'name': 'Area 1 Park',
        'location': {'lat': 9.05, 'lng': 7.45},
      },
      'route_leg_ids': ['leg-1'],
      'fare': {
        'total': {'amount': '575.00', 'currency': 'NGN'},
        'tier': 3,
        'confidence': 0.5,
        'unconfirmed': false,
        'components': [],
        'quote_id': 'quote-neg',
        'expires_at': '2026-09-05T16:05:00Z',
      },
      'load': {'flagged': false},
      'women_only': false,
      'na_me': {
        'color_token': 'green',
        'shape': 'diamond',
        'label': 'Green Diamond',
      },
      'live_channel': 'trip:$tripId',
      'expires_at': '2026-09-05T16:05:00Z',
      'timestamps': {},
    };
