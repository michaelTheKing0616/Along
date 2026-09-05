import 'package:flutter/material.dart';

import '../tokens.g.dart';

/// Fare verification tier (doc 05 §9 `TierPill`, FM8).
enum FareTier { verified, crowd, candidate, estimate }

extension FareTierTokens on FareTier {
  Color get dotColor => switch (this) {
        FareTier.verified => AlongColors.tierVerified,
        FareTier.crowd => AlongColors.tierCrowd,
        FareTier.candidate => AlongColors.tierCandidate,
        FareTier.estimate => AlongColors.tierEstimate,
      };

  String get label => switch (this) {
        FareTier.verified => 'Standard fare',
        FareTier.crowd => 'Community fare',
        FareTier.candidate => 'Unconfirmed',
        FareTier.estimate => 'Estimate — agree price',
      };
}
