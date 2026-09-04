import 'dart:math' as math;

import 'package:along_core/src/models/geo_point.dart';

/// Initial bearing from [from] to [to] in degrees (0 = north, clockwise).
double bearingDegrees(GeoPoint from, GeoPoint to) {
  final lat1 = _toRadians(from.lat);
  final lat2 = _toRadians(to.lat);
  final dLng = _toRadians(to.lng - from.lng);

  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  final bearing = math.atan2(y, x);
  return (_toDegrees(bearing) + 360) % 360;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
double _toDegrees(double radians) => radians * 180 / math.pi;
