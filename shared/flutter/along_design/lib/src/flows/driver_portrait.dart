import 'package:flutter/material.dart';

import '../craft.dart';
import '../elevation.dart';
import '../icons.dart';
import '../palette.dart';
import '../type.dart';

/// Circle crop of a real photograph. See LICENSES for the Unsplash credit.
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
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surface,
              boxShadow: AlongElevation.float(palette.ink),
            ),
            child: ClipOval(
              child: AlongGrade(
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
                  color: palette.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.ink, width: 1.5),
                ),
                child: Icon(
                  AlongIcons.verified,
                  size: badge * 0.55,
                  color: palette.ink,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Initials on a warm gradient. Never a flat black disc.
class AlongMonogram extends StatelessWidget {
  const AlongMonogram({super.key, required this.initials, required this.size});

  final String initials;
  final double size;

  static const _stops = <(Color, Color)>[
    (Color(0xFF3A342C), Color(0xFF8A7E72)),
    (Color(0xFF243028), Color(0xFF6E7A68)),
    (Color(0xFF2A3138), Color(0xFF6A7580)),
    (Color(0xFF3A2C28), Color(0xFF8A6E64)),
  ];

  @override
  Widget build(BuildContext context) {
    final pair = _stops[initials.hashCode.abs() % _stops.length];
    final palette = AlongPalette.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [pair.$1, pair.$2],
        ),
      ),
      child: Text(
        initials,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontFamily: palette.fontFamily,
          fontFamilyFallback: AlongType.fallback,
          fontSize: size * 0.34,
          height: 1,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF7F4EF),
        ),
      ),
    );
  }
}
