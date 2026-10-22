import 'package:along_map/along_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demoStyleUrl is a full MapLibre demotiles style, not a tiles base', () {
    expect(
      AlongStyleLoader.demoStyleUrl,
      'https://demotiles.maplibre.org/style.json',
    );
    expect(AlongStyleLoader.isDemoStyle(AlongStyleLoader.demoStyleUrl), isTrue);
    expect(
      AlongStyleLoader.isDemoStyle(
        const AlongStyleLoader().remoteStyleUrl(),
      ),
      isFalse,
    );
  });

  test('remoteStyleUrl never points at demotiles host', () {
    final url = const AlongStyleLoader(
      tilesBase: 'https://tiles.dev.along.ng',
    ).remoteStyleUrl(citySlug: 'abuja');
    expect(url, contains('tiles.dev.along.ng/styles/along-light.json'));
    expect(url, contains('city=abuja'));
    expect(url.contains('demotiles'), isFalse);
  });
}
