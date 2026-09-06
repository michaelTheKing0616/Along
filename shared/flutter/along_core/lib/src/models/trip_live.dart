import 'package:along_core/src/models/geo_point.dart';

/// Live position sample from [TripView.live] (doc 03 §5).
class LivePosition {
  const LivePosition({
    required this.lat,
    required this.lng,
    required this.ts,
    this.headingDegrees,
    this.speedMps,
  });

  final double lat;
  final double lng;
  final DateTime ts;
  final int? headingDegrees;
  final double? speedMps;

  GeoPoint get point => GeoPoint(lat: lat, lng: lng);

  factory LivePosition.fromJson(Map<String, dynamic> json) => LivePosition(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        ts: DateTime.parse(json['ts'] as String),
        headingDegrees: (json['heading'] as num?)?.toInt(),
        speedMps: (json['speed_mps'] as num?)?.toDouble(),
      );
}

/// Snapshot of live rider/driver positions on a trip.
class TripLiveSnapshot {
  const TripLiveSnapshot({
    required this.asOf,
    this.driver,
    this.rider,
  });

  final DateTime asOf;
  final LivePosition? driver;
  final LivePosition? rider;

  factory TripLiveSnapshot.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('live snapshot json is null');
    }
    return TripLiveSnapshot(
      asOf: DateTime.parse(json['as_of'] as String),
      driver: json['driver'] is Map<String, dynamic>
          ? LivePosition.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      rider: json['rider'] is Map<String, dynamic>
          ? LivePosition.fromJson(json['rider'] as Map<String, dynamic>)
          : null,
    );
  }
}
