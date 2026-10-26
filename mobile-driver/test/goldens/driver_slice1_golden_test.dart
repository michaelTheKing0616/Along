import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:along_location/along_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/features/home/presentation/widgets/driver_home_chrome.dart';
import 'package:mobile_driver/features/incoming_request/presentation/incoming_request_notifier.dart';
import 'package:mobile_driver/features/incoming_request/presentation/incoming_request_sheet.dart';
import 'package:mobile_driver/features/trip/presentation/active_trip_controller.dart';
import 'package:mobile_driver/features/ledger/presentation/earnings_screen.dart';
import 'package:mobile_driver/features/ledger/presentation/settle_screen.dart';
import 'package:mobile_driver/features/ledger/presentation/ledger_controller.dart';
import 'package:mobile_driver/features/trip/presentation/active_trip_screen.dart';
import 'package:mobile_driver/features/trip/presentation/trip_complete_sheet.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_driver/testing/fakes/fake_driver_channel.dart';

/// Driver slice 1: the real home panel, incoming request and active trip
/// screens in light, dark and 1.3x text. The native map is replaced by the
/// design system's city map stand-in, which goldens can draw.
const _config = AppConfig(
  flavor: 'dev',
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'anon',
  batteryGuardPercent: 15,
);

const _variants = [
  ('light', Brightness.light, 1.0),
  ('dark', Brightness.dark, 1.0),
  ('light_1_3x', Brightness.light, 1.3),
];

Widget _app(Brightness brightness, double scale, Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: alongTheme(brightness: brightness),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
      disableAnimations: true,
    ),
    child: child!,
  ),
  home: home,
);

/// Map stand-in under a real overlay, as the home and request screens stack.
Widget _overMap(Widget overlay, {bool scrim = false}) => Builder(
  builder: (context) => Scaffold(
    backgroundColor: AlongPalette.of(context).mapLand,
    body: Stack(
      children: [
        const Positioned.fill(
          child: AlongCityMap(
            mode: AlongCityMapMode.online,
            assetPackage: 'along_design',
          ),
        ),
        if (scrim)
          Positioned.fill(
            child: ColoredBox(
              color: AlongColors.ink900.withValues(alpha: 0.35),
            ),
          ),
        Positioned.fill(child: overlay),
      ],
    ),
  ),
);

Widget _home(DriverHomeState state, {String? earned, int? trips}) => _overMap(
  Align(
    alignment: Alignment.bottomCenter,
    child: DriverHomePanel(
      state: state,
      todayEarned: earned,
      todayTrips: trips,
      onGo: () {},
      onGoOffline: () {},
      onMode: (_) {},
      onPark: () {},
      onSeats: () {},
      onDirection: () {},
      onBuildDay: () {},
      onConductor: () {},
      onRest: () {},
      onMarketplace: () {},
    ),
  ),
);

class _NoLocation implements LocationStreamSource {
  @override
  Stream<LocationSample> samples({
    required double distanceFilterM,
    required double maxAccuracyM,
  }) => const Stream.empty();

  @override
  Future<bool> ensurePermission() async => true;
}

ProviderContainer _container(FakeAlongSupabase supabase, AlongDatabase db) {
  supabase.clock = () => DateTime.utc(2026, 9, 6, 19);
  return ProviderContainer(
    overrides: [
      ...buildProviderOverrides(
        config: _config,
        supabase: supabase,
        database: db,
        driverChannel: FakeDriverChannel(),
        locationStreamSource: _NoLocation(),
      ),
      earningsClockProvider.overrideWithValue(
        () => DateTime.utc(2026, 9, 6, 19, 30),
      ),
    ],
  );
}

CompleteTripResult _cashResult() {
  final json = FakeAlongSupabase.sampleTripView(
    tripId: 'trip-in-transit-1',
    status: 'completed',
  );
  return CompleteTripResult(
    trip: DomainMappers.tripFromDto(TripView.fromJson(json), raw: json),
    commission: Money.parse('34.00', currency: 'NGN'),
    fare: Money.parse('450.00', currency: 'NGN'),
  );
}

Future<void> _shoot(WidgetTester tester, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('driver_$name.png'),
);

void main() {
  setUpAll(() async {
    final manifest = await rootBundle.loadStructuredData<List<dynamic>>(
      'FontManifest.json',
      (s) async => json.decode(s) as List<dynamic>,
    );
    for (final entry in manifest) {
      final loader = FontLoader(entry['family'] as String);
      for (final font in entry['fonts'] as List<dynamic>) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
    await AlongFonts.ensureLoaded();
  });

  setUp(() => AlongHaptics.enabled = false);

  for (final (name, brightness, scale) in _variants) {
    testWidgets('home offline $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var went = false;
      await tester.pumpWidget(
        _app(
          brightness,
          scale,
          _overMap(
            Align(
              alignment: Alignment.bottomCenter,
              child: DriverHomePanel(
                state: const DriverHomeState(isVerified: true),
                todayEarned: '₦0',
                todayTrips: 0,
                onGo: () => went = true,
                onGoOffline: () {},
                onMode: (_) {},
                onPark: () {},
                onSeats: () {},
                onDirection: () {},
                onBuildDay: () {},
                onConductor: () {},
                onRest: () {},
                onMarketplace: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text("You're offline"), findsOneWidget);
      expect(find.byKey(const Key('driver_status_toggle')), findsNothing);
      await _shoot(tester, 'home_offline_$name');
      // GO is one tap, and the target is a full-width 56 px button.
      final go = find.byKey(const Key('home_go'));
      expect(tester.getSize(go).height, greaterThanOrEqualTo(56));
      await tester.tap(go);
      expect(went, isTrue);
    });

    testWidgets('home online $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          brightness,
          scale,
          _home(
            const DriverHomeState(
              isVerified: true,
              status: DriverStatus.roamingAvailable,
              seatsAvailable: 3,
              roamingDirection: RoamingDirection.onRoute,
              demandLabels: ['High demand · Wuse'],
            ),
            earned: '₦18,400',
            trips: 11,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text("You're online"), findsOneWidget);
      expect(find.text('Today · ₦18,400 · 11 trips'), findsOneWidget);
      expect(find.byKey(const Key('home_mode_roamingAvailable')), findsOne);
      await _shoot(tester, 'home_online_$name');
    });

    testWidgets('incoming request $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final trip = DomainMappers.incomingTripFromEnvelope(
        FakeAlongSupabase().sampleTripRequestEnvelope(loadFlagged: true),
      );
      final state = IncomingRequestState(
        trip: trip,
        commissionRate: 0.075,
        requestTtlS: 25,
        remainingSeconds: 18,
      );
      var accepted = 0;
      await tester.pumpWidget(
        _app(
          brightness,
          scale,
          Builder(
            builder: (context) => _overMap(
              IncomingRequestSheet(
                state: state,
                l10n: AppLocalizations.of(context),
                onAccept: () => accepted++,
                onDecline: () {},
              ),
              scrim: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final fare = formatMoney(trip.totalFare);
      expect(find.text('Accept · $fare'), findsOneWidget);
      await _shoot(tester, 'incoming_$name');
      final accept = find.byKey(const Key('incoming_request_accept'));
      expect(tester.getSize(accept).height, greaterThanOrEqualTo(56));
      await tester.tap(accept);
      expect(accepted, 1, reason: 'accept is a single tap');
    });

    for (final (phase, tripId, status) in [
      ('pickup', 'trip-accepted-1', 'accepted'),
      ('board', 'trip-boarded-1', 'boarded'),
      ('drop', 'trip-in-transit-1', 'in_transit'),
    ]) {
      testWidgets('active trip $phase $name', (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final supabase = FakeAlongSupabase();
        final db = AlongDatabase.memory();
        supabase.tripStatuses[tripId] = status;
        if (phase == 'pickup') {
          await db
              .into(db.kvStore)
              .insertOnConflictUpdate(
                KvStoreCompanion.insert(
                  key: 'na_me:$tripId',
                  value: jsonEncode({
                    'color_token': 'green',
                    'shape': 'diamond',
                    'label': 'Green Diamond',
                    'trip_id': tripId,
                  }),
                ),
              );
        }
        final container = ProviderContainer(
          overrides: buildProviderOverrides(
            config: _config,
            supabase: supabase,
            database: db,
            driverChannel: FakeDriverChannel(),
            locationStreamSource: _NoLocation(),
          ),
        );
        addTearDown(supabase.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _app(
              brightness,
              scale,
              ActiveTripScreen(args: ActiveTripArgs(tripId: tripId)),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('drive_phase_0')), findsOneWidget);
        await _shoot(tester, 'active_${phase}_$name');
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        await tester.pump(const Duration(seconds: 1));
      });
    }

    testWidgets('trip complete $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final supabase = FakeAlongSupabase();
      addTearDown(supabase.dispose);
      supabase.tripStatuses['trip-in-transit-1'] = 'in_transit';
      final container = _container(supabase, AlongDatabase.memory());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(
            brightness,
            scale,
            const ActiveTripScreen(
              args: ActiveTripArgs(tripId: 'trip-in-transit-1'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      TripCompleteSheet.show(
        tester.element(find.byKey(const Key('active_trip_screen'))),
        result: _cashResult(),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.text('Yes, I got ₦450'), findsOneWidget);
      await _shoot(tester, 'trip_complete_$name');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('earnings $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final supabase = FakeAlongSupabase();
      addTearDown(supabase.dispose);
      final container = _container(supabase, AlongDatabase.memory());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(brightness, scale, const EarningsScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('earnings_summary')), findsOneWidget);
      await _shoot(tester, 'earnings_$name');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('settle $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final supabase = FakeAlongSupabase();
      addTearDown(supabase.dispose);
      final container = _container(supabase, AlongDatabase.memory());
      supabase.driverBalanceResponse = {
        ...FakeAlongSupabase.defaultDriverBalanceResponse(),
        'balance': {'amount': '-1840.00', 'currency': 'NGN'},
      };
      await container.read(driverLedgerControllerProvider.notifier).refresh();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(brightness, scale, const SettleScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await _shoot(tester, 'settle_$name');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
