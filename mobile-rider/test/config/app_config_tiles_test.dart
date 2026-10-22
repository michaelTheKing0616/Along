import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';

void main() {
  test('hasTiles / allowsDemoMapFallback for staging vs prod', () {
    const stagingEmpty = AppConfig(
      flavor: 'staging',
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
      tilesBaseUrl: null,
    );
    expect(stagingEmpty.hasTiles, isFalse);
    expect(stagingEmpty.allowsDemoMapFallback, isTrue);

    const prodEmpty = AppConfig(
      flavor: 'prod',
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
      tilesBaseUrl: null,
    );
    expect(prodEmpty.hasTiles, isFalse);
    expect(prodEmpty.allowsDemoMapFallback, isFalse);

    const wired = AppConfig(
      flavor: 'staging',
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
      tilesBaseUrl: 'https://tiles-staging.example',
    );
    expect(wired.hasTiles, isTrue);

    const retired = AppConfig(
      flavor: 'prod',
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
      tilesBaseUrl: 'https://tiles.along.ng',
    );
    expect(retired.hasTiles, isFalse);

    const devRetired = AppConfig(
      flavor: 'dev',
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
      tilesBaseUrl: 'https://tiles.dev.along.ng',
    );
    expect(devRetired.hasTiles, isFalse);
  });
}
