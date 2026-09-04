import 'dart:math' as math;

import 'package:along_core/src/models/geo_point.dart';

const _earthRadiusM = 6371000.0;

/// Haversine distance in metres between two points.
double haversineDistanceM(GeoPoint a, GeoPoint b) {
  final lat1 = _toRadians(a.lat);
  final lat2 = _toRadians(b.lat);
  final dLat = _toRadians(b.lat - a.lat);
  final dLng = _toRadians(b.lng - a.lng);

  final sinLat = math.sin(dLat / 2);
  final sinLng = math.sin(dLng / 2);
  final h = sinLat * sinLat + math.cos(lat1) * math.cos(lat2) * sinLng * sinLng;
  return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
}

double _toRadians(double degrees) => degrees * math.pi / 180;
