import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BrandingOverrides parses token hex map', () {
    final overrides = BrandingOverrides.fromConfig(const {
      'brand.yellow': '#FFB800',
      'logo_url': 'https://example.com/logo.png',
      'invalid': 'not-a-color',
    });
    expect(overrides.brandYellow, const Color(0xFFFFB800));
    expect(overrides.mapPuck, AlongColors.mapPuck);
  });

  test('alongTheme secondary reflects branding override', () {
    final theme = alongTheme(
      branding: BrandingOverrides.fromConfig(const {'brand.yellow': '#FFB800'}),
    );
    expect(theme.colorScheme.secondary, const Color(0xFFFFB800));
    expect(
      theme.extension<AlongBranding>()!.brandYellow,
      const Color(0xFFFFB800),
    );
  });
}
