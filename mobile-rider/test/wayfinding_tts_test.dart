import 'package:along_core/along_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/wayfinding/presentation/wayfinding_screen.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

void main() {
  group('R-19 wayfinding audio via TTS', () {
    late FakeAlongSupabase fakeSupabase;
    late FakeWayfindingTts fakeTts;
    late ProviderContainer container;

    setUp(() {
      fakeTts = FakeWayfindingTts();
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
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
          wayfindingTts: fakeTts,
        ),
      );
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('audio play invokes TTS with server script', (tester) async {
      await container.read(riderPrefsStoreProvider).setWayfindingMode(
            WayfindingMode.audio,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: WayfindingScreen(
              args: WayfindingRouteArgs(
                from: const GeoPoint(lat: 9.0765, lng: 7.3986),
                to: const GeoPoint(lat: 9.08, lng: 7.45),
                cityId: 'b1000000-0000-4000-8000-000000000001',
              ),
            ),
          ),
        ),
      );

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byKey(const Key('wayfinding_audio_play')).evaluate().isNotEmpty) {
          break;
        }
      }

      await tester.tap(find.byKey(const Key('wayfinding_audio_play')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeTts.spoken, isNotEmpty);
      expect(fakeTts.spoken.first, contains('Airport Road'));
    });
  });
}
