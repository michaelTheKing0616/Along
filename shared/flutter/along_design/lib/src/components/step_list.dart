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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (variant == StepListVariant.audioPlaying)
          Padding(
            padding: const EdgeInsets.only(bottom: AlongSpace.s12),
            child: Row(
              children: [
                Icon(Icons.volume_up_rounded, color: AlongColors.brandYellowOn, size: 18),
                const SizedBox(width: AlongSpace.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AlongSpace.s8,
                    vertical: AlongSpace.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AlongColors.brandYellow,
                    borderRadius: BorderRadius.circular(AlongRadius.xs.x),
                  ),
                  child: Text(
                    'Audio playing',
                    style: AlongText.caption.copyWith(color: AlongColors.brandYellowOn),
                  ),
                ),
              ],
            ),
          ),
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            highlightActive: variant == StepListVariant.audioPlaying,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.highlightActive,
    required this.isLast,
  });

  final WayfindingStep step;
  final bool highlightActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = highlightActive && step.isActive;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : AlongSpace.s8),
      padding: const EdgeInsets.all(AlongSpace.s12),
      decoration: BoxDecoration(
        color: isHighlighted ? AlongColors.brandYellowTint : AlongColors.surface0,
        borderRadius: BorderRadius.circular(AlongRadius.md.x),
        border: Border.all(
          color: isHighlighted ? AlongColors.brandYellow : AlongColors.ink100,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isHighlighted ? AlongColors.brandYellow : AlongColors.surface100,
              borderRadius: BorderRadius.circular(AlongRadius.sm.x),
            ),
            child: Icon(
              step.maneuverIcon,
              size: 20,
              color: isHighlighted ? AlongColors.brandYellowOn : AlongColors.ink700,
            ),
          ),
          const SizedBox(width: AlongSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction,
                  style: AlongText.bodyStrong.copyWith(
                    color: isHighlighted ? AlongColors.ink900 : AlongColors.ink700,
                  ),
                ),
                const SizedBox(height: AlongSpace.s4),
                Text(
                  step.distance,
                  style: AlongText.caption.copyWith(color: AlongColors.ink500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
