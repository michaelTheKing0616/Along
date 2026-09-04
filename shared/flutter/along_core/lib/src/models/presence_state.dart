import 'package:along_core/src/enums/transport_mode.dart';
import 'package:along_core/src/models/geo_point.dart';

/// Driver presence snapshot for client-side display logic.
class PresenceState {
  const PresenceState({
    required this.driverId,
    required this.mode,
    required this.status,
    required this.location,
    required this.updatedAt,
    this.headingDegrees,
  });

  final String driverId;
  final TransportMode mode;
  final String status;
  final GeoPoint location;
  final DateTime updatedAt;
  final double? headingDegrees;

  bool get isOnline => status != 'offline';
  bool get isRoaming => status.startsWith('roaming');
}
