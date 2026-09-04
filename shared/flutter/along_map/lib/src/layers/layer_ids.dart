/// MapLibre source and layer identifiers for along-light overlays (doc 05 §8).
abstract final class AlongLayerIds {
  static const basemapSource = 'basemap';

  static const puckSource = 'along-puck';
  static const puckRingSource = 'along-puck-ring';
  static const parksSource = 'along-parks';
  static const stagesSource = 'along-stages';
  static const routeActiveSource = 'along-route-active';
  static const routeWalkSource = 'along-route-walk';
  static const ambientCellsSource = 'along-ambient-cells';
  static const vehicleSource = 'along-vehicle';

  static const puckLayer = 'along-puck';
  static const puckRingLayer = 'along-puck-ring';
  static const parksLayer = 'along-parks';
  static const stagesLayer = 'along-stages';
  static const routeActiveLayer = 'along-route-active';
  static const routeWalkLayer = 'along-route-walk-casing';
  static const ambientCellsLayer = 'along-ambient-cells';
  static const vehicleLayer = 'along-vehicle';

  static const allOverlaySources = [
    puckSource,
    puckRingSource,
    parksSource,
    stagesSource,
    routeActiveSource,
    routeWalkSource,
    ambientCellsSource,
    vehicleSource,
  ];

  static const allOverlayLayers = [
    routeWalkLayer,
    'along-route-active-casing',
    routeActiveLayer,
    ambientCellsLayer,
    'along-ambient-label',
    stagesLayer,
    parksLayer,
    puckRingLayer,
    puckLayer,
    vehicleLayer,
  ];
}
