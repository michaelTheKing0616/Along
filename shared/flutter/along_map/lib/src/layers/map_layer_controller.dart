import 'package:along_core/along_core.dart';
import 'package:along_map/src/geojson/geojson_builder.dart';
import 'package:along_map/src/layers/layer_ids.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Updates along overlay GeoJSON sources on a MapLibre controller.
class MapLayerController {
  MapLayerController(this._controller);

  final MapLibreMapController _controller;

  Future<void> setPuck(GeoPoint location, {double ringRadius = 16}) async {
    await _controller.setGeoJsonSource(
      AlongLayerIds.puckSource,
      GeoJsonBuilder.pointFeature(location: location),
    );
    await _controller.setGeoJsonSource(
      AlongLayerIds.puckRingSource,
      GeoJsonBuilder.pointFeature(
        location: location,
        properties: {'radius': ringRadius},
      ),
    );
  }

  Future<void> clearPuck() async {
    await _controller.setGeoJsonSource(
      AlongLayerIds.puckSource,
      GeoJsonBuilder.emptyCollection(),
    );
    await _controller.setGeoJsonSource(
      AlongLayerIds.puckRingSource,
      GeoJsonBuilder.emptyCollection(),
    );
  }

  Future<void> setParks(List<ParkFeature> parks) async {
    await _controller.setGeoJsonSource(
      AlongLayerIds.parksSource,
      GeoJsonBuilder.parks(parks),
    );
  }

  Future<void> setStages(List<GeoPoint> stages) async {
    await _controller.setGeoJsonSource(
      AlongLayerIds.stagesSource,
      GeoJsonBuilder.stages(stages),
    );
  }

  Future<void> setActiveRoute(List<GeoPoint> coordinates) async {
    await _controller.setGeoJsonSource(
      AlongLayerIds.routeActiveSource,
      GeoJsonBuilder.routePolyline(coordinates),
    );
  }

  Future<void> setWalkRoute(List<GeoPoint> coordinates) async {
    await _controller.setGeoJsonSource(
      AlongLayerIds.routeWalkSource,
      GeoJsonBuilder.routePolyline(coordinates),
    );
  }

  Future<void> setAmbientCells(List<AmbientCell> cells) async {
    await _controller.setGeoJsonSource(
      AlongLayerIds.ambientCellsSource,
      GeoJsonBuilder.ambientCells(cells),
    );
  }

  Future<void> setVehicle({
    required GeoPoint location,
    required TransportMode mode,
    double? headingDegrees,
  }) async {
    await _controller.setGeoJsonSource(
      AlongLayerIds.vehicleSource,
      GeoJsonBuilder.vehicle(
        location: location,
        modeIcon: _modeIconName(mode),
        headingDegrees: headingDegrees,
      ),
    );
  }

  Future<void> clearVehicle() async {
    await _controller.setGeoJsonSource(
      AlongLayerIds.vehicleSource,
      GeoJsonBuilder.emptyCollection(),
    );
  }

  static String _modeIconName(TransportMode mode) => switch (mode) {
        TransportMode.car => 'mode-car',
        TransportMode.keke => 'mode-keke',
        TransportMode.okada => 'mode-okada',
        TransportMode.minibus => 'mode-minibus',
      };
}
