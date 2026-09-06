import 'package:along_core/src/enums/fare_tier.dart';
import 'package:along_core/src/value/money.dart';

/// Result of `propose_extension` (doc 03 §5).
class ProposeExtensionResult {
  const ProposeExtensionResult({
    required this.extensionId,
    required this.fareDelta,
    required this.newTotal,
    required this.tier,
    required this.unconfirmed,
  });

  final String extensionId;
  final Money fareDelta;
  final Money newTotal;
  final FareTier tier;
  final bool unconfirmed;
}
