import 'package:flutter/material.dart';

import '../elevation.dart';
import '../palette.dart';

/// Photographic-style portrait of a fictional rider or driver.
/// Generated artwork, not a photograph of a real person.
class AlongDriverPortrait extends StatelessWidget {
  const AlongDriverPortrait({super.key, this.size = 56, this.asset = chinedu});

  /// Fictional driver used on the live trip card.
  static const chinedu = 'assets/avatars/avatar-chinedu.jpg';

  /// Fictional rider used on the offer card.
  static const adaeze = 'assets/avatars/avatar-adaeze.jpg';

  final double size;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AlongElevation.float(palette.ink),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.surface, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          asset,
          package: 'along_design',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
