import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';

/// Shared pieces for the driver's main flow. Everything here is built to be
/// read at a glance in sunlight: ink on surface, large type, 56+ px targets.

/// A floating sheet over the map: squircle card, sheet shadow, safe area.
class DriveSheet extends StatelessWidget {
  const DriveSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 16),
    this.maxHeightFactor = 0.78,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * maxHeightFactor),
        child: DecoratedBox(
          decoration: AlongCraft.surface(
            p,
            radius: AlongRadius.card.x,
            hairline: Theme.of(context).brightness == Brightness.dark,
            shadow: AlongElevation.sheet(p.ink),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Recessed squircle group.
class DrivePanel extends StatelessWidget {
  const DrivePanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.compactFill(p.recessed, 64, corner: 20),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AlongSpace.s16),
        child: child,
      ),
    );
  }
}

/// Small squircle tag (never a pill), e.g. "Women only", "Retry 2 of 3".
class DriveTag extends StatelessWidget {
  const DriveTag({
    super.key,
    required this.label,
    this.icon,
    this.tone = DriveTagTone.neutral,
  });

  final String label;
  final IconData? icon;
  final DriveTagTone tone;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color fg) = switch (tone) {
      DriveTagTone.neutral => (p.recessed, p.ink),
      DriveTagTone.warning => (
        Color.alphaBlend(
          AlongColors.semanticWarning.withValues(alpha: 0.18),
          p.recessed,
        ),
        dark ? p.ink : const Color(0xFF6B4A00),
      ),
      DriveTagTone.info => (
        Color.alphaBlend(
          AlongColors.semanticInfo.withValues(alpha: 0.16),
          p.recessed,
        ),
        dark ? p.ink : AlongColors.semanticInfo,
      ),
    };
    return DecoratedBox(
      decoration: AlongCraft.compactFill(bg, 28, corner: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AlongIcon(icon!, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AlongType.caption(p)
                    .copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum DriveTagTone { neutral, warning, info }

/// Square-ish action tile with icon over label; 64 px tall at 1x.
class DriveActionTile extends StatelessWidget {
  const DriveActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final enabled = onPressed != null;
    final fg = enabled ? p.ink : p.muted;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          shape: AlongCraft.border(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed == null
                ? null
                : () {
                    AlongHaptics.tick(context);
                    onPressed!();
                  },
            child: Ink(
              decoration: AlongCraft.compactFill(p.recessed, 64, corner: 16),
              padding: const EdgeInsets.symmetric(
                horizontal: AlongSpace.s4,
                vertical: AlongSpace.s12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Badge(
                    isLabelVisible: badge > 0,
                    label: Text('$badge'),
                    backgroundColor: p.danger,
                    child: AlongIcon(icon, size: 24, color: fg),
                  ),
                  const SizedBox(height: AlongSpace.s4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: AlongType.caption(p)
                          .copyWith(color: fg, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pickup → Board → Drop as three squircle segments; readable mid-drive.
class DrivePhaseBar extends StatelessWidget {
  const DrivePhaseBar({super.key, required this.labels, required this.current});

  final List<String> labels;

  /// Index of the phase in progress; earlier ones read as done.
  final int current;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: AlongMoves.select.of(context),
                  curve: AlongMoves.select.curve,
                  height: 6,
                  decoration: AlongCraft.compactFill(
                    i < current
                        ? p.ink
                        : i == current
                        ? p.accent
                        : p.recessed,
                    6,
                    corner: 3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  key: Key('drive_phase_$i'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: i <= current
                      ? AlongType.caption(p)
                            .copyWith(color: p.ink, fontWeight: FontWeight.w600)
                      : AlongType.caption(p),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Pickup and drop stacked with a connecting rail, names large.
class DriveRoute extends StatelessWidget {
  const DriveRoute({
    super.key,
    required this.fromLabel,
    required this.from,
    required this.toLabel,
    required this.to,
    this.fromMeta,
    this.fromMetaKey,
  });

  final String fromLabel;
  final String from;
  final String toLabel;
  final String to;
  final String? fromMeta;
  final Key? fromMetaKey;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    Widget stop(String label, String name, {String? meta, Key? metaKey}) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AlongType.caption(p)),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AlongType.title(p).copyWith(height: 1.15),
            ),
            if (meta != null)
              Text(
                meta,
                key: metaKey,
                style: AlongType.caption(p).copyWith(color: p.ink),
              ),
          ],
        );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 22),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.ink, width: 3),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: p.line,
                  ),
                ),
                Container(width: 12, height: 12, color: p.ink),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(width: AlongSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stop(fromLabel, from, meta: fromMeta, metaKey: fromMetaKey),
                const SizedBox(height: AlongSpace.s12),
                stop(toLabel, to),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
