import 'package:along_core/along_core.dart';

/// Builds GeoJSON FeatureCollections for along_map overlay sources.
abstract final class GeoJsonBuilder {
  static Map<String, dynamic> emptyCollection() => const {
        'type': 'FeatureCollection',
        'features': <Map<String, dynamic>>[],
      };

  static Map<String, dynamic> pointFeature({
    required GeoPoint location,
    Map<String, dynamic>? properties,
  }) =>
      {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [location.lng, location.lat],
        },
        if (properties != null) 'properties': properties,
      };

  static Map<String, dynamic> lineFeature({
    required List<GeoPoint> coordinates,
    Map<String, dynamic>? properties,
  }) =>
      {
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            for (final p in coordinates) [p.lng, p.lat],
          ],
        },
        if (properties != null) 'properties': properties,
      };

  static Map<String, dynamic> puck({
    required GeoPoint location,
    double ringRadius = 16,
  }) =>
      {
        'type': 'FeatureCollection',
        'features': [
          pointFeature(location: location),
          pointFeature(
            location: location,
            properties: {'radius': ringRadius},
          ),
        ],
      };

  static Map<String, dynamic> parks(List<ParkFeature> parks) => {
        'type': 'FeatureCollection',
        'features': [
          for (final park in parks)
            pointFeature(
              location: park.location,
              properties: {'name': park.name, 'id': park.id},
            ),
        ],
      };

  static Map<String, dynamic> stages(List<GeoPoint> stages) => {
        'type': 'FeatureCollection',
        'features': [
          for (var i = 0; i < stages.length; i++)
            pointFeature(
              location: stages[i],
              properties: {'sequence': i},
            ),
        ],
      };

  static Map<String, dynamic> routePolyline(List<GeoPoint> coordinates) =>
      lineFeature(coordinates: coordinates);

  static Map<String, dynamic> ambientCells(List<AmbientCell> cells) => {
        'type': 'FeatureCollection',
        'features': [
          for (final cell in cells)
            pointFeature(
              location: cell.center,
              properties: {
                'bucket': cell.bucket,
                'count': cell.count,
                'heading': cell.headingDegrees ?? 0,
              },
            ),
        ],
      };

  static Map<String, dynamic> vehicle({
    required GeoPoint location,
    required String modeIcon,
    double? headingDegrees,
  }) =>
      {
        'type': 'FeatureCollection',
        'features': [
          pointFeature(
            location: location,
            properties: {
              'mode-icon': modeIcon,
              'heading': headingDegrees ?? 0,
            },
          ),
        ],
      };
}

/// Named park marker for the parks layer.
class ParkFeature {
  const ParkFeature({
    required this.id,
    required this.name,
    required this.location,
  });

  final String id;
  final String name;
  final GeoPoint location;
}

/// Ambient demand cell (Tier A — no precise vehicle identity).
class AmbientCell {
  const AmbientCell({
    required this.center,
    required this.bucket,
    required this.count,
    this.headingDegrees,
  });

  final GeoPoint center;
  final int bucket;
  final int count;
  final double? headingDegrees;
}
