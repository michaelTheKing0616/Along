import 'package:along_design/along_design.dart';
import 'package:along_map/src/constants/abuja.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Camera helpers using design-token motion duration (doc 07 §7).
abstract final class MapCamera {
  static CameraPosition forCenter({
    required double lat,
    required double lng,
    double zoom = AbujaMapConstants.defaultZoom,
  }) =>
      CameraPosition(
        target: LatLng(lat, lng),
        zoom: zoom,
      );

  /// Offline Abuja fixture tiles only — not for production map bootstrap.
  static CameraPosition abujaDefault() => forCenter(
        lat: AbujaMapConstants.centerLat,
        lng: AbujaMapConstants.centerLng,
      );

  static CameraUpdate recenter(LatLng target, {double zoom = 14}) =>
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      );

  static Duration get animationDuration => AlongMotion.camera;
}
