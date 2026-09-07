import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';

/// Visible stale indicator for cached offline data (doc 07 §4).
class StaleBadge extends StatelessWidget {
  const StaleBadge({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('stale_badge'),
      padding: const EdgeInsets.symmetric(
        horizontal: AlongSpace.s8,
        vertical: AlongSpace.s4,
      ),
      decoration: BoxDecoration(
        color: AlongColors.semanticWarningTint,
        borderRadius: BorderRadius.circular(AlongSpace.s4),
        border: Border.all(color: AlongColors.semanticWarning),
      ),
      child: Text(
        label,
        style: AlongText.caption.copyWith(color: AlongColors.semanticWarning),
      ),
    );
  }
}

/// Gates avatar network loads when [loadAvatars] is false (doc 07 §4).
class AvatarGate extends StatelessWidget {
  const AvatarGate({
    super.key,
    required this.loadAvatars,
    required this.initials,
    this.imageUrl,
    this.size = 40,
  });

  final bool loadAvatars;
  final String initials;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (loadAvatars && imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        key: const Key('avatar_image'),
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }
    return CircleAvatar(
      key: const Key('avatar_placeholder'),
      radius: size / 2,
      backgroundColor: AlongColors.surface200,
      child: Text(initials, style: AlongText.caption),
    );
  }
}
