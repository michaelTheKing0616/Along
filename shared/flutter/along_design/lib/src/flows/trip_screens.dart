import 'dart:async';

import 'package:along_core/along_core.dart' show TripEta, TripEtaStop;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

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
    this.fill,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final List<Widget> children;
  final Widget? footer;

  /// Replaces the scrolling body: centred in the space above [footer].
  final Widget? fill;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fill != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(_gutter, 24, _gutter, 0),
                child: Text(title, style: AlongType.display(p)),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: _gutter),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: Center(child: fill),
                    ),
                  ),
                ),
              ),
            ] else
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          _gutter,
                          24,
                          _gutter,
                          32,
                        ),
                        children: [
                          Text(title, style: AlongType.display(p)),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: AlongType.body(p)
                                  .copyWith(color: _soft(p)),
                            ),
                          ],
                          if (meta != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              meta!,
                              style: AlongType.label(p)
                                  .copyWith(color: _soft(p)),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ...children,
                        ],
                      ),
                    ),
                    if (footer != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 32,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            key: const Key('page_footer_fade'),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [p.bg.withValues(alpha: 0), p.bg],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (footer != null)
              DecoratedBox(
                decoration: BoxDecoration(color: p.bg),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(_gutter, 4, _gutter, 16),
                  child: footer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A whole-page empty or failure state: icon tile, title, body, centred.
class _FullState extends StatelessWidget {
  const _FullState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconTile(icon: icon, size: 72, radius: _rCard, glyph: 36),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: AlongType.title(p)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: AlongType.body(p).copyWith(color: _soft(p)),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    this.size = 48,
    this.radius = _rControl,
    this.glyph = 24,
  });

  final IconData icon;
  final double size;
  final double radius;
  final double glyph;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: p.ink.withValues(alpha: 0.06),
        shape: AlongCraft.border(radius),
      ),
      child: AlongIcon(icon, size: glyph, color: p.ink),
    );
  }
}

class _StateBlock extends StatelessWidget {
  const _StateBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final tint = p.ink;
    return _Surface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(icon: icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AlongType.title(p).copyWith(color: tint),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: AlongType.body(p).copyWith(color: _soft(p)),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    this.onMessage,
    this.messageLabel,
    this.unread = 0,
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

  /// In-car chat entry; hidden when null.
  final VoidCallback? onMessage;

  /// Localised "Message {driver}"; defaults to English.
  final String? messageLabel;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
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
          AlongLiveEtaPanel(
            eta: eta,
            previous: previous,
            destination: destination,
            failed: failed,
            onRetry: onRetry,
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
          if (onMessage != null) ...[
            const SizedBox(height: 16),
            AlongUnreadBadge(
              count: unread,
              child: AlongButton(
                key: const Key('live_message'),
                label: messageLabel ?? 'Message $driverName',
                variant: AlongButtonVariant.secondary,
                onPressed: onMessage,
              ),
            ),
          ],
          if (stops.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final stop in stops) _StopLine(stop: stop),
          ],
        ],
      ),
    );
  }
}

/// ETA readout: destination line, median to p85 window, and the notices.
/// Embedded in the rider app's live trip sheet and in [AlongLiveTripScreen].
class AlongLiveEtaPanel extends StatelessWidget {
  const AlongLiveEtaPanel({
    super.key,
    required this.eta,
    required this.destination,
    this.previous,
    this.failed = false,
    this.onRetry,
  });

  final TripEta? eta;
  final TripEta? previous;
  final String destination;
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final window = AlongEtaWindow.fromEta(eta);
    final slow = failed ? null : alongEtaSlowdownMinutes(previous, eta);
    final line = window == null
        ? 'Working out your arrival'
        : failed
        ? 'Last estimate to $destination'
        : 'Arriving at $destination';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          line,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AlongType.label(p).copyWith(color: _soft(p)),
        ),
        const SizedBox(height: 4),
        _EtaHeadline(window: window, eta: eta, failed: failed),
        AnimatedSwitcher(
          duration: AlongMoves.arrive.of(context),
          switchInCurve: AlongMoves.arrive.curve,
          switchOutCurve: AlongMoves.arrive.curve,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
          child: slow == null && !failed
              ? const SizedBox(key: ValueKey('none'), width: double.infinity)
              : Padding(
                  key: ValueKey(failed ? 'paused' : 'slow'),
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
      ],
    );
  }
}

/// Placeholder for the ETA window while the estimator has no reading yet.
/// Breathes on [AlongMoves.breathe]; holds still when motion is off.
class _EtaSkeleton extends StatefulWidget {
  const _EtaSkeleton();

  @override
  State<_EtaSkeleton> createState() => _EtaSkeletonState();
}

class _EtaSkeletonState extends State<_EtaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AlongMoves.breathe.duration,
    value: 0.5,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AlongMotionPolicy.play(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c
        ..stop()
        ..value = 0.5;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    Widget bar(double w, double h, double r, Color c) => Container(
      width: w,
      height: h,
      decoration: ShapeDecoration(color: c, shape: AlongCraft.border(r)),
    );
    return Semantics(
      liveRegion: true,
      label: 'Working out your arrival',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = AlongMoves.breathe.curve.transform(_c.value);
            final strong = p.ink.withValues(alpha: 0.10 + 0.08 * t);
            final light = p.ink.withValues(alpha: 0.08 + 0.06 * t);
            return Row(
              key: const Key('live_eta_calculating'),
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                bar(136, 40, 12, strong),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: bar(88, 20, 6, light),
                ),
              ],
            );
          },
        ),
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
      return const _EtaSkeleton();
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
                    minimumSize: const Size(48, 48),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class AlongPickupHandoffScreen extends StatelessWidget {
  const AlongPickupHandoffScreen({
    super.key,
    required this.secondsAway,
    required this.driverName,
    required this.plate,
    required this.car,
    required this.pickupPoint,
    this.pin,
    this.onCall,
    this.onMessage,
    this.onNewPin,
    this.unread = 0,
  });

  final int secondsAway;
  final String driverName;
  final String plate;
  final String car;
  final String pickupPoint;
  final String? pin;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onNewPin;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return _MapSheet(
      map: AlongCityMap(
        approach: true,
        bare: true,
        pickupPin: true,
        progress: (1 - secondsAway / 300).clamp(0.12, 0.86),
        // Route sits in the top third, clear of the sheet.
        center: const LatLng(9.05790, 7.46690),
        zoom: 16,
        sheetInset: 0.6,
        demoLabel: false,
      ),
      sheet: AlongHandoffPanel(
        secondsAway: secondsAway,
        driverName: driverName,
        plate: plate,
        car: car,
        pickupPoint: pickupPoint,
        pin: pin,
        onCall: onCall,
        onMessage: onMessage,
        onNewPin: onNewPin,
        unread: unread,
      ),
    );
  }
}

/// Driver-arrival phase: countdown, pickup point, plate and car, PIN.
/// Embedded in the rider app's live trip sheet while the driver approaches.
class AlongHandoffPanel extends StatefulWidget {
  const AlongHandoffPanel({
    super.key,
    required this.secondsAway,
    required this.driverName,
    required this.plate,
    required this.car,
    required this.pickupPoint,
    this.pin,
    this.onCall,
    this.onMessage,
    this.onNewPin,
    this.unread = 0,
  });

  /// Seconds until the driver reaches the pickup point. 0 means arrived.
  final int secondsAway;
  final String driverName;
  final String plate;

  /// "Silver Toyota Corolla".
  final String car;
  final String pickupPoint;

  /// Digits the rider says before getting in. Hidden when the trip has none.
  final String? pin;

  /// Actions hide when neither is available.
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  /// Rider asks for a fresh PIN (for example after the driver locked it).
  /// Null hides the action.
  final VoidCallback? onNewPin;

  /// Unread chat lines; badges the Message button.
  final int unread;

  @override
  State<AlongHandoffPanel> createState() => _AlongHandoffPanelState();
}

class _AlongHandoffPanelState extends State<AlongHandoffPanel> {
  late int _left = widget.secondsAway;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    _timer = AlongMotionPolicy.play(context) && _left > 0
        ? Timer.periodic(const Duration(seconds: 1), (_) => _tick())
        : null;
  }

  @override
  void didUpdateWidget(AlongHandoffPanel old) {
    super.didUpdateWidget(old);
    if (old.secondsAway != widget.secondsAway) {
      _left = widget.secondsAway;
      _arm();
    }
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
      if (widget.onCall != null)
        AlongButton(
          key: const Key('handoff_call'),
          label: 'Call',
          variant: AlongButtonVariant.secondary,
          onPressed: widget.onCall,
        ),
      if (widget.onMessage != null)
        AlongUnreadBadge(
          count: widget.unread,
          child: AlongButton(
            key: const Key('handoff_message'),
            label: 'Message',
            variant: AlongButtonVariant.secondary,
            onPressed: widget.onMessage,
          ),
        ),
    ];
    final pin = widget.pin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
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
          child: Semantics(
            liveRegion: true,
            label: here ? 'Driver is here' : '$mm minutes $ss seconds',
            child: ExcludeSemantics(
              child: Text(
                here ? 'Meet at pickup' : '$mm:$ss',
                key: const Key('handoff_countdown'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: here
                    ? AlongType.display(p)
                    : AlongType.numeric(p).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: AlongIcon(AlongIcons.locate, size: 20, color: p.ink),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.pickupPoint,
                key: const Key('handoff_pickup'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AlongType.body(p),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AlongType.numeric(p).copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 2),
              Text(
                widget.car,
                style: AlongType.body(p).copyWith(color: _soft(p)),
              ),
            ],
          ),
        ),
        if (pin != null && pin.isNotEmpty) ...[
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
              _PinDigits(pin: pin),
            ],
          ),
          if (widget.onNewPin != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: _InlineAction(
                key: const Key('handoff_new_pin'),
                label: 'Get a new PIN',
                onTap: widget.onNewPin!,
              ),
            ),
          ],
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 20),
          if (roomy || actions.length == 1)
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              actions[i],
            ]
          else
            Row(
              children: [
                Expanded(child: actions[0]),
                const SizedBox(width: 12),
                Expanded(child: actions[1]),
              ],
            ),
        ],
      ],
    );
  }
}

/// Quiet text action with a 44 pt tap height, for secondary steps inside
/// a card. Ink label, underline-free, squircle press highlight.
class _InlineAction extends StatelessWidget {
  const _InlineAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Transform.translate(
      offset: const Offset(-8, 0),
      child: Material(
        color: Colors.transparent,
        shape: AlongCraft.border(_rControl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AlongIcon(AlongIcons.password, size: 20, color: p.ink),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AlongType.label(p)
                        .copyWith(fontWeight: FontWeight.w600),
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
    this.paidCash,
    this.walletBalance,
    this.fareTotal,
  });

  final String route;
  final String when;
  final String driverName;
  final List<AlongReceiptLine> lines;

  /// Cash handed over. Anything above the fare goes to the wallet.
  /// Null when the rider paid digitally or the server did not report cash.
  final int? paidCash;
  final int? walletBalance;

  /// Server total when it differs from the sum of [lines].
  final int? fareTotal;

  int get total => fareTotal ?? lines.fold(0, (sum, l) => sum + l.amount);
  int get change {
    final cash = paidCash;
    if (cash == null) return 0;
    return (cash - total).clamp(0, 1 << 30);
  }

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
    this.ratingTags = const {},
    this.initialTags = const {},
    this.onTagsChanged,
    this.onDone,
    this.onRetry,
  });

  /// Null while the receipt has not reached the phone.
  final AlongReceipt? receipt;
  final int initialRating;
  final ValueChanged<int>? onRate;

  /// Tag id to label. Shown once a star is tapped; empty hides the row.
  final Map<String, String> ratingTags;
  final Set<String> initialTags;
  final ValueChanged<Set<String>>? onTagsChanged;
  final VoidCallback? onDone;
  final VoidCallback? onRetry;

  @override
  State<AlongTripReceiptScreen> createState() => _AlongTripReceiptScreenState();
}

class _AlongTripReceiptScreenState extends State<AlongTripReceiptScreen> {
  late int _stars = widget.initialRating;
  late final Set<String> _tags = {...widget.initialTags};

  void _toggle(String id) {
    setState(() => _tags.contains(id) ? _tags.remove(id) : _tags.add(id));
    AlongHaptics.tick(context);
    widget.onTagsChanged?.call(Set.unmodifiable(_tags));
  }

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
        fill: const _FullState(
          icon: AlongIcons.receipt,
          title: 'Receipt not ready',
          body: 'It is still on its way. It will also be in Trips.',
        ),
        footer: AlongButton(
          key: const Key('receipt_retry'),
          label: 'Try again',
          onPressed: widget.onRetry,
        ),
        children: const [],
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How was ${r.driverName}?', style: AlongType.title(p)),
              const SizedBox(height: 8),
              _Stars(value: _stars, onChanged: _rate),
              _Reveal(
                child: _stars == 0 || widget.ratingTags.isEmpty
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Wrap(
                          key: const Key('receipt_tags'),
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final e in widget.ratingTags.entries)
                              _TagChip(
                                key: Key('receipt_tag_${e.key}'),
                                label: e.value,
                                selected: _tags.contains(e.key),
                                onTap: () => _toggle(e.key),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Fare', style: AlongType.label(p).copyWith(color: _soft(p))),
        const SizedBox(height: 8),
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
                label: 'Total',
                amount: alongNaira(r.total),
                strong: true,
              ),
            ],
          ),
        ),
        if (r.paidCash != null) ...[
          const SizedBox(height: 12),
          _Surface(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                _MoneyLine(label: 'Cash paid', amount: alongNaira(r.paidCash!)),
                if (r.change > 0)
                  _MoneyLine(
                    key: const Key('receipt_change'),
                    label: 'Change to wallet',
                    detail: r.walletBalance == null
                        ? null
                        : 'Wallet now ${alongNaira(r.walletBalance!)}',
                    amount: '+${alongNaira(r.change)}',
                    color: p.success,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Grows to fit its child on [AlongMoves.arrive]. With motion off it lays
/// out at once: AnimatedSize with a zero duration re-dirties itself.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AlongMotionPolicy.play(context)) return child;
    return AnimatedSize(
      duration: AlongMoves.arrive.duration,
      curve: AlongMoves.arrive.curve,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// Rating tag: a radius-16 squircle, never a pill. Selected is solid ink.
class _TagChip extends StatelessWidget {
  const _TagChip({
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
    final shape = AlongCraft.border(
      _rControl,
      side: selected ? BorderSide.none : _hair(p),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? p.ink : Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    AlongIcon(AlongIcons.check, size: 16, color: p.onInk),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AlongType.label(p)
                        .copyWith(color: selected ? p.bg : p.ink),
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

/// Five stars. Selected stars are ink, the rest a quiet outline tone; the
/// tapped star pops on [AlongMoves.pop]. No filled tiles.
class _Stars extends StatefulWidget {
  const _Stars({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_Stars> createState() => _StarsState();
}

class _StarsState extends State<_Stars> {
  int _taps = 0;
  int? _last;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final pop = AlongMoves.pop;
    final play = AlongMotionPolicy.play(context);
    return Row(
      key: const Key('receipt_stars'),
      children: [
        for (var i = 1; i <= 5; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i <= widget.value,
              label: '$i star${i == 1 ? '' : 's'}',
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: Key('receipt_star_$i'),
                  customBorder: AlongCraft.border(_rControl),
                  onTap: () {
                    setState(() {
                      _last = i;
                      _taps++;
                    });
                    widget.onChanged(i);
                  },
                  child: SizedBox(
                    height: 56,
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(i == _last ? 'pop$_taps' : 'still$i'),
                        tween: Tween(
                          begin: i == _last && play ? 0.72 : 1,
                          end: 1,
                        ),
                        duration: pop.of(context),
                        curve: pop.curve,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: i <= widget.value
                            ? AlongIcon(
                                AlongIcons.star,
                                size: 36,
                                color: p.ink,
                                toneColor: p.accent,
                              )
                            : AlongIcon(
                                AlongIcons.star,
                                size: 36,
                                tone: false,
                                color: p.ink.withValues(alpha: 0.36),
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

/// One bar of the earnings chart: an hour block for Today, a day for Week.
class AlongEarningsBar {
  const AlongEarningsBar(this.label, this.amount);

  final String label;
  final int amount;
}

class AlongEarningsPeriod {
  const AlongEarningsPeriod({
    required this.total,
    required this.trips,
    this.online,
    this.bars = const [],
    this.highlight,
  });

  final int total;

  /// "6h 40m". Null when the app has no online-time record.
  final String? online;
  final List<AlongEarnedTrip> trips;
  final List<AlongEarningsBar> bars;

  /// Index of the current bar (this hour block, today).
  final int? highlight;

  static const today = AlongEarningsPeriod(
    total: 18400,
    online: '6h 40m',
    highlight: 1,
    bars: [
      AlongEarningsBar('6a', 4200),
      AlongEarningsBar('8a', 5800),
      AlongEarningsBar('10a', 2100),
      AlongEarningsBar('12p', 1500),
      AlongEarningsBar('2p', 0),
      AlongEarningsBar('4p', 0),
      AlongEarningsBar('6p', 0),
      AlongEarningsBar('8p', 0),
    ],
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
    highlight: 6,
    bars: [
      AlongEarningsBar('M', 14800),
      AlongEarningsBar('T', 12300),
      AlongEarningsBar('W', 16900),
      AlongEarningsBar('T', 19400),
      AlongEarningsBar('F', 9800),
      AlongEarningsBar('S', 4600),
      AlongEarningsBar('S', 18400),
    ],
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

  static const emptyToday = AlongEarningsPeriod(
    total: 0,
    trips: [],
    bars: [
      AlongEarningsBar('6a', 0),
      AlongEarningsBar('8a', 0),
      AlongEarningsBar('10a', 0),
      AlongEarningsBar('12p', 0),
      AlongEarningsBar('2p', 0),
      AlongEarningsBar('4p', 0),
      AlongEarningsBar('6p', 0),
      AlongEarningsBar('8p', 0),
    ],
  );

  static const empty = AlongEarningsPeriod(
    total: 0,
    trips: [],
    bars: [
      AlongEarningsBar('M', 0),
      AlongEarningsBar('T', 0),
      AlongEarningsBar('W', 0),
      AlongEarningsBar('T', 0),
      AlongEarningsBar('F', 0),
      AlongEarningsBar('S', 0),
      AlongEarningsBar('S', 0),
    ],
  );
}

class AlongPayout {
  const AlongPayout({
    required this.state,
    required this.amount,
    required this.when,
    this.account,
  });

  final AlongPayoutState state;
  final int amount;

  /// "Friday" or "Paid Mon 09:00".
  final String when;

  /// "Paystack ••4821". Null when the app does not know the account.
  final String? account;

  static const sample = AlongPayout(
    state: AlongPayoutState.scheduled,
    amount: 96200,
    when: 'sent Fri',
    account: 'GTBank ••4821',
  );
}

class AlongDriverEarningsScreen extends StatelessWidget {
  const AlongDriverEarningsScreen({
    super.key,
    required this.today,
    required this.week,
    this.payout,
    this.initialWeek = false,
    this.onFixPayout,
  });

  final AlongEarningsPeriod today;
  final AlongEarningsPeriod week;
  final AlongPayout? payout;
  final bool initialWeek;
  final VoidCallback? onFixPayout;

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Earnings',
      children: [
        AlongEarningsSummary(
          today: today,
          week: week,
          payout: payout,
          initialWeek: initialWeek,
          onFixPayout: onFixPayout,
        ),
      ],
    );
  }
}

/// Today/Week switch, hero total with bar chart, payout, trip list.
/// Embedded at the top of the driver app's earnings tab.
class AlongEarningsSummary extends StatefulWidget {
  const AlongEarningsSummary({
    super.key,
    required this.today,
    required this.week,
    this.payout,
    this.initialWeek = false,
    this.onFixPayout,
    this.maxTrips,
  });

  final AlongEarningsPeriod today;
  final AlongEarningsPeriod week;
  final AlongPayout? payout;
  final bool initialWeek;
  final VoidCallback? onFixPayout;

  /// Caps the trip list when embedded above other sections.
  final int? maxTrips;

  @override
  State<AlongEarningsSummary> createState() => _AlongEarningsSummaryState();
}

class _AlongEarningsSummaryState extends State<AlongEarningsSummary> {
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
    final trips = widget.maxTrips == null
        ? period.trips
        : period.trips.take(widget.maxTrips!).toList();
    final meta = count == 0
        ? 'No trips yet'
        : [
            '$count ${count == 1 ? 'trip' : 'trips'}',
            if (period.online != null) '${period.online} online',
          ].join(' · ');
    final payout = widget.payout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Segmented(week: _week, onChanged: _set),
        const SizedBox(height: 16),
        _Surface(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Roll(
                value: '$_week${period.total}',
                child: Text(
                  alongNaira(period.total),
                  key: const Key('earnings_total'),
                  style: AlongType.numeric(p).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(meta, style: AlongType.label(p).copyWith(color: _soft(p))),
              if (period.bars.isNotEmpty) ...[
                const SizedBox(height: 20),
                _Bars(period: period),
              ],
            ],
          ),
        ),
        if (payout != null) ...[
          const SizedBox(height: 12),
          _PayoutCard(payout: payout, onFix: widget.onFixPayout),
        ],
        const SizedBox(height: 28),
        Text('Trips', style: AlongType.title(p)),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: swap.of(context),
          switchInCurve: swap.curve,
          switchOutCurve: swap.curve,
          child: Column(
            key: ValueKey(_week),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (trips.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _StateBlock(
                    icon: AlongIcons.receipt,
                    title: _week ? 'No trips this week' : 'No trips today',
                    body: 'Finished trips and what you made on each show here.',
                  ),
                )
              else
                for (final trip in trips) _TripRow(trip: trip),
            ],
          ),
        ),
      ],
    );
  }
}

/// Earnings bars. Squircle tops, tabular labels, the current bar in accent.
class _Bars extends StatelessWidget {
  const _Bars({required this.period});

  final AlongEarningsPeriod period;

  static const _plot = 88.0;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final bars = period.bars;
    final peak = bars.fold<int>(0, (m, b) => b.amount > m ? b.amount : m);
    final move = AlongMoves.swap;
    final tabular = AlongType.caption(p).copyWith(
      color: _soft(p),
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final best = peak == 0 ? null : bars.indexWhere((b) => b.amount == peak);
    // Large text: every other label so none clip; the current one stays.
    final thin =
        bars.length > 7 && MediaQuery.textScalerOf(context).scale(10) >= 12.5;
    return Semantics(
      label: peak == 0
          ? 'No earnings yet'
          : 'Best ${bars[best!].label}, ${alongNaira(peak)}',
      child: ExcludeSemantics(
        child: Column(
          key: const Key('earnings_bars'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _plot,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: _hair(p).color,
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < bars.length; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AnimatedContainer(
                                duration: move.of(context),
                                curve: move.curve,
                                height: peak == 0
                                    ? 6
                                    : (bars[i].amount / peak * _plot).clamp(
                                        6,
                                        _plot,
                                      ),
                                decoration: ShapeDecoration(
                                  color: i == period.highlight
                                      ? p.accent
                                      : bars[i].amount == 0
                                      ? p.ink.withValues(alpha: 0.08)
                                      : p.ink.withValues(alpha: 0.22),
                                  shape: AlongCraft.border(
                                    bars[i].amount == 0 || peak == 0 ? 2 : 8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < bars.length; i++)
                  Expanded(
                    child: Text(
                      thin && i.isOdd && i != period.highlight
                          ? ''
                          : bars[i].label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: i == period.highlight
                          ? tabular.copyWith(
                              color: p.ink,
                              fontWeight: FontWeight.w600,
                            )
                          : tabular,
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
              constraints: const BoxConstraints(minHeight: 48),
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
    final account = payout.account;
    return _Surface(
      key: const Key('earnings_payout'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: tint.withValues(alpha: 0.12),
                  shape: AlongCraft.border(_rControl),
                ),
                child: AlongIcon(icon, size: 28, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AlongType.label(p).copyWith(
                              color: tint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          alongNaira(payout.amount),
                          textAlign: TextAlign.right,
                          style: AlongType.body(p).copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    if (account != null) ...[
                      const SizedBox(height: 2),
                      _AccountLine(
                        prefix: payout.state == AlongPayoutState.failed
                            ? 'Check'
                            : 'To',
                        account: account,
                      ),
                    ],
                  ],
                ),
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

/// "To GTBank ••4821" on one line at any text scale: the bank name gives
/// way (ellipsis) so the last four digits always stay visible.
class _AccountLine extends StatelessWidget {
  const _AccountLine({required this.prefix, required this.account});

  final String prefix;
  final String account;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final style = AlongType.caption(p).copyWith(color: _soft(p));
    final cut = account.lastIndexOf(' ••');
    final name = cut < 0 ? account : account.substring(0, cut);
    final tail = cut < 0 ? '' : account.substring(cut);
    return Row(
      key: const Key('earnings_payout_account'),
      children: [
        Flexible(
          child: Text(
            '$prefix $name',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (tail.isNotEmpty)
          Text(tail, maxLines: 1, softWrap: false, style: style),
      ],
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

/// Unread count on a button's top-right corner, overlapping the edge by
/// 6 px so it stays clear of the centred label. Pops in on [AlongMoves.pop].
/// Hidden at zero.
class AlongUnreadBadge extends StatelessWidget {
  const AlongUnreadBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -6,
          right: -6,
          child: Center(
            child: AnimatedScale(
              scale: count > 0 ? 1 : 0,
              duration: AlongMoves.pop.of(context),
              curve: AlongMoves.pop.curve,
              child: Container(
                key: const Key('handoff_message_unread'),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: const EdgeInsets.symmetric(horizontal: 7),

                decoration: AlongCraft.fill(p.danger, corner: 8),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    textScaler: TextScaler.noScaling,
                    style: AlongType.caption(
                      p,
                    ).copyWith(color: p.dangerOn, fontWeight: FontWeight.w700),
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
