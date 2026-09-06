/// Active settlement agent near the driver (D-20).
class NearbySettlementAgent {
  const NearbySettlementAgent({
    required this.id,
    required this.businessName,
    required this.distanceM,
  });

  final String id;
  final String businessName;
  final int distanceM;

  factory NearbySettlementAgent.fromJson(Map<String, dynamic> json) {
    return NearbySettlementAgent(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      distanceM: (json['distance_m'] as num).round(),
    );
  }
}
