import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/domain/live_trip_config.dart';
import 'package:mobile_rider/features/safety/presentation/share_trip_sheet.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

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
      setState(() {
        _raising = false;
        _queued = true;
        _error = null;
      });
      _scheduleRetry();
      return;
    }
    final result = outcome.result;
    setState(() {
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
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openExternal(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyShare() async {
    final url = _shareUrl;
    if (url == null || url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).sosLiveLinkCopied)),
    );
  }

  Future<void> _cancelSos() async {
    final sosId = _sosId;
    if (sosId == null) return;
    _retryTimer?.cancel();
    await ref.read(safetyRepositoryProvider).cancelSos(sosId);
    if (mounted) Navigator.of(context).pop();
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
    final holdDuration = ref
        .watch(liveTripConfigProvider)
        .maybeWhen(
          data: (cfg) => cfg.sosHoldDurationMs,
          orElse: () => const Duration(milliseconds: 600),
        );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AlongColors.semanticDangerTint,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AlongSpace.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AlongSpace.s32),
                if (_raising) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: AlongSpace.s16),
                  Text(
                    l10n.sosRaising,
                    style: AlongText.heading2,
                    textAlign: TextAlign.center,
                  ),
                ] else if (_error != null) ...[
                  Text(
                    l10n.sosRaiseFailed,
                    style: AlongText.heading2.copyWith(
                      color: AlongColors.semanticDanger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AlongSpace.s12),
                  AlongButton(
                    key: const Key('sos_retry'),
                    label: l10n.sosRetry,
                    variant: AlongButtonVariant.secondary,
                    onPressed: _raiseSos,
                  ),
                ] else
                  Expanded(
                    child: ListView(
                      children: [
                        Text(
                          _queued ? l10n.sosQueued : l10n.sosTeamAlerted,
                          key: _queued ? null : const Key('sos_team_alerted'),
                          style: AlongText.heading1.copyWith(
                            color: AlongColors.semanticDanger,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AlongSpace.s12),
                        Text(
                          l10n.sosSharingDetails,
                          style: AlongText.body,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AlongSpace.s24),
                        AlongButton(
                          key: const Key('sos_call_emergency'),
                          label: l10n.sosCallEmergency(
                            _emergencyNumber ?? '112',
                          ),
                          variant: AlongButtonVariant.danger,
                          onPressed: _callEmergency,
                        ),
                        if (_shareUrl != null) ...[
                          const SizedBox(height: AlongSpace.s12),
                          AlongButton(
                            key: const Key('sos_copy_live_link'),
                            label: l10n.sosLiveLink,
                            variant: AlongButtonVariant.secondary,
                            onPressed: _copyShare,
                          ),
                        ],
                        const SizedBox(height: AlongSpace.s12),
                        AlongButton(
                          key: const Key('sos_share_contact'),
                          label: l10n.sosShareWithContact,
                          variant: AlongButtonVariant.secondary,
                          onPressed: () => ShareTripSheet.show(
                            context,
                            journeyId: widget.args.trip.journeyId,
                          ),
                        ),
                        if (_channels().isNotEmpty) ...[
                          const SizedBox(height: AlongSpace.s24),
                          Text(
                            l10n.sosContactsHeading,
                            style: AlongText.bodyStrong,
                            textAlign: TextAlign.center,
                          ),
                          for (final channel in _channels()) ...[
                            const SizedBox(height: AlongSpace.s12),
                            AlongButton(
                              label: l10n.sosContactWhatsapp(channel.name),
                              variant: AlongButtonVariant.secondary,
                              onPressed: () =>
                                  _openExternal(channel.whatsappUrl),
                            ),
                            const SizedBox(height: AlongSpace.s8),
                            AlongButton(
                              label: l10n.sosContactSms(channel.name),
                              variant: AlongButtonVariant.secondary,
                              onPressed: () => _openExternal(channel.smsUri),
                            ),
                          ],
                        ],
                        if (_queued) ...[
                          const SizedBox(height: AlongSpace.s12),
                          AlongButton(
                            key: const Key('sos_retry'),
                            label: l10n.sosRetry,
                            variant: AlongButtonVariant.secondary,
                            onPressed: _raiseSos,
                          ),
                        ],
                        if (_sosId != null) ...[
                          const SizedBox(height: AlongSpace.s24),
                          Center(
                            child: Column(
                              children: [
                                HoldButton(
                                  key: const Key('sos_hold_cancel'),
                                  type: HoldButtonType.sos,
                                  holdDuration: holdDuration,
                                  label: l10n.sosHoldToCancel,
                                  onFired: _cancelSos,
                                ),
                                const SizedBox(height: AlongSpace.s8),
                                Text(
                                  l10n.sosHoldToCancel,
                                  style: AlongText.label,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
