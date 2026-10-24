import 'package:flutter/material.dart';

import '../craft.dart';
import '../tokens.g.dart';
import '../utils/name_signal.dart';
import 'na_me_shape_painter.dart';

/// Na Me pairing chip — 24 dp shape in colour + text label (doc 05 §6).
class NaMeChip extends StatelessWidget {
  const NaMeChip({
    super.key,
    this.colour = NaMeColour.green,
    this.shape = NaMeShape.diamond,
  });

  final NaMeColour colour;
  final NaMeShape shape;

  String get _label => '${colour.label} ${shape.label}';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Na Me signal: $_label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AlongSpace.s12,
          vertical: AlongSpace.s12,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: AlongCraft.fill(
          AlongColors.surface100,
          corner: AlongRadius.control.x,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size.square(24),
              painter: NaMeShapePainter(
                shape: shape,
                color: colour.color,
              ),
            ),
            const SizedBox(width: AlongSpace.s8),
            Text(
              _label,
              style: AlongText.label.copyWith(color: AlongColors.ink900),
            ),
          ],
        ),
      ),
    );
  }
}
