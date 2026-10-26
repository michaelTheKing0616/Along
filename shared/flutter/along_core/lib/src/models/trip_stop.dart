import 'package:along_core/src/models/geo_point.dart';

/// Boarding stop on a trip (doc 03 §5 TripView.board).
class TripBoardStop {
  const TripBoardStop({
    required this.name,
    this.location,
    this.walkM = 0,
    this.walkS = 0,
  });

  final String name;
  final GeoPoint? location;
  final int walkM;
  final int walkS;
}

/// Alighting stop on a trip (doc 03 §5 TripView.alight).
class TripAlightStop {
  const TripAlightStop({required this.name, this.location});

  final String name;
  final GeoPoint? location;
}
