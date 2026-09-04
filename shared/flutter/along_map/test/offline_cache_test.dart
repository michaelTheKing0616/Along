import 'dart:io';

import 'package:along_map/along_map.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlongStyleLoader', () {
    late AlongStyleLoader loader;

    setUp(() {
      loader = const AlongStyleLoader(tilesBase: 'https://tiles-test.along.ng');
    });

    test('validates all overlay sources and layers', () async {
      final raw = await rootBundle.loadString('assets/style/along-light-test.json');
      final resolved = loader.resolveStyleJson(
        raw,
        pmtilesLocation: 'file:///tmp/abuja_fixture.pmtiles',
      );
      expect(() => loader.parseAndValidate(resolved), returnsNormally);
    });

    test('resolved offline style uses local PMTiles not remote CDN', () async {
      final raw = await rootBundle.loadString('assets/style/along-light-test.json');
      const localPath = '/data/user/0/com.along/cache/abuja_fixture.pmtiles';
      final resolved = loader.resolveStyleJson(
        raw,
        pmtilesLocation: Uri.file(localPath).toString(),
      );
      expect(resolved, contains('pmtiles://file://'));
      expect(resolved, contains(localPath));
      expect(resolved, isNot(contains('{{PMTILES_URL}}')));
      expect(resolved, isNot(contains('pmtiles://https://')));
    });
  });

  group('offline Abuja cache bootstrap', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('along_map_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('seeds fixture PMTiles into cache without network', () async {
      final cache = TileCacheManager(cacheDirectory: tempDir);
      final bundle = await cache.seedAbujaFixture();

      expect(await File(bundle.pmtilesPath).exists(), isTrue);
      expect(await cache.currentUsageBytes(), greaterThan(0));
      expect(bundle.pmtilesPath, endsWith('abuja_fixture.pmtiles'));
    });

    test('bootstrapOffline resolves style from cache only', () async {
      final config = await AlongMap.bootstrapOffline(
        cacheDirectory: tempDir,
      );

      expect(config.usesLocalCache, isTrue);
      expect(config.hasAllOverlayLayers, isTrue);
      expect(config.styleJson, isNot(contains('{{PMTILES_URL}}')));
      expect(config.styleJson, contains('along-puck'));
      expect(config.styleJson, contains('along-vehicle'));
    });

    test('cache LRU evicts oldest when over cap', () async {
      final cache = TileCacheManager(
        cacheDirectory: tempDir,
        maxBytes: 200,
      );
      await cache.seedAbujaFixture();
      final older = File('${tempDir.path}/older.pmtiles');
      await older.writeAsBytes(List.filled(300, 0));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final newer = File('${tempDir.path}/newer.pmtiles');
      await newer.writeAsBytes(List.filled(50, 1));

      await cache.enforceLimit();
      expect(await older.exists(), isFalse);
      expect(await newer.exists(), isTrue);
    });
  });
}
