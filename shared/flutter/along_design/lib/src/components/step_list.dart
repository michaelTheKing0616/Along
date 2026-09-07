import 'package:flutter/material.dart';

import '../tokens.g.dart';

/// Wayfinding presentation mode (doc 05 §9 `StepList`).
enum StepListVariant { text, audioPlaying }

/// One maneuver step in a wayfinding list.
class WayfindingStep {
  const WayfindingStep({
    required this.maneuverIcon,
    required this.instruction,
    required this.distance,
    this.isActive = false,
  });

  final IconData maneuverIcon;
  final String instruction;
  final String distance;
  final bool isActive;
}

/// Per-step wayfinding rows with maneuver icon, instruction, and distance.
class StepList extends StatelessWidget {
  const StepList({
    super.key,
    this.variant = StepListVariant.text,
    required this.steps,
  });

  final StepListVariant variant;
  final List<WayfindingStep> steps;

  @override
  Widget build(BuildContext context) {
    final isAudio = variant == StepListVariant.audioPlaying;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAudio)
          Padding(
            padding: const EdgeInsets.only(bottom: AlongSpace.s12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AlongSpace.s12,
                vertical: AlongSpace.s8,
              ),
              decoration: BoxDecoration(
                color: AlongColors.brandYellowTint,
                borderRadius: BorderRadius.circular(AlongRadius.sm.x),
                border: Border.all(color: AlongColors.brandYellow),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    color: AlongColors.brandYellowOn,
                    size: 20,
                  ),
                  const SizedBox(width: AlongSpace.s8),
                  Text(
                    'Audio playing',
                    style: AlongText.label.copyWith(color: AlongColors.brandYellowOn),
                  ),
                ],
              ),
            ),
          ),
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            isAudio: isAudio,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.isAudio,
    required this.isLast,
  });

  final WayfindingStep step;
  final bool isAudio;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = isAudio && step.isActive;
    final isMuted = isAudio && !step.isActive;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : AlongSpace.s8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AlongColors.brandYellowTint
            : isMuted
                ? AlongColors.surface50
                : AlongColors.surface0,
        borderRadius: BorderRadius.circular(AlongRadius.md.x),
        border: Border.all(
          color: isHighlighted ? AlongColors.brandYellow : AlongColors.ink100,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isHighlighted)
              Container(
                width: AlongSpace.s4,
                decoration: BoxDecoration(
                  color: AlongColors.brandYellow,
                  borderRadius: BorderRadius.horizontal(
                    left: AlongRadius.md,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AlongSpace.s12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: AlongSpace.sizeChip,
                      height: AlongSpace.sizeChip,
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? AlongColors.brandYellow
                            : AlongColors.surface100,
                        borderRadius: BorderRadius.circular(AlongRadius.sm.x),
                      ),
                      child: Icon(
                        step.maneuverIcon,
                        size: 20,
                        color: isHighlighted
                            ? AlongColors.brandYellowOn
                            : isMuted
                                ? AlongColors.ink500
                                : AlongColors.ink700,
                      ),
                    ),
                    const SizedBox(width: AlongSpace.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isHighlighted)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AlongSpace.s4),
                              child: Text(
                                'NOW PLAYING',
                                style: AlongText.overline.copyWith(
                                  color: AlongColors.brandYellowOn,
                                ),
                              ),
                            ),
                          Text(
                            step.instruction,
                            style: (isHighlighted
                                    ? AlongText.bodyStrong
                                    : AlongText.body)
                                .copyWith(
                              color: isMuted
                                  ? AlongColors.ink500
                                  : isHighlighted
                                      ? AlongColors.ink900
                                      : AlongColors.ink700,
                            ),
                          ),
                          const SizedBox(height: AlongSpace.s4),
                          Text(
                            step.distance,
                            style: AlongText.caption.copyWith(
                              color: isMuted
                                  ? AlongColors.ink300
                                  : AlongColors.ink500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isHighlighted) ...[
                      const SizedBox(width: AlongSpace.s8),
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: AlongColors.brandYellowOn,
                        size: 24,
                      ),
                    ],
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
