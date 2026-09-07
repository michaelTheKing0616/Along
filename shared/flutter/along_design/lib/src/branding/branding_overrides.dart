import 'package:flutter/material.dart';

import '../tokens.g.dart';

/// Token-path → colour overrides from `deployments.branding_config`.
///
/// Only design-token paths (doc 05 §2) are applied; logo URLs and unknown keys
/// are ignored. Empty config keeps ink `#0A0A0A` / yellow `#F7D117`.
class BrandingOverrides {
  const BrandingOverrides(this._colors);

  final Map<String, Color> _colors;

  static const empty = BrandingOverrides({});

  /// Parses [config] from `deployments.branding_config` JSONB.
  factory BrandingOverrides.fromConfig(Map<String, dynamic> config) {
    if (config.isEmpty) return empty;
    final colors = <String, Color>{};
    for (final entry in config.entries) {
      final key = entry.key;
      if (key.startsWith('logo')) continue;
      final value = entry.value;
      if (value is! String) continue;
      final color = _tryParseHexColor(value);
      if (color != null) colors[key] = color;
    }
    return BrandingOverrides(colors);
  }

  bool get isEmpty => _colors.isEmpty;

  Color resolve(String tokenPath, Color fallback) =>
      _colors[tokenPath] ?? fallback;

  Color get brandYellow => resolve('brand.yellow', AlongColors.brandYellow);
  Color get brandYellowPressed =>
      resolve('brand.yellow-pressed', AlongColors.brandYellowPressed);
  Color get brandYellowTint =>
      resolve('brand.yellow-tint', AlongColors.brandYellowTint);
  Color get brandYellowOn =>
      resolve('brand.yellow-on', AlongColors.brandYellowOn);
  Color get mapPuck => resolve('map.puck', AlongColors.mapPuck);
  Color get mapClusterStroke =>
      resolve('map.cluster-stroke', AlongColors.mapClusterStroke);

  static Color? _tryParseHexColor(String raw) {
    final trimmed = raw.trim();
    final hex = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
    if (hex.length == 6) {
      final value = int.tryParse(hex, radix: 16);
      if (value == null) return null;
      return Color(0xFF000000 | value);
    }
    if (hex.length == 8) {
      final value = int.tryParse(hex, radix: 16);
      if (value == null) return null;
      return Color(value);
    }
    return null;
  }
}

/// Resolved branding colours exposed via [ThemeExtension] for components.
class AlongBranding extends ThemeExtension<AlongBranding> {
  const AlongBranding({
    required this.brandYellow,
    required this.brandYellowPressed,
    required this.brandYellowTint,
    required this.brandYellowOn,
    required this.mapPuck,
    required this.mapClusterStroke,
  });

  factory AlongBranding.fromOverrides(BrandingOverrides overrides) {
    return AlongBranding(
      brandYellow: overrides.brandYellow,
      brandYellowPressed: overrides.brandYellowPressed,
      brandYellowTint: overrides.brandYellowTint,
      brandYellowOn: overrides.brandYellowOn,
      mapPuck: overrides.mapPuck,
      mapClusterStroke: overrides.mapClusterStroke,
    );
  }

  static const defaults = AlongBranding(
    brandYellow: AlongColors.brandYellow,
    brandYellowPressed: AlongColors.brandYellowPressed,
    brandYellowTint: AlongColors.brandYellowTint,
    brandYellowOn: AlongColors.brandYellowOn,
    mapPuck: AlongColors.mapPuck,
    mapClusterStroke: AlongColors.mapClusterStroke,
  );

  final Color brandYellow;
  final Color brandYellowPressed;
  final Color brandYellowTint;
  final Color brandYellowOn;
  final Color mapPuck;
  final Color mapClusterStroke;

  @override
  AlongBranding copyWith({
    Color? brandYellow,
    Color? brandYellowPressed,
    Color? brandYellowTint,
    Color? brandYellowOn,
    Color? mapPuck,
    Color? mapClusterStroke,
  }) {
    return AlongBranding(
      brandYellow: brandYellow ?? this.brandYellow,
      brandYellowPressed: brandYellowPressed ?? this.brandYellowPressed,
      brandYellowTint: brandYellowTint ?? this.brandYellowTint,
      brandYellowOn: brandYellowOn ?? this.brandYellowOn,
      mapPuck: mapPuck ?? this.mapPuck,
      mapClusterStroke: mapClusterStroke ?? this.mapClusterStroke,
    );
  }

  @override
  AlongBranding lerp(ThemeExtension<AlongBranding>? other, double t) {
    if (other is! AlongBranding) return this;
    return AlongBranding(
      brandYellow: Color.lerp(brandYellow, other.brandYellow, t)!,
      brandYellowPressed:
          Color.lerp(brandYellowPressed, other.brandYellowPressed, t)!,
      brandYellowTint: Color.lerp(brandYellowTint, other.brandYellowTint, t)!,
      brandYellowOn: Color.lerp(brandYellowOn, other.brandYellowOn, t)!,
      mapPuck: Color.lerp(mapPuck, other.mapPuck, t)!,
      mapClusterStroke:
          Color.lerp(mapClusterStroke, other.mapClusterStroke, t)!,
    );
  }
}

/// Reads tenant branding from the active theme.
AlongBranding alongBrandingOf(BuildContext context) =>
    Theme.of(context).extension<AlongBranding>() ?? AlongBranding.defaults;
