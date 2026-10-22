// GENERATED — do not edit. Run: pnpm --filter @along/design-tokens build

import 'package:flutter/material.dart';

/// Generated colour tokens (doc 05 §2).
class AlongColors {
  AlongColors._();
  static const ink100 = Color(0xFFE5E5E5);
  static const ink300 = Color(0xFFB8B8B8);
  static const ink500 = Color(0xFF6B6B6B);
  static const ink700 = Color(0xFF3D3D3D);
  static const ink900 = Color(0xFF0A0A0A);
  static const surface0 = Color(0xFFFFFFFF);
  static const surface50 = Color(0xFFFAFAFA);
  static const surface100 = Color(0xFFF5F5F5);
  static const surface200 = Color(0xFFEEEEEE);
  static const surfaceInverse = Color(0xFF141414);
  static const brandYellow = Color(0xFFF7D117);
  static const brandYellowPressed = Color(0xFFE3BF0F);
  static const brandYellowTint = Color(0xFFFFF6CC);
  static const brandYellowOn = Color(0xFF0A0A0A);
  static const semanticSuccess = Color(0xFF15803D);
  static const semanticSuccessFill = Color(0xFF16A34A);
  static const semanticSuccessTint = Color(0xFFDCFCE7);
  static const semanticWarning = Color(0xFFB45309);
  static const semanticWarningFill = Color(0xFFF59E0B);
  static const semanticWarningTint = Color(0xFFFEF3C7);
  static const semanticDanger = Color(0xFFB91C1C);
  static const semanticDangerFill = Color(0xFFDC2626);
  static const semanticDangerTint = Color(0xFFFEE2E2);
  static const semanticInfo = Color(0xFF1D4ED8);
  static const semanticInfoFill = Color(0xFF2563EB);
  static const semanticInfoTint = Color(0xFFDBEAFE);
  static const modeCar = Color(0xFF0F766E);
  static const modeKeke = Color(0xFFF7D117);
  static const modeOkada = Color(0xFF2563EB);
  static const modeMinibus = Color(0xFF7C3AED);
  static const modeCarOn = Color(0xFFFFFFFF);
  static const modeKekeOn = Color(0xFF0A0A0A);
  static const modeOkadaOn = Color(0xFFFFFFFF);
  static const modeMinibusOn = Color(0xFFFFFFFF);
  static const modeCarTint = Color(0xFFCCFBF1);
  static const modeKekeTint = Color(0xFFFFF6CC);
  static const modeOkadaTint = Color(0xFFDBEAFE);
  static const modeMinibusTint = Color(0xFFEDE9FE);
  static const tierVerified = Color(0xFF15803D);
  static const tierCrowd = Color(0xFF1D4ED8);
  static const tierCandidate = Color(0xFFB45309);
  static const tierEstimate = Color(0xFF6B6B6B);
  static const mapPuck = Color(0xFFF7D117);
  static const mapPuckRing = Color(0x40F7D117);
  static const mapRouteActive = Color(0xFF0A0A0A);
  static const mapRouteWalk = Color(0xFF6B6B6B);
  static const mapClusterFill = Color(0x2EF7D117);
  static const mapClusterStroke = Color(0xFFF7D117);
  static const overlayScrim = Color(0x7A0A0A0A);
  static const overlaySheetShadow = Color(0x1A000000);
  static const naMeRed = Color(0xFFFF1744);
  static const naMeOrange = Color(0xFFFF9100);
  static const naMeYellow = Color(0xFFFFEA00);
  static const naMeGreen = Color(0xFF00E676);
  static const naMeCyan = Color(0xFF00E5FF);
  static const naMeBlue = Color(0xFF2979FF);
  static const naMePurple = Color(0xFFD500F9);
  static const naMeWhite = Color(0xFFFFFFFF);
}

/// Generated spacing and sizing tokens (doc 05 §4).
class AlongSpace {
  AlongSpace._();
  static const s0 = 0.0;
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s40 = 40.0;
  static const s48 = 48.0;
  static const s64 = 64.0;
  static const sizeTouchMin = 48.0;
  static const sizeCtaPrimary = 56.0;
  static const sizeCtaSecondary = 48.0;
  static const sizeChip = 36.0;
  static const sizeMapControl = 44.0;
  static const sizeListRowMin = 56.0;
}

/// Generated corner radii (doc 05 §4).
class AlongRadius {
  AlongRadius._();
  static const xs = Radius.circular(4);
  static const sm = Radius.circular(8);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(16);
  static const sheet = Radius.circular(20);
  static const pill = Radius.circular(999);
}

/// Generated motion durations (doc 05 §5).
class AlongMotion {
  AlongMotion._();
  static const tap = Duration(milliseconds: 120);
  static const sheet = Duration(milliseconds: 220);
  static const route = Duration(milliseconds: 200);
  static const camera = Duration(milliseconds: 350);
  static const pulse = Duration(milliseconds: 1600);
  static const naMeOn = Duration(milliseconds: 250);
  static const naMeCycle = Duration(milliseconds: 8000);
}

/// Generated typography styles (doc 05 §3).
class AlongText {
  AlongText._();
  static TextStyle get displayXl => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static TextStyle get displayL => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 32,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.96,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static TextStyle get heading1 => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );
  static TextStyle get heading2 => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static TextStyle get title => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 18,
    height: 1.3333333333333333,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static TextStyle get body => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static TextStyle get bodyStrong => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static TextStyle get label => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 14,
    height: 1.4285714285714286,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static TextStyle get caption => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 12,
    height: 1.3333333333333333,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );
  static TextStyle get overline => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 12,
    height: 1.3333333333333333,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.72,
  );
  static TextStyle get numericL => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 24,
    height: 1.1666666666666667,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.24,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static TextStyle get numericM => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 18,
    height: 1.2222222222222223,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static TextStyle get buttonPrimary => TextStyle(
    fontFamily: 'Satoshi',
    fontFamilyFallback: const ['Inter'],
    fontSize: 17,
    height: 1.411764705882353,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
}
