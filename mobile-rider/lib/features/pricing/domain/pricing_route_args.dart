import 'package:along_core/along_core.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_helpers.dart';

/// Route args for R-16 Along Pricing sheet.
class PricingRouteArgs {
  const PricingRouteArgs({
    required this.context,
    required this.from,
    required this.to,
    required this.clientRef,
    this.destinationLabel,
    this.candidateToken,
    this.driverId,
    this.extensionDeltaNaira,
    this.hailIntent,
  });

  final String context;
  final GeoPoint from;
  final GeoPoint to;
  final String clientRef;
  final String? destinationLabel;
  final String? candidateToken;
  final String? driverId;
  final int? extensionDeltaNaira;
  final HailIntent? hailIntent;
}

enum PricingTerminalKind {
  none,
  lapsedTimeout,
  lapsedOutOfRange,
  declined,
}
