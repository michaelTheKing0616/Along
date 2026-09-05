import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.g.dart';

/// Vehicle-count bucket for ambient map clusters (doc 05 §9).
enum AmbientClusterBucket { oneToTwo, threeToFive, sixPlus }

/// Map overlay disc showing ambient vehicle count and heading ticks.
///
/// Non-MapLibre visual for goldens; map integration lives in `along_map`.
class AmbientCluster extends StatelessWidget {
  const AmbientCluster({
    super.key,
    this.bucket = AmbientClusterBucket.threeToFive,
    required this.count,
    this.headingDegrees = const [],
    this.isStale = false,
  });

  final AmbientClusterBucket bucket;
  final int count;
  final List<double> headingDegrees;
  final bool isStale;

  double get _discDiameter => switch (bucket) {
        AmbientClusterBucket.oneToTwo => AlongSpace.sizeChip,
        AmbientClusterBucket.threeToFive => AlongSpace.sizeMapControl,
        AmbientClusterBucket.sixPlus => AlongSpace.sizeCtaSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final fill = isStale
        ? AlongColors.mapClusterFill.withValues(alpha: 0.12)
        : AlongColors.mapClusterFill;
    final stroke = isStale ? AlongColors.ink300 : AlongColors.mapClusterStroke;
    final textColor = isStale ? AlongColors.ink500 : AlongColors.ink900;
    final ticks = headingDegrees.take(3).toList();

    return SizedBox(
      width: _discDiameter + 16,
      height: _discDiameter + 16,
      child: CustomPaint(
        painter: _HeadingTicksPainter(
          headings: ticks,
          discRadius: _discDiameter / 2,
          tickColor: isStale ? AlongColors.ink300 : AlongColors.brandYellow,
        ),
        child: Center(
          child: Container(
            width: _discDiameter,
            height: _discDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: stroke, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: AlongText.label.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeadingTicksPainter extends CustomPainter {
  _HeadingTicksPainter({
    required this.headings,
    required this.discRadius,
    required this.tickColor,
  });

  final List<double> headings;
  final double discRadius;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (headings.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outer = discRadius + 6;
    final inner = discRadius + 2;
    final paint = Paint()
      ..color = tickColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final degrees in headings) {
      final radians = (degrees - 90) * math.pi / 180;
      final cos = math.cos(radians);
      final sin = math.sin(radians);
      canvas.drawLine(
        Offset(center.dx + inner * cos, center.dy + inner * sin),
        Offset(center.dx + outer * cos, center.dy + outer * sin),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeadingTicksPainter oldDelegate) =>
      oldDelegate.headings != headings ||
      oldDelegate.discRadius != discRadius ||
      oldDelegate.tickColor != tickColor;
}
