/// Boarding stop on a trip (doc 03 §5 TripView.board).
class TripBoardStop {
  const TripBoardStop({
    required this.name,
    this.walkM = 0,
    this.walkS = 0,
  });

  final String name;
  final int walkM;
  final int walkS;
}

/// Alighting stop on a trip (doc 03 §5 TripView.alight).
class TripAlightStop {
  const TripAlightStop({required this.name});

  final String name;
}
