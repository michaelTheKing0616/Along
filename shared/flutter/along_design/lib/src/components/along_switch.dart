import 'package:flutter/material.dart';

import '../craft.dart';
import '../motion.dart';
import '../palette.dart';

/// Squircle on/off switch: ink track when on, recessed when off.
class AlongSwitch extends StatelessWidget {
  const AlongSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final enabled = onChanged != null;
    final reduced = AlongMotionPolicy.reduced(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: SizedBox(
          width: 60,
          height: 48,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : 0.45,
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOut,
                width: 52,
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: AlongCraft.fill(value ? p.ink : p.line, corner: 12),
                child: AnimatedAlign(
                  duration: duration,
                  curve: Curves.easeOut,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: AlongCraft.fill(
                      value ? p.accent : p.surface,
                      corner: 10,
                    ),
                    child: const SizedBox(width: 26, height: 26),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
