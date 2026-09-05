import 'package:flutter/material.dart';

import '../tokens.g.dart';

/// Bottom sheet snap sizes (doc 05 §9 `BottomSheet`).
enum AlongBottomSheetSize { collapsed, half, full }

/// Along bottom sheet shell — grabber, fixed snap points, scroll at full only.
class AlongBottomSheet extends StatelessWidget {
  const AlongBottomSheet({
    super.key,
    required this.child,
    this.size = AlongBottomSheetSize.half,
    this.title,
  });

  final Widget child;
  final AlongBottomSheetSize size;
  final String? title;

  double _heightFactor() => switch (size) {
        AlongBottomSheetSize.collapsed => 96 / 640,
        AlongBottomSheetSize.half => 0.5,
        AlongBottomSheetSize.full => 0.92,
      };

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        elevation: 0,
        color: AlongColors.surface0,
        shadowColor: AlongColors.overlaySheetShadow,
        borderRadius: const BorderRadius.vertical(top: AlongRadius.sheet),
        child: SizedBox(
          height: 640 * _heightFactor(),
          width: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: AlongSpace.s8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AlongColors.ink300,
                  borderRadius: BorderRadius.circular(AlongRadius.pill.x),
                ),
              ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.all(AlongSpace.s16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(title!, style: AlongText.heading2),
                  ),
                ),
              Expanded(
                child: size == AlongBottomSheetSize.full
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AlongSpace.s16,
                        ),
                        child: child,
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AlongSpace.s16,
                        ),
                        child: child,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
