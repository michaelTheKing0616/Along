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
  static const land = Color(0xFFF4F4F2);
  static const water = Color(0xFFCFE3EA);
  static const parksGreen = Color(0xFFE6EEE3);
  static const buildings = Color(0xFFEBEBE9);
  static const roadMotorway = Color(0xFFD8D8D6);
  static const roadPrimary = Color(0xFFDEDEDC);
  static const roadMinor = Color(0xFFE8E8E6);
  static const roadLabel = Color(0xFF6B6B6B);
}
