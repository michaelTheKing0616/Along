import 'package:flutter/material.dart';

import '../tokens.g.dart';
import '../utils/format_money.dart';
import '../utils/transport_mode.dart';
import 'mode_chip.dart';

/// Layout variants (doc 05 §9 `LegTimeline`).
enum LegTimelineVariant { compact, full }

/// Per-leg progress state on the timeline rail.
enum LegTimelineLegState { done, current, next, pending }

/// One leg row in a multi-modal itinerary.
class LegTimelineLeg {
  const LegTimelineLeg({
    required this.mode,
    required this.boardLabel,
    required this.alightLabel,
    this.fareNaira,
    this.etaAtTransfer,
    this.isWalk = false,
    this.state = LegTimelineLegState.pending,
  });

  final TransportMode mode;
  final String boardLabel;
  final String alightLabel;
  final int? fareNaira;
  final String? etaAtTransfer;
  final bool isWalk;
  final LegTimelineLegState state;
}

/// Vertical or compact leg timeline with mode-coloured rail segments.
class LegTimeline extends StatelessWidget {
  const LegTimeline({
    super.key,
    this.variant = LegTimelineVariant.full,
    required this.legs,
  });

  final LegTimelineVariant variant;
  final List<LegTimelineLeg> legs;

  @override
  Widget build(BuildContext context) {
    if (variant == LegTimelineVariant.compact) {
      return _CompactLegRow(legs: legs);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < legs.length; i++)
          _FullLegRow(
            leg: legs[i],
            isLast: i == legs.length - 1,
          ),
      ],
    );
  }
}

class _CompactLegRow extends StatelessWidget {
  const _CompactLegRow({required this.legs});

  final List<LegTimelineLeg> legs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < legs.length; i++) ...[
            if (i > 0) const SizedBox(width: AlongSpace.s8),
            _CompactLegChip(leg: legs[i]),
          ],
        ],
      ),
    );
  }
}

class _CompactLegChip extends StatelessWidget {
  const _CompactLegChip({required this.leg});

  final LegTimelineLeg leg;

  @override
  Widget build(BuildContext context) {
    final isActive = leg.state == LegTimelineLegState.current ||
        leg.state == LegTimelineLegState.next;
    final opacity = leg.state == LegTimelineLegState.pending ? 0.45 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AlongSpace.s8,
          vertical: AlongSpace.s4,
        ),
        decoration: BoxDecoration(
          color: isActive ? leg.mode.tintColor : AlongColors.surface100,
          borderRadius: BorderRadius.circular(AlongRadius.sm.x),
          border: isActive
              ? Border.all(color: leg.mode.fillColor, width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              leg.isWalk ? Icons.directions_walk_rounded : leg.mode.icon,
              size: 16,
              color: leg.isWalk ? AlongColors.ink700 : leg.mode.fillColor,
            ),
            const SizedBox(width: AlongSpace.s4),
            Text(
              leg.isWalk ? 'Walk' : leg.mode.label,
              style: AlongText.caption.copyWith(
                color: AlongColors.ink900,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullLegRow extends StatelessWidget {
  const _FullLegRow({
    required this.leg,
    required this.isLast,
  });

  final LegTimelineLeg leg;
  final bool isLast;

  Color get _segmentColor {
    if (leg.isWalk) return AlongColors.mapRouteWalk;
    return switch (leg.state) {
      LegTimelineLegState.done => leg.mode.fillColor.withValues(alpha: 0.5),
      LegTimelineLegState.current => leg.mode.fillColor,
      LegTimelineLegState.next => leg.mode.fillColor.withValues(alpha: 0.75),
      LegTimelineLegState.pending => AlongColors.ink300,
    };
  }

  @override
  Widget build(BuildContext context) {
    final opacity = leg.state == LegTimelineLegState.pending ? 0.55 : 1.0;
    final isCurrent = leg.state == LegTimelineLegState.current;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : AlongSpace.s8),
        padding: isCurrent
            ? const EdgeInsets.all(AlongSpace.s12)
            : EdgeInsets.zero,
        decoration: isCurrent
            ? BoxDecoration(
                color: AlongColors.surface50,
                borderRadius: BorderRadius.circular(AlongRadius.md.x),
                border: Border.all(color: leg.mode.fillColor, width: 1),
              )
            : null,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    _RailDot(
                      color: _segmentColor,
                      dashed: leg.isWalk,
                      state: leg.state,
                    ),
                    if (!isLast)
                      Expanded(
                        child: CustomPaint(
                          painter: _RailSegmentPainter(
                            color: _segmentColor,
                            dashed: leg.isWalk,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AlongSpace.s12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : AlongSpace.s8,
                    top: isCurrent ? 0 : AlongSpace.s4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCurrent)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AlongSpace.s4),
                          child: Text(
                            'NOW',
                            style: AlongText.overline.copyWith(
                              color: leg.mode.fillColor,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          if (!leg.isWalk)
                            ModeChip(
                              mode: leg.mode,
                              size: ModeChipSize.small,
                              selected: isCurrent,
                            )
                          else
                            Icon(
                              Icons.directions_walk_rounded,
                              size: 18,
                              color: AlongColors.ink700,
                            ),
                          const SizedBox(width: AlongSpace.s8),
                          Expanded(
                            child: Text(
                              '${leg.boardLabel} → ${leg.alightLabel}',
                              style: (isCurrent
                                      ? AlongText.bodyStrong
                                      : AlongText.body)
                                  .copyWith(
                                color: switch (leg.state) {
                                  LegTimelineLegState.current =>
                                    AlongColors.ink900,
                                  LegTimelineLegState.done =>
                                    AlongColors.ink500,
                                  _ => AlongColors.ink700,
                                },
                                decoration: leg.state == LegTimelineLegState.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (leg.fareNaira != null || leg.etaAtTransfer != null) ...[
                        const SizedBox(height: AlongSpace.s4),
                        Row(
                          children: [
                            if (leg.fareNaira != null)
                              Text(
                                formatMoney(leg.fareNaira!),
                                style: AlongText.numericM.copyWith(
                                  color: leg.state == LegTimelineLegState.pending
                                      ? AlongColors.ink500
                                      : AlongColors.ink900,
                                ),
                                softWrap: false,
                                overflow: TextOverflow.visible,
                              ),
                            if (leg.fareNaira != null && leg.etaAtTransfer != null)
                              Text(
                                ' · ',
                                style: AlongText.caption.copyWith(
                                  color: AlongColors.ink500,
                                ),
                              ),
                            if (leg.etaAtTransfer != null)
                              Text(
                                leg.etaAtTransfer!,
                                style: AlongText.caption.copyWith(
                                  color: AlongColors.ink500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
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

class _RailDot extends StatelessWidget {
  const _RailDot({
    required this.color,
    required this.dashed,
    required this.state,
  });

  final Color color;
  final bool dashed;
  final LegTimelineLegState state;

  @override
  Widget build(BuildContext context) {
    if (state == LegTimelineLegState.done) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(
          Icons.check_rounded,
          size: 12,
          color: AlongColors.surface0,
        ),
      );
    }

    if (state == LegTimelineLegState.current) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: AlongColors.surface0, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 0,
              spreadRadius: 2,
            ),
          ],
        ),
      );
    }

    if (dashed) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      );
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RailSegmentPainter extends CustomPainter {
  _RailSegmentPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (dashed) {
      const dashHeight = 4.0;
      const gap = 4.0;
      var y = 0.0;
      while (y < size.height) {
        final end = (y + dashHeight).clamp(0.0, size.height);
        canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2, end.toDouble()),
          paint,
        );
        y += dashHeight + gap;
      }
    } else {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RailSegmentPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}
