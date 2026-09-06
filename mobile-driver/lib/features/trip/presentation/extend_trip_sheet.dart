import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:along_design/along_design.dart' as design show formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/trip/presentation/driver_destination_search_panel.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// D-17 Extend trip — search + FareHero + propose; rider response accept (doc 06).
class ExtendTripSheet extends ConsumerStatefulWidget {
  const ExtendTripSheet({
    super.key,
    required this.tripId,
    this.onProposed,
  });

  final String tripId;
  final VoidCallback? onProposed;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    VoidCallback? onProposed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExtendTripSheet(tripId: tripId, onProposed: onProposed),
    );
  }

  @override
  ConsumerState<ExtendTripSheet> createState() => _ExtendTripSheetState();
}

class _ExtendTripSheetState extends ConsumerState<ExtendTripSheet> {
  ProposeExtensionResult? _preview;
  String? _destinationName;
  Map<String, dynamic>? _newAlight;
  bool _busy = false;

  Future<void> _previewExtension(DriverDestinationPick pick) async {
    setState(() {
      _busy = true;
      _destinationName = pick.name;
      _newAlight = pick.toNewAlightPayload();
      _preview = null;
    });
    try {
      final result = await ref.read(tripsRepositoryProvider).proposeExtension(
            tripId: widget.tripId,
            newAlight: _newAlight!,
          );
      if (mounted) setState(() => _preview = result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _proposeToRider() async {
    widget.onProposed?.call();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AlongBottomSheet(
        size: AlongBottomSheetSize.full,
        title: l10n.extendTripTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DriverDestinationSearchPanel(
              hint: l10n.extendTripSearchHint,
              onDestinationSelected: _busy ? (_) {} : _previewExtension,
            ),
            if (_preview != null) ...[
              const SizedBox(height: AlongSpace.s16),
              Text(
                l10n.extendTripDestination(_destinationName ?? ''),
                style: AlongText.bodyStrong,
              ),
              const SizedBox(height: AlongSpace.s8),
              FareHero(
                key: const Key('driver_extend_fare_hero'),
                amountNaira: _preview!.newTotal.minorUnits ~/ 100,
                deltaNaira: _preview!.fareDelta.minorUnits ~/ 100,
              ),
              const SizedBox(height: AlongSpace.s16),
              AlongButton(
                key: const Key('driver_extend_propose'),
                label: l10n.extendTripPropose,
                visualState: _busy
                    ? AlongButtonVisualState.loading
                    : AlongButtonVisualState.normal,
                onPressed: _busy || _newAlight == null ? null : _proposeToRider,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Incoming rider extension — 1-tap accept (D-17).
class IncomingRiderExtensionSheet extends ConsumerWidget {
  const IncomingRiderExtensionSheet({
    super.key,
    required this.proposal,
    this.onResponded,
  });

  final TripExtensionProposal proposal;
  final ValueChanged<TripSummary?>? onResponded;

  static Future<void> show(
    BuildContext context, {
    required TripExtensionProposal proposal,
    ValueChanged<TripSummary?>? onResponded,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomingRiderExtensionSheet(
        proposal: proposal,
        onResponded: onResponded,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deltaNaira = proposal.fareDelta.minorUnits ~/ 100;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AlongBottomSheet(
        size: AlongBottomSheetSize.half,
        title: l10n.incomingExtensionTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.incomingRiderExtensionBody(
                proposal.destinationName,
                design.formatMoney(deltaNaira),
              ),
              style: AlongText.body,
            ),
            const SizedBox(height: AlongSpace.s16),
            Row(
              children: [
                Expanded(
                  child: AlongButton(
                    key: const Key('driver_extension_decline'),
                    label: l10n.incomingExtensionDecline,
                    variant: AlongButtonVariant.secondary,
                    onPressed: () async {
                      await ref.read(tripsRepositoryProvider).respondExtension(
                            extensionId: proposal.extensionId,
                            response: 'decline',
                          );
                      if (context.mounted) {
                        onResponded?.call(null);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                const SizedBox(width: AlongSpace.s8),
                Expanded(
                  child: AlongButton(
                    key: const Key('driver_extension_accept'),
                    label: l10n.incomingExtensionAccept,
                    variant: AlongButtonVariant.yellow,
                    onPressed: () async {
                      final updated = await ref
                          .read(tripsRepositoryProvider)
                          .respondExtension(
                            extensionId: proposal.extensionId,
                            response: 'accept',
                          );
                      if (context.mounted) {
                        onResponded?.call(updated);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
