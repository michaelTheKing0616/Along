import 'package:along_core/along_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/transfer/presentation/transfer_screen.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

import 'support/trip_options_fixtures.dart';

void main() {
  group('R-14 transfer screen', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: sampleRequestTripResponse(tripId: 'trip-leg-2'),
        journeyRows: [
          {
            'id': 'journey-1',
            'status': 'transfer',
            'city_id': 'b1000000-0000-4000-8000-000000000001',
            'plan_snapshot': {
              'candidate_id': 'cand-multi-1',
              'legs': [
                {
                  'leg_index': 0,
                  'mode': {'code': 'car', 'label': 'Car'},
                  'board': {
                    'name': 'Lugbe Park',
                    'location': {'lat': 9.01, 'lng': 7.40},
                  },
                  'alight': {'name': 'Berger Park'},
                },
                {
                  'leg_index': 1,
                  'mode': {'code': 'keke', 'label': 'Keke'},
                  'board': {
                    'name': 'Berger Park',
                    'location': {'lat': 9.03, 'lng': 7.42},
                  },
                  'alight': {'name': 'Area 1 Park'},
                  'wait_s': 120,
                  'supply': {'vehicles_bucket': '2-3'},
                },
              ],
            },
          },
        ],
        journeyTransferWalkRows: [
          {
            'journey_id': 'journey-1',
            'after_trip_sequence': 1,
            'directions': sampleWalkingDirectionsPayload(),
          },
        ],
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
          recentPlacesStore: FakeRecentPlacesStore(),
          wayfindingTts: FakeWayfindingTts(),
        ),
      );
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('request next leg is one tap with correct leg index', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TransferScreen(
              args: const TransferRouteArgs(
                journeyId: 'journey-1',
                afterTripSequence: 1,
                candidateId: 'cand-multi-1',
              ),
            ),
          ),
        ),
      );

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byKey(const Key('transfer_request_next_leg')).evaluate().isNotEmpty) {
          break;
        }
      }

      await tester.tap(find.byKey(const Key('transfer_request_next_leg')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakeSupabase.requestTripInvokeCount, 1);
      expect(fakeSupabase.lastRequestTripParams?['p_leg_index'], 1);
      expect(fakeSupabase.lastRequestTripParams?['p_candidate_id'], 'cand-multi-1');
    });
  });
}
