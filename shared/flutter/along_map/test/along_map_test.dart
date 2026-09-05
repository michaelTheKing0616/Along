import 'package:along_core/along_core.dart';
import 'package:along_map/along_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoJsonBuilder', () {
    test('builds puck with ring properties', () {
      const location = GeoPoint(lat: 9.0765, lng: 7.3986);
      final puck = GeoJsonBuilder.puck(location: location, ringRadius: 20);
      expect(puck['features'], hasLength(2));
      final ring = (puck['features'] as List).last as Map<String, dynamic>;
      expect(ring['properties'], {'radius': 20});
    });

    test('builds route polyline as LineString', () {
      final line = GeoJsonBuilder.routePolyline(const [
        GeoPoint(lat: 9.07, lng: 7.39),
        GeoPoint(lat: 9.08, lng: 7.41),
      ]);
      expect(line['geometry']['type'], 'LineString');
      expect(line['geometry']['coordinates'], hasLength(2));
    });

    test('builds ambient cells with stale flag', () {
      final geojson = GeoJsonBuilder.ambientCells(const [
        AmbientCell(
          center: GeoPoint(lat: 9.07, lng: 7.39),
          bucket: 5,
          count: 12,
          headingDegrees: 90,
          stale: true,
        ),
      ]);
      final feature = (geojson['features'] as List).single as Map;
      expect(feature['properties']['stale'], isTrue);
    });
  });

  group('AlongMapColors', () {
    test('uses design tokens for overlay colours', () {
      expect(AlongMapColors.puck, const Color(0xFFF7D117));
      expect(AlongMapColors.routeActive, const Color(0xFF0A0A0A));
      expect(AlongMapColors.clusterStroke, const Color(0xFFF7D117));
    });
  });

  group('MapPanBenchmark', () {
    test('computes p95 from injected frame timings', () {
      final timings = List.generate(
        100,
        (i) => Duration(microseconds: (10000000 + i * 1000).toInt()),
      );
      final result = MapPanBenchmarkResult.fromFrameTimes(
        timings,
        targetP95Ms: 16.7,
        stepCount: 30,
      );
      expect(result.frameCount, 100);
      expect(result.p95Ms, greaterThan(result.p50Ms));
      expect(result.p95Ms, lessThan(20000));
    });

    test('panLngOffset sweeps east-west across center', () {
      expect(
        MapPanBenchmark.panLngOffset(
          index: 0,
          stepCount: 30,
          centerLng: 7.4,
          spanDegrees: 0.2,
        ),
        closeTo(7.3, 0.001),
      );
      expect(
        MapPanBenchmark.panLngOffset(
          index: 29,
          stepCount: 30,
          centerLng: 7.4,
          spanDegrees: 0.2,
        ),
        closeTo(7.5, 0.001),
      );
    });
  });
}
