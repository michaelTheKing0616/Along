import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/along_button.dart';
import '../components/skeleton.dart';
import '../craft.dart';
import '../icons.dart';
import '../palette.dart';
import '../type.dart';
import 'delights.dart';

void _noop() {}

bool _roomy(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > 1.15;

/// A leave time ranked from corridor demand. [best] is the one to take.
class AlongDeparture {
  const AlongDeparture({
    required this.time,
    required this.demand,
    required this.label,
    this.best = false,
  });

  final String time;

  /// 0 is quiet, 1 is the hottest cell on the lattice.
  final double demand;
  final String label;
  final bool best;

  /// Nyanya corridor, read off the same demand that paints the hex outlines.
  static const nyanya = <AlongDeparture>[
    AlongDeparture(time: '06:40', demand: 0.92, label: 'High', best: true),
    AlongDeparture(time: '07:10', demand: 0.61, label: 'Steady'),
    AlongDeparture(time: '09:20', demand: 0.22, label: 'Quiet'),
  ];
}

/// Three departure times. The best one carries a short accent rail.
class AlongDepartureBoard extends StatelessWidget {
  const AlongDepartureBoard({
    super.key,
    this.departures = AlongDeparture.nyanya,
  });

  final List<AlongDeparture> departures;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.surface(palette, radius: 16, hairline: true),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leave at',
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600, height: 1.1),
            ),
            Text(
              'From today\u2019s demand',
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette),
            ),
            const SizedBox(height: 6),
            for (final item in departures) _DepartureRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _DepartureRow extends StatelessWidget {
  const _DepartureRow({required this.item});

  final AlongDeparture item;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final ticks = (item.demand * 5).round().clamp(0, 5);
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 22,
            decoration: BoxDecoration(
              color: item.best
                  ? palette.accent
                  : palette.ink.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Text(
              item.time,
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette).copyWith(
                fontWeight: FontWeight.w600,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette).copyWith(
                color: palette.ink,
                fontWeight: item.best ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Container(
                width: 6,
                height: 10,
                decoration: BoxDecoration(
                  color: i < ticks
                      ? palette.ink.withValues(alpha: 0.2 + 0.16 * i)
                      : palette.ink.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Weekly seat on one corridor.
class AlongFlowPass extends StatelessWidget {
  const AlongFlowPass({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Along Pass',
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette)
              .copyWith(color: palette.ink, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Wuse to Nyanya',
          maxLines: 1,
          softWrap: false,
          style: AlongType.title(palette),
        ),
        const SizedBox(height: 2),
        AlongMoney(value: 4800, style: AlongType.display(palette)),
        Text(
          'Each week · 10 rides',
          maxLines: 1,
          softWrap: false,
          style: AlongType.bodyMuted(palette),
        ),
        const SizedBox(height: 12),
        const _WeekDays(),
        const SizedBox(height: 12),
        const _PassFact(icon: AlongIcons.user, label: 'Same seat, weekday'),
        const _PassFact(
          icon: AlongIcons.receipt,
          label: 'One fare, paid ahead',
        ),
        const _PassFact(icon: AlongIcons.schedule, label: 'Skip a day anytime'),
        if (!roomy)
          const Expanded(
            child: Align(alignment: Alignment.center, child: _PassRoute()),
          ),
        if (roomy) ...[
          const SizedBox(height: 12),
          const _PassRoute(),
          const SizedBox(height: 16),
        ],
        const AlongButton(label: 'Subscribe', onPressed: _noop),
      ],
    );
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: roomy ? SingleChildScrollView(child: column) : column,
        ),
      ),
    );
  }
}

class _WeekDays extends StatelessWidget {
  const _WeekDays();

  static const _days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const _on = [true, true, true, true, true, false, false];

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < _days.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _on[i] ? palette.ink : palette.recessed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _days[i],
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette).copyWith(
                    color: _on[i] ? palette.onInk : palette.muted,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PassRoute extends StatelessWidget {
  const _PassRoute();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.surface(palette, radius: 16, hairline: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: palette.ink,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Wuse',
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600, height: 1.1),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  height: 2,
                  color: palette.ink.withValues(alpha: 0.2),
                ),
              ),
            ),
            Text(
              'Nyanya',
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600, height: 1.1),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: palette.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassFact extends StatelessWidget {
  const _PassFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          AlongIcon(icon, size: 20, color: palette.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette),
            ),
          ),
        ],
      ),
    );
  }
}

/// Half the fare, sent to the person in the other seat.
class AlongFlowSplit extends StatelessWidget {
  const AlongFlowSplit({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Split the fare', style: AlongType.display(palette)),
        const SizedBox(height: 4),
        Text(
          'Wuse to Nyanya · two seats',
          maxLines: 1,
          softWrap: false,
          style: AlongType.bodyMuted(palette),
        ),
        const SizedBox(height: 16),
        const _SplitPerson(name: 'You', amount: 600, you: true),
        const SizedBox(height: 8),
        const _SplitPerson(name: 'Ada', amount: 600),
        const SizedBox(height: 12),
        const AlongFareSplit(each: 600),
        const SizedBox(height: 16),
        Text(
          'Share link',
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette)
              .copyWith(color: palette.ink, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const _ShareLink(link: 'along.app/s/nyanya'),
        if (!roomy) const Spacer(),
        if (roomy) const SizedBox(height: 16),
        const AlongButton(
          key: Key('share_fare_link'),
          label: 'Share link',
          onPressed: _copyLink,
        ),
      ],
    );
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: roomy ? SingleChildScrollView(child: column) : column,
        ),
      ),
    );
  }
}

void _copyLink() {
  Clipboard.setData(const ClipboardData(text: 'https://along.app/s/nyanya'));
}

class _SplitPerson extends StatelessWidget {
  const _SplitPerson({
    required this.name,
    required this.amount,
    this.you = false,
  });

  final String name;
  final int amount;
  final bool you;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.surface(palette, radius: 16, hairline: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: you ? palette.ink : palette.recessed,
                shape: BoxShape.circle,
              ),
              child: Text(
                name == 'You' ? 'YO' : 'AD',
                maxLines: 1,
                softWrap: false,
                style: AlongType.caption(palette).copyWith(
                  color: you ? palette.onInk : palette.ink,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                softWrap: false,
                style: AlongType.body(palette)
                    .copyWith(fontWeight: FontWeight.w600, height: 1.1),
              ),
            ),
            AlongMoney(value: amount, style: AlongType.title(palette)),
          ],
        ),
      ),
    );
  }
}

class _ShareLink extends StatelessWidget {
  const _ShareLink({required this.link});

  final String link;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.surface(
        palette,
        radius: 12,
        color: palette.recessed,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            AlongIcon(AlongIcons.share, size: 20, color: palette.ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                link,
                maxLines: 1,
                softWrap: false,
                style: AlongType.body(palette).copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fare card while the quote is still on the way. The sheen rests in tests.
class AlongFlowLoading extends StatelessWidget {
  const AlongFlowLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Getting the fare',
                maxLines: 1,
                softWrap: false,
                style: AlongType.title(palette),
              ),
              const SizedBox(height: 4),
              Text(
                'Wuse to Nyanya',
                maxLines: 1,
                softWrap: false,
                style: AlongType.bodyMuted(palette),
              ),
              const SizedBox(height: 16),
              const AlongSkeleton(variant: SkeletonVariant.line, height: 28),
              const SizedBox(height: 12),
              const AlongSkeleton(variant: SkeletonVariant.line),
              const SizedBox(height: 8),
              const AlongSkeleton(variant: SkeletonVariant.line, width: 180),
              const SizedBox(height: 8),
              const AlongSkeleton(variant: SkeletonVariant.line),
              const SizedBox(height: 16),
              const AlongSkeleton(variant: SkeletonVariant.card, height: 88),
              const Spacer(),
              const AlongSkeleton(variant: SkeletonVariant.line, height: 56),
            ],
          ),
        ),
      ),
    );
  }
}

/// The pull-to-refresh still. The car sits mid-road. Motion drives it across.
class AlongFlowRefresh extends StatelessWidget {
  const AlongFlowRefresh({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose a ride', style: AlongType.title(palette)),
              const SizedBox(height: 2),
              Text(
                'Updating the list',
                maxLines: 1,
                softWrap: false,
                style: AlongType.bodyMuted(palette),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: AlongCraft.surface(
                  palette,
                  radius: 16,
                  hairline: true,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: AlongDriveTrack(progress: 0.58),
                ),
              ),
              const SizedBox(height: 12),
              const AlongSkeleton(variant: SkeletonVariant.card, height: 72),
              const SizedBox(height: 8),
              const AlongSkeleton(variant: SkeletonVariant.card, height: 64),
              const SizedBox(height: 8),
              const AlongSkeleton(variant: SkeletonVariant.card, height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
