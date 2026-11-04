import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../brand_assets.dart';
import '../palette.dart';

/// Launch composition: the black-car Along logo as the one brand mark, held
/// at the native splash position and size, with a map-filled taxi drawing
/// below it. The drawing rises in once; reduce-motion shows it at rest.
class AlongLaunchArt extends StatefulWidget {
  const AlongLaunchArt({this.illustration = alongTaxiMapSide, super.key});

  /// Defaults to [alongTaxiMapSide].
  final String illustration;

  @override
  State<AlongLaunchArt> createState() => _AlongLaunchArtState();
}

class _AlongLaunchArtState extends State<AlongLaunchArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _reveal.value = 1;
    } else if (!_reveal.isAnimating && _reveal.value == 0) {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final logoWidth = math.min(180.0, box.maxWidth * 0.5);
        final artWidth = math.min(340.0, box.maxWidth * 0.84);
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            // Same 180dp, dead centre, as the native splash: no jump.
            Center(
              child: Semantics(
                label: 'along_logo',
                child: SvgPicture.asset(
                  alongLogoBlackSvg,
                  package: 'along_design',
                  width: logoWidth,
                  colorFilter: ColorFilter.mode(palette.ink, BlendMode.srcIn),
                ),
              ),
            ),
            Positioned(
              left: (box.maxWidth - artWidth) / 2,
              width: artWidth,
              bottom: box.maxHeight * 0.1,
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _reveal,
                  builder: (context, child) {
                    final t = Curves.easeOutCubic.transform(_reveal.value);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - t)),
                        child: child,
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    widget.illustration,
                    package: 'along_design',
                    width: artWidth,
                    colorFilter: ColorFilter.mode(palette.ink, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
