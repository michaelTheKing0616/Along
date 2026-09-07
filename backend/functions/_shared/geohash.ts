import type { Point } from './types.ts';

const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/** GeoHash encode (matches mobile along_realtime geohash.dart). */
export function geohashEncode(point: Point, precision: number): string {
  if (precision <= 0 || precision > 12) {
    throw new RangeError('geohash precision must be 1..12');
  }

  let latMin = -90;
  let latMax = 90;
  let lngMin = -180;
  let lngMax = 180;

  let result = '';
  let bit = 0;
  let ch = 0;
  let isLng = true;

  while (result.length < precision) {
    if (isLng) {
      const mid = (lngMin + lngMax) / 2;
      if (point.lng >= mid) {
        ch = (ch << 1) + 1;
        lngMin = mid;
      } else {
        ch <<= 1;
        lngMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (point.lat >= mid) {
        ch = (ch << 1) + 1;
        latMin = mid;
      } else {
        ch <<= 1;
        latMax = mid;
      }
    }

    isLng = !isLng;
    bit++;
    if (bit === 5) {
      result += BASE32[ch];
      bit = 0;
      ch = 0;
    }
  }

  return result;
}
