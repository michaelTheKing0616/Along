import 'package:flutter/material.dart';

import '../elevation.dart';
import '../icons.dart';
import '../palette.dart';

/// Photographic-style portrait of a fictional rider or driver.
/// Generated artwork, not a photograph of a real person.
class AlongDriverPortrait extends StatelessWidget {
  const AlongDriverPortrait({
    super.key,
    this.size = 56,
    this.asset = chinedu,
    this.verified = false,
  });

  /// Fictional driver used on the live trip card.
  static const chinedu = 'assets/avatars/avatar-chinedu.jpg';

  /// Fictional rider used on the offer card.
  static const adaeze = 'assets/avatars/avatar-adaeze.jpg';

  final double size;
  final String asset;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final badge = size * 0.36;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.accent, width: 2),
              boxShadow: AlongElevation.float(palette.ink),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: palette.surface, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  asset,
                  package: 'along_design',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
          if (verified)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: badge,
                height: badge,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.surface, width: 2),
                ),
                child: Icon(
                  AlongIcons.verified,
                  size: badge * 0.62,
                  color: palette.accentInk,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
