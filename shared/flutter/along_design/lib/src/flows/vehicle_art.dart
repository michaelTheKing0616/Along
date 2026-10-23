import 'package:flutter/material.dart';

import '../craft.dart';
import '../elevation.dart';
import '../palette.dart';

/// Shared vehicle set. Rows and onboarding use the project-owned 3/4
/// photographs. Seats and map markers use the matching top-down renders.
enum AlongVehicleKind { keke, okada, car, danfo, bus }

/// 3/4 studio render. Same camera for every kind.
class AlongVehicleMark extends StatelessWidget {
  const AlongVehicleMark({
    super.key,
    required this.kind,
    this.width = 112,
    this.height,
  });

  final AlongVehicleKind kind;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final h = height ?? width * 9 / 16;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 1,
            child: Container(
              width: width * 0.62,
              height: 8,
              decoration: BoxDecoration(
                color: palette.ink.withValues(alpha: 0.001),
                borderRadius: BorderRadius.circular(4),
                boxShadow: AlongElevation.rest(palette.ink),
              ),
            ),
          ),
          AlongGrade(
            child: Image.asset(
              'assets/vehicles/${kind.name}_three.png',
              package: 'along_design',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
              gaplessPlayback: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Top-down studio render. Nose points up before [heading] is applied.
class AlongTopDownMark extends StatelessWidget {
  const AlongTopDownMark({
    super.key,
    required this.kind,
    this.heading = 0,
    this.size = 36,
  });

  final AlongVehicleKind kind;
  final double heading;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: heading,
        child: Image.asset(
          'assets/vehicles/${kind.name}_top.png',
          package: 'along_design',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
