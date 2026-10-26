import 'package:flutter/material.dart';

import '../craft.dart';
import '../icons.dart';
import '../palette.dart';
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
    this.playingLabel = 'Audio playing',
    this.nowLabel = 'Now playing',
  });

  final StepListVariant variant;
  final List<WayfindingStep> steps;

  /// Translated banner shown while audio plays.
  final String playingLabel;

  /// Translated tag on the step being read out.
  final String nowLabel;

  @override
  Widget build(BuildContext context) {
    final isAudio = variant == StepListVariant.audioPlaying;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAudio)
          Padding(
            padding: const EdgeInsets.only(bottom: AlongSpace.s12),
            child: DecoratedBox(
              decoration: AlongCraft.fill(
                AlongColors.brandYellowTint,
                corner: 16,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AlongSpace.s12,
                  vertical: AlongSpace.s8,
                ),
                child: Row(
                  children: [
                    const AlongIcon(
                      AlongIcons.speaker,
                      color: AlongColors.brandYellowOn,
                      size: 20,
                    ),
                    const SizedBox(width: AlongSpace.s8),
                    Expanded(
                      child: Text(
                        playingLabel,
                        style: AlongText.label.copyWith(
                          color: AlongColors.brandYellowOn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            isAudio: isAudio,
            isLast: i == steps.length - 1,
            nowLabel: nowLabel,
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
    required this.nowLabel,
  });

  final WayfindingStep step;
  final bool isAudio;
  final bool isLast;
  final String nowLabel;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final highlighted = isAudio && step.isActive;
    final muted = isAudio && !step.isActive;
    final current = !isAudio && step.isActive;
    final fg = highlighted ? AlongColors.ink900 : (muted ? p.muted : p.ink);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AlongSpace.s8),
      child: DecoratedBox(
        decoration: AlongCraft.fill(
          highlighted ? AlongColors.brandYellowTint : p.recessed,
          corner: 18,
          side: current
              ? BorderSide(color: p.ink, width: 1.5)
              : highlighted
              ? const BorderSide(color: AlongColors.brandYellow, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: AlongCraft.fill(
                  highlighted
                      ? AlongColors.brandYellow
                      : current
                      ? p.ink
                      : p.surface,
                  corner: 12,
                ),
                child: SizedBox(
                  width: AlongSpace.sizeChip,
                  height: AlongSpace.sizeChip,
                  child: Center(
                    child: AlongIcon(
                      step.maneuverIcon,
                      size: 20,
                      color: highlighted
                          ? AlongColors.brandYellowOn
                          : current
                          ? p.onInk
                          : fg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AlongSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (highlighted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AlongSpace.s4),
                        child: Text(
                          nowLabel,
                          style: AlongText.caption.copyWith(
                            color: AlongColors.brandYellowOn,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      step.instruction,
                      style:
                          (highlighted || current
                                  ? AlongText.bodyStrong
                                  : AlongText.body)
                              .copyWith(color: fg),
                    ),
                    const SizedBox(height: AlongSpace.s4),
                    Text(
                      step.distance,
                      style: AlongText.caption.copyWith(
                        color: highlighted ? AlongColors.ink700 : p.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
