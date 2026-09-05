import 'package:along_core/along_core.dart';
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('geohashEncode', () {
    test('produces 5-char prefix for ambient channel topic', () {
      const point = GeoPoint(lat: 9.0765, lng: 7.3986);
      final hash5 = geohashEncode(point, precision: 5);
      expect(hash5.length, 5);
      expect(ambientChannelTopic(citySlug: 'abuja', location: point),
          'abuja:$hash5');
    });
  });
}
