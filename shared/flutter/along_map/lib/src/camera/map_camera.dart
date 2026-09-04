import 'package:along_design/along_design.dart';
import 'package:along_map/src/constants/abuja.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Camera helpers using design-token motion duration (doc 07 §7).
abstract final class MapCamera {
  static CameraPosition abujaDefault() => const CameraPosition(
        target: LatLng(
          AbujaMapConstants.centerLat,
          AbujaMapConstants.centerLng,
        ),
        zoom: AbujaMapConstants.defaultZoom,
      );

  static CameraUpdate recenter(LatLng target, {double zoom = 14}) =>
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      );

  static Duration get animationDuration => AlongMotion.camera;
}
