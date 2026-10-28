import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/wallet/wallet_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Most co-riders one request can include.
const walletSplitMaxCoRiders = 3;

/// Split a fare: enter it, add co-riders by phone, and ask each for an
/// equal share. They pay from their own wallets.
class WalletSplitScreen extends ConsumerStatefulWidget {
  const WalletSplitScreen({super.key, this.initialFare});

  /// Prefill when opened from a trip.
  final int? initialFare;

  @override
  ConsumerState<WalletSplitScreen> createState() => _WalletSplitScreenState();
}

class _WalletSplitScreenState extends ConsumerState<WalletSplitScreen> {
  late final _fare = TextEditingController(
    text: widget.initialFare?.toString() ?? '',
  );
  final _phones = <TextEditingController>[TextEditingController()];
  bool _busy = false;
  bool _submitted = false;
  String? _error;
  String? _key;

  /// Index of the co-rider whose number is not on Along.
  int? _missing;

  @override
  void initState() {
    super.initState();
    _fare.addListener(_changed);
    _phones.first.addListener(_changed);
  }

  void _changed() => setState(() {
    _key = null;
    _error = null;
    _missing = null;
  });

  @override
  void dispose() {
    _fare.dispose();
    for (final c in _phones) {
      c.dispose();
    }
    super.dispose();
  }

  void _add() {
    if (_phones.length >= walletSplitMaxCoRiders) return;
    setState(() => _phones.add(TextEditingController()..addListener(_changed)));
  }

  void _remove(int i) {
    final c = _phones.removeAt(i);
    c.dispose();
    _changed();
  }

  Future<void> _request(List<String> phones, int share) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final key = _key ??= walletKey('split');
    setState(() => _busy = true);
    try {
      final sent = await ref
          .read(walletRepositoryProvider)
          .requestSplit(phones: phones, share: share, idempotencyKey: key);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.walletSplitSentSnack(sent))),
      );
      ref.invalidate(walletSummaryProvider);
      for (final c in _phones.skip(1)) {
        c.dispose();
      }
      _phones.removeRange(1, _phones.length);
      _phones.first.clear();
      _fare.clear();
      setState(() => _submitted = false);
    } on WalletException catch (e) {
      final at = e.detail == null ? -1 : phones.indexOf(e.detail!);
      setState(() {
        if (e.failure == WalletFailure.notFound && at >= 0) {
          _missing = at;
          _error = l10n.walletSplitNotFoundNumber(_phones[at].text.trim());
        } else {
          _error = e.failure == WalletFailure.notFound
              ? l10n.walletSplitNotFound
              : l10n.walletActionFailed;
        }
      });
    } catch (_) {
      setState(() => _error = l10n.walletActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final fare = int.tryParse(_fare.text);
    final fareOk = fare != null && fare >= 100 && fare <= 50000;
    final people = _phones.length + 1;
    final shares = fareOk ? splitShares(fare, people) : const <int>[];
    final each = shares.length > 1 ? shares[1] : null;
    final normalised = [for (final c in _phones) normaliseNgPhone(c.text)];
    final phonesOk =
        normalised.every((n) => n != null) &&
        normalised.toSet().length == normalised.length;
    final sent =
        ref.watch(walletSummaryProvider).value?.splitsSent ??
        const <WalletSplitSent>[];
    final ready = fareOk && phonesOk && each != null && each >= walletSendMin;
    return WalletPage(
      title: l10n.walletSplitTitle,
      subtitle: l10n.walletSplitSubtitle,
      footer: AlongButton(
        key: const Key('wallet_split_cta'),
        label: each != null
            ? l10n.walletSplitCta(alongNaira(each))
            : l10n.walletSplitCtaEmpty,
        visualState: _busy
            ? AlongButtonVisualState.loading
            : AlongButtonVisualState.normal,
        onPressed: _busy
            ? null
            : () {
                if (!ready) {
                  setState(() => _submitted = true);
                  return;
                }
                _request([for (final n in normalised) n!], each);
              },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('wallet_split_fare'),
            controller: _fare,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.walletSplitFare,
              prefixText: '₦',
              errorText: _submitted && !fareOk
                  ? l10n.walletSplitFareInvalid
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          _ShareStrip(
            names: [
              l10n.walletSplitYou,
              for (var i = 0; i < _phones.length; i++)
                l10n.walletSplitCoRider(i + 1),
            ],
            shares: shares,
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < _phones.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: Key('wallet_split_phone_$i'),
                    controller: _phones[i],
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.walletSplitCoRider(i + 1),
                      hintText: l10n.walletSendPhoneHint,
                      errorText: _submitted && normalised[i] == null
                          ? l10n.walletSendPhoneInvalid
                          : _missing == i
                          ? l10n.walletSplitNotOnAlong
                          : null,
                    ),
                  ),
                ),
                if (_phones.length > 1)
                  IconButton(
                    key: Key('wallet_split_remove_$i'),
                    tooltip: l10n.walletSplitRemove,
                    onPressed: _busy ? null : () => _remove(i),
                    icon: AlongIcon(AlongIcons.close, size: 20, color: p.ink),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_phones.length < walletSplitMaxCoRiders)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('wallet_split_add'),
                onPressed: _busy ? null : _add,
                icon: AlongIcon(AlongIcons.plus, size: 20, color: p.ink),
                label: Text(
                  l10n.walletSplitAdd,
                  style: AlongType.label(p).copyWith(color: p.ink),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(l10n.walletSplitNote, style: AlongType.caption(p)),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                key: const Key('wallet_split_error'),
                style: AlongType.body(p).copyWith(color: p.danger),
              ),
            ),
          ],
          if (sent.isNotEmpty) ...[
            const SizedBox(height: 24),
            AlongTxnGroup(
              label: l10n.walletSplitRequests,
              icon: AlongIcons.history,
            ),
            const SizedBox(height: 4),
            for (final r in sent) _StatusRow(request: r),
          ],
        ],
      ),
    );
  }
}

/// Avatars with each person's share; the requester's tile is outlined in
/// brand yellow, like the design's split card.
class _ShareStrip extends StatelessWidget {
  const _ShareStrip({required this.names, required this.shares});

  final List<String> names;
  final List<int> shares;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < names.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                WalletInitials(
                  name: names[i],
                  size: 48,
                  highlight: i == 0,
                  label: i == 0 ? names[0] : '$i',
                  tintSeed: 'co-rider-$i',
                ),
                const SizedBox(height: 8),
                Container(
                  key: Key('wallet_split_share_$i'),
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(AlongRadius.card.x),
                    border: Border.all(
                      color: i == 0 ? p.accent : p.line,
                      width: i == 0 ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        names[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AlongType.caption(p),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          i < shares.length ? alongNaira(shares[i]) : '—',
                          maxLines: 1,
                          style: AlongType.body(p).copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One co-rider's share and where it stands.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.request});

  final WalletSplitSent request;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final (label, color, icon) = switch (request.status) {
      WalletSplitStatus.paid => (
        l10n.walletSplitPaidStatus,
        p.success,
        AlongIcons.verified,
      ),
      WalletSplitStatus.declined => (
        l10n.walletSplitDeclined,
        p.danger,
        AlongIcons.close,
      ),
      WalletSplitStatus.pending => (
        l10n.walletSplitPending,
        p.muted,
        AlongIcons.schedule,
      ),
    };
    return MergeSemantics(
      child: Padding(
        key: Key('wallet_split_status_${request.id}'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            WalletInitials(name: request.payerName, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.payerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AlongType.label(p),
                  ),
                  Row(
                    children: [
                      AlongIcon(icon, size: 14, color: color),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label,
                          style: AlongType.caption(p).copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              alongNaira(request.amount),
              style: AlongType.body(p).copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                decoration: request.status == WalletSplitStatus.declined
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
