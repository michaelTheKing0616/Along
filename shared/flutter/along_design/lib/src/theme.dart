import 'package:flutter/material.dart';

import 'branding/branding_overrides.dart';
import 'craft.dart';
import 'motion.dart';
import 'palette.dart';
import 'tokens.g.dart';
import 'type.dart';

/// Material 3 theme for Along paper (light) and dusk (dark).
///
/// Does not use [ColorScheme.fromSeed]. Yellow stays the single accent.
/// [branding] applies `deployments.branding_config` token overrides only.
ThemeData alongTheme({
  BrandingOverrides branding = BrandingOverrides.empty,
  Brightness brightness = Brightness.light,
}) {
  final resolved = AlongBranding.fromOverrides(branding);
  final palette = brightness == Brightness.dark
      ? AlongPalette.dark
      : AlongPalette.light;
  final colorScheme = ColorScheme(
    brightness: palette.brightness,
    primary: palette.ink,
    onPrimary: palette.onInk,
    secondary: resolved.brandYellow,
    onSecondary: resolved.brandYellowOn,
    error: palette.danger,
    onError: palette.dangerOn,
    surface: palette.surface,
    onSurface: palette.ink,
  );

  final text = AlongType.textTheme(palette);

  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    visualDensity: VisualDensity.standard,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.bg,
    fontFamily: palette.fontFamily,
    fontFamilyFallback: AlongType.fallback,
    textTheme: text,
    iconTheme: IconThemeData(color: palette.ink, size: 20),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.ink,
      selectionColor: palette.accent.withValues(alpha: 0.28),
      selectionHandleColor: palette.ink,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.ink),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(
          AlongSpace.sizeTouchMin,
          AlongSpace.sizeTouchMin,
        ),
        foregroundColor: palette.ink,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.bg,
      foregroundColor: palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.headlineMedium,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AlongSpace.sizeCtaPrimary),
        textStyle: AlongText.buttonPrimary,
        backgroundColor: palette.ink,
        foregroundColor: palette.onInk,
        shape: AlongCraft.border(AlongRadius.button.x),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AlongSpace.s12,
        vertical: AlongSpace.s16,
      ),
      labelStyle: text.bodySmall,
      hintStyle: text.bodyLarge?.copyWith(color: palette.muted),
      border: AlongCraft.input(
        BorderSide(color: palette.ink.withValues(alpha: 0.14), width: 0.5),
      ),
      enabledBorder: AlongCraft.input(
        BorderSide(color: palette.ink.withValues(alpha: 0.14), width: 0.5),
      ),
      focusedBorder: AlongCraft.input(
        BorderSide(color: palette.ink, width: 1),
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: AlongCraft.border(
        AlongRadius.card.x,
        side: BorderSide(
          color: palette.ink.withValues(alpha: 0.14),
          width: 0.5,
        ),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      shape: AlongCraft.border(AlongRadius.dialog.x),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      shape: AlongCraft.borderVertical(top: AlongRadius.sheet.x),
      clipBehavior: Clip.antiAlias,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _AlongAxisPageTransitionsBuilder(),
        TargetPlatform.iOS: _AlongAxisPageTransitionsBuilder(),
      },
    ),
    extensions: [resolved, palette],
  );
}

/// 200 ms shared-axis transition. Reduced motion keeps the page still. [emil]
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
    if (AlongMotionPolicy.reduced(context)) return child;
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
