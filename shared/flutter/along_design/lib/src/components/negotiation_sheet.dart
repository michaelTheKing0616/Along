import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.g.dart';
import '../utils/format_money.dart';
import 'along_button.dart';

/// Negotiation context variants (doc 05 §9 `NegotiationSheet`).
enum NegotiationSheetVariant {
  park,
  roamingNone,
  roamingSingle,
  roamingFull,
  extension,
}

/// Pre-commit fare negotiation sheet — dumb UI; amounts/steps from caller/config.
class NegotiationSheet extends StatelessWidget {
  const NegotiationSheet({
    super.key,
    this.variant = NegotiationSheetVariant.park,
    required this.anchorNaira,
    required this.chipSteps,
    this.proposedNaira,
    this.splitNaira,
    this.roundNumber = 1,
    this.roundCap = 4,
    this.countdownSeconds = 45,
    this.countdownTotal = 60,
    this.extensionDeltaNaira,
    this.onChipStep,
    this.onAccept,
    this.onSkip,
    this.onSplit,
    this.onOffer,
  });

  final NegotiationSheetVariant variant;
  final int anchorNaira;
  final List<int> chipSteps;
  final int? proposedNaira;
  final int? splitNaira;
  final int roundNumber;
  final int roundCap;
  final int countdownSeconds;
  final int countdownTotal;
  final int? extensionDeltaNaira;
  final ValueChanged<int>? onChipStep;
  final VoidCallback? onAccept;
  final VoidCallback? onSkip;
  final VoidCallback? onSplit;
  final VoidCallback? onOffer;

  bool get _atCap => roundNumber >= roundCap;
  int get _displayAmount => proposedNaira ?? anchorNaira;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AlongSpace.s16),
      decoration: const BoxDecoration(
        color: AlongColors.surface0,
        borderRadius: BorderRadius.vertical(top: AlongRadius.sheet),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: AlongSpace.s16),
          if (variant == NegotiationSheetVariant.extension && extensionDeltaNaira != null)
            _ExtensionDeltaBadge(deltaNaira: extensionDeltaNaira!),
          Text(
            variant == NegotiationSheetVariant.extension
                ? 'Extension fare'
                : 'No standard fare for this trip yet',
            style: AlongText.caption.copyWith(color: AlongColors.ink500),
          ),
          const SizedBox(height: AlongSpace.s8),
          Text(
            '≈ ${formatMoney(_displayAmount)}',
            style: AlongText.displayL,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
          if (variant != NegotiationSheetVariant.roamingNone) ...[
            const SizedBox(height: AlongSpace.s16),
            if (variant == NegotiationSheetVariant.roamingSingle)
            Text(
              'One counter-offer allowed',
              style: AlongText.caption.copyWith(color: AlongColors.ink500),
            )
          else if (!_atCap) ...[
            Text(
              'Round $roundNumber of $roundCap',
              style: AlongText.caption.copyWith(color: AlongColors.ink500),
            ),
            const SizedBox(height: AlongSpace.s12),
          ],
          if (variant == NegotiationSheetVariant.roamingSingle || !_atCap) ...[
            if (variant != NegotiationSheetVariant.roamingSingle)
              const SizedBox(height: AlongSpace.s12),
            _ChipStepRow(
              chipSteps: chipSteps,
              onChipStep: onChipStep,
            ),
          ],
          if (_atCap && splitNaira != null) ...[
              const SizedBox(height: AlongSpace.s12),
              AlongButton(
                label: 'Split the difference → ${formatMoney(splitNaira!)}',
                variant: AlongButtonVariant.yellow,
                onPressed: onSplit ?? () {},
              ),
            ] else if (!_atCap || variant == NegotiationSheetVariant.roamingSingle) ...[
              const SizedBox(height: AlongSpace.s12),
              AlongButton(
                label: 'Offer ${formatMoney(_displayAmount)}',
                onPressed: onOffer ?? onAccept ?? () {},
              ),
            ],
          ],
          const SizedBox(height: AlongSpace.s12),
          if (variant == NegotiationSheetVariant.roamingNone) ...[
            AlongButton(
              label: 'Accept ${formatMoney(anchorNaira)}',
              variant: AlongButtonVariant.yellow,
              onPressed: onAccept ?? () {},
            ),
            const SizedBox(height: AlongSpace.s8),
            AlongButton(
              label: 'Skip',
              variant: AlongButtonVariant.secondary,
              onPressed: onSkip ?? () {},
            ),
          ] else if (_atCap && splitNaira == null)
            AlongButton(
              label: 'Accept ${formatMoney(_displayAmount)}',
              variant: AlongButtonVariant.yellow,
              onPressed: onAccept ?? () {},
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final progress = countdownTotal > 0 ? countdownSeconds / countdownTotal : 0.0;

    return Row(
      children: [
        Text('Along Pricing', style: AlongText.heading2),
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
    );
  }
}

class _ExtensionDeltaBadge extends StatelessWidget {
  const _ExtensionDeltaBadge({required this.deltaNaira});

  final int deltaNaira;

  @override
  Widget build(BuildContext context) {
    final prefix = deltaNaira >= 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AlongSpace.s8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AlongSpace.s8,
          vertical: AlongSpace.s4,
        ),
        decoration: BoxDecoration(
          color: AlongColors.brandYellowTint,
          borderRadius: BorderRadius.circular(AlongRadius.xs.x),
        ),
        child: Text(
          '$prefix${formatMoney(deltaNaira.abs())} extension',
          style: AlongText.caption.copyWith(color: AlongColors.ink900),
        ),
      ),
    );
  }
}

class _ChipStepRow extends StatelessWidget {
  const _ChipStepRow({
    required this.chipSteps,
    this.onChipStep,
  });

  final List<int> chipSteps;
  final ValueChanged<int>? onChipStep;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AlongSpace.s8,
      runSpacing: AlongSpace.s8,
      children: [
        for (final step in chipSteps)
          ActionChip(
            label: Text(_formatStep(step)),
            onPressed: onChipStep != null ? () => onChipStep!(step) : null,
            backgroundColor: AlongColors.surface100,
            side: BorderSide.none,
            labelStyle: AlongText.label,
            padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s8),
          ),
      ],
    );
  }

  String _formatStep(int step) {
    if (step >= 0) return '+${formatMoney(step)}';
    return '−${formatMoney(step.abs())}';
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
