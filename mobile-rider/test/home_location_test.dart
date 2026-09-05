import 'package:along_core/along_core.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/home/domain/ambient_cell_mapper.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/home/presentation/widgets/location_denied_banner.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R-05 location denied banner', () {
    testWidgets('shows localized banner when permission denied', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationStreamSourceProvider.overrideWithValue(
              FakeLocationStreamSource(permissionGranted: false),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LocationDeniedBanner(),
          ),
        ),
      );

      expect(
        find.text('Enable location to see nearby vehicles'),
        findsOneWidget,
      );
    });
  });

  group('HomeController', () {
    late _ConfigurableFakeSupabase fakeSupabase;
    late FakeAmbientChannel fakeAmbient;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = _ConfigurableFakeSupabase(
        configRows: defaultTestConfigRows(),
        ambientAsOf: DateTime.utc(2026, 1, 1),
        ambientCells: [sampleAmbientCell()],
      );
      fakeAmbient = FakeAmbientChannel();
      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          recentPlacesStore: FakeRecentPlacesStore(),
          locationStreamSource: FakeLocationStreamSource(
            permissionGranted: true,
            fixedSamples: [
              LocationSample(
                point: const GeoPoint(lat: 9.0765, lng: 7.3986),
                accuracyM: 10,
                recordedAt: DateTime.utc(2026, 1, 1),
              ),
            ],
          ),
          clock: Clock.fixed(DateTime.utc(2026, 1, 1, 0, 1, 0)),
          ambientChannel: fakeAmbient,
        ),
      );
    });

    tearDown(() {
      fakeSupabase.dispose();
      fakeAmbient.dispose();
      container.dispose();
    });

    test('activates ambient overlay only — never vehicle layer', () async {
      container.read(homeControllerProvider);
      await _waitFor(
        () => container.read(homeControllerProvider).ambientCells.isNotEmpty,
      );
      final state = container.read(homeControllerProvider);

      expect(state.activeLayers, contains(HomeMapOverlayLayer.ambientCells));
      expect(HomeMapLayerPolicy.isVehicleLayerAllowed(state.activeLayers), isFalse);
      expect(state.ambientCells, isNotEmpty);
    });

    test('sets locationDenied when permission denied', () async {
      container.dispose();
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
          locationStreamSource: FakeLocationStreamSource(
            permissionGranted: false,
          ),
        ),
      );

      container.read(homeControllerProvider);
      await _waitFor(
        () => container.read(homeControllerProvider).locationDenied,
      );
      final state = container.read(homeControllerProvider);

      expect(state.locationDenied, isTrue);
      expect(state.showLocationBanner, isTrue);
    });
  });
}

Future<void> _waitFor(bool Function() predicate, {int maxMs = 2000}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: maxMs));
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  fail('Timed out waiting for condition');
}

class _ConfigurableFakeSupabase extends FakeAlongSupabase {
  _ConfigurableFakeSupabase({
    required super.configRows,
    required this.ambientAsOf,
    required super.ambientCells,
  });

  final DateTime ambientAsOf;

  @override
  Future<Map<String, dynamic>> rpc(
    String fn, {
    Map<String, dynamic>? params,
  }) async {
    if (fn == 'ambient_vehicles') {
      return {
        'as_of': ambientAsOf.toIso8601String(),
        'cells': ambientCells,
      };
    }
    return super.rpc(fn, params: params);
  }
}
