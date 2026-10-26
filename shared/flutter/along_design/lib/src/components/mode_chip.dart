import 'package:flutter/material.dart';

import '../craft.dart';
import '../palette.dart';
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
    // 16 radius on a 28-tall chip is a stadium. Keep a flat side.
    final height = size == ModeChipSize.small ? 40.0 : 44.0;
    final iconSize = size == ModeChipSize.small ? 16.0 : 20.0;
    final palette = AlongPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Light keeps the mode tint. Dark mixes the mode fill into the surface
    // so the chip reads as the mode without a bright sticker.
    final tint = dark
        ? Color.alphaBlend(mode.fillColor.withValues(alpha: 0.28), palette.surface)
        : mode.tintColor;
    final bg = selected ? mode.fillColor : tint;
    final fg = selected ? mode.onColor : palette.ink;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: mode.label,
      child: Material(
        color: bg,
        shape: AlongCraft.border(AlongRadius.control.x),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: palette.ink.withValues(alpha: 0.08),
          customBorder: AlongCraft.border(AlongRadius.control.x),
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
