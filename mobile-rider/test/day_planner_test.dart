import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/day_planner/presentation/day_planner_controller.dart';
import 'package:mobile_rider/features/day_planner/presentation/day_planner_screen.dart';
import 'package:mobile_rider/features/day_planner/presentation/itinerary_entry_controller.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

import 'support/trip_options_fixtures.dart';

final _forbiddenCopyPatterns = [
  RegExp(r'\bis booked\b', caseSensitive: false),
  RegExp(r'\bare booked\b', caseSensitive: false),
  RegExp(r'\bbooked for\b', caseSensitive: false),
  RegExp(r'\breserved for you\b', caseSensitive: false),
  RegExp(r'\bguaranteed ride\b', caseSensitive: false),
  RegExp(r'\bguaranteed future\b', caseSensitive: false),
];

bool _isForbiddenFm23Copy(String text) {
  for (final pattern in _forbiddenCopyPatterns) {
    if (pattern.hasMatch(text)) return true;
  }
  return false;
}

ProviderContainer _testContainer(FakeAlongSupabase fakeSupabase) {
  return ProviderContainer(
    overrides: buildProviderOverrides(
      config: const AppConfig(
        flavor: 'dev',
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'test-key',
      ),
      supabase: fakeSupabase,
      ambientChannel: FakeAmbientChannel(),
      recentPlacesStore: FakeRecentPlacesStore(),
    ),
  );
}

Future<void> _pumpDayPlannerLoaded(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DayPlannerScreen(itineraryId: 'itin-test-001'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('P5-B-02 Match now one tap', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: sampleRequestTripResponse(),
        itineraryStateResponse: sampleItineraryStateWithPreparedPlan(),
      );
      container = _testContainer(fakeSupabase);
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    test('matchNow commits request_trip in one controller call', () async {
      await container
          .read(dayPlannerControllerProvider('itin-test-001').notifier)
          .refresh();
      final state = container.read(dayPlannerControllerProvider('itin-test-001'));
      expect(state.itinerary?.hasPreparedPlan, isTrue);

      final trip = await container
          .read(dayPlannerControllerProvider('itin-test-001').notifier)
          .matchNow();

      expect(trip, isNotNull);
      expect(fakeSupabase.requestTripInvokeCount, 1);
    });

    testWidgets('Match now button renders without confirmation dialog',
        (tester) async {
      await _pumpDayPlannerLoaded(tester, container);
      expect(find.byKey(const Key('day_planner_match_now')), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('P5-B-02 day planner FM23 copy', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: sampleRequestTripResponse(),
        itineraryStateResponse: sampleItineraryStateWithPreparedPlan(),
      );
      container = _testContainer(fakeSupabase);
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('no user-visible string uses booked/reserved/guaranteed wording',
        (tester) async {
      await _pumpDayPlannerLoaded(tester, container);

      final elements = find.byType(Text).evaluate();
      for (final element in elements) {
        final data = element.widget as Text;
        final text = data.data ?? '';
        if (text.isEmpty) continue;
        expect(
          _isForbiddenFm23Copy(text),
          isFalse,
          reason: 'Forbidden FM23 copy in: "$text"',
        );
      }
    });
  });

  group('P5-B-02 parse proposal confirm gate', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        itineraryStateResponse: sampleItineraryStateJson(),
      );
      container = _testContainer(fakeSupabase);
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    test('parseNaturalLanguage does not call create_itinerary', () async {
      final controller = container.read(itineraryEntryControllerProvider.notifier);
      controller.setMode(ItineraryEntryMode.naturalLanguage);
      controller.setNlText('school then work');

      await controller.parseNaturalLanguage(
        cityId: 'b1000000-0000-4000-8000-000000000001',
      );

      expect(fakeSupabase.parseItineraryInvokeCount, 1);
      expect(fakeSupabase.createItineraryInvokeCount, 0);
    });

    test('confirmAndCreate writes only after explicit confirm', () async {
      final controller = container.read(itineraryEntryControllerProvider.notifier);
      controller.setMode(ItineraryEntryMode.naturalLanguage);
      controller.setNlText('school then work');

      await controller.parseNaturalLanguage(
        cityId: 'b1000000-0000-4000-8000-000000000001',
      );

      var state = container.read(itineraryEntryControllerProvider);
      expect(state.parseInvoked, isTrue);
      expect(state.createInvoked, isFalse);
      expect(fakeSupabase.createItineraryInvokeCount, 0);

      await controller.confirmAndCreate(
        cityId: 'b1000000-0000-4000-8000-000000000001',
      );

      state = container.read(itineraryEntryControllerProvider);
      expect(state.createInvoked, isTrue);
      expect(fakeSupabase.createItineraryInvokeCount, 1);
    });
  });

  group('P5-B-02 create_itinerary p_load', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        itineraryStateResponse: sampleItineraryStateJson(),
      );
      container = _testContainer(fakeSupabase);
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    test('confirmAndCreate passes p_load when load flagged at create time', () async {
      final controller = container.read(itineraryEntryControllerProvider.notifier);
      controller.updateLoad(
        const LoadFlagState(flagged: true, size: 'medium', rememberForDay: true),
      );
      controller.updateStopLabel(0, 'School');
      controller.updateStopLabel(1, 'Work');

      await controller.confirmAndCreate(
        cityId: 'b1000000-0000-4000-8000-000000000001',
      );

      expect(fakeSupabase.createItineraryInvokeCount, 1);
      final load = fakeSupabase.lastCreateItineraryParams?['p_load']
          as Map<String, dynamic>?;
      expect(load, isNotNull);
      expect(load!['flagged'], isTrue);
      expect(load['size'], 'medium');
    });
  });

  group('P5-B-02 add stop via update_itinerary_stops', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        itineraryStateResponse: sampleItineraryStateJson(),
      );
      container = _testContainer(fakeSupabase);
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    test('append stop calls update_itinerary_stops add op not create_itinerary',
        () async {
      final controller = container.read(itineraryEntryControllerProvider.notifier);
      await controller.configureForExistingItinerary('itin-test-001');
      controller.updateStopLabel(0, 'Market');

      await controller.confirmAndCreate(
        cityId: 'b1000000-0000-4000-8000-000000000001',
      );

      expect(fakeSupabase.createItineraryInvokeCount, 0);
      expect(fakeSupabase.updateItineraryStopsInvokeCount, 1);
      final ops = fakeSupabase.lastUpdateItineraryStopsParams?['p_ops']
          as List<dynamic>?;
      expect(ops, isNotNull);
      expect(ops!.first['op'], 'add');
      expect(ops.first['destination_description'], 'Market');
      expect(ops.first['sequence'], 3);
    });
  });

  group('P5-B-02 matchNow uses server load', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: sampleRequestTripResponse(),
        itineraryStateResponse: sampleItineraryStateJson(
          withPreparedPlan: true,
          loadFlagged: true,
          loadSize: 'large',
          loadNote: 'Boxes',
        ),
      );
      container = _testContainer(fakeSupabase);
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    test('matchNow sends itinerary server load in request_trip p_load', () async {
      await container
          .read(dayPlannerControllerProvider('itin-test-001').notifier)
          .refresh();

      await container
          .read(dayPlannerControllerProvider('itin-test-001').notifier)
          .matchNow();

      final load = fakeSupabase.lastRequestTripParams?['p_load']
          as Map<String, dynamic>?;
      expect(load, isNotNull);
      expect(load!['flagged'], isTrue);
      expect(load['size'], 'large');
      expect(load['note'], 'Boxes');
    });
  });
}
