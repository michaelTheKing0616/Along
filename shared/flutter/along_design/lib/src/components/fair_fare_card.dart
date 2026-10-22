import 'package:flutter/material.dart';

import '../tokens.g.dart';
import 'along_button.dart';

/// Crowd fare next to the offer. The dispute button records a reading.
class FairFareCard extends StatelessWidget {
  const FairFareCard({
    super.key,
    required this.title,
    required this.offeredLabel,
    required this.quietLabel,
    required this.disputeLabel,
    this.usualLabel,
    this.weatherReason,
    this.onDispute,
  });

  final String title;
  final String offeredLabel;
  final String quietLabel;
  final String disputeLabel;
  final String? usualLabel;
  final String? weatherReason;
  final VoidCallback? onDispute;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AlongColors.surface0,
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              key: const Key('fair_fare_title'),
              style: AlongText.heading2,
            ),
            const SizedBox(height: AlongSpace.s8),
            Text(offeredLabel, style: AlongText.bodyStrong),
            const SizedBox(height: AlongSpace.s4),
            Text(
              usualLabel ?? quietLabel,
              key: const Key('fair_fare_usual'),
              style: AlongText.body,
            ),
            if (weatherReason != null && weatherReason!.trim().isNotEmpty) ...[
              const SizedBox(height: AlongSpace.s8),
              Text(
                weatherReason!,
                key: const Key('fair_fare_weather'),
                style: AlongText.caption,
              ),
            ],
            const SizedBox(height: AlongSpace.s12),
            AlongButton(
              key: const Key('fair_fare_dispute'),
              label: disputeLabel,
              variant: AlongButtonVariant.secondary,
              onPressed: onDispute,
            ),
          ],
        ),
      ),
    );
  }
}
