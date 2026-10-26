import 'package:flutter/material.dart';

import '../craft.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';

/// A secondary inline action: icon plus label on a recessed squircle.
class AlongTextLink extends StatelessWidget {
  const AlongTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = AlongIcons.info,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AlongHaptics.tick(context);
          onPressed();
        },
        child: AlongPressable(
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: AlongCraft.compactFill(palette.recessed, 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AlongIcon(icon, size: 20, color: palette.ink),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: AlongType.label(
                      palette,
                    ).copyWith(color: palette.ink, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
