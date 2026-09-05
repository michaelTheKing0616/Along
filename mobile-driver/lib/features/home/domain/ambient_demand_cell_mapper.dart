import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' as dto;
import 'package:along_map/along_map.dart' as map_geo;

/// Maps Tier A ambient demand cells to map overlay discs (no rider identity).
abstract final class AmbientDemandCellMapper {
  static List<map_geo.AmbientCell> toMapCells({
    required List<dto.AmbientDemandCell> apiCells,
  }) {
    return [
      for (final cell in apiCells)
        map_geo.AmbientCell(
          center: GeoPoint(
            lat: cell.centroid.lat,
            lng: cell.centroid.lng,
          ),
          bucket: _bucketRadius(cell.searches_last_15m_bucket),
          count: _bucketCount(cell.searches_last_15m_bucket),
          headingDegrees: _dominantHeading(cell.top_destination_directions),
          stale: false,
        ),
    ];
  }

  static String labelForCell({
    required dto.AmbientDemandCell cell,
    String? areaName,
  }) {
    final searches = cell.searches_last_15m_bucket.replaceAll('+', '+ ');
    final heading = headingLabel(_dominantHeading(cell.top_destination_directions));
    final place = areaName ?? 'here';
    if (heading.isEmpty) {
      return '$searches searches near $place';
    }
    return '$searches searches near $place → $heading';
  }

  static int _bucketRadius(String bucket) => switch (bucket) {
        '1-2' => 1,
        '3-5' => 5,
        '6+' => 10,
        _ => 3,
      };

  static int _bucketCount(String bucket) => switch (bucket) {
        '1-2' => 2,
        '3-5' => 4,
        '6+' => 8,
        _ => 1,
      };

  static double? _dominantHeading(List<int> sectors) {
    if (sectors.isEmpty) return null;
    var bestIndex = 0;
    var bestCount = -1;
    for (var i = 0; i < sectors.length; i++) {
      if (sectors[i] > bestCount) {
        bestCount = sectors[i];
        bestIndex = i;
      }
    }
    if (bestCount <= 0) return null;
    return bestIndex * 45.0;
  }

  static String headingLabel(double? degrees) {
    if (degrees == null) return '';
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) / 45).floor() % 8;
    return labels[index];
  }
}
