import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../craft.dart';
import '../tokens.g.dart';
import '../utils/format_money.dart';
import 'along_button.dart';

/// Driver incoming request sheet (doc 05 §9 `RequestSheet`).
class RequestSheet extends StatelessWidget {
  const RequestSheet({
    super.key,
    this.pickup = 'Lugbe Park',
    this.dropoff = 'Area 1 Park',
    this.fareNaira = 450,
    this.alongFeeNaira = 34,
    this.hasLoad = false,
    this.loadNote,
    this.womenOnly = false,
    this.countdownSeconds = 15,
    this.countdownTotal = 30,
    this.onAccept,
    this.onDecline,
  });

  final String pickup;
  final String dropoff;
  final int fareNaira;
  final int alongFeeNaira;
  final bool hasLoad;
  final String? loadNote;
  final bool womenOnly;
  final int countdownSeconds;
  final int countdownTotal;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final progress = countdownSeconds / countdownTotal;

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(AlongSpace.s16),
      decoration: AlongCraft.fill(
        AlongColors.surface0,
        corner: AlongRadius.sheet.x,
        top: true,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('New request', style: AlongText.heading2),
              const Spacer(),
              SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: _CountdownRingPainter(progress: progress),
                  child: Center(
                    child: Text(
                      '${countdownSeconds}s',
                      style: AlongText.caption,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (womenOnly) ...[
            const SizedBox(height: AlongSpace.s8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AlongSpace.s8,
                vertical: AlongSpace.s4,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: AlongCraft.fill(
                AlongColors.semanticInfoTint,
                corner: AlongRadius.xs.x,
              ),
              child: Text(
                'Women-only match',
                style: AlongText.caption.copyWith(color: AlongColors.semanticInfo),
              ),
            ),
          ],
          const SizedBox(height: AlongSpace.s16),
          _LocationRow(icon: Icons.trip_origin, label: 'Pickup', value: pickup),
          const SizedBox(height: AlongSpace.s8),
          _LocationRow(icon: Icons.place_outlined, label: 'Drop-off', value: dropoff),
          const SizedBox(height: AlongSpace.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rider pays', style: AlongText.body),
              Text(
                formatMoney(fareNaira),
                style: AlongText.numericL,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
          const SizedBox(height: AlongSpace.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Along fee', style: AlongText.caption.copyWith(color: AlongColors.ink500)),
              Text(
                formatMoney(alongFeeNaira),
                style: AlongText.numericM.copyWith(color: AlongColors.ink500),
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
          if (hasLoad) ...[
            const SizedBox(height: AlongSpace.s12),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: AlongColors.semanticWarning, size: 20),
                const SizedBox(width: AlongSpace.s8),
                Expanded(
                  child: Text(
                    loadNote ?? 'Passenger flagged load',
                    style: AlongText.bodyStrong.copyWith(
                      color: AlongColors.semanticWarning,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AlongSpace.s16),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: AlongButton(
                  label: 'Accept',
                  variant: AlongButtonVariant.yellow,
                  onPressed: onAccept ?? () {},
                ),
              ),
              const SizedBox(width: AlongSpace.s12),
              Expanded(
                flex: 4,
                child: AlongButton(
                  label: 'Decline',
                  variant: AlongButtonVariant.secondary,
                  onPressed: onDecline ?? () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AlongColors.ink700),
        const SizedBox(width: AlongSpace.s8),
        Text('$label: ', style: AlongText.caption.copyWith(color: AlongColors.ink500)),
        Expanded(child: Text(value, style: AlongText.bodyStrong)),
      ],
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final track = Paint()
      ..color = AlongColors.surface200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final arc = Paint()
      ..color = AlongColors.brandYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
