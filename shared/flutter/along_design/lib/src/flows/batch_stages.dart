import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/along_button.dart';
import '../components/seat_map.dart';
import '../components/skeleton.dart';
import '../craft.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../tokens.g.dart';
import '../type.dart';
import 'city_map.dart';
import 'delights.dart';
import 'driver_portrait.dart';
import 'vehicle_art.dart';

void _noop() {}

bool _roomy(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > 1.15;

Widget _oneLine(String text, TextStyle style) {
  return Text(
    text,
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
    style: style,
  );
}

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
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
    );
  }
}

class _DepartureRow extends StatelessWidget {
  const _DepartureRow({required this.item});

  final AlongDeparture item;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final demand = item.demand.clamp(0.0, 1.0);
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            clipBehavior: Clip.antiAlias,
            decoration: AlongCraft.fill(
              item.best ? palette.accent : palette.ink.withValues(alpha: 0.12),
              corner: 1,
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 52),
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
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
          SizedBox(
            width: 48,
            height: 12,
            child: AlongCraft.clip(
              corner: AlongRadius.xs.x,
              child: LinearProgressIndicator(
                value: demand,
                minHeight: 12,
                backgroundColor: palette.ink.withValues(alpha: 0.12),
                color: item.best
                    ? palette.accent
                    : palette.ink.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Weekly seat on one corridor. The ticket fills the page.
class AlongFlowPass extends StatelessWidget {
  const AlongFlowPass({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pass', style: AlongType.display(palette)),
        const SizedBox(height: 4),
        _oneLine('Wuse to Nyanya · each week', AlongType.bodyMuted(palette)),
        const SizedBox(height: 12),
        if (roomy)
          const _PassTicket(roomy: true)
        else
          const Expanded(child: _PassTicket(roomy: false)),
        const SizedBox(height: 10),
        const AlongButton(label: 'Subscribe', onPressed: _noop),
      ],
    );
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: roomy ? SingleChildScrollView(child: column) : column,
        ),
      ),
    );
  }
}

class _PassTicket extends StatelessWidget {
  const _PassTicket({required this.roomy});

  final bool roomy;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AlongCraft.surface(
        palette,
        radius: AlongRadius.card.x,
        hairline: true,
      ),
      child: Column(
        children: [
          if (roomy)
            const SizedBox(height: 168, child: _PassMap())
          else
            const Expanded(child: _PassMap()),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _PassRoute(),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: _PassCalendar(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_PassSavings(), SizedBox(height: 8), _PassPerks()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassMap extends StatelessWidget {
  const _PassMap();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: AlongCraft.borderVertical(top: AlongRadius.card.x),
      ),
      child: const Stack(
        fit: StackFit.expand,
        children: [
          AlongCityMap(
            mode: AlongCityMapMode.trip,
            progress: 1,
            sheetInset: 0.08,
            demoLabel: false,
            fix: AlongFix.hidden,
            center: AlongCityMap.corridorCenter,
            zoom: 12,
          ),
        ],
      ),
    );
  }
}

class _PassRoute extends StatelessWidget {
  const _PassRoute();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '10 rides',
            maxLines: 1,
            softWrap: false,
            style: AlongType.body(palette)
                .copyWith(fontWeight: FontWeight.w600, height: 1.1),
          ),
        ),
        AlongMoney(value: 4800, style: AlongType.title(palette)),
      ],
    );
  }
}

class _PassPerks extends StatelessWidget {
  const _PassPerks();

  @override
  Widget build(BuildContext context) {
    return Text(
      'AC · Window · Luggage',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: AlongType.caption(AlongPalette.of(context))
          .copyWith(color: AlongPalette.of(context).ink),
    );
  }
}

class _PassCalendar extends StatelessWidget {
  const _PassCalendar();

  static const _days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final raw = (constraints.maxWidth - gap * 6) / 7;
        final side = raw > 40 ? 40.0 : raw;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < _days.length; i++)
              SizedBox(
                width: side,
                child: _PassDay(label: _days[i], index: i, side: side),
              ),
          ],
        );
      },
    );
  }
}

class _PassDay extends StatelessWidget {
  const _PassDay({
    required this.label,
    required this.index,
    required this.side,
  });

  final String label;
  final int index;
  final double side;

  static const _dates = [19, 20, 21, 22, 23, 24, 25];

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final booked = index < 5;
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final day = AlongType.label(palette).copyWith(height: 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: side,
          height: roomy ? null : 40,
          child: DecoratedBox(
            decoration: AlongCraft.fill(
              booked ? palette.ink : const Color(0x00000000),
              corner: side >= 36 ? AlongRadius.control.x : AlongRadius.xs.x,
              side: booked
                  ? BorderSide.none
                  : BorderSide(color: palette.ink, width: 1.5),
            ),
            child: Center(
              child: Text(
                '${_dates[index]}',
                maxLines: 1,
                softWrap: false,
                style: day.copyWith(
                  color: booked ? palette.onInk : palette.ink,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: day,
        ),
      ],
    );
  }
}

class _PassSavings extends StatelessWidget {
  const _PassSavings();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final label = AlongType.caption(palette)
        .copyWith(color: palette.ink, fontWeight: FontWeight.w600, height: 1.1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Versus single fares', maxLines: 1, softWrap: false, style: label),
        const SizedBox(height: 8),
        const _FareLine(name: 'Single', amount: '₦12,000'),
        const SizedBox(height: 4),
        const _FareLine(name: 'Pass', amount: '₦4,800'),
        const SizedBox(height: 8),
        Text(
          'Save ₦7,200',
          maxLines: 1,
          softWrap: false,
          style: AlongType.body(palette)
              .copyWith(fontWeight: FontWeight.w600, height: 1.2),
        ),
      ],
    );
  }
}

class _FareLine extends StatelessWidget {
  const _FareLine({required this.name, required this.amount});

  final String name;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final style = AlongType.body(palette).copyWith(height: 1.3);
    return Row(
      children: [
        Expanded(child: Text(name, maxLines: 1, softWrap: false, style: style)),
        Text(
          amount,
          maxLines: 1,
          softWrap: false,
          style: style.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Split', style: AlongType.display(palette)),
        const SizedBox(height: 2),
        _oneLine('Wuse to Nyanya · two seats', AlongType.bodyMuted(palette)),
        const SizedBox(height: 8),
        _SplitRiders(size: roomy ? 72 : 84),
        const SizedBox(height: 8),
        const _SplitCards(),
        const SizedBox(height: 8),
        const _PaidRow(),
        const SizedBox(height: 8),
        const _TripSummary(),
        const SizedBox(height: 8),
        const _PayMethod(),
        if (!roomy) const Spacer(),
        const SizedBox(height: 8),
        const AlongButton(
          label: 'Remind Ada',
          variant: AlongButtonVariant.secondary,
          onPressed: _noop,
        ),
        const SizedBox(height: 8),
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: roomy ? SingleChildScrollView(child: column) : column,
        ),
      ),
    );
  }
}

void _copyLink() {
  Clipboard.setData(const ClipboardData(text: 'https://along.app/s/nyanya'));
}

class _TripSummary extends StatelessWidget {
  const _TripSummary();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This trip',
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette).copyWith(
            color: palette.ink,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        const _SummaryLine(icon: AlongIcons.path, label: 'Wuse to Nyanya'),
        const SizedBox(height: 4),
        const _SummaryLine(icon: AlongIcons.seat, label: '2 seats'),
        const SizedBox(height: 4),
        const _SummaryLine(icon: AlongIcons.schedule, label: '4-6 min'),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      children: [
        AlongIcon(icon, size: 20, color: palette.ink),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: AlongType.body(palette)
                .copyWith(fontWeight: FontWeight.w600, height: 1.1),
          ),
        ),
      ],
    );
  }
}

class _PayMethod extends StatelessWidget {
  const _PayMethod();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      children: [
        AlongIcon(AlongIcons.wallet, size: 20, color: palette.ink),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Wallet',
            maxLines: 1,
            softWrap: false,
            style: AlongType.body(palette)
                .copyWith(fontWeight: FontWeight.w600, height: 1.1),
          ),
        ),
        AlongMoney(
          value: 600,
          style: AlongType.body(palette)
              .copyWith(fontWeight: FontWeight.w600, height: 1.1),
        ),
      ],
    );
  }
}

class _SplitRiders extends StatelessWidget {
  const _SplitRiders({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RiderFace(
            name: 'You',
            asset: AlongDriverPortrait.chinedu,
            size: size,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RiderFace(
            name: 'Ada',
            asset: AlongDriverPortrait.adaeze,
            size: size,
          ),
        ),
      ],
    );
  }
}

class _RiderFace extends StatelessWidget {
  const _RiderFace({
    required this.name,
    required this.asset,
    required this.size,
  });

  final String name;
  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      children: [
        AlongDriverPortrait(size: size, asset: asset),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          softWrap: false,
          style: AlongType.body(palette)
              .copyWith(fontWeight: FontWeight.w600, height: 1.1),
        ),
      ],
    );
  }
}

class _SplitCards extends StatelessWidget {
  const _SplitCards();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _SplitCard(name: 'You', yours: true)),
        SizedBox(width: 12),
        Expanded(child: _SplitCard(name: 'Ada')),
      ],
    );
  }
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({required this.name, this.yours = false});

  final String name;
  final bool yours;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: AlongCraft.fill(
        palette.surface,
        corner: AlongRadius.card.x,
        side: BorderSide(
          color: yours ? palette.accent : palette.ink.withValues(alpha: 0.14),
          width: yours ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            softWrap: false,
            style: AlongType.label(palette),
          ),
          const SizedBox(height: 2),
          Text(
            '₦600',
            maxLines: 1,
            softWrap: false,
            style: AlongType.title(palette).copyWith(
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaidRow extends StatelessWidget {
  const _PaidRow();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      children: [
        AlongIcon(AlongIcons.check, size: 20, color: palette.ink),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Ada paid',
            maxLines: 1,
            softWrap: false,
            style: AlongType.body(palette)
                .copyWith(fontWeight: FontWeight.w600, height: 1.1),
          ),
        ),
        AlongMoney(
          value: 600,
          style: AlongType.body(palette)
              .copyWith(fontWeight: FontWeight.w600, height: 1.1),
        ),
      ],
    );
  }
}

/// Fare card while the quote is still on the way. Bones mirror the card.
class AlongFlowLoading extends StatelessWidget {
  const AlongFlowLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _oneLine('Getting the fare', AlongType.title(palette)),
        const SizedBox(height: 2),
        _oneLine('Wuse to Nyanya', AlongType.bodyMuted(palette)),
        const SizedBox(height: 12),
        if (roomy)
          const SizedBox(height: 180, child: _LoadingMap())
        else
          const Expanded(flex: 4, child: _LoadingMap()),
        const SizedBox(height: 12),
        if (roomy)
          const _LoadingCard(spread: false)
        else
          const Expanded(flex: 5, child: _LoadingCard(spread: true)),
        const SizedBox(height: 12),
        const AlongSkeleton(variant: SkeletonVariant.card, height: 56),
      ],
    );
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: roomy ? SingleChildScrollView(child: column) : column,
        ),
      ),
    );
  }
}

class _LoadingMap extends StatelessWidget {
  const _LoadingMap();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final dark = palette.brightness == Brightness.dark;
    final tone = dark ? 'dark' : 'light';
    // Light tiles are almost one grey. Stretch them around the land value
    // so the baked streets read, then blur so none of the edges stay hard.
    final contrast = dark ? 1.0 : 4.0;
    final pivot = dark ? 40.0 : 224.0;
    final shift = pivot * (1 - contrast);
    return ClipPath(
      clipper: ShapeBorderClipper(shape: AlongCraft.border(AlongRadius.card.x)),
      child: ColoredBox(
        color: palette.mapLand,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(<double>[
                  contrast,
                  0,
                  0,
                  0,
                  shift,
                  0,
                  contrast,
                  0,
                  0,
                  shift,
                  0,
                  0,
                  contrast,
                  0,
                  shift,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: Row(
                  children: [
                    for (final name in ['12_2132_1944', '12_2133_1944'])
                      Expanded(
                        child: Image.asset(
                          'assets/map/tiles/$tone/$name.png',
                          package: 'along_design',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.low,
                          excludeFromSemantics: true,
                          gaplessPlayback: true,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ColoredBox(
              color: palette.mapLand.withValues(alpha: dark ? 0.18 : 0.1),
            ),
            const _MapShimmer(),
          ],
        ),
      ),
    );
  }
}

/// Warm band held at the same rest as [AlongSkeleton]. It does not repaint
/// the streets.
class _MapShimmer extends StatefulWidget {
  const _MapShimmer();

  @override
  State<_MapShimmer> createState() => _MapShimmerState();
}

class _MapShimmerState extends State<_MapShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AlongDurations.shimmer,
      value: 0.42,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = AlongMotionPolicy.reduced(context);
    final play = AlongMotionPolicy.play(context) && !reduced;
    if (play) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = reduced ? 0 : 0.42;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.4 + 2.6 * t, 0),
                end: Alignment(-0.2 + 2.6 * t, 0),
                colors: const [
                  Color(0x00FFF6E8),
                  Color(0x47FFF6E8),
                  Color(0x00FFF6E8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.spread});

  final bool spread;

  static const _rows = <(double, double)>[
    (0.62, 0.34),
    (0.48, 0.28),
    (0.56, 0.38),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.surface(
        palette,
        radius: AlongRadius.card.x,
        hairline: true,
        shadow: AlongElevation.rest(palette.ink),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisAlignment: spread
              ? MainAxisAlignment.spaceEvenly
              : MainAxisAlignment.start,
          mainAxisSize: spread ? MainAxisSize.max : MainAxisSize.min,
          children: [
            for (final row in _rows) ...[
              _BoneRow(name: row.$1, meta: row.$2),
              if (!spread) const SizedBox(height: 14),
            ],
            const _BoneFare(),
          ],
        ),
      ),
    );
  }
}

class _BoneRow extends StatelessWidget {
  const _BoneRow({required this.name, required this.meta});

  final double name;
  final double meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ClipOval(child: AlongSkeleton(width: 40, height: 40)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(
                widthFactor: name,
                alignment: Alignment.centerLeft,
                child: const AlongSkeleton(height: 12),
              ),
              const SizedBox(height: 8),
              FractionallySizedBox(
                widthFactor: meta,
                alignment: Alignment.centerLeft,
                child: const AlongSkeleton(height: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoneFare extends StatelessWidget {
  const _BoneFare();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AlongSkeleton(width: 88, height: 12),
        Spacer(),
        AlongSkeleton(width: 64, height: 16),
      ],
    );
  }
}

/// The pull-to-refresh still. The car sits mid-road over the ride list.
class AlongFlowRefresh extends StatelessWidget {
  const AlongFlowRefresh({super.key});

  static const _rides = <_RideSpec>[
    _RideSpec(
      kind: AlongVehicleKind.keke,
      title: 'Keke',
      eta: '4-6 min',
      seats: 2,
      fare: '₦400-600',
      badge: 'For you',
      selected: true,
    ),
    _RideSpec(
      kind: AlongVehicleKind.okada,
      title: 'Okada',
      eta: 'Fastest · 2-4 min',
      seats: 1,
      fare: '₦300-500',
    ),
    _RideSpec(
      kind: AlongVehicleKind.car,
      title: 'Car',
      eta: '6-8 min',
      seats: 3,
      fare: '₦1,100-1,400',
    ),
    _RideSpec(
      kind: AlongVehicleKind.danfo,
      title: 'Danfo',
      eta: 'Cheapest · 8-12 min',
      seats: 8,
      fare: '₦200-350',
    ),
    _RideSpec(
      kind: AlongVehicleKind.bus,
      title: 'Bus',
      eta: '12-16 min',
      seats: 14,
      fare: '₦500-800',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _oneLine('Updating rides', AlongType.title(palette)),
        const SizedBox(height: 2),
        _oneLine('Choose a ride', AlongType.bodyMuted(palette)),
        const SizedBox(height: 8),
        ClipPath(
          clipper: ShapeBorderClipper(
            shape: AlongCraft.border(AlongRadius.card.x),
          ),
          child: ColoredBox(
            color: palette.mapLand,
            child: const AlongDriveTrack(
              progress: 0.58,
              height: 112,
              carWidth: 136,
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final ride in _rides)
          if (roomy)
            _RefreshRide(ride: ride, fill: false)
          else
            Expanded(child: _RefreshRide(ride: ride, fill: true)),
        const SizedBox(height: 8),
        const AlongButton(label: 'Confirm keke', onPressed: _noop),
      ],
    );
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: roomy ? SingleChildScrollView(child: column) : column,
        ),
      ),
    );
  }
}

class _RideSpec {
  const _RideSpec({
    required this.kind,
    required this.title,
    required this.eta,
    required this.seats,
    required this.fare,
    this.badge,
    this.selected = false,
  });

  final AlongVehicleKind kind;
  final String title;
  final String eta;
  final int seats;
  final String fare;
  final String? badge;
  final bool selected;
}

class _RefreshRide extends StatelessWidget {
  const _RefreshRide({required this.ride, required this.fill});

  final _RideSpec ride;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final decoration = BoxDecoration(
      border: Border(
        bottom: BorderSide(color: palette.ink.withValues(alpha: 0.12)),
        left: ride.selected
            ? BorderSide(color: palette.ink, width: 2)
            : BorderSide.none,
      ),
    );
    final row = Row(
      children: [
        AlongVehicleMark(kind: ride.kind, width: 48, height: 30),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ride.title,
                      maxLines: 1,
                      softWrap: false,
                      style: AlongType.body(palette)
                          .copyWith(fontWeight: FontWeight.w600, height: 1.1),
                    ),
                    if (ride.badge != null) ...[
                      const SizedBox(width: 6),
                      const _ForYou(),
                    ],
                  ],
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ride.eta,
                      maxLines: 1,
                      softWrap: false,
                      style: AlongType.caption(palette),
                    ),
                    const SizedBox(width: 6),
                    AlongSeatCount(count: ride.seats, glyph: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              ride.fare,
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600, height: 1.1),
            ),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DecoratedBox(
        decoration: decoration,
        child: fill
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: row,
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: row,
              ),
      ),
    );
  }
}

class _ForYou extends StatelessWidget {
  const _ForYou();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Text(
      'For you',
      maxLines: 1,
      softWrap: false,
      style: AlongType.label(palette),
    );
  }
}
