import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../components/seat_map.dart';
import '../craft.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../tokens.g.dart';
import '../type.dart';
import 'city_map.dart';
import 'delights.dart';
import 'driver_portrait.dart';

/// One ride row on home. Portrait, route, ETA. No nested card.
class AlongLiveStrip extends StatelessWidget {
  const AlongLiveStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final title = AlongType.body(palette)
        .copyWith(fontWeight: FontWeight.w600, height: 1.1);
    final meta = AlongType.caption(palette)
        .copyWith(color: palette.ink, fontWeight: FontWeight.w500, height: 1.1);
    return Container(
      key: const Key('live_strip'),
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: AlongCraft.fill(
        palette.surface,
        corner: AlongRadius.row.x,
        side: BorderSide(color: palette.ink.withValues(alpha: 0.14)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const AlongDriverPortrait(size: 40, verified: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chinedu · Nyanya',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: title,
                ),
                const SizedBox(height: 2),
                Text(
                  'On the way',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: meta,
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
        ],
      ),
    );
  }
}

/// Quote hold. The ring rests on the time still held. It does not tick.
class AlongFareLock extends StatelessWidget {
  const AlongFareLock({super.key, required this.clock, required this.progress});

  final String clock;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      key: const Key('fare_lock'),
      children: [
        _CountRing(progress: progress, size: 40, ink: palette.ink, stroke: 5),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clock,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AlongType.title(palette).copyWith(
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Fare held',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AlongType.label(palette).copyWith(color: palette.ink),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Arrival. The check is drawn at rest. A light haptic only while motion plays.
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
    return Row(
      key: const Key('arrival_mark'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: palette.ink, width: 1.5),
          ),
          child: AlongStrokeCheck(color: palette.ink, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          'Arrived',
          maxLines: 1,
          softWrap: false,
          style: AlongType.body(palette)
              .copyWith(fontWeight: FontWeight.w600, height: 1),
        ),
      ],
    );
  }
}

/// Earnings goal. The arc springs to the day's fraction, then rests.
class AlongGoalSpring extends StatefulWidget {
  const AlongGoalSpring({
    super.key,
    required this.progress,
    required this.label,
    this.size = 48,
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
              child: Text(
                widget.label,
                maxLines: 1,
                softWrap: false,
                style: AlongType.caption(palette).copyWith(
                  color: palette.ink,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
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
    required this.size,
    required this.ink,
    required this.stroke,
  });

  final double progress;
  final double size;
  final Color ink;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(
          progress: progress.clamp(0.0, 1.0),
          track: palette.ink.withValues(alpha: 0.16),
          ink: ink,
          strokeWidth: stroke,
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
    this.strokeWidth,
  });

  final double progress;
  final Color track;
  final Color ink;
  final double? strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth ?? math.max(3.0, size.width * 0.08)
      ..strokeCap = StrokeCap.round;
    // Half the stroke sits outside the path, so the outer edge is the box.
    final arc = (Offset.zero & size).deflate(stroke.strokeWidth / 2);
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

/// One row. The four languages open in a sheet, not a chip grid.
class AlongQuickReplies extends StatelessWidget {
  const AlongQuickReplies({super.key});

  static const lines = <(String, String)>[
    ('English', 'On my way'),
    ('Pidgin', 'I dey come'),
    ('Hausa', 'Ina zuwa'),
    ('Yoruba', 'Mo n bo'),
  ];

  void _open(BuildContext context) {
    final palette = AlongPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: AlongCraft.borderVertical(top: AlongRadius.sheet.x),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick reply', style: AlongType.title(palette)),
                const SizedBox(height: 8),
                for (final line in lines)
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            line.$1,
                            maxLines: 1,
                            softWrap: false,
                            style: AlongType.label(palette),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: AlongType.body(palette)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('quick_replies'),
        onTap: () => _open(context),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              AlongIcon(AlongIcons.chat, size: 20, color: palette.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Quick reply',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.body(palette)
                      .copyWith(fontWeight: FontWeight.w600, height: 1.1),
                ),
              ),
              AlongIcon(AlongIcons.caretRight, size: 20, color: palette.ink),
            ],
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
    final style = AlongType.caption(palette)
        .copyWith(color: palette.ink, fontWeight: FontWeight.w600, height: 1);
    return Container(
      key: const Key('break_nudge'),
      height: 48,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: AlongCraft.fill(
        palette.surface,
        corner: AlongRadius.control.x,
        side: BorderSide(color: palette.ink.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          AlongIcon(AlongIcons.schedule, size: 20, color: palette.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '4h online',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: style,
            ),
          ),
          const SizedBox(width: 8),
          Text('Take a break', maxLines: 1, softWrap: false, style: style),
        ],
      ),
    );
  }
}

/// Dawn, day, dusk, and night on the same street.
class AlongFlowPhases extends StatelessWidget {
  const AlongFlowPhases({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Light', style: AlongType.display(palette)),
        Text(
          'Dawn, day, dusk, night',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: AlongType.bodyMuted(palette),
        ),
        const SizedBox(height: 12),
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
          const SizedBox(width: 12),
          Expanded(child: _PhaseCell(phase: phases[start + 1])),
        ],
      );
      if (expand) return Expanded(child: pair);
      return SizedBox(height: 220, child: pair);
    }

    return Column(children: [row(0), const SizedBox(height: 12), row(2)]);
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
          child: AlongCraft.clip(
            corner: AlongRadius.card.x,
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
        const SizedBox(height: 6),
        Text(
          phase.dayName,
          maxLines: 1,
          softWrap: false,
          style: AlongType.label(palette).copyWith(
            color: palette.ink,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ],
    );
  }
}
