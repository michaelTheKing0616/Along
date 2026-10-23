import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';

/// Map paint colours sourced from design tokens (doc 05 §8 — no ad-hoc values).
abstract final class AlongMapColors {
  static Color get puck => AlongColors.mapPuck;
  static Color get puckRing => AlongColors.mapPuckRing;
  static Color get routeActive => AlongColors.mapRouteActive;
  static Color get routeWalk => AlongColors.mapRouteWalk;
  static Color get clusterFill => AlongColors.mapClusterFill;
  static Color get clusterStroke => AlongColors.mapClusterStroke;
  static Color get ink => AlongColors.ink900;

  /// Basemap tokens from doc 05 §8 (not yet in Style Dictionary — fixed spec values).
  static const land = Color(0xFFF3EFE6);
  static const water = Color(0xFFD4E2E2);
  static const parksGreen = Color(0xFFE4EBD8);
  static const buildings = Color(0xFFE8E2D6);
  static const roadMotorway = Color(0xFFB7AA96);
  static const roadPrimary = Color(0xFFC4B7A4);
  static const roadMinor = Color(0xFFD5C9B8);
  static const roadLabel = Color(0xFF5E574C);
}
