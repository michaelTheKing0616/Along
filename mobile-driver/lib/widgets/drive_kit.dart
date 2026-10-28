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

/// A full driver page: display title, muted subtitle, scrolling body and an
/// optional pinned footer. The body always keeps room above the footer so the
/// last row never hides behind it at large text sizes.
class DrivePage extends StatelessWidget {
  const DrivePage({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.footer,
    this.trailing,
    this.back = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;
  final Widget? trailing;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final canPop = back && Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canPop || trailing != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    if (canPop)
                      IconButton(
                        key: const Key('drive_page_back'),
                        tooltip: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.arrow_back_rounded, color: p.ink),
                      ),
                    const Spacer(),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AlongSpace.s16,
                  AlongSpace.s8,
                  AlongSpace.s16,
                  AlongSpace.s24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: AlongType.display(p)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: AlongType.bodyMuted(p)),
                    ],
                    const SizedBox(height: AlongSpace.s16),
                    ...children,
                  ],
                ),
              ),
            ),
            if (footer != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: p.bg,
                  border: Border(top: BorderSide(color: p.line, width: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AlongSpace.s16,
                    AlongSpace.s12,
                    AlongSpace.s16,
                    AlongSpace.s16,
                  ),
                  child: footer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// White squircle card with a hairline, the design's money surface.
class DriveCard extends StatelessWidget {
  const DriveCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.fill(
        p.surface,
        corner: AlongRadius.card.x,
        side: BorderSide(color: p.ink.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AlongSpace.s16),
        child: child,
      ),
    );
  }
}

/// Section title above a group.
class DriveSection extends StatelessWidget {
  const DriveSection(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: AlongSpace.s24,
        bottom: AlongSpace.s8,
      ),
      child: Text(_sentence(label), style: AlongType.title(p)),
    );
  }

  /// Older headings were written as all-caps overlines; sections read in
  /// sentence case.
  static String _sentence(String s) => s.length > 1 && s == s.toUpperCase()
      ? s[0] + s.substring(1).toLowerCase()
      : s;
}

/// A list row: optional icon, title, detail, trailing text or check.
/// 56 px minimum so it is an easy target while parked.
class DriveRow extends StatelessWidget {
  const DriveRow({
    super.key,
    required this.title,
    this.detail,
    this.icon,
    this.trailing,
    this.trailingStyle,
    this.selected,
    this.onTap,
    this.chevron = false,
  });

  final String title;
  final String? detail;
  final IconData? icon;
  final String? trailing;
  final TextStyle? trailingStyle;

  /// Non-null renders a radio mark.
  final bool? selected;
  final VoidCallback? onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AlongSpace.s8),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: AlongCraft.fill(p.recessed, corner: 10),
                child: Icon(icon, size: 20, color: p.ink),
              ),
              const SizedBox(width: AlongSpace.s12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AlongType.body(p)
                        .copyWith(fontWeight: FontWeight.w600, height: 1.2),
                  ),
                  if (detail != null)
                    Text(detail!, style: AlongType.caption(p)),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AlongSpace.s12),
              Text(
                trailing!,
                style:
                    trailingStyle ??
                    AlongType.body(p).copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: AlongType.figures,
                    ),
              ),
            ],
            if (selected != null) ...[
              const SizedBox(width: AlongSpace.s12),
              AnimatedContainer(
                duration: AlongMoves.select.of(context),
                curve: AlongMoves.select.curve,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected! ? p.ink : Colors.transparent,
                  border: Border.all(
                    color: selected! ? p.ink : p.muted,
                    width: 1.5,
                  ),
                ),
                child: selected!
                    ? Icon(Icons.check_rounded, size: 14, color: p.onInk)
                    : null,
              ),
            ],
            if (chevron) ...[
              const SizedBox(width: AlongSpace.s8),
              Icon(AlongIcons.caretRight, size: 18, color: p.muted),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: () {
        AlongHaptics.selection(context);
        onTap!();
      },
      customBorder: AlongCraft.border(12),
      child: row,
    );
  }
}

/// Rows separated by hairlines inside a card.
class DriveRows extends StatelessWidget {
  const DriveRows({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return DriveCard(
      padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s16),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 0.5, color: p.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Two-up money card (Pending / Paid style).
class DriveMoneyCard extends StatelessWidget {
  const DriveMoneyCard({
    super.key,
    required this.label,
    required this.amount,
    this.strong = false,
  });

  final String label;
  final String amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return DriveCard(
      padding: const EdgeInsets.all(AlongSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: strong ? p.ink : p.ink.withValues(alpha: 0.36),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AlongType.caption(p),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: AlongType.title(p)
                  .copyWith(fontFeatures: AlongType.figures),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recessed, borderless text field decoration used across drive pages.
InputDecoration driveInput(
  BuildContext context,
  String label, {
  Widget? prefix,
}) {
  final p = AlongPalette.of(context);
  return InputDecoration(
    labelText: label,
    prefixIcon: prefix,
    filled: true,
    fillColor: p.recessed,
    border: AlongCraft.input(BorderSide.none),
    enabledBorder: AlongCraft.input(BorderSide.none),
    focusedBorder: AlongCraft.input(BorderSide(color: p.ink, width: 1.5)),
  );
}

class DriveSteps extends StatelessWidget {
  const DriveSteps({super.key, required this.steps});

  /// (icon, title, detail) per step, shown as a numbered read-only list.
  final List<(IconData, String, String)> steps;

  @override
  Widget build(BuildContext context) {
    return DriveRows(
      children: [
        for (final (icon, title, detail) in steps)
          DriveRow(icon: icon, title: title, detail: detail),
      ],
    );
  }
}
