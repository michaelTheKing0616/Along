import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// R-25 Share trip — create link, copy/share, list active shares, revoke.
class ShareTripSheet extends ConsumerStatefulWidget {
  const ShareTripSheet({super.key, required this.journeyId});

  final String journeyId;

  static Future<void> show(BuildContext context, {required String journeyId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareTripSheet(journeyId: journeyId),
    );
  }

  @override
  ConsumerState<ShareTripSheet> createState() => _ShareTripSheetState();
}

class _ShareTripSheetState extends ConsumerState<ShareTripSheet> {
  List<TripShareRow> _shares = const [];
  String? _latestUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshShares();
  }

  Future<void> _refreshShares() async {
    final shares = await ref
        .read(safetyRepositoryProvider)
        .listActiveShares(widget.journeyId);
    if (mounted) setState(() => _shares = shares);
  }

  Future<void> _createShare() async {
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(safetyRepositoryProvider)
          .createTripShare(journeyId: widget.journeyId);
      if (!mounted) return;
      setState(() => _latestUrl = created.url);
      await _refreshShares();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).shareTripCopied)),
    );
  }

  Future<void> _shareSms(String url) async {
    final uri = Uri(
      scheme: 'sms',
      queryParameters: {
        'body': AppLocalizations.of(context).shareTripSmsBody(url),
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _revoke(String shareId) async {
    setState(() => _busy = true);
    try {
      await ref.read(safetyRepositoryProvider).revokeTripShare(shareId);
      await _refreshShares();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final url = _latestUrl;

    return TripModalSheet(
      title: l10n.shareTripTitle,
      subtitle: l10n.shareTripExpiryNote,
      icon: AlongIcons.share,
      footer: url == null
          ? AlongButton(
              key: const Key('share_trip_create'),
              label: l10n.shareTripCreateLink,
              visualState: _busy
                  ? AlongButtonVisualState.loading
                  : AlongButtonVisualState.normal,
              onPressed: _busy ? null : _createShare,
            )
          : null,
      children: [
        if (url != null) ...[
          TripPanel(
            child: Row(
              children: [
                AlongIcon(AlongIcons.path, size: 20, color: p.ink),
                const SizedBox(width: AlongSpace.s12),
                Expanded(
                  child: Text(
                    url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AlongType.label(p),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AlongSpace.s12),
          Row(
            children: [
              Expanded(
                child: TripActionTile(
                  key: const Key('share_trip_copy'),
                  icon: AlongIcons.checks,
                  label: l10n.shareTripCopy,
                  onPressed: () => _copyLink(url),
                ),
              ),
              const SizedBox(width: AlongSpace.s8),
              Expanded(
                child: TripActionTile(
                  key: const Key('share_trip_sms'),
                  icon: AlongIcons.chat,
                  label: l10n.shareTripSms,
                  onPressed: () => _shareSms(url),
                ),
              ),
            ],
          ),
        ],
        if (_shares.isNotEmpty) ...[
          const SizedBox(height: AlongSpace.s20),
          Text(l10n.shareTripActiveHeading, style: AlongType.label(p)),
          const SizedBox(height: AlongSpace.s8),
          for (final share in _shares)
            Padding(
              key: Key('share_row_${share.id}'),
              padding: const EdgeInsets.only(bottom: AlongSpace.s8),
              child: TripPanel(
                padding: const EdgeInsets.fromLTRB(
                  AlongSpace.s16,
                  AlongSpace.s8,
                  AlongSpace.s4,
                  AlongSpace.s8,
                ),
                child: Row(
                  children: [
                    TripDriverAvatar(name: share.contactName ?? '·', size: 36),
                    const SizedBox(width: AlongSpace.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            share.contactName ?? l10n.shareTripAnonymousContact,
                            style: AlongType.label(p),
                          ),
                          Text(
                            l10n.shareTripExpires(
                              MaterialLocalizations.of(context)
                                  .formatShortDate(share.expiresAt.toLocal()),
                            ),
                            style: AlongType.caption(p),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: Key('share_revoke_${share.id}'),
                      tooltip: l10n.shareTripRevoke,
                      icon: AlongIcon(AlongIcons.close, size: 20, color: p.ink),
                      onPressed: _busy ? null : () => _revoke(share.id),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
