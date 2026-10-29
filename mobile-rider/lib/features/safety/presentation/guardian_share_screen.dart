import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/safety/presentation/safety_kit.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

class GuardianShareArgs {
  const GuardianShareArgs({required this.trip});

  final TripSummary trip;
}

/// How long a Guardian link lives. `null` minutes = until the trip ends
/// (server caps it at `share.link_ttl_hours`).
enum GuardianExpiry {
  min30(30),
  hour1(60),
  tripEnd(null);

  const GuardianExpiry(this.minutes);

  final int? minutes;
}

/// A link created this session; the token only exists at creation time.
class _SentLink {
  const _SentLink({required this.share, required this.url, this.phone});

  final TripShareRow share;
  final String url;
  final String? phone;
}

/// R-25 Guardian — trusted contacts follow the trip live until it ends or
/// the link expires. One primary action: share, then stop.
class GuardianShareScreen extends ConsumerStatefulWidget {
  const GuardianShareScreen({super.key, required this.args});

  final GuardianShareArgs args;

  @override
  ConsumerState<GuardianShareScreen> createState() =>
      _GuardianShareScreenState();
}

class _GuardianShareScreenState extends ConsumerState<GuardianShareScreen> {
  List<EmergencyContact> _contacts = const [];
  final Set<String> _picked = {};
  List<TripShareRow> _shares = const [];
  final Map<String, _SentLink> _sent = {};
  bool _plate = false;
  GuardianExpiry _expiry = GuardianExpiry.tripEnd;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  String get _journeyId => widget.args.trip.journeyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(safetyRepositoryProvider);
    final store = ref.read(emergencyContactStoreProvider);
    List<EmergencyContact> contacts;
    try {
      contacts = await repo.listEmergencyContacts();
      await store.write(contacts);
    } catch (_) {
      contacts = await store.read().catchError((_) => <EmergencyContact>[]);
    }
    List<TripShareRow> shares = const [];
    try {
      shares = await repo.listActiveShares(_journeyId);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _picked
        ..clear()
        ..addAll(contacts.map((c) => c.id));
      _shares = shares;
      _loading = false;
    });
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(safetyRepositoryProvider);
    final targets = _contacts.where((c) => _picked.contains(c.id)).toList();
    try {
      final created = <_SentLink>[];
      for (final contact in targets.isEmpty ? [null] : targets) {
        final made = await repo.createTripShare(
          journeyId: _journeyId,
          contactName: contact?.name,
          contactPhone: contact?.phoneE164,
          sharePlate: _plate,
          ttlMinutes: _expiry.minutes,
        );
        created.add(
          _SentLink(
            share: TripShareRow(
              id: made.shareId,
              journeyId: _journeyId,
              expiresAt: made.expiresAt,
              contactName: contact?.name,
            ),
            url: made.url,
            phone: contact?.phoneE164,
          ),
        );
      }
      if (!mounted) return;
      AlongHaptics.success(context);
      setState(() {
        for (final link in created) {
          _sent[link.share.id] = link;
        }
        _shares = [..._shares, for (final link in created) link.share];
      });
    } on AlongException catch (e) {
      if (!mounted) return;
      AlongHaptics.error(context);
      setState(
        () => _error = sosFailureIsRetryable(e)
            ? l10n.guardianShareOffline
            : l10n.guardianShareFailed,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.guardianShareOffline);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(safetyRepositoryProvider);
    try {
      for (final share in _shares) {
        await repo.revokeTripShare(share.id);
      }
      if (!mounted) return;
      AlongHaptics.confirm(context);
      setState(() {
        _shares = const [];
        _sent.clear();
      });
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.guardianShareStopped)),
      );
    } catch (_) {
      if (mounted) setState(() => _error = l10n.guardianShareOffline);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _launch(Uri uri) => ref.read(safetyLauncherProvider)(uri);

  void _whatsapp(_SentLink link) {
    final text = AppLocalizations.of(context).shareTripSmsBody(link.url);
    final digits = (link.phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    _launch(
      Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(text)}'),
    );
  }

  void _sms(_SentLink link) {
    final text = AppLocalizations.of(context).shareTripSmsBody(link.url);
    _launch(
      Uri(
        scheme: 'sms',
        path: link.phone ?? '',
        queryParameters: {'body': text},
      ),
    );
  }

  Future<void> _copy(_SentLink link) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: link.url));
    messenger.showSnackBar(SnackBar(content: Text(l10n.shareTripCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final sharing = _shares.isNotEmpty;
    final until = sharing
        ? _shares.map((s) => s.expiresAt).reduce((a, b) => a.isAfter(b) ? a : b)
        : null;
    final status = sharing
        ? SafetyStatusLine(
            key: const Key('guardian_status_sharing'),
            label:
                '${l10n.guardianShareWatching(_shares.length)} · '
                '${l10n.guardianShareUntil(safetyClock(until!))}',
            tone: SafetyTone.ok,
          )
        : SafetyStatusLine(
            label: l10n.guardianShareSubtitle,
            tone: SafetyTone.idle,
          );
    final picked = _contacts.where((c) => _picked.contains(c.id)).length;

    return SafetyPage(
      title: l10n.guardianTitle,
      status: status,
      footer: sharing
          ? AlongButton(
              key: const Key('guardian_share_stop'),
              label: l10n.guardianShareStop,
              variant: AlongButtonVariant.secondary,
              visualState: _busy
                  ? AlongButtonVisualState.loading
                  : AlongButtonVisualState.normal,
              onPressed: _busy ? null : _stop,
            )
          : AlongButton(
              key: const Key('share_trip_create'),
              label: _error != null
                  ? l10n.sosRetry
                  : l10n.guardianShareCta(picked),
              visualState: _busy
                  ? AlongButtonVisualState.loading
                  : _loading
                  ? AlongButtonVisualState.disabled
                  : AlongButtonVisualState.normal,
              onPressed: _busy || _loading ? null : _share,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SafetyTripMap(trip: widget.args.trip, chip: l10n.sosMapLive),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: AlongCraft.surface(
              p,
              radius: AlongRadius.card.x,
              hairline: true,
              shadow: AlongElevation.rest(p.ink),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _loading
                  ? const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : sharing
                  ? _sharingCard(l10n, p)
                  : _setupCard(l10n, p),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                key: const Key('guardian_share_error'),
                style: AlongType.body(p).copyWith(color: p.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _setupCard(AppLocalizations l10n, AlongPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.guardianShareWho,
          style: AlongType.caption(p)
              .copyWith(color: p.ink, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              for (final c in _contacts)
                SafetyContactFace(
                  key: Key('guardian_contact_${c.id}'),
                  size: 44,
                  name: c.name,
                  selected: _picked.contains(c.id),
                  onTap: () {
                    AlongHaptics.tick(context);
                    setState(() {
                      if (!_picked.remove(c.id)) _picked.add(c.id);
                    });
                  },
                ),
              SafetyAddFace(
                key: const Key('guardian_add_contact'),
                label: l10n.sosAddContact,
                onTap: () => context.push(AppRoutes.account),
              ),
              if (_contacts.isEmpty)
                SizedBox(
                  width: 200,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14, left: 4),
                    child: Text(
                      l10n.guardianShareNoContacts,
                      style: AlongType.bodyMuted(p),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: p.line),
        SizedBox(
          height: 52,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.guardianSharePlate,
                  style: AlongType.body(p)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              AlongSwitch(
                key: const Key('guardian_share_plate'),
                value: _plate,
                semanticLabel: l10n.guardianSharePlate,
                onChanged: (v) {
                  AlongHaptics.tick(context);
                  setState(() => _plate = v);
                },
              ),
            ],
          ),
        ),
        Divider(height: 1, color: p.line),
        const SizedBox(height: 12),
        Text(
          l10n.guardianShareExpiry,
          style: AlongType.caption(p)
              .copyWith(color: p.ink, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final e in GuardianExpiry.values) ...[
              if (e != GuardianExpiry.values.first) const SizedBox(width: 8),
              Expanded(
                child: _ExpiryPill(
                  key: Key('guardian_expiry_${e.name}'),
                  label: switch (e) {
                    GuardianExpiry.min30 => l10n.guardianShare30,
                    GuardianExpiry.hour1 => l10n.guardianShare60,
                    GuardianExpiry.tripEnd => l10n.guardianShareTripEnd,
                  },
                  selected: _expiry == e,
                  onTap: () {
                    AlongHaptics.tick(context);
                    setState(() => _expiry = e);
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _sharingCard(AppLocalizations l10n, AlongPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final share in _shares) ...[
          if (share != _shares.first) Divider(height: 16, color: p.line),
          Column(
            key: Key('share_row_${share.id}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AlongMonogram(
                    initials: safetyInitials(
                      share.contactName ?? l10n.shareTripAnonymousContact,
                    ),
                    size: 40,
                    mark: 0.36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          share.contactName ?? l10n.shareTripAnonymousContact,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AlongType.body(p)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          l10n.guardianShareUntil(safetyClock(share.expiresAt)),
                          style: AlongType.caption(p).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_sent[share.id] case final link?)
                Padding(
                  padding: const EdgeInsets.only(left: 52, top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (link.phone != null) ...[
                        _SendChip(
                          key: Key('share_whatsapp_${share.id}'),
                          label: l10n.guardianShareWhatsapp,
                          onTap: () => _whatsapp(link),
                        ),
                        _SendChip(
                          key: Key('share_sms_${share.id}'),
                          label: l10n.shareTripSms,
                          onTap: () => _sms(link),
                        ),
                      ] else
                        _SendChip(
                          key: Key('share_copy_${share.id}'),
                          label: l10n.shareTripCopy,
                          onTap: () => _copy(link),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ExpiryPill extends StatelessWidget {
  const _ExpiryPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: AlongMotionPolicy.reduced(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: ShapeDecoration(
            shape: StadiumBorder(
              side: BorderSide(color: selected ? p.ink : p.line),
            ),
            color: selected ? p.ink : p.surface,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AlongType.caption(p).copyWith(
              color: selected ? p.onInk : p.ink,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _SendChip extends StatelessWidget {
  const _SendChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: ShapeDecoration(
            shape: StadiumBorder(side: BorderSide(color: p.line)),
            color: p.recessed,
          ),
          child: Text(
            label,
            style: AlongType.caption(p)
                .copyWith(color: p.ink, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
