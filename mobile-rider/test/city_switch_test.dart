import 'package:along_data/along_data.dart';
import 'package:along_location/along_location.dart';
import 'package:along_map/along_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P9-B-01 city switching', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    const abujaId = 'b1000000-0000-4000-8000-000000000001';
    const zariaId = '0a000000-0000-4000-8000-000000000001';

    setUp(() async {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        otpCode: '123456',
      );
      await fakeSupabase.verifyOtp(phone: '+2348000000001', token: '123456');

      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          ambientChannel: FakeAmbientChannel(),
          locationStreamSource: FakeLocationStreamSource(permissionGranted: false),
          recentPlacesStore: FakeRecentPlacesStore(),
        ),
      );
      addTearDown(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    test('switchCity persists Abuja then recenters to Zaria-Test', () async {
      await container.read(homeControllerProvider.notifier).switchCity(abujaId);
      final abujaState = container.read(homeControllerProvider);

      expect(abujaState.cityId, abujaId);
      expect(abujaState.citySlug, 'abuja');
      expect(abujaState.cityName, 'Abuja');
      expect(abujaState.mapCenter!.lat, closeTo(9.057, 0.001));
      expect(abujaState.mapCenter!.lng, closeTo(7.495, 0.001));

      await container.read(homeControllerProvider.notifier).switchCity(zariaId);
      final zariaState = container.read(homeControllerProvider);

      expect(zariaState.cityId, zariaId);
      expect(zariaState.citySlug, 'zaria-test');
      expect(zariaState.cityName, 'Zaria-Test');
      expect(zariaState.mapCenter!.lat, closeTo(11.066, 0.001));
      expect(zariaState.mapCenter!.lng, closeTo(7.702, 0.001));
      expect(zariaState.mapCenter!.lat, isNot(closeTo(abujaState.mapCenter!.lat, 0.01)));
      expect(
        fakeSupabase.rpcCalls.where((call) => call.$1 == 'set_home_city').length,
        2,
      );
    });
  });

  group('resolveModeLabel', () {
    test('prefers locale key then en then label column', () {
      expect(
        resolveModeLabel(
          labelI18n: const {'en': 'cars', 'ha': 'motoci'},
          fallbackLabel: 'Along taxi',
          locale: 'ha-NG',
        ),
        'motoci',
      );
      expect(
        resolveModeLabel(
          labelI18n: const {'en': 'cars'},
          fallbackLabel: 'Along taxi',
          locale: 'yo-NG',
        ),
        'cars',
      );
      expect(
        resolveModeLabel(
          labelI18n: const {},
          fallbackLabel: 'Along taxi',
          locale: 'en-NG',
        ),
        'Along taxi',
      );
    });
  });

  group('AlongStyleLoader per-city tiles', () {
    test('remoteStyleUrl includes city slug query param', () {
      const loader = AlongStyleLoader(tilesBase: 'https://tiles.dev.along.ng');
      expect(
        loader.remoteStyleUrl(citySlug: 'kaduna-pilot'),
        'https://tiles.dev.along.ng/styles/along-light.json?city=kaduna-pilot',
      );
      expect(
        loader.remoteStyleUrl(),
        'https://tiles.dev.along.ng/styles/along-light.json',
      );
    });
  });
}
