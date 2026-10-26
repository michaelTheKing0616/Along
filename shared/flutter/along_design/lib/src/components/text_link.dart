import 'package:flutter/material.dart';

import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';

/// A quiet inline action: icon plus label, no box. 44pt tall to tap.
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AlongIcon(icon, size: 16, color: palette.ink),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: AlongType.meta(palette).copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: palette.line,
                    ),
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
