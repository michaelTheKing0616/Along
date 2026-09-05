import 'package:flutter/material.dart';

import '../tokens.g.dart';
import '../utils/transport_mode.dart';

/// Mode chip sizes (doc 05 §9 `ModeChip`).
enum ModeChipSize { small, medium }

/// Colour-filled mode identity chip — never colour alone (icon + label).
class ModeChip extends StatelessWidget {
  const ModeChip({
    super.key,
    required this.mode,
    this.size = ModeChipSize.medium,
    this.selected = false,
    this.onTap,
  });

  final TransportMode mode;
  final ModeChipSize size;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final height = size == ModeChipSize.small
        ? AlongSpace.sizeChip - AlongSpace.s8
        : AlongSpace.sizeChip;
    final iconSize = size == ModeChipSize.small ? 16.0 : 20.0;
    final bg = selected ? mode.fillColor : mode.tintColor;
    final fg = selected ? mode.onColor : AlongColors.ink900;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: mode.label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AlongRadius.sm.x),
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: AlongColors.ink900.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AlongRadius.sm.x),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s8),
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(mode.icon, size: iconSize, color: fg),
                  const SizedBox(width: AlongSpace.s4),
                  Text(
                    mode.label,
                    style: AlongText.label.copyWith(color: fg),
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
