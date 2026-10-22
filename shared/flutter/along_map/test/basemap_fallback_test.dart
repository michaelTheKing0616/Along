import 'dart:io';

import 'package:along_map/along_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flutter test sets FLUTTER_TEST in the environment', () {
    expect(Platform.environment['FLUTTER_TEST'], 'true');
  });

  group('AlongStyleLoader.resolveBasemapStyleUrl', () {
    test('retired along.ng hosts fall back to OpenFreeMap', () {
      for (final host in AlongStyleLoader.unreachableTileHosts) {
        expect(
          AlongStyleLoader.resolveBasemapStyleUrl(
            tilesBase: 'https://$host',
            citySlug: 'abuja',
          ),
          AlongStyleLoader.openFreeMapStyleUrl,
        );
        expect(AlongStyleLoader.isReachableTilesBase('https://$host'), isFalse);
      }
      expect(
        AlongStyleLoader.resolveBasemapStyleUrl(tilesBase: ''),
        AlongStyleLoader.openFreeMapStyleUrl,
      );
      expect(
        AlongStyleLoader.resolveBasemapStyleUrl(tilesBase: null),
        AlongStyleLoader.openFreeMapStyleUrl,
      );
    });

    test('a real https tiles base still builds the Along style URL', () {
      const base =
          'https://example.supabase.co/storage/v1/object/public/tiles-staging';
      expect(AlongStyleLoader.isReachableTilesBase(base), isTrue);
      expect(
        AlongStyleLoader.resolveBasemapStyleUrl(
          tilesBase: base,
          citySlug: 'kaduna-pilot',
        ),
        '$base/styles/along-light.json?city=kaduna-pilot',
      );
    });
  });
}
