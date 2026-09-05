import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' as dto;
import 'package:along_map/along_map.dart' as map_geo;

/// Maps Tier A ambient API cells to map overlay cells (no vehicle identity).
abstract final class AmbientCellMapper {
  static List<map_geo.AmbientCell> toMapCells({
    required List<dto.AmbientCell> apiCells,
    required DateTime asOf,
    required int staleAfterS,
    required DateTime now,
  }) {
    final stale = now.difference(asOf).inSeconds > staleAfterS;
    return [
      for (final cell in apiCells)
        map_geo.AmbientCell(
          center: GeoPoint(
            lat: cell.centroid.lat,
            lng: cell.centroid.lng,
          ),
          bucket: _bucketRadius(cell.count_bucket),
          count: _bucketCount(cell.count_bucket),
          headingDegrees: _dominantHeading(cell.heading_sectors),
          stale: stale,
        ),
    ];
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

/// Tracks which map overlay layers the home screen populates (for tests).
enum HomeMapOverlayLayer {
  puck,
  ambientCells,
  parks,
  stages,
  routeActive,
  routeWalk,
}

abstract final class HomeMapLayerPolicy {
  static const allowedLayers = {
    HomeMapOverlayLayer.puck,
    HomeMapOverlayLayer.ambientCells,
    HomeMapOverlayLayer.parks,
    HomeMapOverlayLayer.stages,
  };

  static bool isVehicleLayerAllowed(Set<HomeMapOverlayLayer> layers) => false;
}
