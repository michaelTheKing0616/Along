import 'package:flutter/material.dart';

import '../branding/branding_overrides.dart';
import '../motion.dart';
import '../palette.dart';
import '../tokens.g.dart';
import 'skeleton.dart';

/// Visual button variants (doc 05 §9 `AlongButton`).
enum AlongButtonVariant { primary, secondary, tertiary, danger, yellow }

/// Button height tier (doc 05 §4).
enum AlongButtonSize { primary, secondary }

/// Snapshot states for golden tests and previews.
enum AlongButtonVisualState { normal, pressed, loading, disabled }

/// Primary action button — ink, outline, text, danger, and brand-yellow fills.
class AlongButton extends StatelessWidget {
  const AlongButton({
    super.key,
    required this.label,
    this.variant = AlongButtonVariant.primary,
    this.size = AlongButtonSize.primary,
    this.onPressed,
    this.fullWidth = true,
    this.visualState = AlongButtonVisualState.normal,
  });

  final String label;
  final AlongButtonVariant variant;
  final AlongButtonSize size;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final AlongButtonVisualState visualState;

  bool get _isDisabled =>
      visualState == AlongButtonVisualState.disabled || onPressed == null;

  bool get _isLoading => visualState == AlongButtonVisualState.loading;

  bool get _isPressed => visualState == AlongButtonVisualState.pressed;

  double get _height => size == AlongButtonSize.primary
      ? AlongSpace.sizeCtaPrimary
      : AlongSpace.sizeCtaSecondary;

  @override
  Widget build(BuildContext context) {
    final branding = alongBrandingOf(context);
    final palette = AlongPalette.of(context);
    final style = _styleForVariant(branding, palette);
    final child = _isLoading
        ? const AlongSkeleton(width: 72, height: 10)
        : Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: AlongText.buttonPrimary.copyWith(
              color: style.foregroundColor,
            ),
          );

    final button = Material(
      color: style.backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AlongRadius.md.x),
        side: style.borderSide,
      ),
      child: InkWell(
        onTap: _isDisabled || _isLoading
            ? null
            : () {
                AlongHaptics.confirm(context);
                onPressed?.call();
              },
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AlongRadius.md.x),
        child: SizedBox(
          height: _height,
          width: fullWidth ? double.infinity : null,
          child: Center(child: child),
        ),
      ),
    );

    return AlongPressable(
      child: Opacity(
        opacity: _isDisabled ? 0.38 : 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            button,
            if (_isPressed)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _pressedOverlay(
                        style.backgroundColor,
                        branding,
                        palette,
                      ),
                      borderRadius: BorderRadius.circular(AlongRadius.md.x),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _pressedOverlay(
    Color base,
    AlongBranding branding,
    AlongPalette palette,
  ) {
    if (variant == AlongButtonVariant.yellow) {
      return branding.brandYellowPressed.withValues(alpha: 0.35);
    }
    return palette.ink.withValues(alpha: 0.08);
  }

  _ButtonStyle _styleForVariant(AlongBranding branding, AlongPalette palette) {
    return switch (variant) {
      AlongButtonVariant.primary => _ButtonStyle(
        backgroundColor: palette.ink,
        foregroundColor: palette.onInk,
      ),
      AlongButtonVariant.secondary => _ButtonStyle(
        backgroundColor: palette.surface,
        foregroundColor: palette.ink,
        borderSide: BorderSide(color: palette.ink),
      ),
      AlongButtonVariant.tertiary => _ButtonStyle(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.ink,
      ),
      AlongButtonVariant.danger => _ButtonStyle(
        backgroundColor: palette.danger,
        foregroundColor: palette.dangerOn,
      ),
      AlongButtonVariant.yellow => _ButtonStyle(
        backgroundColor: branding.brandYellow,
        foregroundColor: branding.brandYellowOn,
      ),
    };
  }
}

class _ButtonStyle {
  const _ButtonStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderSide = BorderSide.none,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide borderSide;
}
