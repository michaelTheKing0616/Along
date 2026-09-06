import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:along_design/along_design.dart' as design show formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/domain/trip_ui_helpers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-15 Extend trip — rider-initiated search/stage pick + driver proposal accept.
class ExtendTripSheet extends ConsumerStatefulWidget {
  const ExtendTripSheet({
    super.key,
    required this.trip,
    this.onSent,
  });

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
  final _controller = TextEditingController();
  ProposeExtensionResult? _preview;
  String? _destinationName;
  Map<String, dynamic>? _newAlight;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _previewExtension(String name, Map<String, dynamic> alight) async {
    setState(() {
      _busy = true;
      _destinationName = name;
      _newAlight = alight;
    });
    try {
      final result = await ref.read(tripsRepositoryProvider).proposeExtension(
            tripId: widget.trip.tripId,
            newAlight: alight,
          );
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
    final places = ref.watch(_extendPlacesProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AlongBottomSheet(
        size: AlongBottomSheetSize.full,
        title: l10n.extendTripTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchField(
              variant: SearchFieldVariant.full,
              hint: l10n.extendTripSearchHint,
              controller: _controller,
              onChanged: (_) => setState(() => _preview = null),
            ),
            const SizedBox(height: AlongSpace.s12),
            ...places.map(
              (place) => ListTile(
                key: Key('extend_place_${place.name}'),
                title: Text(place.name),
                onTap: _busy
                    ? null
                    : () => _previewExtension(place.name, place.alight),
              ),
            ),
            if (_preview != null) ...[
              const SizedBox(height: AlongSpace.s16),
              Text(
                l10n.extendTripDestination(_destinationName ?? ''),
                style: AlongText.bodyStrong,
              ),
              const SizedBox(height: AlongSpace.s8),
              FareHero(
                key: const Key('extend_fare_hero'),
                amountNaira: _preview!.newTotal.minorUnits ~/ 100,
                deltaNaira: _preview!.fareDelta.minorUnits ~/ 100,
                tier: designFareTier(
                  _preview!.tier,
                  unconfirmed: _preview!.unconfirmed,
                ),
              ),
              const SizedBox(height: AlongSpace.s16),
              AlongButton(
                key: const Key('extend_send_to_driver'),
                label: l10n.extendTripSend,
                visualState: _busy
                    ? AlongButtonVisualState.loading
                    : AlongButtonVisualState.normal,
                onPressed: _busy || _newAlight == null ? null : _sendToDriver,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExtendPlace {
  const _ExtendPlace({required this.name, required this.alight});

  final String name;
  final Map<String, dynamic> alight;
}

final _extendPlacesProvider = Provider<List<_ExtendPlace>>((ref) {
  return const [
    _ExtendPlace(
      name: 'Wuse Market',
      alight: {
        'stage_id': 's-wuse',
        'name': 'Wuse Market',
        'lat': 9.07,
        'lng': 7.48,
      },
    ),
    _ExtendPlace(
      name: 'Area 1 Park',
      alight: {
        'stage_id': 's-area1',
        'name': 'Area 1 Park',
        'lat': 9.05,
        'lng': 7.45,
      },
    ),
  ];
});

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
              l10n.incomingExtensionBody(
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
                    key: const Key('extension_decline'),
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
                    key: const Key('extension_accept'),
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
