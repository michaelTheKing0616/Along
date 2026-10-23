import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../components/along_button.dart';
import '../craft.dart';
import '../components/seat_map.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../theme.dart';
import '../type.dart';
import 'batch_stages.dart';
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
              final fraction = constraints.maxHeight >= 760 ? 0.54 : 0.67;
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
                      child: Builder(
                        builder: (context) {
                          const body = _HomeSheetBody();
                          if (MediaQuery.textScalerOf(context).scale(1) <=
                              1.05) {
                            return body;
                          }
                          return const SingleChildScrollView(child: body);
                        },
                      ),
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
          decoration: ShapeDecoration(
            color: palette.ink,
            shape: AlongCraft.border(16),
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
        const SizedBox(height: 16),
        const _PlaceRow(
          icon: AlongIcons.home,
          title: 'Home',
          detail: 'Garki · 12 min',
        ),
        const _PlaceRow(
          icon: AlongIcons.work,
          title: 'Work',
          detail: 'Wuse Market',
        ),
        const _PlaceRow(
          icon: AlongIcons.schedule,
          title: 'Wuse to Nyanya',
          detail: 'Regular',
          action: 'Rebook',
          actionKey: Key('rebook_regular'),
        ),
        const SizedBox(height: 16),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 320×640 is already full before the perks row. Tighten only then.
            final short = constraints.maxHeight < 720;
            final gap = short ? 4.0 : 8.0;
            final seatColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Choose a seat',
                        style: AlongType.display(palette),
                      ),
                    ),
                    SizedBox(height: gap),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _SeatDriver(),
                    ),
                    SizedBox(height: gap),
                    const SeatMap(
                      body: 'cabin',
                      rows: [
                        SeatMapRowView(
                          id: 'front',
                          seats: [
                            SeatMapSeat(
                              id: 'drv',
                              label: 'Driver',
                              role: 'driver',
                              status: 'occupied',
                              statusWord: 'Driver',
                            ),
                            SeatMapSeat(
                              id: 'fr',
                              label: 'FR',
                              role: 'passenger',
                              status: 'yours',
                              statusWord: 'Yours',
                              price: '₦1,200',
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
                SizedBox(height: gap),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: AlongWhosRiding(riders: AlongRider.riding),
                ),
                SizedBox(height: gap),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: AlongSeatContext(
                    origin: 'Wuse Market',
                    destination: 'Garki',
                    departs: 'Departs in 12 min',
                    seatsLeft: '4/6 seats left',
                    ruled: true,
                  ),
                ),
                SizedBox(height: gap),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'AC · Window · Luggage',
                    maxLines: 2,
                    softWrap: true,
                    style: AlongType.body(palette),
                  ),
                ),
              ],
            );
            final page = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    short ? 4 : 12,
                    0,
                    short ? 0 : 12,
                  ),
                  child: seatColumn,
                ),
                _SeatBar(dense: short),
              ],
            );
            return SingleChildScrollView(child: page);
          },
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Chinedu', maxLines: 1, softWrap: false, style: name),
                    const SizedBox(width: 8),
                    AlongIcon(AlongIcons.star, size: 20, color: palette.accent),
                    const SizedBox(width: 2),
                    Text('4.9', maxLines: 1, softWrap: false, style: rating),
                  ],
                ),
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
          decoration: AlongCraft.surface(palette, radius: 16),
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

class _SeatBar extends StatelessWidget {
  const _SeatBar({this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final pad = dense ? 8.0 : 12.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(color: palette.ink.withValues(alpha: 0.12)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, pad, 16, pad),
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
                        'Front right',
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
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Hero(
                      tag: 'along-fare-car',
                      child: AlongOdometer(
                        value: 1200,
                        style: AlongType.numeric(palette),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: pad),
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
    return Text(
      label,
      maxLines: 1,
      softWrap: false,
      style: AlongType.label(palette).copyWith(
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
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
              sheetInset: 0.32,
              fix: AlongFix.stale,
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
                final fraction = constraints.maxHeight >= 760 ? 0.30 : 0.40;
                return AlongSpringSheet(
                  fraction: fraction,
                  snaps: [fraction, 0.72],
                  child: Builder(
                    builder: (context) {
                      final roomy =
                          MediaQuery.textScalerOf(context).scale(1) > 1.05;
                      const sheet = _LiveSheet();
                      if (!roomy) return sheet;
                      return const SingleChildScrollView(child: sheet);
                    },
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
                            fontWeight: FontWeight.w600,
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
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.05;
            final eta = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlongRollingDigits(
                  text: '4-6',
                  suffix: ' min',
                  style: AlongType.display(palette),
                ),
              ],
            );
            final place = Text(
              'Nyanya',
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600, height: 1.2),
            );
            if (roomy) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [eta, const SizedBox(height: 4), place],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [eta, const Spacer(), place],
            );
          },
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            _LiveAction(icon: AlongIcons.call, label: 'Call'),
            _LiveAction(icon: AlongIcons.chat, label: 'Message'),
            _LiveAction(icon: AlongIcons.share, label: 'Share'),
            _LiveAction(icon: AlongIcons.shield, label: 'Safety'),
            _LiveAction(
              icon: AlongIcons.receipt,
              label: 'Report',
              semanticsLabel: 'Report an issue',
            ),
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
    return Text(
      label,
      maxLines: 1,
      softWrap: false,
      style: AlongType.label(palette).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _LiveAction extends StatelessWidget {
  const _LiveAction({
    required this.icon,
    required this.label,
    this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Expanded(
      child: Semantics(
        button: true,
        label: semanticsLabel ?? label,
        child: InkWell(
          onTap: _noop,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: AlongElevation.hairline(palette.ink),
                ),
                child: AlongIcon(icon, size: 20, color: palette.ink),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: MediaQuery.textScalerOf(context).scale(1) > 1.05
                    ? 2
                    : 1,
                softWrap: MediaQuery.textScalerOf(context).scale(1) > 1.05,
                textAlign: TextAlign.center,
                style: AlongType.caption(palette).copyWith(
                  color: palette.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
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
            'Call 112 · share with contacts',
            maxLines: 1,
            softWrap: false,
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 8),
          const Center(child: _HoldRing(size: 160)),
          const SizedBox(height: 12),
          const Expanded(
            child: _MapHero(height: double.infinity, label: 'Live', live: true),
          ),
          const SizedBox(height: 12),
          Text(
            'Contacts',
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette)
                .copyWith(color: palette.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const _SosAvatars(),
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
          const Expanded(
            child: _MapHero(
              height: double.infinity,
              label: '6 min',
              live: true,
            ),
          ),
          const SizedBox(height: 8),
          const _GuardianPeople(),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Check the plate',
                      maxLines: 1,
                      softWrap: false,
                      style: AlongType.display(palette)
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  Text(
                    'Fit the plate in the frame.',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.caption(palette).copyWith(
                      color: const Color(0xFFF7F4EF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: AlongCraft.surface(
                      palette,
                      radius: 20,
                      hairline: true,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
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
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Pay ₦1,200', onPressed: _noop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Balance', style: AlongType.caption(palette)),
          Text(
            '₦6,400',
            maxLines: 1,
            softWrap: false,
            style: AlongType.display(palette),
          ),
          const SizedBox(height: 16),
          const _WalletActions(),
          const SizedBox(height: 8),
          const Expanded(child: _ActivityCard()),
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
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thursday', style: AlongType.display(palette)),
        const SizedBox(height: 4),
        Text(
          'Nyanya corridor',
          maxLines: 1,
          softWrap: false,
          style: AlongType.bodyMuted(palette),
        ),
        const SizedBox(height: 12),
        Text(
          '7 trips · 25 seats · ₦9,300',
          maxLines: 1,
          softWrap: false,
          style: AlongType.body(palette).copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 16),
        const AlongDepartureBoard(),
        const SizedBox(height: 8),
        const _DayBoard(),
        const SizedBox(height: 12),
        const AlongButton(label: 'Save the day', onPressed: _noop),
      ],
    );
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: SingleChildScrollView(child: column),
        ),
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
          const Positioned(top: 16, left: 16, child: _HeatLegend()),
          const Positioned(top: 16, right: 16, child: _HeatTip()),
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
              decoration: AlongCraft.surface(
                palette,
                radius: 20,
                shadow: AlongElevation.sheet(palette.ink),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 6,
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
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                            const AlongSeatCount(count: 2, glyph: 14),
                            const SizedBox(width: 8),
                            Text(
                              '4.2 km',
                              maxLines: 1,
                              softWrap: false,
                              style: AlongType.caption(palette).copyWith(
                                color: palette.ink,
                                fontWeight: FontWeight.w600,
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
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today', style: AlongType.caption(palette)),
              AlongOdometer(value: 48200, style: AlongType.display(palette)),
              Text(
                '11 trips · goal ₦60,000',
                maxLines: 1,
                softWrap: false,
                style: AlongType.bodyMuted(palette),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 160, child: _WeekBars()),
              const SizedBox(height: 16),
              const _EarnList(),
              const SizedBox(height: 12),
              const AlongButton(label: 'Cash out', onPressed: _noop),
            ],
          ),
        ),
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
                final height = math
                    .min(constraints.maxHeight - 48, 500)
                    .toDouble();
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
        Text(
          'Choose a ride',
          maxLines: 1,
          softWrap: false,
          style: AlongType.title(palette).copyWith(height: 1.1),
        ),
        const SizedBox(height: 2),
        Text(
          'Wuse to Nyanya · 4.2 km',
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette).copyWith(
            color: palette.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        const Expanded(child: _RideList()),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: palette.ink.withValues(alpha: 0.12)),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: AlongButton(label: 'Confirm keke', onPressed: _noop),
          ),
        ),
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
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          _RecommendedRide(),
          SizedBox(height: 8),
          AlongStagger(
            index: 0,
            child: _RideLine(
              kind: AlongVehicleKind.okada,
              title: 'Okada',
              eta: '2-4 min',
              seatCount: 1,
              fare: '₦300-500',
              badge: 'Fastest',
            ),
          ),
          AlongStagger(
            index: 1,
            child: _RideLine(
              kind: AlongVehicleKind.car,
              title: 'Car',
              eta: '6-8 min',
              seatCount: 3,
              fare: '₦1,100-1,400',
            ),
          ),
          AlongStagger(
            index: 2,
            child: _RideLine(
              kind: AlongVehicleKind.danfo,
              title: 'Danfo',
              eta: '8-12 min',
              seatCount: 8,
              fare: '₦200-350',
              badge: 'Cheapest',
            ),
          ),
          AlongStagger(
            index: 3,
            child: _RideLine(
              kind: AlongVehicleKind.bus,
              title: 'Bus',
              eta: '12-16 min',
              seatCount: 14,
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
                final fraction = constraints.maxHeight >= 760 ? 0.44 : 0.56;
                return AlongSpringSheet(
                  fraction: fraction,
                  snaps: [fraction, 0.72],
                  child: const _SearchBody(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBid {
  const _SearchBid({
    required this.name,
    required this.rating,
    required this.eta,
    required this.fare,
    this.initials,
    this.rider = false,
  });

  final String name;
  final String rating;
  final String eta;
  final String fare;
  final String? initials;
  final bool rider;
}

class _SearchBody extends StatefulWidget {
  const _SearchBody();

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  static const _bids = <_SearchBid>[
    _SearchBid(
      name: 'Ife',
      rating: '4.7',
      eta: '8 min',
      fare: '₦380',
      initials: 'IF',
    ),
    _SearchBid(name: 'Chinedu', rating: '4.9', eta: '4 min', fare: '₦400'),
    _SearchBid(
      name: 'Adaeze',
      rating: '4.8',
      eta: '6 min',
      fare: '₦450',
      rider: true,
    ),
  ];

  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
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
            children: [
              for (var i = 0; i < _bids.length; i++)
                _BidRow(
                  bid: _bids[i],
                  selected: i == _selected,
                  onTap: () => setState(() => _selected = i),
                ),
            ],
          ),
        ),
        AlongButton(label: 'Accept ${_bids[_selected].fare}', onPressed: _noop),
      ],
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
            final star = short ? 36.0 : 44.0;
            return Column(
              children: [
                const Expanded(
                  child: AlongCityMap(mode: AlongCityMapMode.completed),
                ),
                ColoredBox(
                  color: palette.bg,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          portrait / 2 + (short ? 6 : 8),
                          16,
                          12,
                        ),
                        child: Column(
                          children: [
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
                            SizedBox(height: short ? 12 : 16),
                            const _RatingGrid(),
                            SizedBox(height: short ? 8 : 12),
                            const _TipRow(),
                            SizedBox(height: short ? 8 : 12),
                            const _NoteField(),
                            SizedBox(height: short ? 8 : 12),
                            const _SendThanks(),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -portrait / 2,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: AlongDriverPortrait(
                            size: portrait,
                            verified: true,
                          ),
                        ),
                      ),
                    ],
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

class _RatingGrid extends StatelessWidget {
  const _RatingGrid();

  static const _tags = <(String, bool)>[
    ('Smooth ride', true),
    ('Clean car', false),
    ('On time', false),
    ('Safe driving', false),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    Widget tile(String label, bool selected) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: palette.ink.withValues(alpha: selected ? 1 : 0.28),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: AlongType.label(palette),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _tags.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: tile(_tags[i].$1, _tags[i].$2)),
              const SizedBox(width: 8),
              Expanded(child: tile(_tags[i + 1].$1, _tags[i + 1].$2)),
            ],
          ),
        ],
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow();

  static const _tips = ['₦100', '₦200', '₦500', 'Custom'];

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < _tips.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.ink.withValues(
                    alpha: _tips[i] == '₦200' ? 1 : 0.28,
                  ),
                  width: _tips[i] == '₦200' ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _tips[i],
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: AlongType.label(palette).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 40,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: palette.recessed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Add a note',
        maxLines: 1,
        softWrap: false,
        style: AlongType.caption(palette),
      ),
    );
  }
}

/// Content-width pills, two per row. A chip must not stretch.
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
              progress: live ? 0.62 : 1,
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
          AlongGrade(
            child: Image.asset(
              'assets/photos/onboarding-fleet.jpg',
              package: 'along_design',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
          const AlongNoise(opacity: 0.03),
          const Positioned.fill(child: _PosterRoute()),
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
          const Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: _StepDots(count: 3, index: 0),
          ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? const Color(0xFFF7D117)
                  : const Color(0xE6FFFFFF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}

/// A quiet route drawn across the poster. Tests and reduced motion show
/// the finished line.
class _PosterRoute extends StatefulWidget {
  const _PosterRoute();

  @override
  State<_PosterRoute> createState() => _PosterRouteState();
}

class _PosterRouteState extends State<_PosterRoute>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: AlongDurations.routeDraw,
      value: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AlongMotionPolicy.play(context)) return;
      _draw.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _draw,
      builder: (context, _) {
        final t = AlongMotionPolicy.play(context) ? _draw.value : 1.0;
        return CustomPaint(
          painter: _PosterRoutePainter(progress: t),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _PosterRoutePainter extends CustomPainter {
  const _PosterRoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.48,
        size.width * 0.52,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.68,
        size.width * 0.90,
        size.height * 0.46,
      );
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress.clamp(0, 1));
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x660E0E10),
    );
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xF2FFFFFF),
    );
    if (progress > 0.98) {
      canvas.drawCircle(
        Offset(size.width * 0.90, size.height * 0.46),
        5,
        Paint()..color = const Color(0xFFF7D117),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PosterRoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
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
      duration: AlongDurations.hold,
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Call 112',
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: AlongType.body(palette).copyWith(
                        color: palette.onInk,
                        height: 1,
                        fontWeight: FontWeight.w600,
                      ),
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
      decoration: AlongCraft.surface(
        palette,
        radius: 18,
        shadow: AlongElevation.card(palette.ink),
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
                      .copyWith(fontWeight: FontWeight.w600),
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
        style: AlongType.title(palette).copyWith(fontWeight: FontWeight.w600),
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
    // One rest pose. A looping glow is decoration, not the next action.
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
            borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
    this.action,
    this.actionKey,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? action;
  final Key? actionKey;

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
              borderRadius: BorderRadius.circular(12),
            ),
            child: AlongIcon(icon, size: 20, color: palette.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AlongType.body(palette),
            ),
          ),
          if (action != null)
            TextButton(
              key: actionKey,
              onPressed: _noop,
              style: TextButton.styleFrom(
                foregroundColor: palette.ink,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                action!,
                maxLines: 1,
                softWrap: false,
                style: AlongType.label(palette).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              detail,
              maxLines: 1,
              softWrap: false,
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
    return Text(
      label,
      maxLines: 1,
      softWrap: false,
      style: AlongType.label(palette).copyWith(height: 1.2),
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
        border: Border(
          bottom: BorderSide(color: palette.ink.withValues(alpha: 0.12)),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: _RideRow(
          kind: AlongVehicleKind.keke,
          title: 'Keke',
          eta: '4-6 min',
          seatCount: 2,
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
    required this.fare,
    required this.seatCount,
    this.badge,
  });

  final AlongVehicleKind kind;
  final String title;
  final String eta;
  final String fare;
  final int seatCount;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink.withValues(alpha: 0.12)),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
              children: [
                AlongVehicleHero(kind: kind, width: 48, height: 30),
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
                        style: AlongType.body(palette)
                            .copyWith(fontWeight: FontWeight.w600, height: 1.1),
                      ),
                      Text(
                        badge == null ? eta : '$badge · $eta',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: AlongType.caption(palette).copyWith(
                          color: palette.ink.withValues(alpha: 0.72),
                        ),
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
                    style: AlongType.body(palette).copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
          ),
        ),
      ),
    );
  }
}

class _RideRow extends StatelessWidget {
  const _RideRow({
    required this.kind,
    required this.title,
    required this.eta,
    required this.fare,
    this.seatCount = 2,
    this.rules = const [],
    this.badge,
    this.selected = false,
  });

  final AlongVehicleKind kind;
  final String title;
  final String eta;
  final String fare;
  final int seatCount;
  final List<String> rules;
  final String? badge;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final rulesLine = rules.join(' · ');
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.05;
    return ConstrainedBox(
      key: ValueKey(selected),
      constraints: BoxConstraints(
        minHeight: 104,
        maxHeight: roomy ? double.infinity : 104,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            AlongVehicleHero(kind: kind, width: 96, height: 60),
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
                          title,
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.body(
                            palette,
                          ).copyWith(fontWeight: FontWeight.w600, height: 1.1),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          _RideBadge(badge!),
                        ],
                      ],
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          eta,
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.caption(palette),
                        ),
                        const SizedBox(width: 6),
                        AlongSeatCount(count: seatCount, glyph: 14),
                      ],
                    ),
                  ),
                  if (rulesLine.isNotEmpty)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        rulesLine,
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.caption(palette).copyWith(
                          color: palette.ink,
                          fontWeight: FontWeight.w600,
                        ),
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
                  fare,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.body(palette)
                      .copyWith(fontWeight: FontWeight.w600, height: 1.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        solid: true,
        radius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: AlongType.caption(palette).copyWith(
            fontWeight: FontWeight.w600,
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
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.05;
    final place = AlongType.body(palette)
        .copyWith(fontWeight: FontWeight.w600, height: 1.1);
    return SizedBox(
      height: roomy ? null : 44,
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

/// Seat-screen painter, high contrast, inside the cabin outline. Selected
/// cushions are yellow. Taken and driver cushions are dark.
class _OfferSeats extends StatelessWidget {
  const _OfferSeats();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inner = math.max(0.0, constraints.maxWidth - 24 - 16);
        final seat = math.min(44.0, inner / 4);
        return AlongCabinDiagram(
          seat: seat,
          contrast: true,
          rows: const [
            ['driver', 'yours'],
            ['occupied', 'free', 'free', 'held'],
          ],
        );
      },
    );
  }
}

class _RiderRow extends StatelessWidget {
  const _RiderRow();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.05;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 48,
        maxHeight: roomy ? double.infinity : 48,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: roomy ? 4 : 0),
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
      fontWeight: FontWeight.w600,
      color: palette.ink.withValues(alpha: 0.72),
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
                width: 40,
                child: Padding(
                  padding: const EdgeInsets.only(top: 22, bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₦60k', maxLines: 1, softWrap: false, style: axis),
                      const Spacer(),
                      Text('₦30k', maxLines: 1, softWrap: false, style: axis),
                      const Spacer(),
                      Text('₦0', maxLines: 1, softWrap: false, style: axis),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 22,
                      bottom: 18,
                      child: Column(
                        children: [
                          _grid(palette),
                          const Spacer(),
                          _grid(palette),
                          const Spacer(),
                          _grid(palette),
                        ],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [for (final bar in bars) _WeekBar(bar: bar)],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _grid(AlongPalette palette) {
    return Container(height: 0.5, color: palette.ink.withValues(alpha: 0.10));
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({required this.bar});

  final (String, double, bool) bar;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final selected = bar.$3;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            SizedBox(
              height: 18,
              width: double.infinity,
              child: selected
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.ink,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          child: Text(
                            '₦48k',
                            maxLines: 1,
                            softWrap: false,
                            style: AlongType.caption(palette).copyWith(
                              fontWeight: FontWeight.w600,
                              color: palette.onInk,
                              height: 1,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: bar.$2 / 60,
                  child: Container(
                    width: 8,
                    decoration: BoxDecoration(
                      color: selected
                          ? palette.ink
                          : palette.ink.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bar.$1,
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette).copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? palette.ink : palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarnList extends StatelessWidget {
  const _EarnList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: const [
        _EarningTrip(place: 'Nyanya', fare: '₦1,800', tip: '₦200'),
        _EarningTrip(place: 'Wuse', fare: '₦1,200'),
        _EarningTrip(place: 'Garki', fare: '₦900', tip: '₦100'),
        _EarningTrip(place: 'Berger', fare: '₦1,400'),
        _EarningTrip(place: 'Jabi', fare: '₦1,600', tip: '₦300'),
        _EarningTrip(place: 'Airport', fare: '₦3,200'),
      ],
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
                fontSize: 16,
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
                fontSize: 13,
                height: 1.1,
                color: palette.success,
                fontWeight: FontWeight.w600,
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
      solid: true,
              radius: 12,
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
        if (_open) ...[
          const SizedBox(height: 8),
          Text(
            'Wuse park · 3 seats open',
            maxLines: 1,
            softWrap: false,
            style: AlongType.meta(AlongPalette.of(context)),
          ),
        ],
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
              solid: true,
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                'Today · ₦18,400',
                maxLines: 1,
                softWrap: false,
                style: AlongType.title(palette)
                    .copyWith(fontSize: 16, height: 1.2),
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
      fontSize: 13,
      height: 1.1,
      color: palette.ink,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  palette.ink.withValues(alpha: 0.06),
                  palette.ink.withValues(alpha: 0.12),
                  palette.ink.withValues(alpha: 0.20),
                  palette.accent.withValues(alpha: 0.85),
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

/// Vector plate inside the viewfinder. The bumper photo was a foreshortened
/// crop, so the characters read as stretched. This plate is drawn front-on.
class _PlateFrame extends StatelessWidget {
  const _PlateFrame();

  /// Front-on Nigerian plate, green band included. Not the bumper crop.
  static const _aspect = 3.45;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final holeW = size.width - 32;
        final hole = Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.40),
          width: holeW,
          height: holeW / _aspect,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF12110F)),
            Positioned.fromRect(rect: hole, child: const _NigeriaPlate()),
            Positioned.fill(child: _Viewfinder(hole: hole)),
          ],
        );
      },
    );
  }
}

class _NigeriaPlate extends StatelessWidget {
  const _NigeriaPlate();

  @override
  Widget build(BuildContext context) {
    final font = AlongPalette.of(context).fontFamily;
    const ink = Color(0xFF141210);
    const green = Color(0xFF0C6B32);
    final band = TextStyle(
      fontFamily: font,
      fontFamilyFallback: AlongType.fallback,
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      height: 1,
    );
    final state = TextStyle(
      fontFamily: font,
      fontFamilyFallback: AlongType.fallback,
      color: green,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.4,
      height: 1,
    );
    final number = TextStyle(
      fontFamily: font,
      fontFamilyFallback: AlongType.fallback,
      color: ink,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget line(String text, TextStyle style) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, maxLines: 1, softWrap: false, style: style),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ink, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Expanded(
              flex: 24,
              child: ColoredBox(
                color: green,
                child: Center(child: line('FEDERAL REPUBLIC OF NIGERIA', band)),
              ),
            ),
            Expanded(flex: 18, child: Center(child: line('ABUJA', state))),
            Expanded(
              flex: 46,
              child: Center(child: line('ABC-123-XY', number)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Viewfinder extends StatefulWidget {
  const _Viewfinder({required this.hole});

  final Rect hole;

  @override
  State<_Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<_Viewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(
      vsync: this,
      duration: AlongDurations.scan,
      value: 0.42,
    );
    // The scan rests. A loop would decorate the photo.
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scan,
      builder: (context, _) {
        final scan = AlongMotionPolicy.play(context) ? _scan.value : 0.42;
        return CustomPaint(
          painter: _ViewfinderPainter(hole: widget.hole, scan: scan),
        );
      },
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter({required this.hole, required this.scan});

  final Rect hole;
  final double scan;

  @override
  void paint(Canvas canvas, Size size) {
    final cut = RRect.fromRectAndRadius(hole, const Radius.circular(18));
    final dim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(cut),
    );
    canvas.drawPath(dim, Paint()..color = const Color(0xB3000000));
    canvas.drawRRect(
      cut,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFF7F4EF),
    );
    const arm = 22.0;
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF7F4EF);
    void corner(Offset origin, double dx, double dy) {
      canvas.drawLine(origin, origin + Offset(dx * arm, 0), bracket);
      canvas.drawLine(origin, origin + Offset(0, dy * arm), bracket);
    }

    corner(hole.topLeft, 1, 1);
    corner(hole.topRight, -1, 1);
    corner(hole.bottomLeft, 1, -1);
    corner(hole.bottomRight, -1, -1);
    final y = hole.top + hole.height * scan.clamp(0.08, 0.92);
    canvas.drawLine(
      Offset(hole.left + 14, y),
      Offset(hole.right - 14, y),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF7D117),
    );
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) {
    return oldDelegate.hole != hole || oldDelegate.scan != scan;
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
      duration: AlongDurations.hold,
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
                      'Call 112',
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
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Icon(AlongIcons.check, size: 18, color: palette.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Plate matches',
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette).copyWith(
                color: palette.success,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
          const _PlateChip(label: 'ABC-123-XY'),
        ],
      ),
    );
  }
}

class _SosAvatars extends StatelessWidget {
  const _SosAvatars();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _SosAvatar(name: 'Adaeze', asset: AlongDriverPortrait.adaeze),
        SizedBox(width: 16),
        _SosAvatar(name: 'Chidi', initials: 'CH'),
        SizedBox(width: 16),
        _SosAvatar(name: 'Ngozi', initials: 'NG'),
      ],
    );
  }
}

class _SosAvatar extends StatelessWidget {
  const _SosAvatar({required this.name, this.asset, this.initials});

  final String name;
  final String? asset;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      children: [
        if (asset != null)
          AlongDriverPortrait(size: 48, asset: asset!, verified: true)
        else
          _Monogram(initials: initials ?? '', size: 48),
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette)
              .copyWith(color: palette.ink, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _GuardianPeople extends StatelessWidget {
  const _GuardianPeople();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: AlongElevation.hairline(palette.ink),
        boxShadow: AlongElevation.rest(palette.ink),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          children: [
            _AvatarStack(),
            SizedBox(height: 8),
            _GuardianFoot(),
            _ShareToggle(label: 'Share live location', on: true),
            _ShareToggle(label: 'Share the plate', on: false),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    Widget face(Widget child) {
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.surface, width: 2),
        ),
        child: child,
      );
    }

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Stack(
              children: [
                face(
                  const AlongDriverPortrait(
                    size: 44,
                    asset: AlongDriverPortrait.adaeze,
                    verified: true,
                  ),
                ),
                Positioned(
                  left: 32,
                  child: face(const _Monogram(initials: 'CH', size: 44)),
                ),
                Positioned(
                  left: 64,
                  child: face(const _Monogram(initials: 'NG', size: 44)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Adaeze, Chidi, Ngozi',
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600, height: 1.1),
            ),
          ),
        ],
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

class _WalletActions extends StatelessWidget {
  const _WalletActions();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final style = AlongType.label(palette);
    Widget word(String label) => Text(
      label,
      maxLines: 1,
      softWrap: false,
      style: style,
    );
    return Row(
      children: [
        word('Top up'),
        const SizedBox(width: 24),
        word('Send'),
        const SizedBox(width: 24),
        word('Pass'),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
          _TxnGroup(label: 'Today', icon: AlongIcons.schedule),
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
          _TxnGroup(label: 'Yesterday', icon: AlongIcons.path),
          _TxnRow(
            icon: AlongIcons.navigate,
            title: 'Berger',
            detail: 'Seat hold',
            value: '−₦900',
          ),
          _TxnGroup(label: 'This week', icon: AlongIcons.receipt),
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
    );
  }
}

class _TxnGroup extends StatelessWidget {
  const _TxnGroup({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: [
          AlongIcon(icon, size: 20, color: palette.ink),
          const SizedBox(width: 8),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette)
                .copyWith(fontWeight: FontWeight.w600, color: palette.ink),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: palette.ink.withValues(alpha: 0.12),
            ),
          ),
        ],
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
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.05;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 52,
        maxHeight: roomy ? double.infinity : 52,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: roomy ? 4 : 0),
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
      ),
    );
  }
}

class _DayBoard extends StatelessWidget {
  const _DayBoard();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [_DayTimeline(), SizedBox(height: 8), _DayFooter()],
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

  static const _morning = <(String, AlongVehicleKind, String, String, String)>[
    ('07:10', AlongVehicleKind.keke, 'Wuse', 'Nyanya', '₦1,400'),
    ('08:40', AlongVehicleKind.car, 'Berger', 'Garki', '₦900'),
    ('10:15', AlongVehicleKind.danfo, 'Jabi', 'Wuse', '₦1,200'),
  ];

  static const _afternoon =
      <(String, AlongVehicleKind, String, String, String)>[
        ('12:05', AlongVehicleKind.keke, 'Nyanya', 'Wuse', '₦1,600'),
        ('14:20', AlongVehicleKind.car, 'Garki', 'Jabi', '₦700'),
        ('16:45', AlongVehicleKind.bus, 'Wuse', 'Berger', '₦1,100'),
        ('18:30', AlongVehicleKind.car, 'Airport', 'Wuse', '₦2,400'),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _DayBand(label: 'Morning', stops: _morning),
        _DayBand(label: 'Afternoon', stops: _afternoon),
      ],
    );
  }
}

class _DayBand extends StatelessWidget {
  const _DayBand({required this.label, required this.stops});

  final String label;
  final List<(String, AlongVehicleKind, String, String, String)> stops;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette)
                .copyWith(color: palette.ink, fontWeight: FontWeight.w600),
          ),
        ),
        Stack(
          children: [
            Positioned(
              left: 5,
              top: 12,
              bottom: 12,
              child: SizedBox(
                width: 2,
                child: ColoredBox(color: palette.ink.withValues(alpha: 0.16)),
              ),
            ),
            Column(
              children: [
                for (final stop in stops)
                  _DayStop(
                    time: stop.$1,
                    kind: stop.$2,
                    from: stop.$3,
                    to: stop.$4,
                    fare: stop.$5,
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DayStop extends StatelessWidget {
  const _DayStop({
    required this.time,
    required this.kind,
    required this.from,
    required this.to,
    required this.fare,
  });

  final String time;
  final AlongVehicleKind kind;
  final String from;
  final String to;
  final String fare;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final route = AlongType.caption(palette)
        .copyWith(color: palette.ink, fontWeight: FontWeight.w600, height: 1.1);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: palette.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.ink, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AlongVehicleMark(kind: kind, width: 64, height: 40),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 16,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: from),
                          const TextSpan(text: ' → '),
                          TextSpan(text: to),
                        ],
                      ),
                      maxLines: 1,
                      softWrap: false,
                      style: route,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            fare,
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 14, height: 1.1, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _BidRow extends StatelessWidget {
  const _BidRow({
    required this.bid,
    required this.selected,
    required this.onTap,
  });

  final _SearchBid bid;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? palette.ink
                    : palette.ink.withValues(alpha: 0.12),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _BidRadio(selected: selected),
                  const SizedBox(width: 8),
                  if (bid.initials != null)
                    AlongMonogram(initials: bid.initials!, size: 40)
                  else
                    AlongDriverPortrait(
                      size: 40,
                      asset: bid.rider
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
                          bid.name,
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.body(
                            palette,
                          ).copyWith(fontWeight: FontWeight.w600, height: 1.1),
                        ),
                        Text(
                          '${bid.rating} · ${bid.eta}',
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.caption(palette).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    bid.fare,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.body(palette)
                        .copyWith(fontWeight: FontWeight.w600, height: 1.1),
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

class _BidRadio extends StatelessWidget {
  const _BidRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? palette.accent : const Color(0x00000000),
        border: Border.all(
          color: selected
              ? palette.accentInk
              : palette.ink.withValues(alpha: 0.35),
          width: selected ? 0 : 1.5,
        ),
      ),
      child: selected
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: palette.accentInk,
                shape: BoxShape.circle,
              ),
            )
          : null,
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
        Text(
          '4-day streak',
          maxLines: 1,
          softWrap: false,
          style: AlongType.label(palette),
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
      duration: AlongDurations.scan,
    );
    // Rest pose. A looping sweep is decoration, not status.
    _controller.value = 0.38;
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
            animate: false,
            repeat: false,
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
