import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// R-25 Share trip — create link, copy/share, list active shares, revoke.
class ShareTripSheet extends ConsumerStatefulWidget {
  const ShareTripSheet({
    super.key,
    required this.journeyId,
  });

  final String journeyId;

  static Future<void> show(
    BuildContext context, {
    required String journeyId,
  }) {
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
      final created = await ref.read(safetyRepositoryProvider).createTripShare(
            journeyId: widget.journeyId,
          );
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
      queryParameters: {'body': AppLocalizations.of(context).shareTripSmsBody(url)},
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AlongBottomSheet(
        size: AlongBottomSheetSize.half,
        title: l10n.shareTripTitle,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(l10n.shareTripExpiryNote, style: AlongText.caption),
            const SizedBox(height: AlongSpace.s16),
            AlongButton(
              key: const Key('share_trip_create'),
              label: l10n.shareTripCreateLink,
              visualState: _busy
                  ? AlongButtonVisualState.loading
                  : AlongButtonVisualState.normal,
              onPressed: _busy ? null : _createShare,
            ),
            if (_latestUrl != null) ...[
              const SizedBox(height: AlongSpace.s12),
              Text(_latestUrl!, style: AlongText.bodyStrong),
              const SizedBox(height: AlongSpace.s8),
              Row(
                children: [
                  Expanded(
                    child: AlongButton(
                      key: const Key('share_trip_copy'),
                      label: l10n.shareTripCopy,
                      variant: AlongButtonVariant.secondary,
                      onPressed: () => _copyLink(_latestUrl!),
                    ),
                  ),
                  const SizedBox(width: AlongSpace.s8),
                  Expanded(
                    child: AlongButton(
                      key: const Key('share_trip_sms'),
                      label: l10n.shareTripSms,
                      variant: AlongButtonVariant.secondary,
                      onPressed: () => _shareSms(_latestUrl!),
                    ),
                  ),
                ],
              ),
            ],
            if (_shares.isNotEmpty) ...[
              const SizedBox(height: AlongSpace.s24),
              Text(l10n.shareTripActiveHeading, style: AlongText.heading2),
              const SizedBox(height: AlongSpace.s8),
              for (final share in _shares)
                ListTile(
                  key: Key('share_row_${share.id}'),
                  title: Text(
                    share.contactName ?? l10n.shareTripAnonymousContact,
                    style: AlongText.bodyStrong,
                  ),
                  subtitle: Text(
                    l10n.shareTripExpires(
                      MaterialLocalizations.of(context).formatShortDate(
                        share.expiresAt.toLocal(),
                      ),
                    ),
                    style: AlongText.caption,
                  ),
                  trailing: IconButton(
                    key: Key('share_revoke_${share.id}'),
                    icon: const Icon(Icons.close),
                    onPressed: _busy ? null : () => _revoke(share.id),
                  ),
                ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}
