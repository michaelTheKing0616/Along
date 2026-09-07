import 'package:along_core/along_core.dart';
import 'package:along_data/src/cache/filters_hash.dart';
import 'package:along_realtime/along_realtime.dart';

/// Cache key for [PlanCache] — origin geohash7 + destination geohash7 + filters hash.
String planCacheKey({
  required GeoPoint origin,
  required GeoPoint destination,
  required Map<String, dynamic> filters,
}) {
  final originGh = geohashEncode(origin, precision: 7);
  final destGh = geohashEncode(destination, precision: 7);
  final filterKey = filtersHash(filters);
  return '$originGh:$destGh:$filterKey';
}
