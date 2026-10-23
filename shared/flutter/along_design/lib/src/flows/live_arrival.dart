import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../components/seat_map.dart';
import '../craft.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';
import 'city_map.dart';
import 'delights.dart';
import 'driver_portrait.dart';

/// Pinned ride status on home. One portrait, one route, one ETA.
class AlongLiveStrip extends StatelessWidget {
  const AlongLiveStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final title = AlongType.body(palette).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.1,
    );
    final meta = AlongType.caption(palette).copyWith(
      color: palette.ink,
      fontWeight: FontWeight.w600,
      height: 1.1,
    );
    return SizedBox(
      key: const Key('live_strip'),
      height: 72,
      child: DecoratedBox(
        decoration: AlongCraft.surface(palette, radius: 16, hairline: true),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
            const AlongDriverPortrait(size: 40, verified: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chinedu · to Nyanya',
                      maxLines: 1,
                      softWrap: false,
                      style: title,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Keke · on the way',
                      maxLines: 1,
                      softWrap: false,
                      style: meta,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '4 min',
              maxLines: 1,
              softWrap: false,
              style: AlongType.title(palette).copyWith(height: 1),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// Quote lock. The ring rests on the time still held. It does not tick.
class AlongFareLock extends StatelessWidget {
  const AlongFareLock({
    super.key,
    required this.clock,
    required this.progress,
  });

  final String clock;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      key: const Key('fare_lock'),
      children: [
        _CountRing(progress: progress, label: clock, size: 56),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fare locked',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AlongType.title(palette).copyWith(height: 1.1),
              ),
              Text(
                'Holds this quote',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AlongType.caption(palette),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Arrival. The check draws on, then a light haptic. Rest is the drawn check.
class AlongArrivalMark extends StatefulWidget {
  const AlongArrivalMark({super.key});

  @override
  State<AlongArrivalMark> createState() => _AlongArrivalMarkState();
}

class _AlongArrivalMarkState extends State<AlongArrivalMark> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AlongMotionPolicy.play(context)) return;
      AlongHaptics.confirm(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      key: const Key('arrival_mark'),
      decoration: AlongCraft.surface(
        palette,
        radius: 999,
        shadow: AlongElevation.float(palette.ink),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.ink, width: 1.5),
                ),
                child: Center(
                  child: AlongStrokeCheck(color: palette.ink, size: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Arrived',
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette).copyWith(
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Earnings goal. The arc springs to the day's fraction, then rests.
class AlongGoalSpring extends StatefulWidget {
  const AlongGoalSpring({
    super.key,
    required this.progress,
    required this.label,
    this.size = 64,
  });

  final double progress;
  final String label;
  final double size;

  @override
  State<AlongGoalSpring> createState() => _AlongGoalSpringState();
}

class _AlongGoalSpringState extends State<AlongGoalSpring>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill;

  @override
  void initState() {
    super.initState();
    final end = widget.progress.clamp(0.0, 1.0);
    _fill = AnimationController.unbounded(vsync: this, value: end);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AlongMotionPolicy.play(context)) return;
      _fill.value = 0;
      _fill.animateWith(SpringSimulation(AlongSprings.route, 0, end, 0));
    });
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      key: const Key('goal_spring'),
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _fill,
        builder: (context, _) {
          return CustomPaint(
            painter: _ArcPainter(
              progress: _fill.value.clamp(0.0, 1.0),
              track: palette.recessed,
              ink: palette.accent,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.title(palette).copyWith(height: 1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CountRing extends StatelessWidget {
  const _CountRing({
    required this.progress,
    required this.label,
    required this.size,
  });

  final double progress;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(
          progress: progress.clamp(0.0, 1.0),
          track: palette.recessed,
          ink: palette.accent,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette).copyWith(
                fontWeight: FontWeight.w600,
                height: 1,
                color: palette.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.track,
    required this.ink,
  });

  final double progress;
  final Color track;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke.strokeWidth);
    canvas.drawArc(arc, 0, math.pi * 2, false, stroke..color = track);
    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      stroke..color = ink,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.ink != ink;
}

/// One canned line per language. The row stays one line high.
class AlongQuickReplies extends StatelessWidget {
  const AlongQuickReplies({super.key});

  static const lines = <(String, String)>[
    ('EN', 'On my way'),
    ('PCM', 'I dey come'),
    ('HA', 'Ina zuwa'),
    ('YO', 'Mo n bọ'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('quick_replies'),
      height: 36,
      child: Row(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _ReplyChip(code: lines[i].$1, phrase: lines[i].$2)),
          ],
        ],
      ),
    );
  }
}

class _ReplyChip extends StatelessWidget {
  const _ReplyChip({required this.code, required this.phrase});

  final String code;
  final String phrase;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(999),
        border: AlongElevation.hairline(palette.ink),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$code $phrase',
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette).copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Four hours online. The nudge is the rest state, not a ticking clock.
class AlongBreakNudge extends StatelessWidget {
  const AlongBreakNudge({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final style = AlongType.caption(palette).copyWith(
      color: palette.ink,
      fontWeight: FontWeight.w600,
      height: 1,
    );
    return DecoratedBox(
      key: const Key('break_nudge'),
      decoration: AlongCraft.surface(
        palette,
        radius: 999,
        shadow: AlongElevation.float(palette.ink),
      ),
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              AlongIcon(AlongIcons.schedule, size: 20, color: palette.ink),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '4h online',
                    maxLines: 1,
                    softWrap: false,
                    style: style,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Take a break',
                    maxLines: 1,
                    softWrap: false,
                    style: style,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dawn, day, dusk, and night on the same street, so the veil is the only change.
class AlongFlowPhases extends StatelessWidget {
  const AlongFlowPhases({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Map light', style: AlongType.display(palette)),
        Text(
          'Dawn, day, dusk, night',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: AlongType.bodyMuted(palette),
        ),
        const SizedBox(height: 8),
        if (roomy)
          const _PhaseGrid(expand: false)
        else
          const Expanded(child: _PhaseGrid(expand: true)),
      ],
    );
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: roomy ? SingleChildScrollView(child: body) : body,
        ),
      ),
    );
  }
}

class _PhaseGrid extends StatelessWidget {
  const _PhaseGrid({required this.expand});

  final bool expand;

  @override
  Widget build(BuildContext context) {
    const phases = [
      AlongDayPhase.morning,
      AlongDayPhase.afternoon,
      AlongDayPhase.evening,
      AlongDayPhase.night,
    ];
    Widget row(int start) {
      final pair = Row(
        children: [
          Expanded(child: _PhaseCell(phase: phases[start])),
          const SizedBox(width: 8),
          Expanded(child: _PhaseCell(phase: phases[start + 1])),
        ],
      );
      if (expand) return Expanded(child: pair);
      return SizedBox(height: 200, child: pair);
    }

    return Column(
      children: [
        row(0),
        const SizedBox(height: 8),
        row(2),
      ],
    );
  }
}

class _PhaseCell extends StatelessWidget {
  const _PhaseCell({required this.phase});

  final AlongDayPhase phase;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: AlongCraft.border(16)),
            child: AlongCityMap(
              phase: phase,
              zoom: 16,
              center: AlongCityMap.neighborhoodCenter,
              bare: true,
              demoLabel: false,
              fix: AlongFix.hidden,
              sheetInset: 0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          phase.dayName,
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette).copyWith(
            color: palette.ink,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ],
    );
  }
}
