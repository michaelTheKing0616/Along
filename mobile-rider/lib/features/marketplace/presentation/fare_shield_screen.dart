import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

class FareShieldArgs {
  const FareShieldArgs({
    required this.offeredLabel,
    this.usualLabel,
    this.weatherReason,
    this.window,
    this.history = const {},
    this.onDispute,
  });

  final String offeredLabel;
  final String? usualLabel;
  final String? weatherReason;
  final AnchoredWindow? window;
  final Map<int, String> history;
  final VoidCallback? onDispute;
}

/// Usual fare, one anchored counter, and the hour-by-hour crowd median.
class FareShieldScreen extends StatelessWidget {
  const FareShieldScreen({super.key, required this.args});

  final FareShieldArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final window = args.window;
    final hours = args.history.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fareShieldTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AlongSpace.s16),
        children: [
          if (window != null)
            Text(
              l10n.fareShieldAnchored(window.timeoutSeconds),
              key: const Key('fare_shield_anchored'),
              style: AlongText.body,
            ),
          FairFareCard(
            title: l10n.fareShieldTitle,
            offeredLabel: args.offeredLabel,
            usualLabel: args.usualLabel,
            quietLabel: l10n.fareShieldQuiet,
            disputeLabel: l10n.fareShieldDispute,
            weatherReason: args.weatherReason,
            onDispute: args.onDispute,
          ),
          if (hours.isNotEmpty) ...[
            const SizedBox(height: AlongSpace.s16),
            Text(l10n.fareHistoryTitle, style: AlongText.overline),
            for (final hour in hours)
              Text(
                l10n.fareHistoryRow(hour, args.history[hour] ?? ''),
                key: Key('fare_history_$hour'),
                style: AlongText.body,
              ),
          ],
        ],
      ),
    );
  }
}
