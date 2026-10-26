import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/tenant/tenant_providers.dart';
import 'package:mobile_rider/features/search/presentation/destination_search_panel.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-15 Extend trip — rider-initiated R-06 search + driver proposal accept.
class ExtendTripSheet extends ConsumerStatefulWidget {
  const ExtendTripSheet({super.key, required this.trip, this.onSent});

  final TripSummary trip;
  final VoidCallback? onSent;

  static Future<void> show(
    BuildContext context, {
    required TripSummary trip,
    VoidCallback? onSent,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExtendTripSheet(trip: trip, onSent: onSent),
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

  Future<void> _previewExtension(DestinationPick pick) async {
    setState(() {
      _busy = true;
      _destinationName = pick.name;
      _newAlight = pick.toNewAlightPayload();
      _preview = null;
    });
    try {
      final result = await ref
          .read(tripsRepositoryProvider)
          .proposeExtension(tripId: widget.trip.tripId, newAlight: _newAlight!);
      if (mounted) setState(() => _preview = result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendToDriver() async {
    widget.onSent?.call();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final preview = _preview;
    final delta = preview == null ? 0 : majorUnits(preview.fareDelta);
    return TripModalSheet(
      title: l10n.extendTripTitle,
      icon: AlongIcons.addTime,
      footer: preview == null
          ? null
          : AlongButton(
              key: const Key('extend_send_to_driver'),
              label: l10n.extendTripSend,
              visualState: _busy
                  ? AlongButtonVisualState.loading
                  : AlongButtonVisualState.normal,
              onPressed: _busy || _newAlight == null ? null : _sendToDriver,
            ),
      children: [
        if (preview == null)
          DestinationSearchPanel(
            embedded: true,
            hint: l10n.extendTripSearchHint,
            onDestinationSelected: _busy ? (_) {} : _previewExtension,
          )
        else ...[
          Material(
            color: p.recessed,
            shape: AlongCraft.border(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('extend_change_destination'),
              onTap: _busy
                  ? null
                  : () => setState(() {
                      _preview = null;
                      _newAlight = null;
                    }),
              child: Padding(
                padding: const EdgeInsets.all(AlongSpace.s12),
                child: Row(
                  children: [
                    AlongIcon(AlongIcons.mapPin, size: 20, color: p.ink),
                    const SizedBox(width: AlongSpace.s12),
                    Expanded(
                      child: Text(
                        l10n.extendTripDestination(_destinationName ?? ''),
                        style: AlongType.label(p),
                      ),
                    ),
                    Text(l10n.payDriverChangeMethod, style: AlongType.label(p)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AlongSpace.s12),
          TripPanel(
            key: const Key('extend_fare_hero'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.extendTripNowFare,
                        style: AlongType.body(p),
                      ),
                    ),
                    Text(
                      formatAppMoney(ref, preview.newTotal - preview.fareDelta),
                      style: AlongType.body(p),
                    ),
                  ],
                ),
                const SizedBox(height: AlongSpace.s8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.receiptExtension,
                        style: AlongType.body(p),
                      ),
                    ),
                    Text(
                      '${delta >= 0 ? '+' : '−'}${formatAppMoneyMajor(ref, delta.abs())}',
                      style: AlongType.body(p),
                    ),
                  ],
                ),
                Divider(height: AlongSpace.s24, color: p.line),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.extendTripNewTotal,
                        style: AlongType.title(p),
                      ),
                    ),
                    Text(
                      formatAppMoney(ref, preview.newTotal),
                      style: AlongType.display(p).copyWith(fontSize: 28),
                    ),
                  ],
                ),
                const SizedBox(height: AlongSpace.s4),
                Text(
                  l10n.extendTripDriverConfirms,
                  style: AlongType.caption(p),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Incoming driver extension proposal — 1-tap accept (R-15).
class IncomingExtensionSheet extends ConsumerWidget {
  const IncomingExtensionSheet({
    super.key,
    required this.trip,
    required this.proposal,
    this.onResponded,
  });

  final TripSummary trip;
  final TripExtensionProposal proposal;
  final ValueChanged<TripSummary?>? onResponded;

  static Future<void> show(
    BuildContext context, {
    required TripSummary trip,
    required TripExtensionProposal proposal,
    ValueChanged<TripSummary?>? onResponded,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomingExtensionSheet(
        trip: trip,
        proposal: proposal,
        onResponded: onResponded,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deltaNaira = majorUnits(proposal.fareDelta);

    return TripModalSheet(
      title: l10n.incomingExtensionTitle,
      icon: AlongIcons.addTime,
      footer: Row(
        children: [
          Expanded(
            child: AlongButton(
              key: const Key('extension_decline'),
              label: l10n.incomingExtensionDecline,
              variant: AlongButtonVariant.secondary,
              onPressed: () async {
                await ref
                    .read(tripsRepositoryProvider)
                    .respondExtension(
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
              key: const Key('extension_accept'),
              label: l10n.incomingExtensionAccept,
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
      children: [
        Text(
          l10n.incomingExtensionBody(
            proposal.destinationName,
            formatAppMoneyMajor(ref, deltaNaira),
          ),
          style: AlongType.body(AlongPalette.of(context)),
        ),
      ],
    );
  }
}
