import 'package:flutter/material.dart';

import '../tokens.g.dart';

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
    final style = _styleForVariant();
    final child = _isLoading
        ? SizedBox(
            width: AlongSpace.s24,
            height: AlongSpace.s24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: style.foregroundColor,
            ),
          )
        : Text(label, style: AlongText.buttonPrimary.copyWith(color: style.foregroundColor));

    final button = Material(
      color: style.backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AlongRadius.sm.x),
        side: style.borderSide,
      ),
      child: InkWell(
        onTap: _isDisabled || _isLoading ? null : onPressed,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AlongRadius.sm.x),
        child: SizedBox(
          height: _height,
          width: fullWidth ? double.infinity : null,
          child: Center(child: child),
        ),
      ),
    );

    return Opacity(
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
                    color: _pressedOverlay(style.backgroundColor),
                    borderRadius: BorderRadius.circular(AlongRadius.sm.x),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _pressedOverlay(Color base) {
    if (variant == AlongButtonVariant.yellow) {
      return AlongColors.brandYellowPressed.withValues(alpha: 0.35);
    }
    return AlongColors.ink900.withValues(alpha: 0.08);
  }

  _ButtonStyle _styleForVariant() {
    return switch (variant) {
      AlongButtonVariant.primary => _ButtonStyle(
          backgroundColor: AlongColors.ink900,
          foregroundColor: AlongColors.surface0,
        ),
      AlongButtonVariant.secondary => _ButtonStyle(
          backgroundColor: AlongColors.surface0,
          foregroundColor: AlongColors.ink900,
          borderSide: const BorderSide(color: AlongColors.ink900),
        ),
      AlongButtonVariant.tertiary => _ButtonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AlongColors.ink900,
        ),
      AlongButtonVariant.danger => _ButtonStyle(
          backgroundColor: AlongColors.semanticDangerFill,
          foregroundColor: AlongColors.surface0,
        ),
      AlongButtonVariant.yellow => _ButtonStyle(
          backgroundColor: AlongColors.brandYellow,
          foregroundColor: AlongColors.brandYellowOn,
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
