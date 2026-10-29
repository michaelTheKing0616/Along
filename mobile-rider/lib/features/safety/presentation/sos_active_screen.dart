import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/domain/live_trip_config.dart';
import 'package:mobile_rider/features/safety/presentation/guardian_share_screen.dart';
import 'package:mobile_rider/features/safety/presentation/safety_kit.dart';
import 'package:mobile_rider/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Route args for R-23 SOS active.
class SosActiveRouteArgs {
  const SosActiveRouteArgs({required this.trip, this.initialLocation});

  final TripSummary trip;
  final Point? initialLocation;
}

/// R-23 SOS active — server alert, offline queue, contact deep links.
class SosActiveScreen extends ConsumerStatefulWidget {
  const SosActiveScreen({super.key, required this.args});

  final SosActiveRouteArgs args;

  @override
  ConsumerState<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends ConsumerState<SosActiveScreen> {
  static const _retryDelay = Duration(seconds: 12);

  String? _sosId;
  String? _emergencyNumber;
  String? _shareUrl;
  bool _raising = true;
  bool _queued = false;
  String? _error;
  List<EmergencyContact> _contacts = const [];
  Timer? _retryTimer;
  DateTime? _sentAt;

  @override
  void initState() {
    super.initState();
    _raiseSos();
    _loadContacts();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Point _locationPayload() {
    final live = widget.args.trip.live;
    final rider = live?.rider;
    if (rider != null) {
      return Point(lat: rider.lat, lng: rider.lng);
    }
    final driver = live?.driver;
    if (driver != null) {
      return Point(lat: driver.lat, lng: driver.lng);
    }
    final initial = widget.args.initialLocation;
    if (initial != null) return initial;
    return const Point(lat: 9.0579, lng: 7.4951);
  }

  SosRaiseRequest _request() {
    final location = _locationPayload();
    return SosRaiseRequest(
      tripId: widget.args.trip.tripId,
      journeyId: widget.args.trip.journeyId,
      lat: location.lat,
      lng: location.lng,
    );
  }

  Future<void> _loadContacts() async {
    final store = ref.read(emergencyContactStoreProvider);
    try {
      final contacts = await ref
          .read(safetyRepositoryProvider)
          .listEmergencyContacts();
      await store.write(contacts);
      if (!mounted) return;
      setState(() => _contacts = contacts);
    } catch (_) {
      try {
        final cached = await store.read();
        if (!mounted) return;
        setState(() => _contacts = cached);
      } catch (_) {}
    }
  }

  Future<void> _raiseSos() async {
    _retryTimer?.cancel();
    setState(() {
      _raising = true;
      _error = null;
      _queued = false;
    });
    try {
      final outcome = await ref
          .read(sosRaiseCoordinatorProvider)
          .submit(_request());
      if (!mounted) return;
      _applyOutcome(outcome);
    } on AlongException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _raising = false;
        _queued = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _raising = false;
        _queued = false;
      });
    }
  }

  Future<void> _flushQueued() async {
    if (!_queued) return;
    try {
      final outcome = await ref
          .read(sosRaiseCoordinatorProvider)
          .flushPending();
      if (!mounted) return;
      if (outcome.isQueued) {
        final stillPending = await ref.read(sosOutboxProvider).hasPending();
        if (!mounted) return;
        if (!stillPending) {
          setState(() {
            _queued = false;
            _raising = false;
            _error = AppLocalizations.of(context).sosRaiseFailed;
          });
          return;
        }
        _scheduleRetry();
        return;
      }
      _applyOutcome(outcome);
    } catch (_) {
      if (!mounted || !_queued) return;
      _scheduleRetry();
    }
  }

  void _applyOutcome(SosDeliveryOutcome outcome) {
    if (outcome.isQueued) {
      AlongHaptics.confirm(context);
      setState(() {
        _raising = false;
        _queued = true;
        _error = null;
      });
      _scheduleRetry();
      return;
    }
    final result = outcome.result;
    AlongHaptics.success(context);
    setState(() {
      _sentAt = ref.read(safetyNowProvider)();
      _sosId = result?.sosId;
      _emergencyNumber = result?.emergencyNumber;
      _shareUrl = result?.shareUrl;
      _raising = false;
      _queued = false;
      _error = null;
    });
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (!mounted || !_queued) return;
      _flushQueued();
    });
  }

  Future<void> _callEmergency() async {
    final number = _emergencyNumber ?? '112';
    final uri = Uri(scheme: 'tel', path: number);
    await ref.read(safetyLauncherProvider)(uri);
  }

  Future<void> _openExternal(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await ref.read(safetyLauncherProvider)(uri);
  }

  Future<void> _confirmSafe() async {
    final sosId = _sosId;
    if (sosId == null) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sosImSafeTitle),
        content: Text(l10n.sosImSafeBody),
        actions: [
          TextButton(
            key: const Key('sos_keep_alert'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.sosKeepAlert),
          ),
          TextButton(
            key: const Key('sos_confirm_safe'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.sosImSafeConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _retryTimer?.cancel();
    await ref.read(safetyRepositoryProvider).cancelSos(sosId);
    if (mounted) Navigator.of(context).pop();
  }

  void _openContact(SosContactChannel channel) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final p = AlongPalette.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.sosReach(channel.name), style: AlongType.title(p)),
                const SizedBox(height: 16),
                AlongButton(
                  key: const Key('sos_contact_whatsapp'),
                  label: l10n.sosContactWhatsapp(safetyFirstName(channel.name)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openExternal(channel.whatsappUrl);
                  },
                ),
                const SizedBox(height: 8),
                AlongButton(
                  key: const Key('sos_contact_sms'),
                  label: l10n.sosContactSms(safetyFirstName(channel.name)),
                  variant: AlongButtonVariant.secondary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openExternal(channel.smsUri);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<SosContactChannel> _channels() {
    final location = _locationPayload();
    return sosContactChannels(
      contacts: _contacts,
      message: sosHelpMessage(
        lat: location.lat,
        lng: location.lng,
        shareUrl: _shareUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final holdDuration = ref
        .watch(liveTripConfigProvider)
        .maybeWhen(
          data: (cfg) => cfg.sosHoldDurationMs,
          orElse: () => AlongDurations.sos,
        );
    final number = _emergencyNumber ?? '112';
    final failed = !_raising && _error != null;
    final status = _raising
        ? SafetyStatusLine(
            key: const Key('sos_status_sending'),
            label: l10n.sosStatusSending,
            tone: SafetyTone.working,
          )
        : failed
        ? SafetyStatusLine(
            key: const Key('sos_status_failed'),
            label: l10n.sosStatusFailed,
            tone: SafetyTone.alarm,
          )
        : _queued
        ? SafetyStatusLine(
            key: const Key('sos_status_queued'),
            label: l10n.sosStatusQueued,
            tone: SafetyTone.waiting,
          )
        : SafetyStatusLine(
            key: const Key('sos_team_alerted'),
            label: l10n.sosStatusSent(
              safetyClock(_sentAt ?? ref.read(safetyNowProvider)()),
            ),
            tone: SafetyTone.ok,
          );
    final channels = _channels();

    return PopScope(
      canPop: _sosId == null && !_raising,
      child: SafetyPage(
        title: l10n.sosTitle,
        status: status,
        canClose: _sosId == null && !_raising,
        footer: Row(
          children: [
            Expanded(
              child: AlongButton(
                key: const Key('sos_share_contact'),
                label: l10n.sosShareLive,
                variant: AlongButtonVariant.secondary,
                onPressed: () => context.push(
                  AppRoutes.guardianShare,
                  extra: GuardianShareArgs(trip: widget.args.trip),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: failed || _queued
                  ? AlongButton(
                      key: const Key('sos_retry'),
                      label: l10n.sosRetry,
                      variant: AlongButtonVariant.secondary,
                      onPressed: _raiseSos,
                    )
                  : AlongButton(
                      key: const Key('sos_hold_cancel'),
                      label: l10n.sosImSafe,
                      variant: AlongButtonVariant.secondary,
                      onPressed: _sosId == null ? null : _confirmSafe,
                    ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: AlongHoldRing(
                key: const Key('sos_call_emergency'),
                label: l10n.sosCallEmergency(number),
                hint: l10n.sosHoldHint,
                holdDuration: holdDuration,
                onFired: _callEmergency,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sosHoldHint,
              textAlign: TextAlign.center,
              style: AlongType.caption(p),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SafetyTripMap(
                trip: widget.args.trip,
                chip: l10n.sosMapLive,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.sosContactsTitle,
              style: AlongType.caption(p)
                  .copyWith(color: p.ink, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              child: channels.isEmpty
                  ? Row(
                      children: [
                        SafetyAddFace(
                          key: const Key('sos_add_contact'),
                          label: l10n.sosAddContact,
                          onTap: () => context.push(AppRoutes.account),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.sosNoContacts,
                            style: AlongType.bodyMuted(p),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          for (final (i, channel) in channels.indexed)
                            SafetyContactFace(
                              key: Key('sos_contact_$i'),
                              name: channel.name,
                              onTap: () => _openContact(channel),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
