import 'dart:async';

import 'package:along_core/along_core.dart' show TripEta, TripEtaStop;
import 'package:flutter/material.dart';

import '../components/along_button.dart';
import '../craft.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';
import 'city_map.dart';
import 'delights.dart';
import 'driver_portrait.dart';

// Live trip, pickup handoff, receipt, and driver earnings.
// Radii: 16 controls, 20 rows and buttons, 24 cards, 28 dialogs, 32 sheets.
// Money is right-aligned. Geist sets the type; the naira falls back to Inter.

const _rControl = 16.0;
const _rRow = 20.0;
const _rCard = 24.0;
const _rSheet = 32.0;
const _gutter = 16.0;

bool _roomy(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > 1.15;

Color _soft(AlongPalette p) => p.ink.withValues(alpha: 0.72);

BorderSide _hair(AlongPalette p) =>
    BorderSide(color: p.ink.withValues(alpha: 0.12), width: 1);

String _clock(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

int _minutes(int seconds) => (seconds / 60).round().clamp(1, 999);

/// Arrival window from the estimator: median edge first, p85 edge last.
class AlongEtaWindow {
  const AlongEtaWindow({required this.lowMin, required this.highMin});

  final int lowMin;
  final int highMin;

  bool get single => lowMin == highMin;

  /// "12–16" or "12". The unit is set apart by the caller.
  String get figure => single ? '$lowMin' : '$lowMin–$highMin';

  static AlongEtaWindow? fromEta(TripEta? eta) {
    if (eta == null || !eta.isReady) return null;
    final value = eta.trip ?? eta.pickup;
    if (value == null) return null;
    final low = _minutes(value.lowS);
    final high = _minutes(value.highS);
    return AlongEtaWindow(lowMin: low, highMin: high < low ? low : high);
  }
}

/// Minutes the slow edge moved out since the last reading, when that is more
/// than the estimator's 90 second publish threshold. Null otherwise.
int? alongEtaSlowdownMinutes(TripEta? previous, TripEta? current) {
  if (previous == null || current == null) return null;
  if (!previous.isReady || !current.isReady) return null;
  final before = previous.trip ?? previous.pickup;
  final now = current.trip ?? current.pickup;
  if (before == null || now == null) return null;
  final delta = now.highS - before.highS;
  if (delta <= 90) return null;
  return _minutes(delta);
}

// ---------------------------------------------------------------------------
// Shared pieces

class _Surface extends StatelessWidget {
  const _Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(_gutter),
    this.corner = _rCard,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final double corner;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color ?? p.surface,
        shape: AlongCraft.border(corner, side: _hair(p)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({
    super.key,
    required this.label,
    required this.amount,
    this.detail,
    this.strong = false,
    this.color,
  });

  final String label;
  final String amount;
  final String? detail;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final base = strong ? AlongType.title(p) : AlongType.body(p);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: base.copyWith(color: color)),
                if (detail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      detail!,
                      style: AlongType.caption(p).copyWith(color: _soft(p)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            textAlign: TextAlign.right,
            style: base.copyWith(
              color: color,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      child: AlongPressable(
        child: Material(
          color: p.recessed,
          shape: AlongCraft.border(_rControl),
          child: InkWell(
            customBorder: AlongCraft.border(_rControl),
            onTap: onTap == null
                ? null
                : () {
                    AlongHaptics.tick(context);
                    onTap!();
                  },
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(child: AlongIcon(icon, size: 24, color: p.ink)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet over a map. Top corners 32.
class _MapSheet extends StatelessWidget {
  const _MapSheet({required this.map, required this.sheet, this.overlay});

  final Widget map;
  final Widget sheet;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned.fill(child: map),
          if (overlay != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(bottom: false, child: overlay!),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: p.surface,
                shadows: AlongElevation.sheet(p.ink),
                shape: AlongCraft.borderVertical(top: _rSheet),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _gutter,
                  12,
                  _gutter,
                  _gutter + bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: ShapeDecoration(
                          color: p.ink.withValues(alpha: 0.18),
                          shape: AlongCraft.border(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    sheet,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.children,
    this.subtitle,
    this.meta,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(_gutter, 24, _gutter, 16),
                children: [
                  Text(title, style: AlongType.display(p)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AlongType.body(p).copyWith(color: _soft(p)),
                    ),
                  ],
                  if (meta != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta!,
                      style: AlongType.label(p).copyWith(color: _soft(p)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(_gutter, 8, _gutter, 16),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

class _StateBlock extends StatelessWidget {
  const _StateBlock({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
    this.actionKey,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final tint = p.ink;
    return _Surface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlongIcon(icon, size: 24, color: tint),
          const SizedBox(height: 12),
          Text(title, style: AlongType.title(p).copyWith(color: tint)),
          const SizedBox(height: 4),
          Text(body, style: AlongType.body(p).copyWith(color: _soft(p))),
          if (action != null) ...[
            const SizedBox(height: 16),
            AlongButton(
              key: actionKey,
              label: action!,
              variant: AlongButtonVariant.secondary,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// Rolls a value in when it changes. Holds still when motion is off.
class _Roll extends StatelessWidget {
  const _Roll({required this.value, required this.child});

  final Object value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final move = AlongMoves.roll;
    return AnimatedSwitcher(
      duration: move.of(context),
      reverseDuration: move.of(context) * 0.75,
      switchInCurve: move.curve,
      switchOutCurve: move.curve,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(value), child: child),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Rider live trip

/// The rider's live trip. Reads the PR #13 estimator payload directly.
class AlongLiveTripScreen extends StatelessWidget {
  const AlongLiveTripScreen({
    super.key,
    required this.eta,
    this.previous,
    required this.driverName,
    required this.vehicle,
    required this.destination,
    this.progress = 0.55,
    this.failed = false,
    this.onRetry,
    this.onCall,
    this.onSos,
  });

  final TripEta? eta;

  /// The reading before [eta]. A slow edge more than 90s later shows a notice.
  final TripEta? previous;
  final String driverName;

  /// "Yellow keke · ABJ 482 KE".
  final String vehicle;
  final String destination;
  final double progress;

  /// Live updates stopped. The last window stays, marked as paused.
  final bool failed;
  final VoidCallback? onRetry;
  final VoidCallback? onCall;
  final VoidCallback? onSos;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final window = AlongEtaWindow.fromEta(eta);
    final slow = failed ? null : alongEtaSlowdownMinutes(previous, eta);
    final stops = (eta?.stops ?? const <TripEtaStop>[])
        .where((s) => s.state != 'passed')
        .take(2)
        .toList();
    return _MapSheet(
      map: AlongCityMap(
        mode: AlongCityMapMode.trip,
        progress: progress,
        sheetInset: 0.5,
        demoLabel: false,
      ),
      overlay: Padding(
        padding: const EdgeInsets.fromLTRB(_gutter, 8, _gutter, 0),
        child: Align(
          alignment: Alignment.centerRight,
          child: _SosButton(onTap: onSos),
        ),
      ),
      sheet: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            failed
                ? 'Last estimate to $destination'
                : 'Arriving at $destination',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AlongType.label(p).copyWith(color: _soft(p)),
          ),
          const SizedBox(height: 4),
          _EtaHeadline(window: window, eta: eta, failed: failed),
          AnimatedSize(
            duration: AlongMoves.arrive.of(context),
            curve: AlongMoves.arrive.curve,
            alignment: Alignment.topCenter,
            child: slow == null && !failed
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: failed
                        ? _Notice(
                            key: const Key('live_eta_paused'),
                            icon: AlongIcons.info,
                            text: 'Live times paused',
                            action: onRetry == null ? null : 'Retry',
                            onAction: onRetry,
                          )
                        : _Notice(
                            key: const Key('live_eta_slowdown'),
                            icon: AlongIcons.schedule,
                            text: 'Traffic ahead. About $slow min later.',
                            warn: true,
                          ),
                  ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, thickness: 1, color: _hair(p).color),
          const SizedBox(height: 16),
          Row(
            children: [
              const AlongDriverPortrait(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AlongType.title(p),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AlongType.label(p).copyWith(color: _soft(p)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _IconAction(
                key: const Key('live_call'),
                icon: AlongIcons.call,
                label: 'Call $driverName',
                onTap: onCall,
              ),
            ],
          ),
          if (stops.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final stop in stops) _StopLine(stop: stop),
          ],
        ],
      ),
    );
  }
}

class _EtaHeadline extends StatelessWidget {
  const _EtaHeadline({
    required this.window,
    required this.eta,
    required this.failed,
  });

  final AlongEtaWindow? window;
  final TripEta? eta;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final w = window;
    if (w == null) {
      return Semantics(
        liveRegion: true,
        child: Text(
          'Calculating…',
          key: const Key('live_eta_calculating'),
          style: AlongType.display(p).copyWith(color: _soft(p)),
        ),
      );
    }
    final updated = eta!.updatedAt.toLocal();
    final first = updated.add(Duration(minutes: w.lowMin));
    final last = updated.add(Duration(minutes: w.highMin));
    final clock = w.single
        ? 'About ${_clock(first)}'
        : '${_clock(first)} to ${_clock(last)}';
    final number = AlongType.numeric(p)
        .copyWith(color: failed ? _soft(p) : p.ink);
    return Semantics(
      liveRegion: true,
      label: w.single
          ? '${w.lowMin} minutes'
          : '${w.lowMin} to ${w.highMin} minutes',
      child: ExcludeSemantics(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 12,
          runSpacing: 2,
          children: [
            _Roll(
              value: w.figure,
              child: Row(
                key: const Key('live_eta_window'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(w.figure, style: number),
                  Text(
                    ' min',
                    style: AlongType.title(p).copyWith(color: number.color),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                clock,
                style: AlongType.label(p).copyWith(color: _soft(p)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    required this.text,
    this.warn = false,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final bool warn;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = warn
        ? (dark ? const Color(0xFF3A2E12) : const Color(0xFFFBEFC9))
        : p.recessed;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: fill,
          shape: AlongCraft.border(_rRow),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              AlongIcon(icon, size: 20, color: p.ink),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: AlongType.label(p))),
              if (action != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: p.ink,
                    minimumSize: const Size(48, 40),
                    shape: AlongCraft.border(_rControl),
                    textStyle: AlongType.label(p)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  child: Text(action!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopLine extends StatelessWidget {
  const _StopLine({required this.stop});

  final TripEtaStop stop;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final next = stop.state == 'next' || stop.state == 'current';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: ShapeDecoration(
              color: next ? p.accent : p.surface,
              shape: CircleBorder(
                side: BorderSide(color: p.ink, width: next ? 0 : 1.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stop.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AlongType.body(p),
            ),
          ),
          const SizedBox(width: 12),
          Text(stop.label, style: AlongType.label(p)),
        ],
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: 'Emergency',
      child: AlongPressable(
        child: Material(
          color: p.surface,
          elevation: 0,
          shape: AlongCraft.border(_rControl, side: _hair(p)),
          child: InkWell(
            key: const Key('live_sos'),
            customBorder: AlongCraft.border(_rControl),
            onTap: onTap == null
                ? null
                : () {
                    AlongHaptics.confirm(context);
                    onTap!();
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AlongIcon(AlongIcons.sos, size: 20, color: p.danger),
                  const SizedBox(width: 8),
                  Text(
                    'SOS',
                    style: AlongType.label(p)
                        .copyWith(color: p.danger, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Pickup handoff

class AlongPickupHandoffScreen extends StatefulWidget {
  const AlongPickupHandoffScreen({
    super.key,
    required this.secondsAway,
    required this.driverName,
    required this.plate,
    required this.car,
    required this.pin,
    required this.pickupPoint,
    this.onCall,
    this.onMessage,
  });

  /// Seconds until the driver reaches the pickup point. 0 means arrived.
  final int secondsAway;
  final String driverName;
  final String plate;

  /// "Silver Toyota Corolla".
  final String car;

  /// Four digits the rider says before getting in.
  final String pin;
  final String pickupPoint;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  @override
  State<AlongPickupHandoffScreen> createState() =>
      _AlongPickupHandoffScreenState();
}

class _AlongPickupHandoffScreenState extends State<AlongPickupHandoffScreen> {
  late int _left = widget.secondsAway;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer ??= AlongMotionPolicy.play(context) && _left > 0
        ? Timer.periodic(const Duration(seconds: 1), (_) => _tick())
        : null;
  }

  @override
  void didUpdateWidget(AlongPickupHandoffScreen old) {
    super.didUpdateWidget(old);
    if (old.secondsAway != widget.secondsAway) _left = widget.secondsAway;
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _left = (_left - 1).clamp(0, 1 << 30));
    if (_left == 0) {
      _timer?.cancel();
      AlongHaptics.confirm(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final here = _left <= 0;
    final mm = (_left ~/ 60).toString();
    final ss = (_left % 60).toString().padLeft(2, '0');
    final roomy = _roomy(context);
    final actions = [
      AlongButton(
        key: const Key('handoff_call'),
        label: 'Call',
        variant: AlongButtonVariant.secondary,
        onPressed: widget.onCall,
      ),
      AlongButton(
        key: const Key('handoff_message'),
        label: 'Message',
        variant: AlongButtonVariant.secondary,
        onPressed: widget.onMessage,
      ),
    ];
    return _MapSheet(
      map: const AlongCityMap(
        approach: true,
        sheetInset: 0.62,
        demoLabel: false,
      ),
      sheet: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      here
                          ? '${widget.driverName} is here'
                          : '${widget.driverName} arrives in',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AlongType.label(p).copyWith(color: _soft(p)),
                    ),
                    const SizedBox(height: 4),
                    _Roll(
                      value: here ? 'here' : _left,
                      child: Text(
                        here ? widget.pickupPoint : '$mm:$ss',
                        key: const Key('handoff_countdown'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: here ? AlongType.title(p) : AlongType.numeric(p),
                      ),
                    ),
                  ],
                ),
              ),
              if (!here)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      widget.pickupPoint,
                      maxLines: 2,
                      textAlign: TextAlign.right,
                      style: AlongType.label(p).copyWith(color: _soft(p)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _Surface(
            color: p.recessed,
            corner: _rRow,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plate,
                  key: const Key('handoff_plate'),
                  style: AlongType.numeric(p).copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 2),
                Text(widget.car, style: AlongType.body(p)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trip PIN', style: AlongType.label(p)),
                    const SizedBox(height: 2),
                    Text(
                      'Say it at the door',
                      style: AlongType.caption(p).copyWith(color: _soft(p)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _PinDigits(pin: widget.pin),
            ],
          ),
          const SizedBox(height: 20),
          if (roomy)
            Column(
              children: [actions[0], const SizedBox(height: 8), actions[1]],
            )
          else
            Row(
              children: [
                Expanded(child: actions[0]),
                const SizedBox(width: 12),
                Expanded(child: actions[1]),
              ],
            ),
        ],
      ),
    );
  }
}

class _PinDigits extends StatelessWidget {
  const _PinDigits({required this.pin});

  final String pin;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      label: 'Trip PIN ${pin.split('').join(' ')}',
      child: ExcludeSemantics(
        child: Row(
          key: const Key('handoff_pin'),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < pin.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: ShapeDecoration(
                  color: p.ink,
                  shape: AlongCraft.border(_rControl),
                ),
                child: Text(
                  pin[i],
                  style: AlongType.title(p).copyWith(color: p.bg),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Trip receipt

class AlongReceiptLine {
  const AlongReceiptLine(this.label, this.amount, {this.detail});

  final String label;
  final int amount;
  final String? detail;
}

class AlongReceipt {
  const AlongReceipt({
    required this.route,
    required this.when,
    required this.driverName,
    required this.lines,
    required this.paidCash,
    required this.walletBalance,
  });

  final String route;
  final String when;
  final String driverName;
  final List<AlongReceiptLine> lines;

  /// Cash handed over. Anything above the fare goes to the wallet.
  final int paidCash;
  final int walletBalance;

  int get total => lines.fold(0, (sum, l) => sum + l.amount);
  int get change => (paidCash - total).clamp(0, 1 << 30);

  static const sample = AlongReceipt(
    route: 'Wuse Market to Nyanya',
    when: 'Today, 07:52',
    driverName: 'Musa',
    lines: [
      AlongReceiptLine('Base fare', 900),
      AlongReceiptLine('Distance', 450, detail: '8.2 km'),
      AlongReceiptLine('Waiting', 100, detail: '3 min'),
    ],
    paidCash: 2000,
    walletBalance: 4750,
  );
}

class AlongTripReceiptScreen extends StatefulWidget {
  const AlongTripReceiptScreen({
    super.key,
    required this.receipt,
    this.initialRating = 0,
    this.onRate,
    this.onDone,
    this.onRetry,
  });

  /// Null while the receipt has not reached the phone.
  final AlongReceipt? receipt;
  final int initialRating;
  final ValueChanged<int>? onRate;
  final VoidCallback? onDone;
  final VoidCallback? onRetry;

  @override
  State<AlongTripReceiptScreen> createState() => _AlongTripReceiptScreenState();
}

class _AlongTripReceiptScreenState extends State<AlongTripReceiptScreen> {
  late int _stars = widget.initialRating;

  void _rate(int value) {
    setState(() => _stars = value);
    AlongHaptics.tick(context);
    widget.onRate?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final r = widget.receipt;
    if (r == null) {
      return _Page(
        title: 'Receipt',
        children: [
          _StateBlock(
            icon: AlongIcons.receipt,
            title: 'Receipt not ready',
            body: 'It is still on its way. It will also be in Trips.',
            action: 'Try again',
            actionKey: const Key('receipt_retry'),
            onAction: widget.onRetry,
          ),
        ],
      );
    }
    return _Page(
      title: alongNaira(r.total),
      subtitle: r.route,
      meta: r.when,
      footer: AlongButton(
        key: const Key('receipt_done'),
        label: 'Done',
        onPressed: () {
          AlongHaptics.success(context);
          widget.onDone?.call();
        },
      ),
      children: [
        _Surface(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              for (final line in r.lines)
                _MoneyLine(
                  label: line.label,
                  detail: line.detail,
                  amount: alongNaira(line.amount),
                ),
              Divider(height: 17, thickness: 1, color: _hair(p).color),
              _MoneyLine(
                label: 'Fare',
                amount: alongNaira(r.total),
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Surface(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              _MoneyLine(label: 'Cash paid', amount: alongNaira(r.paidCash)),
              if (r.change > 0)
                _MoneyLine(
                  key: const Key('receipt_change'),
                  label: 'Change to wallet',
                  detail: 'Wallet now ${alongNaira(r.walletBalance)}',
                  amount: '+${alongNaira(r.change)}',
                  color: p.success,
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text('Rate ${r.driverName}', style: AlongType.title(p)),
        const SizedBox(height: 12),
        _Stars(value: _stars, onChanged: _rate),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final move = AlongMoves.select;
    return Row(
      key: const Key('receipt_stars'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            selected: i <= value,
            label: '$i star${i == 1 ? '' : 's'}',
            child: AlongPressable(
              child: Material(
                color: i <= value ? p.accent : p.recessed,
                shape: AlongCraft.border(_rControl),
                child: InkWell(
                  key: Key('receipt_star_$i'),
                  customBorder: AlongCraft.border(_rControl),
                  onTap: () => onChanged(i),
                  child: SizedBox(
                    width: 56,
                    height: 52,
                    child: Center(
                      child: AnimatedScale(
                        scale: i == value ? 1.08 : 1,
                        duration: move.of(context),
                        curve: move.curve,
                        child: AlongIcon(
                          AlongIcons.star,
                          size: 24,
                          color: i <= value ? p.accentInk : _soft(p),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Driver earnings

enum AlongPayoutState { scheduled, paid, failed }

class AlongEarnedTrip {
  const AlongEarnedTrip({
    required this.route,
    required this.when,
    required this.amount,
    this.method = 'Cash',
  });

  final String route;
  final String when;
  final int amount;
  final String method;
}

class AlongEarningsPeriod {
  const AlongEarningsPeriod({
    required this.total,
    required this.online,
    required this.trips,
  });

  final int total;

  /// "6h 40m".
  final String online;
  final List<AlongEarnedTrip> trips;

  static const today = AlongEarningsPeriod(
    total: 18400,
    online: '6h 40m',
    trips: [
      AlongEarnedTrip(
        route: 'Wuse Market to Nyanya',
        when: '07:52',
        amount: 1450,
      ),
      AlongEarnedTrip(
        route: 'Berger to Area 1',
        when: '07:10',
        amount: 900,
        method: 'Wallet',
      ),
      AlongEarnedTrip(route: 'Garki to Wuse 2', when: '06:41', amount: 1200),
      AlongEarnedTrip(
        route: 'Jabi Lake to Utako',
        when: '06:05',
        amount: 700,
        method: 'Transfer',
      ),
    ],
  );

  static const week = AlongEarningsPeriod(
    total: 96200,
    online: '38h 15m',
    trips: [
      AlongEarnedTrip(
        route: 'Wuse Market to Nyanya',
        when: 'Sun 07:52',
        amount: 1450,
      ),
      AlongEarnedTrip(
        route: 'Kubwa to Berger',
        when: 'Sat 18:20',
        amount: 2300,
      ),
      AlongEarnedTrip(
        route: 'Maitama to Garki',
        when: 'Sat 09:12',
        amount: 1100,
        method: 'Wallet',
      ),
    ],
  );

  static const empty = AlongEarningsPeriod(total: 0, online: '0m', trips: []);
}

class AlongPayout {
  const AlongPayout({
    required this.state,
    required this.amount,
    required this.when,
    required this.account,
  });

  final AlongPayoutState state;
  final int amount;

  /// "Friday" or "Paid Mon 09:00".
  final String when;

  /// "GTBank ••21".
  final String account;

  static const sample = AlongPayout(
    state: AlongPayoutState.scheduled,
    amount: 96200,
    when: 'Friday',
    account: 'GTBank ••21',
  );
}

class AlongDriverEarningsScreen extends StatefulWidget {
  const AlongDriverEarningsScreen({
    super.key,
    required this.today,
    required this.week,
    required this.payout,
    this.initialWeek = false,
    this.onFixPayout,
  });

  final AlongEarningsPeriod today;
  final AlongEarningsPeriod week;
  final AlongPayout payout;
  final bool initialWeek;
  final VoidCallback? onFixPayout;

  @override
  State<AlongDriverEarningsScreen> createState() =>
      _AlongDriverEarningsScreenState();
}

class _AlongDriverEarningsScreenState extends State<AlongDriverEarningsScreen> {
  late bool _week = widget.initialWeek;

  void _set(bool week) {
    if (week == _week) return;
    AlongHaptics.selection(context);
    setState(() => _week = week);
  }

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final period = _week ? widget.week : widget.today;
    final count = period.trips.length;
    final swap = AlongMoves.swap;
    return _Page(
      title: 'Earnings',
      children: [
        _Segmented(week: _week, onChanged: _set),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: swap.of(context),
          switchInCurve: swap.curve,
          switchOutCurve: swap.curve,
          child: Column(
            key: ValueKey(_week),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                alongNaira(period.total),
                key: const Key('earnings_total'),
                style: AlongType.numeric(p),
              ),
              const SizedBox(height: 4),
              Text(
                '$count ${count == 1 ? 'trip' : 'trips'} · ${period.online} online',
                style: AlongType.body(p).copyWith(color: _soft(p)),
              ),
              const SizedBox(height: 20),
              _PayoutCard(payout: widget.payout, onFix: widget.onFixPayout),
              const SizedBox(height: 32),
              Text('Trips', style: AlongType.title(p)),
              const SizedBox(height: 8),
              if (period.trips.isEmpty)
                _StateBlock(
                  icon: AlongIcons.receipt,
                  title: _week ? 'No trips this week' : 'No trips today',
                  body: 'Finished trips and what you made on each show here.',
                )
              else
                for (final trip in period.trips) _TripRow(trip: trip),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.week, required this.onChanged});

  final bool week;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final move = AlongMoves.select;
    Widget seg(String label, bool value) {
      final on = value == week;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            key: Key('earnings_${label.toLowerCase()}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: move.of(context),
              curve: move.curve,
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: on ? p.surface : p.recessed,
                shadows: on ? AlongElevation.rest(p.ink) : null,
                shape: AlongCraft.border(_rControl - 4),
              ),
              child: Text(
                label,
                style: AlongType.label(p).copyWith(
                  fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                  color: on ? p.ink : _soft(p),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: p.recessed,
        shape: AlongCraft.border(_rControl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(children: [seg('Today', false), seg('Week', true)]),
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.payout, this.onFix});

  final AlongPayout payout;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final (String status, Color tint, IconData icon) = switch (payout.state) {
      AlongPayoutState.scheduled => (
        'Payout ${payout.when}',
        p.ink,
        AlongIcons.schedule,
      ),
      AlongPayoutState.paid => (payout.when, p.success, AlongIcons.check),
      AlongPayoutState.failed => ('Payout failed', p.danger, AlongIcons.info),
    };
    return _Surface(
      key: const Key('earnings_payout'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AlongIcon(icon, size: 24, color: tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: AlongType.label(p)
                          .copyWith(color: tint, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payout.state == AlongPayoutState.failed
                          ? 'Check ${payout.account}'
                          : 'To ${payout.account}',
                      style: AlongType.caption(p).copyWith(color: _soft(p)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                alongNaira(payout.amount),
                textAlign: TextAlign.right,
                style: AlongType.label(p).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (payout.state == AlongPayoutState.failed) ...[
            const SizedBox(height: 16),
            AlongButton(
              key: const Key('earnings_fix_payout'),
              label: 'Update bank details',
              variant: AlongButtonVariant.secondary,
              onPressed: onFix,
            ),
          ],
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});

  final AlongEarnedTrip trip;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _Surface(
        corner: _rRow,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.route,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AlongType.label(p),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${trip.when} · ${trip.method}',
                    style: AlongType.caption(p).copyWith(color: _soft(p)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              alongNaira(trip.amount),
              textAlign: TextAlign.right,
              style: AlongType.label(p).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
