/// Aggregate context for FM39-compliant sponsored placement resolution.
enum PlacementContextType {
  destination('destination'),
  park('park'),
  corridor('corridor');

  const PlacementContextType(this.rpcValue);

  final String rpcValue;

  static PlacementContextType? tryParse(String? raw) {
    if (raw == null) return null;
    for (final value in PlacementContextType.values) {
      if (value.rpcValue == raw) return value;
    }
    return null;
  }
}

class PlacementContext {
  const PlacementContext({
    required this.type,
    required this.targetReference,
    this.deploymentId,
  });

  final PlacementContextType type;
  final String targetReference;
  final String? deploymentId;
}

/// Resolved sponsored placement row from `resolve_sponsored_placements`.
class SponsoredPlacement {
  const SponsoredPlacement({
    required this.id,
    required this.contextType,
    required this.targetReference,
    required this.advertiser,
    required this.content,
  });

  final String id;
  final PlacementContextType contextType;
  final String targetReference;
  final String advertiser;
  final Map<String, dynamic> content;

  String? get headline => content['headline'] as String?;
  String? get body => content['body'] as String?;
  String? get ctaLabel => content['cta_label'] as String?;
  String? get ctaUrl => content['cta_url'] as String?;

  factory SponsoredPlacement.fromJson(Map<String, dynamic> json) {
    return SponsoredPlacement(
      id: json['id'] as String,
      contextType: PlacementContextType.tryParse(json['context_type'] as String?) ??
          PlacementContextType.park,
      targetReference: json['target_reference'] as String,
      advertiser: json['advertiser'] as String? ?? '',
      content: (json['content'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Keys that must never appear in placement RPC payloads (FM39).
const placementForbiddenRequestKeys = {
  'rider_id',
  'p_rider_id',
  'phone',
  'p_phone',
  'trip_id',
  'p_trip_id',
  'query_id',
  'p_query_id',
  'history',
  'p_history',
  'profile_id',
  'p_profile_id',
  'user_id',
  'p_user_id',
};
