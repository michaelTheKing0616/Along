import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../components/along_button.dart';
import '../components/seat_map.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../theme.dart';
import '../type.dart';
import 'city_map.dart';
import 'delights.dart';
import 'driver_portrait.dart';
import 'map_sketch.dart';
import 'spring_sheet.dart';
import 'vehicle_art.dart';

/// Premium flow frames for both apps. Copy is warm and plain. [jk-writing]
/// Layout groups with a 4pt scale and 48dp targets. [jk-layout] [jk-accessibility]

class AlongFlowOnboarding extends StatelessWidget {
  const AlongFlowOnboarding({
    super.key,
    this.legacyCopy = false,
    this.step = 0,
  });

  final bool legacyCopy;

  /// 0 is the poster. 1 is the phone step, still one tap away.
  final int step;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    if (step > 0) return _phoneStep(palette);
    // The poster is a photograph. Keep the light paper theme so the
    // headline and the button stay readable in the dark gallery too.
    return Theme(data: alongTheme(), child: const _Poster());
  }

  Widget _phoneStep(AlongPalette palette) {
    return _Page(
      bottom: const AlongButton(label: 'Text me the code', onPressed: _noop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your number', style: AlongType.display(palette)),
          const SizedBox(height: 8),
          Text(
            legacyCopy
                ? 'Enter your number to continue'
                : 'We text a code to this number so the ride stays yours.',
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 16),
          _Field(
            fill: palette.surface,
            child: Row(
              children: [
                Text('+234', style: AlongType.title(palette)),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: palette.line.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: Text(
                    '801 234 5678',
                    style: AlongType.body(palette).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const _FactRow(icon: AlongIcons.shield, label: 'Code by text'),
          const _FactRow(
            icon: AlongIcons.seat,
            label: 'The ride stays on this number',
          ),
          const _FactRow(
            icon: AlongIcons.wallet,
            label: 'No password to remember',
          ),
        ],
      ),
    );
  }
}

class AlongFlowHome extends StatelessWidget {
  const AlongFlowHome({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return AlongMapMotion(
      builder: (context, extent) {
        return Scaffold(
          backgroundColor: palette.mapLand,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final fraction = constraints.maxHeight >= 760 ? 0.58 : 0.64;
              final sheetTop = constraints.maxHeight * (1 - fraction);
              Widget map = const AlongCityMap();
              if (extent != 0) {
                map = Transform.translate(
                  offset: Offset(0, extent * 18),
                  child: map,
                );
              }
              return Stack(
                children: [
                  Positioned.fill(child: map),
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 180,
                    child: IgnorePointer(
                      child: AlongDayGradient(phase: AlongDayPhase.afternoon),
                    ),
                  ),
                  if (extent != 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: Color.fromRGBO(14, 14, 16, 0.35 * extent),
                        ),
                      ),
                    ),
                  const Positioned(
                    top: 16,
                    left: 16,
                    child: AlongMapButton(
                      icon: AlongIcons.menu,
                      tooltip: 'Menu',
                    ),
                  ),
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: AlongMapButton(
                      icon: AlongIcons.locate,
                      tooltip: 'Recenter',
                    ),
                  ),
                  const Positioned(
                    top: 76,
                    left: 16,
                    right: 72,
                    child: AlongGreeting(phase: AlongDayPhase.afternoon),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: sheetTop - 60,
                    child: const AlongTabBar(),
                  ),
                  Positioned.fill(
                    child: AlongSpringSheet(
                      fraction: fraction,
                      snaps: [fraction, 0.88],
                      child: const _HomeSheetBody(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _HomeSheetBody extends StatelessWidget {
  const _HomeSheetBody();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: palette.ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              AlongIcon(AlongIcons.search, color: palette.onInk, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Where to?',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.title(palette)
                      .copyWith(color: palette.onInk),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: AlongElevation.hairline(palette.ink),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _PlaceRow(
                  icon: AlongIcons.home,
                  title: 'Home',
                  detail: 'Garki · 12 min',
                ),
                _PlaceRow(
                  icon: AlongIcons.work,
                  title: 'Work',
                  detail: 'Wuse Market',
                ),
                _PlaceRow(
                  icon: AlongIcons.schedule,
                  title: 'Nyanya',
                  detail: 'Yesterday · ₦1,200',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _RoutePromo(),
        const Spacer(),
        const _ServiceRow(),
      ],
    );
  }
}

class _RoutePromo extends StatelessWidget {
  const _RoutePromo();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: AlongElevation.hairline(palette.ink),
      ),
      child: Row(
        children: [
          const AlongVehicleMark(
            kind: AlongVehicleKind.keke,
            width: 64,
            height: 40,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evening along',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.body(palette)
                      .copyWith(fontWeight: FontWeight.w700, height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wuse to Nyanya · ₦200 off',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow();

  static const _items = <(AlongVehicleKind, String)>[
    (AlongVehicleKind.keke, 'Keke'),
    (AlongVehicleKind.okada, 'Okada'),
    (AlongVehicleKind.car, 'Car'),
    (AlongVehicleKind.danfo, 'Danfo'),
    (AlongVehicleKind.bus, 'Bus'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final label = AlongType.caption(palette)
        .copyWith(fontWeight: FontWeight.w700, color: palette.ink, height: 1.1);
    return Row(
      children: [
        for (final item in _items)
          Expanded(
            child: Column(
              children: [
                AlongVehicleMark(kind: item.$1, width: 52, height: 32),
                const SizedBox(height: 4),
                Text(item.$2, maxLines: 1, softWrap: false, style: label),
              ],
            ),
          ),
      ],
    );
  }
}

class AlongFlowSeats extends StatelessWidget {
  const AlongFlowSeats({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Choose a seat',
                          style: AlongType.display(palette),
                        ),
                        const SizedBox(height: 12),
                        const _SeatDriver(),
                        const SizedBox(height: 16),
                        const SeatMap(
                          body: 'cabin',
                          rows: [
                            SeatMapRowView(
                              id: 'front',
                              seats: [
                                SeatMapSeat(
                                  id: 'fm',
                                  label: 'FM',
                                  role: 'passenger',
                                  status: 'yours',
                                  statusWord: 'Yours',
                                  price: '₦1,200',
                                ),
                                SeatMapSeat(
                                  id: 'fr',
                                  label: 'FR',
                                  role: 'passenger',
                                  status: 'held',
                                  statusWord: 'Held',
                                  price: '₦900',
                                ),
                                SeatMapSeat(
                                  id: 'drv',
                                  label: 'Driver',
                                  role: 'driver',
                                  status: 'occupied',
                                  statusWord: 'Driver',
                                ),
                              ],
                            ),
                            SeatMapRowView(
                              id: 'back',
                              seats: [
                                SeatMapSeat(
                                  id: 'b1',
                                  label: 'BL',
                                  role: 'passenger',
                                  status: 'free',
                                  statusWord: 'Free',
                                  price: '₦700',
                                ),
                                SeatMapSeat(
                                  id: 'b2',
                                  label: 'ML',
                                  role: 'passenger',
                                  status: 'occupied',
                                  statusWord: 'Taken',
                                ),
                                SeatMapSeat(
                                  id: 'b3',
                                  label: 'MR',
                                  role: 'passenger',
                                  status: 'free',
                                  statusWord: 'Free',
                                  price: '₦700',
                                ),
                                SeatMapSeat(
                                  id: 'b4',
                                  label: 'BR',
                                  role: 'passenger',
                                  status: 'held',
                                  statusWord: 'Held',
                                  price: '₦800',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const _SeatSection(
                      child: AlongWhosRiding(riders: AlongRider.riding),
                    ),
                    const _SeatSection(
                      child: AlongSeatContext(
                        origin: 'Wuse Market',
                        destination: 'Garki',
                        departs: 'Departs in 12 min',
                        seatsLeft: '3/6 seats left',
                        ruled: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _SeatBar(),
          ],
        ),
      ),
    );
  }
}

class _SeatDriver extends StatelessWidget {
  const _SeatDriver();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final name = AlongType.title(palette).copyWith(fontSize: 16, height: 1.1);
    final rating = AlongType.meta(palette).copyWith(
      color: palette.ink,
      fontWeight: FontWeight.w600,
      height: 1.1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      children: [
        const AlongDriverPortrait(size: 48, verified: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Chinedu', maxLines: 1, softWrap: false, style: name),
                  const SizedBox(width: 8),
                  AlongIcon(AlongIcons.star, size: 20, color: palette.accent),
                  const SizedBox(width: 2),
                  Text('4.9', maxLines: 1, softWrap: false, style: rating),
                ],
              ),
              const SizedBox(height: 6),
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    _SeatChip(label: 'Sedan'),
                    SizedBox(width: 6),
                    _SeatChip(label: 'ABC-123-XY', tabular: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: AlongVehicleHero(
                kind: AlongVehicleKind.car,
                width: 44,
                height: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SeatSection extends StatelessWidget {
  const _SeatSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: child,
      ),
    );
  }
}

class _SeatBar extends StatelessWidget {
  const _SeatBar();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(color: palette.ink.withValues(alpha: 0.12)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Front middle',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.title(palette)
                            .copyWith(fontSize: 16, height: 1.1),
                      ),
                      const SizedBox(height: 6),
                      const _SeatChip(label: 'Window stays open'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Hero(
                  tag: 'along-fare-car',
                  child: AlongOdometer(
                    value: 1200,
                    style: AlongType.numeric(palette),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AlongSwipeConfirm(label: 'Hold this seat', onConfirmed: _noop),
          ],
        ),
      ),
    );
  }
}

class _SeatChip extends StatelessWidget {
  const _SeatChip({required this.label, this.tabular = false});

  final String label;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.recessed,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette).copyWith(
            fontWeight: FontWeight.w600,
            height: 1.1,
            fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
          ),
        ),
      ),
    );
  }
}

class AlongFlowLive extends StatelessWidget {
  const AlongFlowLive({super.key, this.progress = 0.62});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlongPalette.of(context).mapLand,
      body: Stack(
        children: [
          Positioned.fill(
            child: AlongCityMap(
              mode: AlongCityMapMode.trip,
              progress: progress,
            ),
          ),
          const Positioned(
            top: 16,
            left: 16,
            child: AlongMapButton(icon: AlongIcons.shield, tooltip: 'Safety'),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fraction = constraints.maxHeight >= 760 ? 0.46 : 0.54;
                return AlongSpringSheet(
                  fraction: fraction,
                  snaps: [fraction, 0.72],
                  child: const _LiveSheet(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveSheet extends StatelessWidget {
  const _LiveSheet();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AlongDriverPortrait(size: 56, verified: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chinedu',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.title(palette).copyWith(height: 1.1),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const _PlateChip(label: 'ABC-123-XY'),
                        const SizedBox(width: 8),
                        AlongIcon(
                          AlongIcons.star,
                          size: 20,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '4.9',
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.caption(palette).copyWith(
                            color: palette.ink,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const AlongVehicleMark(
              kind: AlongVehicleKind.car,
              width: 72,
              height: 44,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AlongTickingEta(label: '6 min', style: AlongType.display(palette)),
            const Spacer(),
            Text(
              'Nyanya',
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600, height: 1.2),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: palette.recessed),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.62,
                  child: ColoredBox(color: palette.ink),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        const Row(
          children: [
            _LiveAction(icon: AlongIcons.call, label: 'Call'),
            _LiveAction(icon: AlongIcons.chat, label: 'Message'),
            _LiveAction(icon: AlongIcons.share, label: 'Share'),
            _LiveAction(icon: AlongIcons.shield, label: 'Safety'),
          ],
        ),
      ],
    );
  }
}

class _PlateChip extends StatelessWidget {
  const _PlateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.recessed,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: AlongType.caption(palette).copyWith(
          color: palette.ink,
          fontWeight: FontWeight.w700,
          height: 1,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _LiveAction extends StatelessWidget {
  const _LiveAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
              border: AlongElevation.hairline(palette.ink),
            ),
            child: AlongIcon(icon, size: 20, color: palette.ink),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette).copyWith(
              color: palette.ink,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class AlongFlowSos extends StatelessWidget {
  const AlongFlowSos({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Safety', style: AlongType.display(palette)),
          const SizedBox(height: 4),
          Text(
            'Ready · your location stays with you',
            maxLines: 1,
            softWrap: false,
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 16),
          const Center(child: _HoldRing(size: 148)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Hold for 2 seconds',
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: AlongElevation.hairline(palette.ink),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _ContactLine(
                      name: 'Adaeze',
                      detail: 'Sister · gets the alert',
                      asset: AlongDriverPortrait.adaeze,
                    ),
                    _SafetyLine(icon: AlongIcons.share, label: 'Share trip'),
                    _SafetyLine(icon: AlongIcons.call, label: 'Call 112'),
                    _SafetyLine(icon: AlongIcons.shield, label: 'Guardian'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AlongFlowGuardian extends StatelessWidget {
  const AlongFlowGuardian({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Save', onPressed: _noop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Guardian', style: AlongType.display(palette)),
          const SizedBox(height: 4),
          Text(
            'On Nyanya road · check-in 14:02',
            maxLines: 1,
            softWrap: false,
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 8),
          const _MapHero(height: 128, label: 'Live', live: true),
          const SizedBox(height: 8),
          const Expanded(child: _GuardianCard()),
        ],
      ),
    );
  }
}

class AlongFlowPlate extends StatelessWidget {
  const AlongFlowPlate({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _PlateFrame(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Color(0x00000000),
                  Color(0xCC000000),
                ],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check the plate',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.heading(palette)
                        .copyWith(color: Colors.white),
                  ),
                  Text(
                    'Fit the plate in the frame.',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.meta(palette)
                        .copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PlateMatch(),
                          _Fold(
                            label: 'Driver',
                            child: _PersonCard(
                              name: 'Chinedu',
                              detail: 'Sedan · matches this plate',
                              trailing: '4.9',
                            ),
                          ),
                          SizedBox(height: 8),
                          AlongButton(label: 'Continue', onPressed: _noop),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AlongFlowWallet extends StatelessWidget {
  const AlongFlowWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      bottom: const AlongButton(label: 'Pay ₦1,200', onPressed: _noop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AlongGyroCard(child: _BalanceCard()),
          SizedBox(height: 16),
          _WalletTiles(),
          SizedBox(height: 16),
          Expanded(child: _ActivityCard()),
        ],
      ),
    );
  }
}

class AlongFlowDay extends StatelessWidget {
  const AlongFlowDay({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Save the day', onPressed: _noop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thursday', style: AlongType.display(palette)),
          const SizedBox(height: 4),
          Text(
            '7 runs · Nyanya corridor',
            maxLines: 1,
            softWrap: false,
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 8),
          const _DaySummary(),
          const SizedBox(height: 8),
          const Expanded(child: _DayBoard()),
        ],
      ),
    );
  }
}

class AlongFlowOnline extends StatelessWidget {
  const AlongFlowOnline({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(mode: AlongCityMapMode.online),
          ),
          const Positioned(top: 16, left: 16, child: _HeatTip()),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TodayPill(),
                SizedBox(height: 8),
                _DemandHint(),
                SizedBox(height: 16),
                _GoButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlongFlowOffer extends StatelessWidget {
  const AlongFlowOffer({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(mode: AlongCityMapMode.routeHero),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AlongElevation.sheet(palette.ink),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: SizedBox(
                      height: 4,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: palette.recessed),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.72,
                            child: ColoredBox(color: palette.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _OfferRoute(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '₦1,800',
                                maxLines: 1,
                                softWrap: false,
                                style: AlongType.display(palette),
                              ),
                            ),
                            Text(
                              '4.2 km',
                              maxLines: 1,
                              softWrap: false,
                              style: AlongType.caption(palette).copyWith(
                                color: palette.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const _RiderRow(),
                        const SizedBox(height: 8),
                        const _OfferSeats(),
                        const SizedBox(height: 12),
                        AlongSwipeConfirm(label: 'Accept', onConfirmed: _noop),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AlongFlowEarnings extends StatelessWidget {
  const AlongFlowEarnings({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Cash out', onPressed: _noop),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The first viewport is the total and the chart. Payout and the
          // trip list start on the next scroll.
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today', style: AlongType.caption(palette)),
                      AlongOdometer(
                        value: 48200,
                        style: AlongType.display(palette),
                      ),
                      Text(
                        '11 trips · goal ₦60,000',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.bodyMuted(palette),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 132, child: _WeekBars()),
                      const SizedBox(height: 8),
                      const _EarnBreakdown(),
                      const SizedBox(height: 8),
                      const _PassUpsell(),
                      const SizedBox(height: 8),
                      const Expanded(child: _EarnList()),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AlongFlowRides extends StatelessWidget {
  const AlongFlowRides({super.key, this.rulesFor});

  /// When set, the ride-details sheet is open on this product.
  final int? rulesFor;

  static const _products = <(String, String, List<String>)>[
    ('Keke', '₦400-600', ['Window open', 'Women in back']),
    ('Okada', '₦300-500', ['Helmet on']),
    ('Car', '₦1,100-1,400', ['AC', 'Trust 86']),
    ('Danfo', '₦200-350', ['Along the corridor']),
    ('Bus', '₦500-800', ['Seats assigned']),
  ];

  @override
  Widget build(BuildContext context) {
    final detail = rulesFor;
    final product = detail == null ? null : _products[detail];
    return Scaffold(
      backgroundColor: AlongPalette.of(context).mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(mode: AlongCityMapMode.trip, progress: 1),
          ),
          const Positioned(
            top: 16,
            left: 16,
            child: AlongMapButton(icon: AlongIcons.back, tooltip: 'Back'),
          ),
          const Positioned(
            top: 16,
            right: 16,
            child: _MapChip(label: '4.2 km · 18 min'),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Three large cards, then the rest of the fleet scrolls.
                // Uber's select screen is the list. Leave a strip of map.
                final height = constraints.maxHeight - 72;
                return AlongSpringSheet(
                  restingHeight: height,
                  child: const _RideSheet(),
                );
              },
            ),
          ),
          if (product != null)
            Positioned.fill(
              child: AlongSpringSheet(
                fraction: 0.42,
                child: _RideRules(
                  title: product.$1,
                  fare: product.$2,
                  rules: product.$3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RideSheet extends StatelessWidget {
  const _RideSheet();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose a ride', style: AlongType.heading(palette)),
        const SizedBox(height: 2),
        Text(
          'Wuse to Nyanya · 4.2 km',
          maxLines: 1,
          softWrap: false,
          style: AlongType.meta(palette)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 8),
        const _RecommendedRide(),
        const SizedBox(height: 4),
        const Expanded(child: _RideList()),
        const SizedBox(height: 6),
        const AlongButton(label: 'Confirm keke', onPressed: _noop),
      ],
    );
  }
}

class _RideList extends StatelessWidget {
  const _RideList();

  @override
  Widget build(BuildContext context) {
    return AlongKekeRefresh(
      onRefresh: () async {},
      child: ListView(
        padding: EdgeInsets.zero,
        children: const [
          AlongStagger(
            index: 0,
            child: _RideLine(
              kind: AlongVehicleKind.okada,
              title: 'Okada',
              eta: '3 min',
              seats: '1 left',
              fare: '₦300-500',
              badge: 'Fastest',
            ),
          ),
          AlongStagger(
            index: 1,
            child: _RideLine(
              kind: AlongVehicleKind.car,
              title: 'Car',
              eta: '6 min',
              seats: '3 left',
              fare: '₦1,100-1,400',
            ),
          ),
          AlongStagger(
            index: 2,
            child: _RideLine(
              kind: AlongVehicleKind.danfo,
              title: 'Danfo',
              eta: '8 min',
              seats: '8 left',
              fare: '₦200-350',
              badge: 'Cheapest',
            ),
          ),
          AlongStagger(
            index: 3,
            child: _RideLine(
              kind: AlongVehicleKind.bus,
              title: 'Bus',
              eta: '12 min',
              seats: '14 left',
              fare: '₦500-800',
            ),
          ),
        ],
      ),
    );
  }
}

class AlongFlowSearch extends StatelessWidget {
  const AlongFlowSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(mode: AlongCityMapMode.search),
          ),
          const Positioned(
            top: 16,
            left: 16,
            child: AlongMapButton(icon: AlongIcons.back, tooltip: 'Back'),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fraction = constraints.maxHeight >= 760 ? 0.56 : 0.64;
                return AlongSpringSheet(
                  fraction: fraction,
                  snaps: [fraction, 0.72],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3 offers',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.heading(palette),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Wuse · keke',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.meta(palette),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: const [
                            _BidRow(
                              name: 'Ife',
                              rating: '4.7',
                              vehicle: 'Keke',
                              eta: '8 min',
                              fare: '₦380',
                              initials: 'IF',
                              best: true,
                            ),
                            _BidRow(
                              name: 'Chinedu',
                              rating: '4.9',
                              vehicle: 'Keke',
                              eta: '4 min',
                              fare: '₦400',
                            ),
                            _BidRow(
                              name: 'Adaeze',
                              rating: '4.8',
                              vehicle: 'Keke',
                              eta: '6 min',
                              fare: '₦450',
                              rider: true,
                            ),
                          ],
                        ),
                      ),
                      const AlongButton(
                        label: 'Cancel',
                        variant: AlongButtonVariant.secondary,
                        onPressed: _noop,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AlongFlowRating extends StatelessWidget {
  const AlongFlowRating({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final short = constraints.maxHeight < 700;
            final portrait = short ? 72.0 : 88.0;
            final star = short ? 40.0 : 48.0;
            return Column(
              children: [
                const Expanded(
                  child: AlongCityMap(mode: AlongCityMapMode.completed),
                ),
                Transform.translate(
                  offset: Offset(0, -portrait / 2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      children: [
                        AlongDriverPortrait(size: portrait, verified: true),
                        SizedBox(height: short ? 8 : 10),
                        Text(
                          'Chinedu',
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: AlongType.heading(palette),
                        ),
                        Text(
                          'Wuse to Nyanya',
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: AlongType.meta(palette),
                        ),
                        SizedBox(height: short ? 8 : 12),
                        _Stars(filled: 4, size: star),
                        SizedBox(height: short ? 10 : 14),
                        const _ComplimentWrap(),
                        SizedBox(height: short ? 10 : 14),
                        const _TipSegments(),
                        SizedBox(height: short ? 10 : 12),
                        const _SendThanks(),
                        const SizedBox(height: 4),
                        const _ViewReceipt(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Two rows, always. The long labels share the second row so a narrow
/// phone does not drop "On time" onto a third line.
class _ComplimentWrap extends StatelessWidget {
  const _ComplimentWrap();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: _ComplimentChip('Smooth ride', selected: true)),
            SizedBox(width: 8),
            Expanded(child: _ComplimentChip('Clean car')),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ComplimentChip('On time')),
            SizedBox(width: 8),
            Expanded(child: _ComplimentChip('Safe driving')),
          ],
        ),
      ],
    );
  }
}

class _ComplimentChip extends StatelessWidget {
  const _ComplimentChip(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? palette.ink : palette.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected ? palette.ink : palette.line.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: AlongType.meta(palette).copyWith(
          color: selected ? palette.onInk : palette.ink,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _TipSegments extends StatelessWidget {
  const _TipSegments();

  static const _tips = ['₦100', '₦200', '₦500', 'Custom'];

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.recessed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final tip in _tips)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tip == '₦200'
                      ? palette.accent
                      : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    tip,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.caption(palette).copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SendThanks extends StatefulWidget {
  const _SendThanks();

  @override
  State<_SendThanks> createState() => _SendThanksState();
}

class _SendThanksState extends State<_SendThanks> {
  var _burst = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AlongButton(
          label: 'Send thanks',
          onPressed: () {
            AlongHaptics.success(context);
            if (!AlongMotionPolicy.play(context)) return;
            setState(() => _burst = true);
          },
        ),
        Positioned.fill(
          child: AlongConfetti(
            play: _burst,
            onDone: () {
              if (mounted) setState(() => _burst = false);
            },
          ),
        ),
      ],
    );
  }
}

class _ViewReceipt extends StatelessWidget {
  const _ViewReceipt();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return GestureDetector(
      onTap: _noop,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'View receipt',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: AlongType.title(palette).copyWith(
            fontSize: 16,
            height: 1.2,
            decoration: TextDecoration.underline,
            decorationColor: palette.ink,
          ),
        ),
      ),
    );
  }
}

class _MapHero extends StatelessWidget {
  const _MapHero({
    required this.height,
    required this.label,
    this.live = false,
  });

  final double height;
  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final map = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AlongCityMap(
              mode: AlongCityMapMode.routeHero,
              liveMarker: live,
            ),
          ),
          Positioned(left: 10, bottom: 10, child: _MapChip(label: label)),
        ],
      ),
    );
    if (!height.isFinite) return map;
    return SizedBox(height: height, width: double.infinity, child: map);
  }
}

class _Poster extends StatelessWidget {
  const _Poster();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    const ink = Color(0xFFFFFFFF);
    return Scaffold(
      backgroundColor: const Color(0xFF8ECAE6),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/photos/onboarding-fleet.jpg',
            package: 'along_design',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66101828),
                  Color(0x00000000),
                  Color(0x00000000),
                ],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AlongWordmark(color: Color(0xFFFFFFFF)),
                const SizedBox(height: 12),
                Text(
                  'Move around.',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.display(palette).copyWith(color: ink),
                ),
                Text(
                  'Your way.',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.display(palette).copyWith(color: ink),
                ),
                const SizedBox(height: 16),
                const AlongButton(label: 'Continue', onPressed: _noop),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldRing extends StatefulWidget {
  const _HoldRing({this.size = 220});

  final double size;

  @override
  State<_HoldRing> createState() => _HoldRingState();
}

class _HoldRingState extends State<_HoldRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      value: 0.66,
    );
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) => _fill.forward(from: 0);

  void _up(PointerEvent _) {
    if (_fill.value < 1) _fill.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedBuilder(
        animation: _fill,
        builder: (context, _) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _HoldRingPainter(
                progress: _fill.value,
                color: palette.ink,
                progressColor: palette.accent,
                track: palette.onInk,
              ),
              child: Center(
                child: SizedBox(
                  width: widget.size * 0.70,
                  child: Text(
                    'Hold to alert',
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: AlongType.body(palette).copyWith(
                      color: palette.onInk,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HoldRingPainter extends CustomPainter {
  _HoldRingPainter({
    required this.progress,
    required this.color,
    required this.progressColor,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color progressColor;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius - 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = track.withValues(alpha: 0.22),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = progressColor,
    );
  }

  @override
  bool shouldRepaint(covariant _HoldRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.name,
    required this.detail,
    required this.trailing,
    this.verified = true,
  });

  final String name;
  final String detail;
  final String trailing;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: Row(
        children: [
          _Face(name: name, verified: verified),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AlongType.title(palette)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                Text(detail, style: AlongType.caption(palette)),
              ],
            ),
          ),
          Text(
            trailing,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 16, height: 1.1),
          ),
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.name, required this.verified});

  final String name;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    if (name == 'Adaeze') {
      return const AlongDriverPortrait(
        size: 48,
        asset: AlongDriverPortrait.adaeze,
        verified: true,
      );
    }
    if (name == 'Chinedu') {
      return AlongDriverPortrait(size: 48, verified: verified);
    }
    final palette = AlongPalette.of(context);
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.recessed,
        shape: BoxShape.circle,
      ),
      child: Text(
        name.substring(0, 1),
        style: AlongType.title(palette).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Fold extends StatefulWidget {
  const _Fold({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  State<_Fold> createState() => _FoldState();
}

class _FoldState extends State<_Fold> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.title(palette)
                        .copyWith(fontSize: 16, height: 1.1),
                  ),
                ),
                AlongIcon(
                  _open ? AlongIcons.caretUp : AlongIcons.caretDown,
                  size: 20,
                  color: palette.muted,
                ),
              ],
            ),
          ),
        ),
        if (_open) widget.child,
      ],
    );
  }
}

class _GoButton extends StatefulWidget {
  const _GoButton();

  @override
  State<_GoButton> createState() => _GoButtonState();
}

class _GoButtonState extends State<_GoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      value: 0.45,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AlongMotionPolicy.play(context)) return;
      _glow.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        final breathe = AlongMotionPolicy.play(context) ? _glow.value : 0.45;
        return Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.ink,
            shape: BoxShape.circle,
            border: Border.all(color: palette.accent, width: 3),
            boxShadow: [
              ...AlongElevation.raised(palette.ink),
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.28 + 0.28 * breathe),
                blurRadius: 18 + 10 * breathe,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            'GO',
            maxLines: 1,
            softWrap: false,
            style: AlongType.display(
              palette,
            ).copyWith(fontSize: 28, letterSpacing: -0.8, color: palette.onInk),
          ),
        );
      },
    );
  }
}

class _SafetyLine extends StatelessWidget {
  const _SafetyLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Icon(icon, size: 22, color: palette.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AlongType.title(palette),
            ),
          ),
          AlongIcon(AlongIcons.caretRight, size: 20, color: palette.muted),
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.child, required this.bottom});

  final Widget child;
  final Widget bottom;

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
              Expanded(child: child),
              const SizedBox(height: 12),
              bottom,
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.child, this.fill});

  final Widget child;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: fill ?? palette.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.recessed,
              shape: BoxShape.circle,
            ),
            child: AlongIcon(icon, size: 20, color: palette.ink),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AlongType.body(palette))),
          Text(
            detail,
            style: AlongType.caption(palette)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Icon(icon, size: 20, color: palette.ink),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AlongType.body(palette))),
        ],
      ),
    );
  }
}

class _RideBadge extends StatelessWidget {
  const _RideBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: AlongType.caption(palette).copyWith(
          fontSize: 10,
          height: 1.05,
          fontWeight: FontWeight.w700,
          color: palette.accentInk,
        ),
      ),
    );
  }
}

class _RecommendedRide extends StatelessWidget {
  const _RecommendedRide();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AlongElevation.float(palette.ink),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(4, 4, 8, 4),
        child: _RideRow(
          kind: AlongVehicleKind.keke,
          title: 'Keke',
          eta: '4 min',
          seats: '2 left',
          fare: '₦400-600',
          rules: ['Window open', 'Women in back'],
          badge: 'For you',
          selected: true,
        ),
      ),
    );
  }
}

class _RideLine extends StatelessWidget {
  const _RideLine({
    required this.kind,
    required this.title,
    required this.eta,
    required this.seats,
    required this.fare,
    this.badge,
  });

  final AlongVehicleKind kind;
  final String title;
  final String eta;
  final String seats;
  final String fare;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          AlongVehicleHero(kind: kind, width: 72, height: 40),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.title(palette).copyWith(
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  badge == null ? '$eta · $seats' : '$badge · $eta',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.meta(palette),
                ),
              ],
            ),
          ),
          Hero(
            tag: 'along-fare-${kind.name}',
            child: Text(
              fare,
              maxLines: 1,
              softWrap: false,
              style: AlongType.numeric(palette)
                  .copyWith(fontSize: 15, height: 1.05, letterSpacing: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideRow extends StatelessWidget {
  const _RideRow({
    required this.kind,
    required this.title,
    required this.eta,
    required this.seats,
    required this.fare,
    this.rules = const [],
    this.badge,
    this.selected = false,
  });

  final AlongVehicleKind kind;
  final String title;
  final String eta;
  final String seats;
  final String fare;
  final List<String> rules;
  final String? badge;
  final bool selected;

  static const height = 108.0;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? palette.ink.withValues(alpha: 0.04) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? palette.ink.withValues(alpha: 0.22)
                : const Color(0x00000000),
          ),
        ),
        child: Row(
          children: [
            AlongVehicleHero(kind: kind, width: 140, height: 78),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return _fittedTitle(
                        maxWidth: constraints.maxWidth,
                        nameStyle: AlongType.title(palette).copyWith(
                          fontSize: 20,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                        fareStyle: AlongType.numeric(palette).copyWith(
                          fontSize: 18,
                          height: 1.05,
                          letterSpacing: -0.4,
                        ),
                        badgeStyle: AlongType.caption(palette).copyWith(
                          fontSize: 10,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          color: palette.accentInk,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$seats · $eta',
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.meta(palette).copyWith(
                            fontSize: 15,
                            height: 1.15,
                            fontWeight: FontWeight.w500,
                            color: palette.brightness == Brightness.dark
                                ? const Color(0xFFC8C8D0)
                                : const Color(0xFF3A3A42),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (rules.isNotEmpty)
                        Icon(AlongIcons.info, size: 16, color: palette.muted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Keeps the fare on the right at 18sp. Scales the whole line only when a
  /// 320 row cannot hold the name, badge, and fare without clipping.
  Widget _fittedTitle({
    required double maxWidth,
    required TextStyle nameStyle,
    required TextStyle fareStyle,
    required TextStyle badgeStyle,
  }) {
    final nameW = _lineWidth(title, nameStyle);
    final fareW = _lineWidth(fare, fareStyle);
    final badgeW = badge == null ? 0.0 : _lineWidth(badge!, badgeStyle) + 16;
    const gap = 8.0;
    final needed = nameW + badgeW + gap + fareW;
    final width = math.max(maxWidth, needed + 1);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            Text(title, maxLines: 1, softWrap: false, style: nameStyle),
            if (badge != null) ...[
              const SizedBox(width: 6),
              _RideBadge(badge!),
            ],
            const Spacer(),
            Text(fare, maxLines: 1, softWrap: false, style: fareStyle),
          ],
        ),
      ),
    );
  }

  double _lineWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

/// Rules live here, not as chips on the product row.
class _RideRules extends StatelessWidget {
  const _RideRules({
    required this.title,
    required this.rules,
    required this.fare,
  });

  final String title;
  final List<String> rules;
  final String fare;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AlongType.heading(palette)),
        const SizedBox(height: 4),
        Text(fare, style: AlongType.title(palette)),
        const SizedBox(height: 12),
        for (final rule in rules)
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Icon(AlongIcons.info, size: 16, color: palette.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rule,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.meta(palette).copyWith(color: palette.ink),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: AlongElevation.float(palette.ink)),
      child: AlongFrost(
        radius: 99,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: AlongType.caption(palette).copyWith(
            fontWeight: FontWeight.w700,
            color: palette.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _OfferRoute extends StatelessWidget {
  const _OfferRoute();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final place = AlongType.body(palette)
        .copyWith(fontWeight: FontWeight.w700, height: 1.1);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Wuse Market', maxLines: 1, softWrap: false, style: place),
                Text(
                  'Pickup',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            height: 16,
            child: CustomPaint(painter: _OfferLine(color: palette.ink)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Nyanya', maxLines: 1, softWrap: false, style: place),
                Text(
                  'Drop',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferLine extends CustomPainter {
  const _OfferLine({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), paint);
    canvas.drawCircle(Offset(4, y), 3, Paint()..color = color);
    canvas.drawCircle(
      Offset(size.width - 4, y),
      3,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawCircle(
      Offset(size.width - 4, y),
      3,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _OfferLine oldDelegate) =>
      oldDelegate.color != color;
}

class _OfferSeats extends StatelessWidget {
  const _OfferSeats();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          for (var i = 0; i < 6; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == 1
                      ? palette.accent
                      : i == 0
                      ? palette.ink.withValues(alpha: 0.16)
                      : palette.recessed,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RiderRow extends StatelessWidget {
  const _RiderRow();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const AlongDriverPortrait(
            size: 36,
            asset: AlongDriverPortrait.adaeze,
            verified: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adaeze · 4.9',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.body(palette)
                      .copyWith(fontWeight: FontWeight.w600, height: 1.1),
                ),
                Text(
                  'Rider',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette),
                ),
              ],
            ),
          ),
          const _Stars(filled: 5, size: 14),
        ],
      ),
    );
  }
}

class _EarnBreakdown extends StatelessWidget {
  const _EarnBreakdown();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _EarnCell(label: 'Trips', value: '11'),
        SizedBox(width: 8),
        _EarnCell(label: 'Tips', value: '₦600'),
        SizedBox(width: 8),
        _EarnCell(label: 'Hours', value: '6.5'),
      ],
    );
  }
}

class _EarnCell extends StatelessWidget {
  const _EarnCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: AlongElevation.hairline(palette.ink),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w700, height: 1.1),
            ),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassUpsell extends StatelessWidget {
  const _PassUpsell();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: AlongElevation.hairline(palette.ink),
      ),
      child: Row(
        children: [
          AlongIcon(AlongIcons.receipt, size: 20, color: palette.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Along Pass',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.body(palette)
                      .copyWith(fontWeight: FontWeight.w700, height: 1.1),
                ),
                Text(
                  'Keep ₦200 more on each trip',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarnList extends StatelessWidget {
  const _EarnList();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: AlongElevation.hairline(palette.ink),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: const [
          _EarningTrip(place: 'Nyanya', fare: '₦1,800', tip: '₦200'),
          _EarningTrip(place: 'Wuse', fare: '₦1,200'),
          _EarningTrip(place: 'Garki', fare: '₦900', tip: '₦100'),
          _EarningTrip(place: 'Berger', fare: '₦1,400'),
          _EarningTrip(place: 'Jabi', fare: '₦1,600', tip: '₦300'),
          _EarningTrip(place: 'Airport', fare: '₦3,200'),
        ],
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    const bars = <(String, double, bool)>[
      ('M', 22, false),
      ('Tu', 31, false),
      ('W', 18, false),
      ('Th', 48, true),
      ('F', 36, false),
      ('Sa', 14, false),
      ('Su', 9, false),
    ];
    final axis = AlongType.caption(palette).copyWith(
      fontSize: 10,
      height: 1,
      fontWeight: FontWeight.w600,
      color: palette.muted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 32,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₦9k', maxLines: 1, softWrap: false, style: axis),
                      const Spacer(),
                      Text('₦5k', maxLines: 1, softWrap: false, style: axis),
                      const Spacer(),
                      Text('₦0', maxLines: 1, softWrap: false, style: axis),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              for (final bar in bars)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Text(
                          bar.$3 ? '48k' : '',
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.caption(palette).copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 8,
                                child: Container(
                                  height: 1,
                                  color: palette.ink.withValues(alpha: 0.28),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: bar.$2 / 60,
                                  child: Container(
                                    width: 8,
                                    decoration: BoxDecoration(
                                      color: bar.$3
                                          ? palette.ink
                                          : palette.ink.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bar.$1,
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.caption(palette).copyWith(
                            fontWeight: bar.$3
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: bar.$3 ? palette.ink : palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EarningTrip extends StatelessWidget {
  const _EarningTrip({required this.place, required this.fare, this.tip});

  final String place;
  final String fare;
  final String? tip;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.recessed,
              shape: BoxShape.circle,
            ),
            child: Icon(AlongIcons.navigate, size: 15, color: palette.ink),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              place,
              maxLines: 1,
              softWrap: false,
              style: AlongType.title(palette).copyWith(
                fontSize: 15,
                height: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (tip != null) ...[
            const SizedBox(width: 6),
            Text(
              tip!,
              maxLines: 1,
              softWrap: false,
              style: AlongType.meta(palette).copyWith(
                fontSize: 12,
                height: 1.1,
                color: palette.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(width: 8),
          Text(
            fare,
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 16, height: 1.05, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _DemandHint extends StatelessWidget {
  const _DemandHint();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return AlongFrost(
      radius: 99,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        'High demand near Wuse',
        maxLines: 1,
        softWrap: false,
        style: AlongType.caption(palette)
            .copyWith(color: palette.ink, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HeatTip extends StatefulWidget {
  const _HeatTip();

  @override
  State<_HeatTip> createState() => _HeatTipState();
}

class _HeatTipState extends State<_HeatTip> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AlongMapButton(
          icon: AlongIcons.info,
          tooltip: 'Heat',
          onPressed: () => setState(() => _open = !_open),
        ),
        if (_open) ...[const SizedBox(height: 8), const _HeatLegend()],
      ],
    );
  }
}

class _TodayPill extends StatefulWidget {
  const _TodayPill();

  @override
  State<_TodayPill> createState() => _TodayPillState();
}

class _TodayPillState extends State<_TodayPill> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: AlongElevation.float(palette.ink),
            ),
            child: AlongFrost(
              radius: 99,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                'Today · ₦18,400',
                maxLines: 1,
                softWrap: false,
                style: AlongType.title(palette)
                    .copyWith(fontSize: 15, height: 1.1),
              ),
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          Text(
            'Wuse park · 3 seats open',
            maxLines: 1,
            softWrap: false,
            style: AlongType.meta(palette),
          ),
          const SizedBox(height: 8),
          const _GoalRow(),
          const SizedBox(height: 8),
          const AlongButton(
            label: 'Go offline',
            variant: AlongButtonVariant.secondary,
            onPressed: _noop,
          ),
        ],
      ],
    );
  }
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final label = AlongType.meta(palette).copyWith(
      fontSize: 12,
      height: 1.1,
      color: palette.ink,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(99),
        boxShadow: AlongElevation.float(palette.ink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Quiet', maxLines: 1, softWrap: false, style: label),
          const SizedBox(width: 8),
          Container(
            width: 108,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2F6F8F),
                  Color(0xFFE39B2B),
                  Color(0xFFB93815),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('Busy', maxLines: 1, softWrap: false, style: label),
        ],
      ),
    );
  }
}

/// Puts the whole fictional plate inside the brackets. Cover-fit on a
/// portrait phone was cropping ABC-123-XY down to C-123-X.
class _PlateFrame extends StatelessWidget {
  const _PlateFrame();

  /// Source pixels of plate-abuja.jpg (1040×760) that contain the full plate.
  static const _photoW = 1040.0;
  static const _photoH = 760.0;
  static const _plate = Rect.fromLTRB(250, 400, 760, 540);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final frame = Rect.fromLTWH(
          16,
          size.height * 0.40,
          size.width - 32,
          size.height * 0.20,
        );
        final scale = math.min(
          frame.width / _plate.width,
          frame.height / _plate.height,
        );
        final imageLeft =
            frame.center.dx - (_plate.left + _plate.width / 2) * scale;
        final imageTop =
            frame.center.dy - (_plate.top + _plate.height / 2) * scale;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: imageLeft,
              top: imageTop,
              width: _photoW * scale,
              height: _photoH * scale,
              child: Image.asset(
                'assets/photos/plate-abuja.jpg',
                package: 'along_design',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
            Positioned.fromRect(
              rect: frame.inflate(22),
              child: const _ViewfinderCorners(),
            ),
          ],
        );
      },
    );
  }
}

class _ViewfinderCorners extends StatelessWidget {
  const _ViewfinderCorners();

  @override
  Widget build(BuildContext context) {
    const mark = Color(0xFFF7D117);
    Widget corner(Alignment align) {
      final top = align.y < 0;
      final left = align.x < 0;
      return Align(
        alignment: align,
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              top: top
                  ? const BorderSide(color: mark, width: 3)
                  : BorderSide.none,
              bottom: top
                  ? BorderSide.none
                  : const BorderSide(color: mark, width: 3),
              left: left
                  ? const BorderSide(color: mark, width: 3)
                  : BorderSide.none,
              right: left
                  ? BorderSide.none
                  : const BorderSide(color: mark, width: 3),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        corner(Alignment.topLeft),
        corner(Alignment.topRight),
        corner(Alignment.bottomLeft),
        corner(Alignment.bottomRight),
      ],
    );
  }
}

class _HoldAlert extends StatefulWidget {
  const _HoldAlert();

  @override
  State<_HoldAlert> createState() => _HoldAlertState();
}

class _HoldAlertState extends State<_HoldAlert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      value: 0.66,
    );
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) {
    _fill.forward(from: 0);
  }

  void _up(PointerEvent _) {
    if (_fill.value < 1) _fill.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedBuilder(
        animation: _fill,
        builder: (context, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: palette.danger.withValues(alpha: 0.16)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _fill.value.clamp(0.0, 1.0),
                    child: ColoredBox(color: palette.danger),
                  ),
                  Center(
                    child: Text(
                      'Hold to alert',
                      maxLines: 1,
                      softWrap: false,
                      style: AlongType.button(palette)
                          .copyWith(color: palette.dangerOn),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlateMatch extends StatelessWidget {
  const _PlateMatch();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Text(
      'Plate matches',
      maxLines: 1,
      softWrap: false,
      style: AlongType.title(palette).copyWith(color: palette.success),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  const _GuardianCard();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: AlongElevation.hairline(palette.ink),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            _ContactLine(
              name: 'Adaeze',
              detail: 'Sister · shares this trip',
              asset: AlongDriverPortrait.adaeze,
            ),
            _ContactLine(name: 'Chidi', detail: 'Brother', initials: 'CH'),
            _ContactLine(name: 'Ngozi', detail: 'Aunt', initials: 'NG'),
            _ShareToggle(label: 'Share live location', on: true),
            _ShareToggle(label: 'Share the plate', on: false),
            Spacer(),
            _GuardianFoot(),
          ],
        ),
      ),
    );
  }
}

class _GuardianFoot extends StatelessWidget {
  const _GuardianFoot();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          AlongIcon(AlongIcons.shield, size: 20, color: palette.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '3 people can see this trip',
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette).copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareToggle extends StatelessWidget {
  const _ShareToggle({required this.label, required this.on});

  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600, height: 1.1),
            ),
          ),
          Switch(
            value: on,
            onChanged: (_) {},
            activeThumbColor: palette.accentInk,
            activeTrackColor: palette.accent,
            inactiveThumbColor: palette.surface,
            inactiveTrackColor: palette.recessed,
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.name,
    required this.detail,
    this.asset,
    this.initials,
  });

  final String name;
  final String detail;
  final String? asset;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          if (asset != null)
            AlongDriverPortrait(size: 44, asset: asset!, verified: true)
          else
            _Monogram(initials: initials ?? '', size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.title(palette)
                      .copyWith(fontSize: 16, height: 1.1),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.meta(palette),
                ),
              ],
            ),
          ),
          AlongIcon(AlongIcons.caretRight, size: 20, color: palette.muted),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 168,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A342C), Color(0xFF161513)],
        ),
        boxShadow: AlongElevation.raised(const Color(0xFF111111)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _CardNoise())),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: _BalanceFace(),
          ),
        ],
      ),
    );
  }
}

class _BalanceFace extends StatelessWidget {
  const _BalanceFace();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    const paper = Color(0xFFF7F4EF);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFC8BBA4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x66FFFFFF)),
              ),
            ),
            const Spacer(),
            Text(
              'Along',
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette)
                  .copyWith(color: paper, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const Spacer(),
        Text(
          'Balance',
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette).copyWith(color: paper),
        ),
        Text(
          '₦6,400',
          maxLines: 1,
          softWrap: false,
          style: AlongType.display(palette).copyWith(color: paper),
        ),
      ],
    );
  }
}

class _CardNoise extends CustomPainter {
  const _CardNoise();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x18FFFFFF);
    final rnd = math.Random(4);
    for (var i = 0; i < 220; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 0.7 + 0.25,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardNoise oldDelegate) => false;
}

class _WalletTiles extends StatelessWidget {
  const _WalletTiles();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _IconTile(icon: AlongIcons.plus, label: 'Top up'),
        SizedBox(width: 8),
        _IconTile(icon: AlongIcons.share, label: 'Send'),
        SizedBox(width: 8),
        _IconTile(icon: AlongIcons.receipt, label: 'Pass'),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Expanded(
      child: Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AlongElevation.card(palette.ink),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: palette.ink),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette)
                  .copyWith(fontWeight: FontWeight.w700, color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: AlongElevation.hairline(palette.ink),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        children: const [
          _TxnGroup(label: 'Today'),
          _TxnRow(
            icon: AlongIcons.navigate,
            title: 'Nyanya',
            detail: 'Seat hold',
            value: '−₦1,200',
          ),
          _TxnRow(
            icon: AlongIcons.plus,
            title: 'Top up',
            detail: 'Transfer',
            value: '+₦5,000',
          ),
          _TxnGroup(label: 'Earlier'),
          _TxnRow(
            icon: AlongIcons.navigate,
            title: 'Berger',
            detail: 'Yesterday',
            value: '−₦900',
          ),
          _TxnRow(
            icon: AlongIcons.navigate,
            title: 'Jabi',
            detail: 'Monday',
            value: '−₦1,600',
          ),
          _TxnRow(
            icon: AlongIcons.wallet,
            title: 'Cash out',
            detail: 'Sunday · GTBank',
            value: '−₦8,000',
          ),
          _TxnRow(
            icon: AlongIcons.receipt,
            title: 'Along Pass',
            detail: 'This month',
            value: '−₦2,000',
          ),
        ],
      ),
    );
  }
}

class _TxnGroup extends StatelessWidget {
  const _TxnGroup({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: AlongType.caption(palette)
            .copyWith(fontWeight: FontWeight.w700, color: palette.ink),
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
              border: AlongElevation.hairline(palette.ink),
            ),
            child: AlongIcon(icon, size: 20, color: palette.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.body(palette)
                      .copyWith(fontWeight: FontWeight.w600, height: 1.1),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.meta(palette),
                ),
              ],
            ),
          ),
          Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 16, height: 1.1, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _DayStat(value: '7', label: 'Trips'),
        SizedBox(width: 8),
        _DayStat(value: '₦9,300', label: 'Earned'),
        SizedBox(width: 8),
        _DayStat(value: '6.5', label: 'Hours'),
      ],
    );
  }
}

class _DayStat extends StatelessWidget {
  const _DayStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: AlongElevation.hairline(palette.ink),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: AlongType.title(palette)
                  .copyWith(fontSize: 16, height: 1.1),
            ),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBoard extends StatelessWidget {
  const _DayBoard();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: AlongElevation.hairline(palette.ink),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          children: [
            Expanded(child: _DayTimeline()),
            SizedBox(height: 4),
            _DayFooter(),
          ],
        ),
      ),
    );
  }
}

class _DayFooter extends StatelessWidget {
  const _DayFooter();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          AlongIcon(AlongIcons.path, size: 20, color: palette.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nyanya corridor · 6.5 hours',
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette).copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTimeline extends StatelessWidget {
  const _DayTimeline();

  @override
  Widget build(BuildContext context) {
    const stops = <(String, AlongVehicleKind, String, String)>[
      ('07:10', AlongVehicleKind.keke, 'Nyanya', '₦1,400'),
      ('08:40', AlongVehicleKind.car, 'Garki', '₦900'),
      ('10:15', AlongVehicleKind.danfo, 'Wuse', '₦1,200'),
      ('12:05', AlongVehicleKind.keke, 'Nyanya', '₦1,600'),
      ('14:20', AlongVehicleKind.car, 'Jabi', '₦700'),
      ('16:45', AlongVehicleKind.bus, 'Berger', '₦1,100'),
      ('18:30', AlongVehicleKind.car, 'Airport', '₦2,400'),
    ];
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (var i = 0; i < stops.length; i++)
          _DayStop(
            time: stops[i].$1,
            kind: stops[i].$2,
            title: stops[i].$3,
            fare: stops[i].$4,
            last: i == stops.length - 1,
          ),
      ],
    );
  }
}

class _DayStop extends StatelessWidget {
  const _DayStop({
    required this.time,
    required this.kind,
    required this.title,
    required this.fare,
    required this.last,
  });

  final String time;
  final AlongVehicleKind kind;
  final String title;
  final String fare;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: last ? palette.muted : palette.ink,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: palette.ink.withValues(alpha: 0.12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(
              time,
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette).copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          AlongVehicleMark(kind: kind, width: 44, height: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600, height: 1.1),
            ),
          ),
          Text(
            fare,
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 16, height: 1.1, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _BidRow extends StatelessWidget {
  const _BidRow({
    required this.name,
    required this.rating,
    required this.vehicle,
    required this.eta,
    required this.fare,
    this.rider = false,
    this.initials,
    this.best = false,
  });

  final String name;
  final String rating;
  final String vehicle;
  final String eta;
  final String fare;
  final bool rider;
  final String? initials;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: best ? palette.ink : palette.ink.withValues(alpha: 0.12),
            width: best ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              if (initials != null)
                AlongMonogram(initials: initials!, size: 40)
              else
                AlongDriverPortrait(
                  size: 40,
                  asset: rider
                      ? AlongDriverPortrait.adaeze
                      : AlongDriverPortrait.chinedu,
                  verified: true,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      softWrap: false,
                      style: AlongType.body(palette)
                          .copyWith(fontWeight: FontWeight.w700, height: 1.1),
                    ),
                    Text(
                      '$rating · $eta',
                      maxLines: 1,
                      softWrap: false,
                      style: AlongType.caption(palette).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const AlongVehicleMark(
                kind: AlongVehicleKind.keke,
                width: 44,
                height: 28,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fare,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.body(palette)
                        .copyWith(fontWeight: FontWeight.w700, height: 1.1),
                  ),
                  const SizedBox(height: 4),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Text(
                        'Accept',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.caption(palette).copyWith(
                          color: palette.accentInk,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AlongMonogram(initials: initials, size: size);
  }
}

class _MapDriver extends StatelessWidget {
  const _MapDriver({required this.name, required this.eta, this.rider = false});

  final String name;
  final String eta;
  final bool rider;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      children: [
        AlongDriverPortrait(
          size: 36,
          asset: rider
              ? AlongDriverPortrait.adaeze
              : AlongDriverPortrait.chinedu,
          verified: true,
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: AlongElevation.float(palette.ink),
          ),
          child: Text(
            '$name · $eta',
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      children: [
        const _GoalRing(progress: 0.75),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('6 of 8 trips', style: AlongType.title(palette)),
              Text('Daily goal', style: AlongType.caption(palette)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: palette.accent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '4-day streak',
            style: AlongType.caption(
              palette,
            ).copyWith(color: palette.accentInk, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          track: palette.line.withValues(alpha: 0.35),
          ink: palette.accent,
        ),
        child: Center(
          child: Text(
            '6',
            style: AlongType.numeric(palette).copyWith(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.ink,
  });

  final double progress;
  final Color track;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(4),
      0,
      math.pi * 2,
      false,
      stroke..color = track,
    );
    canvas.drawArc(
      rect.deflate(4),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      stroke..color = ink,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Stars extends StatelessWidget {
  const _Stars({required this.filled, required this.size});

  final int filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              AlongIcons.star,
              size: i < filled ? size : size * 0.86,
              color: i < filled ? palette.accent : palette.line,
            ),
          ),
      ],
    );
  }
}

class _SearchRadar extends StatefulWidget {
  const _SearchRadar();

  @override
  State<_SearchRadar> createState() => _SearchRadarState();
}

class _SearchRadarState extends State<_SearchRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (AlongMotionPolicy.inWidgetTest) {
      _controller.value = 0.38;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Lottie.asset(
            'assets/motion/radar.json',
            package: 'along_design',
            width: 200,
            height: 200,
            animate: !AlongMotionPolicy.inWidgetTest,
            repeat: true,
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: const Size.square(200),
                painter: _SweepPainter(
                  turn: _controller.value,
                  color: palette.accent,
                  ink: palette.ink,
                ),
              );
            },
          ),
          const AlongVehicleMark(kind: AlongVehicleKind.keke, width: 96),
          const Positioned(
            left: 4,
            top: 18,
            child: _MapDriver(name: 'Chinedu', eta: '4 min'),
          ),
          const Positioned(
            right: 4,
            bottom: 16,
            child: _MapDriver(name: 'Adaeze', eta: '6 min', rider: true),
          ),
        ],
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter({required this.turn, required this.color, required this.ink});

  final double turn;
  final Color color;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = ink.withValues(alpha: 0.35);
    for (final radius in [46.0, 72.0, 96.0]) {
      canvas.drawCircle(center, radius, paint);
    }
    final sweep = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: 96),
        turn * math.pi * 2 - 0.6,
        0.6,
        false,
      )
      ..close();
    canvas.drawPath(sweep, Paint()..color = color.withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) =>
      oldDelegate.turn != turn;
}

void _noop() {}
