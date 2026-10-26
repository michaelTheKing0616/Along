/// One live ETA payload for pickup, the trip, and each remaining stop.
class TripEtaValue {
  const TripEtaValue({
    required this.kind,
    required this.lowS,
    required this.highS,
    required this.label,
  });

  final String kind;
  final int lowS;
  final int highS;
  final String label;

  static TripEtaValue? fromJson(Object? json) {
    if (json is! Map) return null;
    final label = json['label'];
    final low = json['low_s'];
    final high = json['high_s'];
    if (label is! String || low is! num || high is! num) return null;
    return TripEtaValue(
      kind: json['kind'] as String? ?? 'single',
      lowS: low.toInt(),
      highS: high.toInt(),
      label: label,
    );
  }
}

class TripEtaStop {
  const TripEtaStop({
    required this.id,
    required this.name,
    required this.state,
    required this.label,
  });

  final String id;
  final String name;
  final String state;
  final String label;

  static TripEtaStop? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    final state = json['state'];
    final label = json['label'];
    if (id is! String ||
        name is! String ||
        state is! String ||
        label is! String) {
      return null;
    }
    return TripEtaStop(id: id, name: name, state: state, label: label);
  }
}

class TripEta {
  const TripEta({
    required this.status,
    required this.stops,
    required this.updatedAt,
    this.pickup,
    this.trip,
  });

  final String status;
  final TripEtaValue? pickup;
  final TripEtaValue? trip;
  final List<TripEtaStop> stops;
  final DateTime updatedAt;

  bool get isReady => status == 'ready';

  /// Trip label, then pickup. Null until the estimator has a number, so
  /// callers show their own localised "calculating" copy.
  String? get headline {
    if (!isReady) return null;
    return trip?.label ?? pickup?.label;
  }

  /// Driver sheet line. Pickup and the remaining trip share this payload.
  /// [pickupLine] localises the pickup part. Null while calculating.
  String? driverLine(String Function(String label) pickupLine) {
    if (!isReady) return null;
    final parts = <String>[
      if (pickup != null) pickupLine(pickup!.label),
      if (trip != null) trip!.label,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static TripEta? fromJson(Object? json) {
    if (json is! Map) return null;
    final status = json['status'];
    if (status is! String) return null;
    final updated = json['updated_at'];
    final stopsJson = json['stops'];
    final stops = <TripEtaStop>[];
    if (stopsJson is List) {
      for (final item in stopsJson) {
        final stop = TripEtaStop.fromJson(item);
        if (stop != null) stops.add(stop);
      }
    }
    return TripEta(
      status: status,
      pickup: TripEtaValue.fromJson(json['pickup']),
      trip: TripEtaValue.fromJson(json['trip']),
      stops: stops,
      updatedAt: updated is String
          ? DateTime.tryParse(updated) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
