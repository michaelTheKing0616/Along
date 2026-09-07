import 'package:flutter/material.dart';

import 'branding/branding_overrides.dart';
import 'tokens.g.dart';

/// Material 3 theme wired to generated Along tokens (doc 05 §10).
///
/// Does not use [ColorScheme.fromSeed] — explicit ink/yellow palette per ADR-0005.
/// [branding] applies `deployments.branding_config` token overrides only.
ThemeData alongTheme({BrandingOverrides branding = BrandingOverrides.empty}) {
  final resolved = AlongBranding.fromOverrides(branding);
  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AlongColors.ink900,
    onPrimary: AlongColors.surface0,
    secondary: resolved.brandYellow,
    onSecondary: resolved.brandYellowOn,
    error: AlongColors.semanticDangerFill,
    onError: AlongColors.surface0,
    surface: AlongColors.surface0,
    onSurface: AlongColors.ink900,
  );

  return ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AlongColors.surface0,
    fontFamily: 'Inter',
    textTheme: TextTheme(
      displayLarge: AlongText.displayXl,
      displayMedium: AlongText.displayL,
      headlineLarge: AlongText.heading1,
      headlineMedium: AlongText.heading2,
      titleMedium: AlongText.title,
      bodyLarge: AlongText.body,
      bodyMedium: AlongText.bodyStrong,
      labelLarge: AlongText.label,
      bodySmall: AlongText.caption,
      labelSmall: AlongText.overline,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(AlongSpace.sizeCtaPrimary),
        textStyle: AlongText.buttonPrimary,
        backgroundColor: AlongColors.ink900,
        foregroundColor: AlongColors.surface0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AlongRadius.sm.x),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AlongColors.surface0,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AlongRadius.md.x),
        side: const BorderSide(color: AlongColors.ink100),
      ),
      margin: EdgeInsets.zero,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _AlongAxisPageTransitionsBuilder(),
        TargetPlatform.iOS: _AlongAxisPageTransitionsBuilder(),
      },
    ),
    extensions: [resolved],
  );
}

/// 200 ms shared-axis transition (doc 05 §5 `motion.route`).
class _AlongAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AlongAxisPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.2, 0, 0, 1),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
