import 'package:along_core/along_core.dart';

/// Encodes [point] as a geohash string at [precision] (doc 03 §2 ambient channels).
String geohashEncode(GeoPoint point, {required int precision}) {
  assert(precision > 0 && precision <= 12);

  const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  var latMin = -90.0;
  var latMax = 90.0;
  var lngMin = -180.0;
  var lngMax = 180.0;

  final buffer = StringBuffer();
  var bit = 0;
  var ch = 0;
  var isLng = true;

  while (buffer.length < precision) {
    if (isLng) {
      final mid = (lngMin + lngMax) / 2;
      if (point.lng >= mid) {
        ch = (ch << 1) + 1;
        lngMin = mid;
      } else {
        ch = (ch << 1);
        lngMax = mid;
      }
    } else {
      final mid = (latMin + latMax) / 2;
      if (point.lat >= mid) {
        ch = (ch << 1) + 1;
        latMin = mid;
      } else {
        ch = (ch << 1);
        latMax = mid;
      }
    }

    isLng = !isLng;
    bit++;
    if (bit == 5) {
      buffer.write(base32[ch]);
      bit = 0;
      ch = 0;
    }
  }

  return buffer.toString();
}

/// Topic suffix for ambient Realtime: `{city_slug}:{geohash5}`.
String ambientChannelTopic({
  required String citySlug,
  required GeoPoint location,
}) {
  return '$citySlug:${geohashEncode(location, precision: 5)}';
}
