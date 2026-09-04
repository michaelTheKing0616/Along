/// Parsed FCM data message (driver request TTL 25 s per ADR-0011).
class PushMessage {
  const PushMessage({
    required this.type,
    required this.data,
    this.tripId,
    this.collapseKey,
  });

  final String type;
  final Map<String, String> data;
  final String? tripId;
  final String? collapseKey;

  factory PushMessage.fromData(Map<String, dynamic> raw) {
    final data = raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    return PushMessage(
      type: data['type'] ?? 'unknown',
      data: data,
      tripId: data['trip_id'],
      collapseKey: data['collapse_key'],
    );
  }

  bool get isDriverRequest => type == 'trip_request';
}
