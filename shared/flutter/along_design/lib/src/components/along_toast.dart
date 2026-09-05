import 'package:flutter/material.dart';

import '../tokens.g.dart';

/// Toast / snackbar variants (doc 05 §9 `Toast/Snackbar`).
enum AlongToastVariant { info, success, undo }

/// Inline toast banner — undo variant shows countdown action.
class AlongToast extends StatelessWidget {
  const AlongToast({
    super.key,
    required this.message,
    this.variant = AlongToastVariant.info,
    this.undoLabel = 'Undo',
    this.countdownSeconds = 3,
    this.onUndo,
  });

  final String message;
  final AlongToastVariant variant;
  final String undoLabel;
  final int countdownSeconds;
  final VoidCallback? onUndo;

  Color get _background => switch (variant) {
        AlongToastVariant.info => AlongColors.ink900,
        AlongToastVariant.success => AlongColors.semanticSuccessFill,
        AlongToastVariant.undo => AlongColors.ink900,
      };

  IconData get _icon => switch (variant) {
        AlongToastVariant.info => Icons.info_outline_rounded,
        AlongToastVariant.success => Icons.check_circle_outline_rounded,
        AlongToastVariant.undo => Icons.undo_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _background,
      borderRadius: BorderRadius.circular(AlongRadius.sm.x),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AlongSpace.s16,
          vertical: AlongSpace.s12,
        ),
        child: Row(
          children: [
            Icon(_icon, color: AlongColors.surface0, size: 20),
            const SizedBox(width: AlongSpace.s12),
            Expanded(
              child: Text(
                message,
                style: AlongText.body.copyWith(color: AlongColors.surface0),
              ),
            ),
            if (variant == AlongToastVariant.undo) ...[
              TextButton(
                onPressed: onUndo,
                child: Text(
                  '$undoLabel (${countdownSeconds}s)',
                  style: AlongText.label.copyWith(color: AlongColors.brandYellow),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows an [AlongToast] via [ScaffoldMessenger].
void showAlongToast(
  BuildContext context, {
  required String message,
  AlongToastVariant variant = AlongToastVariant.info,
  VoidCallback? onUndo,
  int countdownSeconds = 3,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: const EdgeInsets.all(AlongSpace.s16),
      behavior: SnackBarBehavior.floating,
      content: AlongToast(
        message: message,
        variant: variant,
        onUndo: onUndo,
        countdownSeconds: countdownSeconds,
      ),
    ),
  );
}
