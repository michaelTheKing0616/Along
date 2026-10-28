import 'package:flutter/material.dart';

import '../craft.dart';
import 'along_button.dart';
import '../icons.dart';
import '../palette.dart';
import '../tokens.g.dart';
import '../type.dart';

/// Which moment of the offline cycle the banner shows.
enum AlongConnectionTone { offline, reconnecting, restored }

/// Floating status bar for offline, reconnecting and back-online.
///
/// It never covers the screen or disables anything; core actions keep
/// working underneath and queue until the network returns.
class AlongConnectionBanner extends StatelessWidget {
  const AlongConnectionBanner({
    super.key,
    required this.tone,
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  final AlongConnectionTone tone;
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final style = AlongType.label(p)
        .copyWith(fontWeight: FontWeight.w600, height: 1.15);
    final mark = switch (tone) {
      AlongConnectionTone.offline => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
      ),
      AlongConnectionTone.reconnecting => SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: p.ink,
          value: TickerMode.valuesOf(context).enabled ? null : 0.7,
        ),
      ),
      AlongConnectionTone.restored => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(color: p.success, shape: BoxShape.circle),
        child: Icon(AlongIcons.check, size: 12, color: p.bg),
      ),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: DecoratedBox(
          decoration: AlongCraft.fill(
            p.surface,
            corner: AlongRadius.control.x,
            side: BorderSide(color: p.ink.withValues(alpha: 0.14)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Row(
              children: [
                SizedBox(width: 18, child: Center(child: mark)),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: roomy ? 10 : 0),
                    child: Text(
                      label,
                      maxLines: roomy ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  Semantics(
                    button: true,
                    child: InkWell(
                      key: const Key('connection_banner_action'),
                      onTap: onAction,
                      borderRadius: BorderRadius.circular(
                        AlongRadius.control.x,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          minWidth: 48,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Center(
                            widthFactor: 1,
                            child: Text(actionLabel!, style: style),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hosts [AlongConnectionBanner] above every route. When visible it reserves
/// room at the top by growing the safe-area inset, so screens slide down
/// instead of being covered, and nothing underneath is blocked.
class AlongConnectionHost extends StatelessWidget {
  const AlongConnectionHost({super.key, required this.child, this.banner});

  final Widget child;

  /// Null hides the banner.
  final AlongConnectionBanner? banner;

  static const _reserve = 48.0 + AlongSpace.s8 * 2;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final shown = banner != null;
    final reserve = shown
        ? _reserve + (media.textScaler.scale(1) > 1.15 ? 16 : 0)
        : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: reserve),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, inset, _) {
        return Stack(
          children: [
            MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(top: media.padding.top + inset),
                viewPadding: media.viewPadding.copyWith(
                  top: media.viewPadding.top + inset,
                ),
              ),
              child: child,
            ),
            Positioned(
              left: AlongSpace.s12,
              right: AlongSpace.s12,
              top: media.padding.top + AlongSpace.s8,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, -0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: banner == null
                    ? const SizedBox.shrink()
                    : KeyedSubtree(
                        key: ValueKey(banner!.tone),
                        child: Material(
                          type: MaterialType.transparency,
                          child: banner!,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Inline failure or empty state: what happened, what still works, one way
/// forward. Sits in the flow of the screen, never as a blocking dialog.
class AlongNoticeCard extends StatelessWidget {
  const AlongNoticeCard({
    super.key,
    required this.title,
    required this.body,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// Optional context line, e.g. the place being searched.
  final String? detail;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.surface(p, radius: AlongRadius.card.x),
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AlongType.title(p)),
            if (detail != null) ...[
              const SizedBox(height: AlongSpace.s4),
              Text(detail!, style: AlongType.body(p)),
            ],
            const SizedBox(height: AlongSpace.s4),
            Text(body, style: AlongType.bodyMuted(p)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AlongSpace.s16),
              AlongButton(
                key: const Key('notice_card_action'),
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
