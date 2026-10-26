import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';

/// The drawn trip map with the vehicle placed on the route.
///
/// [vehicle] is the last live fix; the marker sits at its share of the way
/// from [from] to [to]. Without a fix it waits at [from].
class VehicleMarkerPanel extends StatelessWidget {
  const VehicleMarkerPanel({
    super.key,
    required this.from,
    required this.to,
    this.vehicle,
    this.fromLabel,
    this.toLabel,
    this.summary,
    this.modeCode = 'taxi',
    this.semanticLabel,
    this.topInset = 88,
    this.bottomInset = 0,
  });

  final GeoPoint? from;
  final GeoPoint? to;
  final GeoPoint? vehicle;
  final String? fromLabel;
  final String? toLabel;
  final String? summary;
  final String modeCode;
  final String? semanticLabel;
  final double topInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return AlongRoutePreview(
      pickup: lngLat(from),
      drop: lngLat(to),
      from: fromLabel,
      to: toLabel,
      summary: summary,
      semanticLabel: semanticLabel,
      vehicleAt: progressBetween(from, to, vehicle) ?? 0,
      vehicleIcon: tripModeIcon(modeCode),
      vehicleKey: const Key('vehicle_direction_arrow'),
      topInset: topInset,
      bottomInset: bottomInset,
    );
  }
}
